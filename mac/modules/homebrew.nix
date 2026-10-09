{ ... }:
{
  # Homebrew stays for what nixpkgs cannot deliver on macOS: the apps.
  # Declared here so `brew list --cask` is a file in git, and so a cask
  # that is not on this list is a decision, not a leftover.
  #
  # cleanup is "none" for the first switch: nix-darwin would otherwise
  # uninstall every formula not listed in `brews` (there are none), and
  # the CLI set should resolve from /run/current-system/sw/bin first.
  # Flip to "uninstall" once `which` agrees for each tool in
  # modules/packages.nix; that removes the 103 formulae and every cask
  # off this list (iTerm2, Alacritty, VS Code, Zed, KiCad, Steam, Whisky,
  # XQuartz, primetime, and the SF Mono nerd font that only Alacritty used).
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    taps = [
      "sf1tzp/tap"   # moment-tally
    ];
    casks = [
      # terminals and editors (iterm2, alacritty, visual-studio-code and
      # zed retire; the terminal is Claude Code's, the editor is neovim)
      "obsidian"
      # browsers
      "firefox"
      "google-chrome"
      "polypane"
      # ours
      "claude-code"
      "moment-tally"
      # audio and screen
      "airfoil"
      "audio-hijack"
      "loopback"
      "soundsource"
      "obs"
      "superwhisper"
      "ankerwork"
      # the desk
      "betterdisplay"
      "rectangle"
      "stats"
      "clocker"
      "datweatherdoe"
      "mac-mouse-fix"
      "grandperspective"
      "macusb"
      "equinox"
      "bitwarden"
      "dropbox"
      # tools that are apps
      "mysqlworkbench"
      "ogdesign-eagle"
      "moonlight"
      "basictex"
    ];
  };
}
