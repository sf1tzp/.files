{ inputs, ... }:
{
  # macbook-air — the primary Mac-app dev machine (CLAUDE.md "Machines"):
  # full Xcode, the only host where the verify and capture skills auto-run.
  # The CLI set and the casks are the common lists (modules/packages.nix,
  # modules/homebrew.nix); this file adds the laptop's own apps.
  networking.hostName = "macbook-air";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix owns the daemon and /etc/nix/nix.conf.
  nix.enable = false;

  # The two estate meshes, as a client (a Mac behind NAT the forts cannot
  # dial: a `clients.macbook-air` entry in each peers.json, no endpoint,
  # no listenPort). The last octet follows the LAN address (10.0.0.208),
  # the lab convention. The key is modules/mesh.nix's default,
  # /etc/wireguard/mesh.key, minted by the first activation; the public
  # key goes into both estates by PR (README.md "The meshes"). This Mac
  # was on no estate mesh before: the WireGuard app holds only the
  # homelab tunnel, which stays there.
  sfi.meshes.staging = {
    peersFile = "${inputs.staging}/mesh/peers.json";
    interface = "wg-staging";
    address = "10.2.0.208/24";
  };
  sfi.meshes.estate-hub = {
    peersFile = "${inputs.estate-hub}/mesh/peers.json";
    interface = "wg-estate-hub";
    address = "10.3.0.208/24";
  };

  system.stateVersion = 6;
  system.primaryUser = "steven";
  users.users.steven.home = "/Users/steven";

  # Homebrew: "none" for the first switch, as it was on macmini, so the
  # casks the lists dropped (README.md "macbook-air") stay until every
  # tool in modules/packages.nix resolves from /run/current-system/sw/bin.
  # Then "uninstall", as hosts/macmini.nix.
  homebrew.onActivation.cleanup = "none";

  # This machine's own casks, beside the common list (modules/homebrew.nix):
  # the creative work that lives on the laptop, and LM Studio.
  homebrew.casks = [
    "blender"
    "resolume-arena"
    "lm-studio"
  ];
}
