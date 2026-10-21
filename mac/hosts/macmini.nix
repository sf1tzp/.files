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
  # The one key for every mesh (modules/mesh.nix). This file was minted
  # when the module made one key per mesh; its public key is what both
  # estates register for macmini, so it stays where it is.
  sfi.meshKeyFile = "/etc/wireguard/wg-staging.key";

  system.stateVersion = 6;
  system.primaryUser = "steven";
  users.users.steven.home = "/Users/steven";

  # The Mac's scrape target for luxor's central Prometheus (the brew
  # service it replaces ran as a LaunchAgent on the same port with no
  # flags). A daemon: it answers whether or not anyone is logged in.
  # Migration: `brew services stop node_exporter` before the switch, or
  # the two fight over :9100.
  launchd.daemons.node-exporter = {
    serviceConfig = {
      # The store mounts after launchd starts its daemons; a program
      # path under /nix/store is a missing executable at boot, and
      # launchd parks the service (EX_CONFIG) rather than retry. Wait
      # for the store, as nix-darwin's own activate-system plist does.
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec ${pkgs.prometheus-node-exporter}/bin/node_exporter --web.listen-address=:9100"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/node_exporter.log";
      StandardErrorPath = "/var/log/node_exporter.err.log";
    };
  };
}
