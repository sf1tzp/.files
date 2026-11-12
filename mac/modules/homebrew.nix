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
      # Dev work
      "firefox"
      "polypane"
      "obsidian"
      "claude"
      "claude-code"
      # Audio / Video
      "audio-hijack"
      "loopback"
      "soundsource"
      "obs"
      "moonlight"
      # Things MacOS lacks out of the box
      "betterdisplay"     # menu bar display controls
      "rectangle"         # menu bar window snapping
      "stats"             # menu bar utilization stats
      "clocker"           # menu bar clock (timezones)
      "datweatherdoe"     # menu bar weather
      "moment-tally"      # menu bar timer
      "mac-mouse-fix"     # use the mouse wheel to zoom etc
      "sanesidebuttons"   # more mouse fix
      "keymapp"           # keyboard layers
      "equinox"           # create dynamic wallpapers (light/dark mode)
      "grandperspective"  # disk consumption visualizer
      "macusb"            # usb formatter ala 'rufus'
      "nghialuong/fileoctopus/fileoctopus" # better finder: panes
      "Sanyam-G/switch/switch" # better alt+tab: fullscreen apps
      # Tools that are apps
      "dropbox"
      "bitwarden"
      "superwhisper"      # local model dictation
      "basictex"
      "ogdesign-eagle"
      "paper-design"
    ];
  };
}
