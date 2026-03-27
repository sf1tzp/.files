#!/bin/bash
set -euo pipefail

# Installs Rust via rustup for the target user.
# Expects IMAGE_USER env var to be set.

echo "=== Installing Rust for $IMAGE_USER ==="

su - "$IMAGE_USER" -s /bin/bash -c \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal"

echo "=== Rust installation complete ==="
