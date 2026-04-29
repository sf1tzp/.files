# Development tools module
{ config, pkgs, ... }:

{
  # Docker
  virtualisation.docker.enable = true;

  # Development packages
  environment.systemPackages = with pkgs; [
    # Version control
    git

    # Editors
    neovim
    vim

    # Languages & runtimes
    go
    rustup
    gcc

    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
    kubebuilder
    kustomize

    # CLI tools
    bind
    curl
    gnumake
    htop
    jq
    openssl
    tmux
    unzip
    wget
  ];
}
