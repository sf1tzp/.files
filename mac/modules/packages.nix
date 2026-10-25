{ pkgs, ... }:
{
  # The CLI set, one list for every Mac: what `brew leaves` held on
  # macmini on 2026-10-10, plus what macbook-air added on 2026-10-25
  # (bash, coreutils-prefixed, exiv2, libheif), minus the casks
  # (modules/homebrew.nix) and what the revamp retires (pyenv, pipx, the
  # six CLI leaves; on the air, wimlib, speedtest and postgresql@18).
  # Every name here is a nixpkgs attribute on aarch64-darwin; Homebrew
  # keeps nothing that is on this list once the cleanup in the host file
  # is "uninstall".
  environment.systemPackages = with pkgs; [
    # the estates: sops/age for every contract, the mesh, the forge
    age
    sops
    step-cli
    tea
    forgejo-cli           # fj: Forgejo's own CLI, beside tea, for forge.streetfortress.cloud
    gnupg                 # the agent persona signs its commits (modules/sfi-agent.nix)
    wireguard-tools
    wireguard-go          # wg-quick's tunnel driver on macOS (no kernel module)
    # kubernetes, read-only from here (ops-ro contexts)
    kubectl
    kubectx
    kubernetes-helm
    kustomize
    kind
    k6
    # pulumi-bin, not pulumi: the source build in nixpkgs ships the CLI
    # alone, and `fort provision` needs the Go language host that the
    # official distribution puts beside its own binary (sfi/forts,
    # internal/tools/tools.json names the attribute and the reason)
    pulumi-bin
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
    bash                  # bash 5; macOS ships 3.2
    coreutils-prefixed    # the g-prefixed names (gdate, gsed, ...), as brew's coreutils gave them
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
    exiv2
    libheif               # heif-convert and friends
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
