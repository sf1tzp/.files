#!/bin/bash
set -euo pipefail

# Installs Neovim to /usr/local/nvim.
# Expects NEOVIM_VERSION env var to be set.

echo "=== Installing Neovim ${NEOVIM_VERSION} ==="

curl -fsSL "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz" -o /tmp/nvim.tar.gz
tar -xzf /tmp/nvim.tar.gz -C /tmp
mv /tmp/nvim-linux-x86_64 /usr/local/nvim
rm -f /tmp/nvim.tar.gz

echo "=== Neovim installation complete ==="
