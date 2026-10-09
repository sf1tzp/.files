{ config, ... }:
let
  # Links into the checkout, not copies into the store: an edit in
  # ~/.files is live at the next prompt, which is how these files have
  # always been used. The paths are the ones shell/zsh/profile made by
  # hand before; home-manager owns them now and the profile's `ln -s`
  # guards find them present.
  files = "${config.home.homeDirectory}/.files";
  link = path: config.lib.file.mkOutOfStoreSymlink "${files}/${path}";
in
{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.file = {
    ".zshrc".source = link "shell/zsh/profile";
    ".tmux.conf".source = link "shell/config/tmux.conf";
    ".config/starship.toml".source = link "shell/config/starship.toml";
    ".config/herdr/config.toml".source = link "shell/config/herdr.toml";
    ".claude/CLAUDE.md".source = link "shell/config/CLAUDE.md";
    ".claude/skills".source = link "shell/config/claude-skills";
  };
}
