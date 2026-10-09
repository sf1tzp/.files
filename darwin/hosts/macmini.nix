{ pkgs, ... }:
{
  # macmini — the always-on Mac (CLAUDE.md "Machines"): Command Line Tools,
  # compile checks and swift test, never the heavy interactive verbs. On
  # the deployments mesh at 10.1.0.96 as a client; the staging mesh next.
  networking.hostName = "macmini";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix owns the daemon and /etc/nix/nix.conf.
  nix.enable = false;

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
      ProgramArguments = [
        "${pkgs.prometheus-node-exporter}/bin/node_exporter"
        "--web.listen-address=:9100"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/node_exporter.log";
      StandardErrorPath = "/var/log/node_exporter.err.log";
    };
  };
}
