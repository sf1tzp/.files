#!/usr/bin/env python3
"""
Cloud-init based image builder.

Reads a YAML config file and builds a custom VM base image.
No Ansible required — uses cloud-init for all provisioning.

Usage:
    ./build-image.py images/devbox.yaml
    ./build-image.py images/devbox.yaml --name my-custom-image
    ./build-image.py images/routing.yaml --interactive
"""

import argparse
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import yaml


VM_NAME = "image-builder"
IMAGES_DIR = Path("/var/lib/libvirt/images")
BASES_DIR = IMAGES_DIR / "bases"

VM_XML = """\
<domain type='kvm'>
  <name>{vm_name}</name>
  <memory unit='MiB'>{memory}</memory>
  <vcpu placement='static'>{vcpus}</vcpu>
  <os>
    <type arch='x86_64' machine='pc-q35-6.2'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='{disk_path}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='{iso_path}'/>
      <target dev='hda' bus='ide'/>
      <readonly/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <graphics type='vnc' port='-1' autoport='yes'/>
  </devices>
</domain>"""


# --- YAML literal block scalar support ---

class LiteralStr(str):
    """String that serializes as a YAML literal block scalar (|)."""
    pass


def _literal_representer(dumper, data):
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")


yaml.add_representer(LiteralStr, _literal_representer)


# --- Image Builder ---

class ImageBuilder:
    def __init__(self, config_path, name=None, interactive=False):
        self.config_path = Path(config_path).resolve()
        self.scripts_dir = self.config_path.parent / "scripts"
        self.interactive = interactive

        with open(self.config_path) as f:
            self.config = yaml.safe_load(f)

        self.name = name or self.config_path.stem
        self.base_image = self.config["base_image"]
        self.user = self.config["user"]
        self.packages = self.config.get("packages", [])
        self.versions = self.config.get("versions", {})
        self.scripts = self.config.get("scripts", [])

        self.disk_path = IMAGES_DIR / f"{VM_NAME}.qcow2"
        self.iso_path = IMAGES_DIR / f"{VM_NAME}-cloudinit.iso"
        self.output_path = BASES_DIR / f"{self.name}.qcow2"
        self.base_image_path = BASES_DIR / f"{self.base_image}.qcow2"

    # --- Validation ---

    def check_prerequisites(self):
        for cmd in ["virsh", "qemu-img", "cloud-localds"]:
            if subprocess.run(["which", cmd], capture_output=True).returncode != 0:
                print(f"Error: {cmd} not found")
                sys.exit(1)

        if not self.base_image_path.exists():
            print(f"Error: Base image not found: {self.base_image_path}")
            sys.exit(1)

        for script in self.scripts:
            if not (self.scripts_dir / script).exists():
                print(f"Error: Script not found: {self.scripts_dir / script}")
                sys.exit(1)

        if not (self.scripts_dir / "finalize.sh").exists():
            print(f"Error: finalize.sh not found in {self.scripts_dir}")
            sys.exit(1)

        if self.output_path.exists():
            print(f"Error: Output image already exists: {self.output_path}")
            print("  Delete it first if you want to rebuild.")
            sys.exit(1)

    # --- Cloud-init generation ---

    def _build_env_content(self):
        lines = [f'export IMAGE_USER="{self.user["name"]}"']
        for key, value in self.versions.items():
            lines.append(f'export {key.upper()}_VERSION="{value}"')
        return "\n".join(lines) + "\n"

    def _build_write_files(self):
        files = []

        # Env file with version variables
        files.append({
            "path": "/opt/image-build/env",
            "content": LiteralStr(self._build_env_content()),
        })

        # Setup scripts
        for script in self.scripts:
            content = (self.scripts_dir / script).read_text()
            files.append({
                "path": f"/opt/image-build/scripts/{script}",
                "permissions": "0755",
                "content": LiteralStr(content),
            })

        # Finalize script (always included)
        content = (self.scripts_dir / "finalize.sh").read_text()
        files.append({
            "path": "/opt/image-build/finalize.sh",
            "permissions": "0755",
            "content": LiteralStr(content),
        })

        return files

    def _build_runcmd(self):
        cmds = []
        for script in self.scripts:
            cmds.append(
                ["bash", "-c", f"source /opt/image-build/env && /opt/image-build/scripts/{script}"]
            )

        if not self.interactive:
            cmds.append(
                ["bash", "-c", "/opt/image-build/finalize.sh"]
            )

        return cmds

    def generate_userdata(self):
        cloud_config = {
            "hostname": VM_NAME,
            "users": [
                {
                    "name": self.user["name"],
                    "shell": self.user.get("shell", "/bin/bash"),
                    "groups": "sudo",
                    "sudo": "ALL=(ALL) NOPASSWD:ALL",
                    "ssh_import_id": [f"gh:{self.user['github']}"],
                }
            ],
            "package_update": True,
            "package_upgrade": True,
            "packages": self.packages,
            "write_files": self._build_write_files(),
            "runcmd": self._build_runcmd(),
        }

        if not self.interactive:
            cloud_config["power_state"] = {
                "mode": "poweroff",
                "message": "Image build complete",
                "timeout": 30,
                "condition": True,
            }

        return "#cloud-config\n" + yaml.dump(
            cloud_config, default_flow_style=False, sort_keys=False
        )

    def generate_metadata(self):
        return yaml.dump(
            {"instance-id": VM_NAME, "local-hostname": VM_NAME},
            default_flow_style=False,
        )

    def generate_network_config(self):
        return yaml.dump(
            {"version": 2, "ethernets": {"ens3": {"dhcp4": True}}},
            default_flow_style=False,
        )

    # --- VM lifecycle ---

    def cleanup_existing(self):
        result = subprocess.run(
            ["virsh", "domstate", VM_NAME], capture_output=True, text=True
        )
        if result.returncode == 0:
            state = result.stdout.strip()
            if state == "running":
                subprocess.run(["virsh", "destroy", VM_NAME], capture_output=True)
            subprocess.run(["virsh", "undefine", VM_NAME], capture_output=True)

        for path in [self.disk_path, self.iso_path]:
            if path.exists():
                path.unlink()

    def create_vm(self):
        # Clone base image
        subprocess.run(
            [
                "qemu-img", "create", "-f", "qcow2",
                "-b", str(self.base_image_path), "-F", "qcow2",
                str(self.disk_path),
            ],
            check=True,
        )

        # Generate cloud-init ISO
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            (tmp / "userdata.yaml").write_text(self.generate_userdata())
            (tmp / "metadata.yaml").write_text(self.generate_metadata())
            (tmp / "network-config.yaml").write_text(self.generate_network_config())

            subprocess.run(
                [
                    "cloud-localds", str(self.iso_path),
                    "-N", str(tmp / "network-config.yaml"),
                    str(tmp / "userdata.yaml"),
                    str(tmp / "metadata.yaml"),
                ],
                check=True,
            )

        # Define and start VM
        vm_xml = VM_XML.format(
            vm_name=VM_NAME,
            memory=8192,
            vcpus=4,
            disk_path=self.disk_path,
            iso_path=self.iso_path,
        )

        with tempfile.NamedTemporaryFile(mode="w", suffix=".xml", delete=False) as f:
            f.write(vm_xml)
            xml_path = f.name

        try:
            subprocess.run(["virsh", "define", xml_path], check=True)
        finally:
            os.unlink(xml_path)

        subprocess.run(["virsh", "start", VM_NAME], check=True)

    def get_vm_ip(self):
        """Try to get the VM's DHCP-assigned IP address."""
        for _ in range(30):
            result = subprocess.run(
                ["virsh", "domifaddr", VM_NAME],
                capture_output=True, text=True,
            )
            if result.returncode == 0:
                for line in result.stdout.splitlines():
                    parts = line.split()
                    if len(parts) >= 4 and "/" in parts[-1]:
                        return parts[-1].split("/")[0]
            time.sleep(5)
        return None

    def wait_for_shutdown(self):
        print("Waiting for build to complete", end="", flush=True)
        while True:
            result = subprocess.run(
                ["virsh", "domstate", VM_NAME],
                capture_output=True, text=True,
            )
            if result.returncode != 0 or result.stdout.strip() == "shut off":
                break
            print(".", end="", flush=True)
            time.sleep(10)
        print(" done")

    def wait_interactive(self):
        ip = self.get_vm_ip()
        print()
        if ip:
            print(f"  SSH:  ssh {self.user['name']}@{ip}")
        else:
            print("  Could not determine VM IP.")
        print(f"  Console:  virsh console {VM_NAME}")
        print()
        print("  When done, run inside the VM:")
        print(f"    sudo /opt/image-build/finalize.sh && sudo poweroff")
        print()

        self.wait_for_shutdown()

    def convert_image(self):
        subprocess.run(
            [
                "qemu-img", "convert",
                "-f", "qcow2", "-O", "qcow2", "-c",
                str(self.disk_path), str(self.output_path),
            ],
            check=True,
        )

    def cleanup(self):
        subprocess.run(["virsh", "undefine", VM_NAME], capture_output=True)
        for path in [self.disk_path, self.iso_path]:
            if path.exists():
                path.unlink()

    # --- Main build flow ---

    def build(self):
        print(f"Building image '{self.name}' from {self.base_image}")
        print(f"  User: {self.user['name']}")
        print(f"  Packages: {len(self.packages)}")
        print(f"  Scripts: {', '.join(self.scripts) or 'none'}")
        if self.interactive:
            print(f"  Mode: interactive")
        print()

        self.check_prerequisites()

        print("Cleaning up any existing builder VM...")
        self.cleanup_existing()

        print("Creating builder VM...")
        self.create_vm()
        print("VM started. Cloud-init is provisioning...")

        if self.interactive:
            self.wait_interactive()
        else:
            self.wait_for_shutdown()

        print(f"Converting to base image: {self.output_path}")
        self.convert_image()

        print("Cleaning up builder VM...")
        self.cleanup()

        # Show result
        result = subprocess.run(
            ["qemu-img", "info", str(self.output_path)],
            capture_output=True, text=True,
        )
        print()
        print(f"Image saved to: {self.output_path}")
        print(f"Use in inventory as:  os: {self.name}")
        if result.returncode == 0:
            print()
            print(result.stdout)


def main():
    parser = argparse.ArgumentParser(
        description="Build custom VM images from YAML config using cloud-init.",
        epilog="""\
examples:
  %(prog)s images/devbox.yaml
  %(prog)s images/devbox.yaml --name sf1tzp-24.04
  %(prog)s images/routing.yaml --interactive
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("config", help="Path to image config YAML file")
    parser.add_argument("--name", help="Override output image name (default: config filename)")
    parser.add_argument(
        "--interactive",
        action="store_true",
        help="Keep VM running for manual intervention before finalizing",
    )

    args = parser.parse_args()

    if not Path(args.config).exists():
        print(f"Error: Config file not found: {args.config}")
        sys.exit(1)

    builder = ImageBuilder(args.config, name=args.name, interactive=args.interactive)
    builder.build()


if __name__ == "__main__":
    main()
