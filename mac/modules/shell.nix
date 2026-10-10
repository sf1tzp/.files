{ ... }:
{
  # zsh is the shell; the rc that matters is the one home-manager links
  # from shell/zsh/profile (home/steven.nix), the same file every host has
  # read since the Ubuntu era. nix-darwin's /etc/zshrc puts the system
  # profile on PATH before it; the profile puts Homebrew after nix when
  # both exist.
  programs.zsh.enable = true;

  # nixpkgs' zplug keeps init.zsh under share/zplug, which nix-darwin does
  # not link into /run/current-system/sw by default. The profile's guard
  # (shell/zsh/profile) looks there; without this it falls through to
  # Homebrew's zplug, which cleanup removes.
  environment.pathsToLink = [ "/share/zplug" ];
}
