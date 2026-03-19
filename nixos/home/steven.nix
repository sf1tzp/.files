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
    eza
    fzf
    fd
    gping
    helix
    htop
    hyperfine
    fastfetch  # neofetch is unmaintained, fastfetch is the successor
    pipes
    ripgrep
    starship
    yq
    zoxide
  ];

  # Dotfiles managed by Home Manager
  home.file = {
    ".config/alacritty/alacritty.toml".source = ../../shell/config/alacritty.toml;
    ".config/fzf.bash".source = ../../shell/bash/fzf.bash;
    ".config/nvim".source = ../../nvim;
    ".config/starship.toml".source = ../../shell/config/starship.toml;
    ".shellcheckrc".source = ../../shell/config/shellcheckrc;
    ".tmux.conf".source = ../../shell/config/tmux.conf;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
      get = "git";
      git-log = "git log --date=short --pretty=\"%h  %cd  %s\"";
      git-out = "git commit --amend --date=\"$(date -R)\" --no-edit; git push --force-with-lease";
      git-fetch-checkout = "git fetch; git checkout";
      gl = "git-log";
      git-fetch-rebase = "git fetch; git rebase -i";
      gd = "git diff";
      gs = "git status";
      gfs = "git fetch; git status";
      gfc = "git-fetch-checkout";
      gfr = "git-fetch-rebase";
      grc = "git rebase --continue";
      gum = "git checkout main && git reset --hard origin/main";
      gtfo = "git-out";
      clera = "clear";
      watch = "watch ";
      # Simplified rebuild - HM is now a NixOS module, single command
      nix-rebuild = "sudo nixos-rebuild switch --flake ~/.files/nixos";
    };
    initExtra = ''
      . ~/.config/fzf.bash
      eval "$(starship init bash)"
      [ -f ~/.files/shell/bash/profile ] && . ~/.files/shell/bash/profile
    '';
  };

  # GNOME settings
  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
  };

  programs.home-manager.enable = true;
}
