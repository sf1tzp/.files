{ pkgs, ... }:
{
  # The CLI set, from what `brew leaves` held on macmini on 2026-10-10,
  # minus the casks (modules/homebrew.nix) and what the revamp
  # retires (pyenv, pipx, and the six CLI leaves). Every name here is a nixpkgs attribute on aarch64-darwin;
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
    # languages and their managers (fnm/rustup stay until the projects'
    # own flakes carry their toolchains). Python is one interpreter for
    # `python3` and uv for the rest: versions (`uv python`), venvs and
    # projects (`uv run`), tools (`uv tool install`, which is what pipx
    # did; fb-idb goes in that way). pyenv and pipx retire.
    go
    rustup
    python313
    uv
    fnm
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
    pipes-rs
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
