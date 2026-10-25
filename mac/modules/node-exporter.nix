{ pkgs, ... }:
{
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
