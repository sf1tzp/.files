#!/usr/bin/env python3
"""
Custom Base Image Builder Script
Builds Ubuntu base images with pre-installed homelab setup
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path


class CustomImageBuilder:
    def __init__(self):
        self.script_dir = Path(__file__).parent.resolve()
        self.playbook = "custom-base-image.yaml"

        # Default configuration
        self.base_image = "ubuntu-server-24.04"
        self.custom_name = ""
        self.username = "steven"
        self.include_common = True
        self.include_containerd = True
        self.include_nvidia = False
        self.include_monitoring = True
        self.run_tags = ["setup", "finalize"]  # Default: run both

    def parse_arguments(self):
        parser = argparse.ArgumentParser(
            description="Build a custom Ubuntu base image with pre-installed homelab setup.",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
EXAMPLES:
    %(prog)s --name sf1tzp-24.04                     # Basic custom image
    %(prog)s --name sf1tzp-24.04-nvidia --nvidia     # NVIDIA-enabled image
    %(prog)s --name minimal-dev --no-containerd      # Minimal development image
    %(prog)s -b ubuntu-server-22.04 --name sf1tzp-22.04  # Ubuntu 22.04 base
    %(prog)s --name dev-image --username developer   # Custom username
    %(prog)s --name sf1tzp-24.04 --setup             # Setup only (for manual intervention)
    %(prog)s --name sf1tzp-24.04 --finalize          # Finalize only (after manual changes)

TAG-BASED WORKFLOW:
    For custom images requiring manual intervention between setup and finalization:
    1. Run with --setup to install and configure packages
    2. Make manual adjustments to the VM as needed
    3. Run with --finalize to clean up and create the final base image

The resulting image will be saved to:
    /var/lib/libvirt/images/bases/{NAME}.qcow2

You can then reference it in create-linux.yaml vm_specs as:
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
            help="Custom name for the image (e.g., sf1tzp-24.04)",
        )

        parser.add_argument(
            "-u",
            "--username",
            default=self.username,
            help="Username to create and configure in the image (default: %(default)s)",
        )

        parser.add_argument(
            "-n",
            "--no-common",
            action="store_true",
            help="Skip common development tools",
        )

        parser.add_argument(
            "-c",
            "--no-containerd",
            action="store_true",
            help="Skip containerd/nerdctl installation",
        )

        parser.add_argument(
            "-g",
            "--nvidia",
            action="store_true",
            help="Include NVIDIA drivers and toolkit",
        )

        parser.add_argument(
            "-m",
            "--no-monitoring",
            action="store_true",
            help="Skip monitoring tools installation",
        )

        # Tag selection - mutually exclusive
        tag_group = parser.add_mutually_exclusive_group()
        tag_group.add_argument(
            "--setup",
            action="store_true",
            help="Run only setup tasks (install packages, configure tools)",
        )

        tag_group.add_argument(
            "--finalize",
            action="store_true",
            help="Run only finalization tasks (cleanup, convert to base image)",
        )

        args = parser.parse_args()

        # Apply parsed arguments
        self.base_image = args.base_image
        self.custom_name = args.name
        self.username = args.username
        self.include_common = not args.no_common
        self.include_containerd = not args.no_containerd
        self.include_nvidia = args.nvidia
        self.include_monitoring = not args.no_monitoring

        # Set run tags based on arguments
        if args.setup:
            self.run_tags = ["setup"]
        elif args.finalize:
            self.run_tags = ["finalize"]
        else:
            self.run_tags = ["setup", "finalize"]

        return args

    def print_config(self):
        """Print the build configuration"""
        print("🚀 Building custom base image with the following configuration:")
        print(f"   Base image: {self.base_image}")
        print(f"   Custom name: {self.custom_name}")
        print(f"   Username: {self.username}")
        print(f"   Run tags: {','.join(self.run_tags)}")
        print(f"   Common tools: {self.include_common}")
        print(f"   Containerd: {self.include_containerd}")
        print(f"   NVIDIA: {self.include_nvidia}")
        print(f"   Monitoring: {self.include_monitoring}")
        print()

    def check_prerequisites(self):
        """Check that all required tools are available"""
        print("🔍 Checking prerequisites...")

        # Check required commands
        required_commands = ["just", "ansible-playbook", "virsh"]
        for cmd in required_commands:
            if subprocess.run(["which", cmd], capture_output=True).returncode != 0:
                print(f"❌ {cmd} not found. Please install it.")
                if cmd == "just":
                    print("   See: https://github.com/casey/just#installation")
                elif cmd == "ansible-playbook":
                    print("   Please install Ansible.")
                elif cmd == "virsh":
                    print("   Please install libvirt.")
                sys.exit(1)

        # Check SSH key
        ssh_key_path = Path.home() / ".ssh" / "id_ed25519.pub"
        if not ssh_key_path.exists():
            print("❌ SSH public key not found at ~/.ssh/id_ed25519.pub")
            print("   Please generate one with: ssh-keygen -t ed25519")
            sys.exit(1)

        # Check base image
        base_image_path = Path(f"/var/lib/libvirt/images/bases/{self.base_image}.qcow2")
        if not base_image_path.exists():
            print(f"❌ Base image not found: {base_image_path}")
            print("   Please run: ansible-playbook base-images.yaml")
            sys.exit(1)

        print("✅ Prerequisites check passed")
        print()

    def run_command(self, cmd, check=True, cwd=None):
        """Run a command and return the result"""
        result = subprocess.run(
            cmd, shell=True, cwd=cwd, capture_output=True, text=True
        )
        if check and result.returncode != 0:
            print(f"❌ Command failed: {cmd}")
            print(f"Error: {result.stderr}")
            sys.exit(1)
        return result

    def handle_vm_creation(self):
        """Handle VM creation or validation based on run tags"""
        if "setup" in self.run_tags:
            print("🔧 Cleaning up any existing custom image builder VM...")
            os.chdir(self.script_dir.parent)

            # Clean up any existing VM
            result = subprocess.run(
                ["just", "delete", "custom-image-builder"],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                print("   Existing VM cleaned up")
            else:
                print("   No existing VM to clean up")

            print("🔧 Creating custom image builder VM...")

            # Create the VM
            cmd = [
                "ansible-playbook",
                "vms/create-linux.yaml",
                "--inventory",
                str(Path.home() / ".files/homelab/inventory.yaml"),
                "--vault-password-file",
                str(Path.home() / ".ansible-password"),
                "--extra-vars",
                f"target_vms=custom-image-builder vm_username={self.username}",
            ]

            result = subprocess.run(cmd)
            if result.returncode != 0:
                print("❌ Failed to create custom image builder VM")
                sys.exit(1)

            print("✅ Custom image builder VM created successfully")
            time.sleep(15)

        elif self.run_tags == ["finalize"]:
            print("🔧 Using existing custom image builder VM for finalization...")
            os.chdir(self.script_dir.parent)

            # Check if VM exists
            result = subprocess.run(
                ["virsh", "domstate", "custom-image-builder"],
                capture_output=True,
                text=True,
            )

            if result.returncode != 0:
                print(
                    "❌ VM 'custom-image-builder' does not exist. Run setup phase first:"
                )
                print(f"   {sys.argv[0]} --name {self.custom_name} --setup")
                sys.exit(1)

            # Check if VM is running
            vm_state = result.stdout.strip()
            if vm_state != "running":
                print("🔧 Starting existing custom-image-builder VM...")
                subprocess.run(["virsh", "start", "custom-image-builder"], check=True)
                time.sleep(15)

    def run_ansible_playbook(self):
        """Run the ansible playbook with proper configuration"""
        print("🔧 Running custom image build playbook...")
        os.chdir(self.script_dir)

        # Build setup_components as individual variables
        # Ansible handles boolean values better when passed individually

        # Build ansible command
        cmd = [
            "ansible-playbook",
            self.playbook,
            "-e",
            f"base_image_name={self.base_image}",
            "-e",
            f"custom_image_name={self.custom_name}",
            "-e",
            f"target_username={self.username}",
            "-e",
            f"include_common={str(self.include_common).lower()}",
            "-e",
            f"include_containerd={str(self.include_containerd).lower()}",
            "-e",
            f"include_nvidia={str(self.include_nvidia).lower()}",
            "-e",
            f"include_monitoring={str(self.include_monitoring).lower()}",
            "--inventory",
            str(Path.home() / ".files/homelab/inventory.yaml"),
        ]

        # Only limit to custom-image-builder for setup tasks
        # For finalize, we need both custom-image-builder and localhost
        if "setup" in self.run_tags and "finalize" not in self.run_tags:
            cmd.extend(["--limit", "custom-image-builder"])

        # Add tags if not running both
        if self.run_tags != ["setup", "finalize"]:
            cmd.extend(["--tags", ",".join(self.run_tags)])

        print(f"🔧 Running: {' '.join(cmd)}")
        result = subprocess.run(cmd)

        return result.returncode == 0

    def handle_success(self):
        """Handle successful completion based on run tags"""
        if "finalize" in self.run_tags:
            print()
            print("🎉 Custom base image build completed successfully!")
            print("🧹 Cleaning up custom image builder VM...")
            result = subprocess.run(
                ["just", "delete", "custom-image-builder"], capture_output=True
            )
            if result.returncode != 0:
                print("⚠️  Warning: Failed to delete custom-image-builder VM")

        elif self.run_tags == ["setup"]:
            print()
            print("✅ Setup phase completed successfully!")
            print(
                "🔍 VM 'custom-image-builder' is still running for manual adjustments"
            )
            print(f"    SSH: ssh {self.username}@10.0.0.7")
            print("    Console: virsh console custom-image-builder")
            print()
            print("💡 After making manual changes, run the finalization phase:")
            print(f"   {sys.argv[0]} --name {self.custom_name} --finalize")
            print()
            print("⚠️  Or cleanup when done: just delete custom-image-builder")
        else:
            print()
            print("✅ Playbook execution completed successfully!")
            print("🔍 VM 'custom-image-builder' is still running")
            print(f"    SSH: ssh {self.username}@10.0.0.7")
            print("    Console: virsh console custom-image-builder")
            print("    Cleanup when done: just delete custom-image-builder")

    def handle_failure(self):
        """Handle failed execution"""
        print()
        print("❌ Build failed. Check the output above for details.")
        print("🔍 VM 'custom-image-builder' has been left running for investigation")
        print(f"    SSH: ssh {self.username}@10.0.0.7")
        print("    Console: virsh console custom-image-builder")
        print("    Cleanup when done: just delete custom-image-builder")

    def build(self):
        """Main build process"""
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
    builder = CustomImageBuilder()
    builder.build()


if __name__ == "__main__":
    main()
