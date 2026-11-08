{ ... }:
{
  # Homebrew stays for what nixpkgs cannot deliver on macOS: the apps, and
  # the one formula nixpkgs lacks. Declared here so `brew list --cask` is
  # a file in git, and so a cask that is not on this list is a decision,
  # not a leftover. One list for every Mac; a host file adds only the
  # casks that are that machine's hardware or craft (hosts/*.nix).
  #
  # cleanup is the host file's: "uninstall" removes every formula not in
  # `brews` and every cask not listed by any module; "none" for a host's
  # first switch, until each tool in modules/packages.nix resolves from
  # /run/current-system/sw/bin and zplug runs from the store. Retired, on
  # the two Macs together: iTerm2, Alacritty, Ghostty, VS Code, Zed,
  # KiCad, Steam, Whisky, XQuartz, primetime, Raycast, Pomatez, Inkscape,
  # Kdenlive, LICEcap, Streamlabs, mGBA, MySQL Workbench, and the SF Mono
  # nerd font that only Alacritty used. Formulae: sunshine, speedtest,
  # wimlib, postgresql@18, tpm (the profile clones it instead).
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
    };
    taps = [
      "sf1tzp/tap"   # moment-tally
    ];
    brews = [
      "cliclick"     # the capture skill's clicks; not in nixpkgs
    ];
    casks = [
      # terminals and editors (the terminal is Claude Code's, the editor
      # is neovim)
      "obsidian"
      # browsers
      "firefox"
      "google-chrome"
      "polypane"
      # ours
      "claude"       # Claude Desktop
      "claude-code"
      "moment-tally"
      # audio and screen
      "audio-hijack"
      "loopback"
      "soundsource"
      "obs"
      "superwhisper"
      # the desk
      "betterdisplay"
      "rectangle"
      "stats"
      "clocker"
      "datweatherdoe"
      "mac-mouse-fix"
      "sanesidebuttons"
      "keymapp"
      "grandperspective"
      "macusb"
      "equinox"
      "bitwarden"
      "dropbox"
      "nghialuong/fileoctopus/fileoctopus"
      # tools that are apps
      "ogdesign-eagle"
      "moonlight"
      "basictex"
    ];
  };
}
