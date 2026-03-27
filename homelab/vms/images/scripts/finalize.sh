#!/bin/bash
set -euo pipefail

echo "=== Finalizing image ==="

# Clean apt cache
apt-get autoremove -y
apt-get autoclean -y

# Clear user state
rm -f /home/*/.*_history /root/.*_history

# Clear cloud-init logs and instance data
rm -f /var/log/cloud-init.log /var/log/cloud-init-output.log
rm -rf /var/lib/cloud/instances /var/lib/cloud/instance /var/lib/cloud/data

# Clear SSH host keys (regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

# Clear machine-id (regenerated on first boot)
truncate -s 0 /etc/machine-id

# Clear systemd journal
journalctl --vacuum-time=1s

# Clean logs and temp files
find /var/log -type f -exec truncate -s 0 {} \;
rm -rf /tmp/* /var/tmp/*

# Remove cloud-init's passwordless sudo config
rm -f /etc/sudoers.d/90-cloud-init-users

# Remove build artifacts
rm -rf /opt/image-build

echo "=== Finalization complete ==="
