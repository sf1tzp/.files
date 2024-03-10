{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "steven";
  home.homeDirectory = "/home/steven";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    ".config/alacritty.yml" = ../alacritty.yml;
    ".config/nvim".source = ../nvim;
    ".config/starship.toml".source = ../starship.toml;
    ".shellcheckrc".source = ../shellcheckrc;
    ".tmux.conf".source = ../tmux.conf;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/steven/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
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
    };
    bashrcExtra = ". ~/.files/profile";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
