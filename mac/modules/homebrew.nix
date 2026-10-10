{ ... }:
{
  # Homebrew stays for what nixpkgs cannot deliver on macOS: the apps.
  # Declared here so `brew list --cask` is a file in git, and so a cask
  # that is not on this list is a decision, not a leftover.
  #
  # cleanup is "uninstall": nix-darwin removes every formula not listed
  # in `brews` (there are none) and every cask off this list. It was
  # "none" for the first switch, until each tool in modules/packages.nix
  # resolved from /run/current-system/sw/bin and zplug ran from the
  # store. The casks it retires: iTerm2, Alacritty, VS Code, Zed, KiCad,
  # Steam, Whisky, XQuartz, primetime, and the SF Mono nerd font that only
  # Alacritty used.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
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
