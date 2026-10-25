{ pkgs, inputs, ... }:
{
  # macmini — the always-on Mac (CLAUDE.md "Machines"): Command Line Tools,
  # compile checks and swift test, never the heavy interactive verbs. On
  # the deployments mesh at 10.1.0.96 as a client; the staging mesh next.
  networking.hostName = "macmini";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix owns the daemon and /etc/nix/nix.conf.
  nix.enable = false;

  # Homebrew removes what the lists (modules/homebrew.nix) do not name.
  homebrew.onActivation.cleanup = "uninstall";

  # The staging mesh (sfi/staging estate.toml: 10.2.0.0/24, wg-staging),
  # as a peer the forts dial at this Mac's LAN address: peers.macmini in
  # that estate's mesh/peers.json, with the public key of the key this
  # module mints (modules/mesh.nix). The last octet follows the LAN
  # address, the lab convention. The deployments mesh stays in the
  # WireGuard app for now; moving it here is a new key in that estate.
  sfi.meshes.staging = {
    peersFile = "${inputs.staging}/mesh/peers.json";
    interface = "wg-staging";
    address = "10.2.0.96/24";
  };
  sfi.meshes.estate-hub = {
    peersFile = "${inputs.estate-hub}/mesh/peers.json";
    interface = "wg-estate-hub";
    address = "10.3.0.96/24";
  };
  # The development mesh (sfi/development estate.toml: 10.5.0.0/24): the
  # dev fort sfi-dev lives there, and this Mac dispatches to it. Client
  # entry clients.macmini in that estate's mesh/peers.json, same key.
  sfi.meshes.development = {
    peersFile = "${inputs.development}/mesh/peers.json";
    interface = "wg-development";
    address = "10.5.0.96/24";
  };
  # The one key for every mesh (modules/mesh.nix). This file was minted
  # when the module made one key per mesh; its public key is what both
  # estates register for macmini, so it stays where it is.
  sfi.meshKeyFile = "/etc/wireguard/wg-staging.key";

  system.stateVersion = 6;
  system.primaryUser = "steven";
  users.users.steven.home = "/Users/steven";
}
