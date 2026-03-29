# Home Manager configuration for steven
{ config, pkgs, ... }:

{
  home.username = "steven";
  home.homeDirectory = "/home/steven";

  # Keep at fresh install version
  home.stateVersion = "25.11";

  # User packages (CLI tools that don't need system-level config)
  home.packages = with pkgs; [
    bat
    bottom
    claude-code
    duf
    dust
    eza
    fastfetch
    fd
    fnm
    fzf
    helix
    htop
    hyperfine
    jq
    just
    pipes-rs
    ripgrep
    starship
    uv
    yq
    zoxide
  ];

  # Dotfiles managed by Home Manager
  home.file = {
    ".config/alacritty/alacritty.toml".source = ../../shell/config/alacritty.toml;
    ".config/fzf.bash".source = ../../shell/bash/fzf.bash;
    ".config/nvim".source = ../../nvim;
    ".config/starship.toml".source = ../../shell/config/starship.toml;
    ".inputrc".source = ../../shell/config/inputrc;
    ".shellcheckrc".source = ../../shell/config/shellcheckrc;
    ".tmux.conf".source = ../../shell/config/tmux.conf;

  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Ensure ~/.local/bin is on PATH (for tools managed by installs.py)
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      nix-rebuild = "sudo nixos-rebuild switch --flake ~/.files/nixos";
    };
    initExtra = ''
      . ~/.config/fzf.bash
      eval "$(starship init bash)"
      [ -f ~/.files/shell/bash/profile ] && . ~/.files/shell/bash/profile
    '';
  };

  programs.zsh = {
    enable = true;
    initContent = ''
      [ -f ~/.files/shell/zsh/profile ] && source ~/.files/shell/zsh/profile
    '';
    shellAliases = {
      nix-rebuild = "sudo nixos-rebuild switch --flake ~/.files/nixos";
    };
    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };

  services.vscode-server.enable = true;

  programs.home-manager.enable = true;
}
