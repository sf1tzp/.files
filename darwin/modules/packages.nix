{ pkgs, ... }:
{
  # The CLI set, from what `brew leaves` held on macmini on 2026-10-10,
  # minus the casks (modules/homebrew.nix) and the six the revamp
  # retires. Every name here is a nixpkgs attribute on aarch64-darwin;
  # Homebrew keeps nothing that is on this list once the cleanup in
  # homebrew.nix is flipped to "uninstall".
  environment.systemPackages = with pkgs; [
    # the estates: sops/age for every contract, the mesh, the forge
    age
    sops
    step-cli
    tea
    wireguard-tools
    wireguard-go          # wg-quick's tunnel driver on macOS (no kernel module)
    # kubernetes, read-only from here (ops-ro contexts)
    kubectl
    kubectx
    kubernetes-helm
    kustomize
    kind
    k6
    pulumi
    # languages and their managers (fnm/pyenv/rustup stay until the
    # projects' own flakes carry their toolchains)
    go
    rustup
    python313
    uv
    pipx
    fnm
    pyenv
    # shell
    starship
    zplug
    tmux
    neovim
    fzf
    zoxide
    eza
    bat
    fd
    ripgrep
    jq
    yq
    just
    glow
    htop
    duf
    dust
    fastfetch
    watch
    shellcheck
    pipes
    gh
    git
    # media and documents
    ffmpeg
    pandoc
    pngquant
    # the Mac itself
    smartmontools
    prometheus-node-exporter
    # apple
    xcodegen
    idb-companion
    # ours
    herdr
    ollama
  ];
}
