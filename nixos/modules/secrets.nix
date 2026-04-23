# Secrets management via sops-nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  sops = {
    defaultSopsFile = ../secrets/cluster.yaml;

    age.sshKeyPaths = [];          # Don't derive from SSH host keys
    age.keyFile = "/home/steven/.config/sops/age/keys.txt";

    secrets = {
      k3s-token = {
        # Available at /run/secrets/k3s-token after activation
      };
      wireguard-private-key = {
        # Available at /run/secrets/wireguard-private-key after activation
        mode = "0400";
        owner = "root";
      };
    };
  };
}
