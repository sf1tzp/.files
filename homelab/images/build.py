#!/usr/bin/env python3
"""
Custom Base Image Builder

Builds user-agnostic Ubuntu base images. Creates a temporary VM from a cloud
image, installs system packages defined by a spec file, cleans up, and converts
the disk to a reusable base image.
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path


class ImageBuilder:
    def __init__(self):
        self.script_dir = Path(__file__).parent.resolve()
        self.playbook = "build-playbook.yaml"

        # Default configuration
        self.base_image = "ubuntu-server-24.04"
        self.custom_name = ""
        self.spec = "base"
        self.run_tags = ["setup", "finalize"]

    def parse_arguments(self):
        parser = argparse.ArgumentParser(
            description="Build a custom Ubuntu base image from an image spec.",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
EXAMPLES:
    %(prog)s --name base-24.04                          # Base image (default spec)
    %(prog)s --name base-24.04 --spec containerd        # With container prerequisites
    %(prog)s --name base-24.04 --spec full              # Everything
    %(prog)s --name base-24.04 --setup                  # Setup only (for manual intervention)
    %(prog)s --name base-24.04 --finalize               # Finalize only (after manual changes)
    %(prog)s -b ubuntu-server-22.04 --name base-22.04   # Ubuntu 22.04

TAG-BASED WORKFLOW:
    For images requiring manual intervention between setup and finalization:
    1. Run with --setup to install and configure packages
    2. Make manual adjustments to the VM as needed
    3. Run with --finalize to clean up and create the final base image

The resulting image will be saved to:
    /var/lib/libvirt/images/bases/{NAME}.qcow2

You can then reference it in inventory as:
    os: {NAME}
            """,
        )

        parser.add_argument(
            "-b",
            "--base-image",
            choices=["ubuntu-server-24.04", "ubuntu-server-22.04"],
            default=self.base_image,
            help="Base image to use (default: %(default)s)",
        )

        parser.add_argument(
            "-o",
            "--name",
            required=True,
            help="Name for the output image (e.g., base-24.04)",
        )

        parser.add_argument(
            "-s",
            "--spec",
            default=self.spec,
            help="Image spec to use (default: %(default)s). Loads specs/{SPEC}.yaml",
        )

        tag_group = parser.add_mutually_exclusive_group()
        tag_group.add_argument(
            "--setup",
            action="store_true",
            help="Run only setup tasks (install packages)",
        )
        tag_group.add_argument(
            "--finalize",
            action="store_true",
            help="Run only finalization tasks (cleanup, convert to base image)",
        )

        args = parser.parse_args()

        self.base_image = args.base_image
        self.custom_name = args.name
        self.spec = args.spec

        if args.setup:
            self.run_tags = ["setup"]
        elif args.finalize:
            self.run_tags = ["finalize"]
        else:
            self.run_tags = ["setup", "finalize"]

        return args

    def print_config(self):
        print("Building custom base image:")
        print(f"   Base image: {self.base_image}")
        print(f"   Output name: {self.custom_name}")
        print(f"   Spec: {self.spec}")
        print(f"   Tags: {','.join(self.run_tags)}")
        print()

    def check_prerequisites(self):
        print("Checking prerequisites...")

        required_commands = ["just", "ansible-playbook", "virsh"]
        for cmd in required_commands:
            if subprocess.run(["which", cmd], capture_output=True).returncode != 0:
                print(f"Error: {cmd} not found.")
                sys.exit(1)

        ssh_key_path = Path.home() / ".ssh" / "id_ed25519.pub"
        if not ssh_key_path.exists():
            print("Error: SSH public key not found at ~/.ssh/id_ed25519.pub")
            sys.exit(1)

        base_image_path = Path(
            f"/var/lib/libvirt/images/bases/{self.base_image}.qcow2"
        )
        if not base_image_path.exists():
            print(f"Error: Base image not found: {base_image_path}")
            print("   Run: ansible-playbook vms/base-images.yaml")
            sys.exit(1)

        spec_path = self.script_dir / "specs" / f"{self.spec}.yaml"
        if not spec_path.exists():
            print(f"Error: Spec file not found: {spec_path}")
            print(f"   Available specs: {', '.join(p.stem for p in (self.script_dir / 'specs').glob('*.yaml'))}")
            sys.exit(1)

        print("Prerequisites OK")
        print()

    def run_command(self, cmd, check=True, cwd=None):
        result = subprocess.run(
            cmd, shell=True, cwd=cwd, capture_output=True, text=True
        )
        if check and result.returncode != 0:
            print(f"Command failed: {cmd}")
            print(f"Error: {result.stderr}")
            sys.exit(1)
        return result

    def cleanup_stale_disks(self):
        """Remove leftover disk files from previous builds.

        The delete playbook skips disk removal if the VM is no longer defined
        in libvirt, leaving orphaned qcow2/iso files owned by libvirt-qemu
        that block qemu-img create.
        """
        libvirt_images = Path("/var/lib/libvirt/images")
        stale_files = [
            libvirt_images / "custom-image-builder.qcow2",
            libvirt_images / "custom-image-builder-cloud-init.iso",
        ]
        for path in stale_files:
            if path.exists():
                try:
                    path.unlink()
                    print(f"   Removed stale {path.name}")
                except PermissionError:
                    print(f"   Cannot remove {path} -- trying with sudo")
                    subprocess.run(["sudo", "rm", "-f", str(path)], check=True)

    def handle_vm_creation(self):
        if "setup" in self.run_tags:
            print("Cleaning up any existing builder VM...")
            os.chdir(self.script_dir.parent)

            result = subprocess.run(
                ["just", "delete", "custom-image-builder"],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                print("   Existing VM cleaned up")
            else:
                print("   No existing VM to clean up")

            self.cleanup_stale_disks()

            print("Creating builder VM...")

            cmd = [
                "ansible-playbook",
                "vms/create-linux.yaml",
                "--inventory",
                str(Path.home() / ".files/homelab/inventory.yaml"),
                "--vault-password-file",
                str(Path.home() / ".ansible-password"),
                "--extra-vars",
                "target_vms=custom-image-builder",
            ]

            result = subprocess.run(cmd)
            if result.returncode != 0:
                print("Failed to create builder VM")
                sys.exit(1)

            print("Builder VM created")
            time.sleep(15)

        elif self.run_tags == ["finalize"]:
            print("Using existing builder VM for finalization...")
            os.chdir(self.script_dir.parent)

            result = subprocess.run(
                ["virsh", "domstate", "custom-image-builder"],
                capture_output=True,
                text=True,
            )

            if result.returncode != 0:
                print("Error: VM 'custom-image-builder' does not exist. Run setup first:")
                print(f"   {sys.argv[0]} --name {self.custom_name} --setup")
                sys.exit(1)

            vm_state = result.stdout.strip()
            if vm_state != "running":
                print("Starting existing builder VM...")
                subprocess.run(
                    ["virsh", "start", "custom-image-builder"], check=True
                )
                time.sleep(15)

    def run_ansible_playbook(self):
        print("Running build playbook...")
        os.chdir(self.script_dir)

        cmd = [
            "ansible-playbook",
            self.playbook,
            "-e",
            f"spec={self.spec}",
            "-e",
            f"custom_image_name={self.custom_name}",
            "--inventory",
            str(Path.home() / ".files/homelab/inventory.yaml"),
        ]

        if "setup" in self.run_tags and "finalize" not in self.run_tags:
            cmd.extend(["--limit", "custom-image-builder"])

        if self.run_tags != ["setup", "finalize"]:
            cmd.extend(["--tags", ",".join(self.run_tags)])

        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd)

        return result.returncode == 0

    def handle_success(self):
        if "finalize" in self.run_tags:
            print()
            print("Build completed successfully!")
            print("Cleaning up builder VM...")
            result = subprocess.run(
                ["just", "delete", "custom-image-builder"], capture_output=True
            )
            if result.returncode != 0:
                print("Warning: Failed to delete builder VM")
        elif self.run_tags == ["setup"]:
            print()
            print("Setup phase completed.")
            print("VM 'custom-image-builder' is running for manual adjustments:")
            print("    SSH: ssh ubuntu@10.0.0.10")
            print("    Console: virsh console custom-image-builder")
            print()
            print("After manual changes, finalize:")
            print(f"   {sys.argv[0]} --name {self.custom_name} --finalize")
            print()
            print("Or cleanup: just delete custom-image-builder")

    def handle_failure(self):
        print()
        print("Build failed. Check output above.")
        print("VM left running for investigation:")
        print("    SSH: ssh ubuntu@10.0.0.10")
        print("    Console: virsh console custom-image-builder")
        print("    Cleanup: just delete custom-image-builder")

    def build(self):
        self.parse_arguments()
        self.print_config()
        self.check_prerequisites()
        self.handle_vm_creation()

        success = self.run_ansible_playbook()

        if success:
            self.handle_success()
        else:
            self.handle_failure()
            sys.exit(1)


def main():
    builder = ImageBuilder()
    builder.build()


if __name__ == "__main__":
    main()
