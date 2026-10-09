{ ... }:
{
  # zsh is the shell; the rc that matters is the one home-manager links
  # from shell/zsh/profile (home/steven.nix), the same file every host has
  # read since the Ubuntu era. nix-darwin's /etc/zshrc puts the system
  # profile on PATH before it; the profile puts Homebrew after nix when
  # both exist.
  programs.zsh.enable = true;
}
