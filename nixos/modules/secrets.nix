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

    # Derive age key from the host's SSH key
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      k3s-token = {
        # Available at /run/secrets/k3s-token after activation
      };
    };
  };
}
