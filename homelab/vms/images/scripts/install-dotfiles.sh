#!/bin/bash
set -euo pipefail

# Installs dotfiles, shell config, and CLI tools for the target user.
# Expects IMAGE_USER env var to be set.

USER_HOME="/home/$IMAGE_USER"

echo "=== Installing dotfiles and shell tools for $IMAGE_USER ==="

# Clone dotfiles
su - "$IMAGE_USER" -s /bin/bash -c \
  "git clone https://github.com/sf1tzp/.files.git ~/.files" || true

# Create standard directories
su - "$IMAGE_USER" -s /bin/bash -c \
  "mkdir -p ~/.config ~/.local ~/.local/bin"

# Symlink zsh profile
su - "$IMAGE_USER" -s /bin/bash -c \
  "ln -sf ~/.files/shell/zsh/profile ~/.zshrc"

# Install zplug
su - "$IMAGE_USER" -s /bin/bash -c \
  "git clone https://github.com/zplug/zplug ~/.zplug"

# Install TPM (Tmux Plugin Manager)
su - "$IMAGE_USER" -s /bin/bash -c \
  "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"

# Symlink tmux config
su - "$IMAGE_USER" -s /bin/bash -c \
  "ln -sf ~/.files/shell/config/tmux.conf ~/.tmux.conf"

# Install fzf
su - "$IMAGE_USER" -s /bin/bash -c \
  "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --bin"

# Run dotfiles install script
su - "$IMAGE_USER" -s /bin/bash -c \
  "AUTOMATIC=true PATH=~/.local/bin:\$PATH ~/.files/shell/scripts/install.py"

echo "=== Dotfiles installation complete ==="
