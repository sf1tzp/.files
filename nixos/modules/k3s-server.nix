# Reusable single-node k3s control plane.
#
# Host-specific networking (bridge, static IP) is left to the host config, and
# the host's secrets module (hosts/<name>/secrets.nix) supplies the sops file /
# age key that k3s-token is decrypted from.
# clusterInit (embedded etcd) is on by default; a lean single-node host that
# wants the sqlite datastore instead can set `services.k3s.clusterInit = false;`.
{ config, lib, ... }:

{
  # Cluster join token, consumed below. The host's secrets module points sops at
  # the file that carries it.
  sops.secrets.k3s-token = { };

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = lib.mkDefault true;
    tokenFile = config.sops.secrets.k3s-token.path;
    extraFlags = [
      "--disable=traefik"
      "--kubelet-arg=read-only-port=10255"
      # World-readable kubeconfig so `steven` can pull /etc/rancher/k3s/k3s.yaml
      # over SSH without sudo (see `just fetch-kubeconfig`). These are single-
      # purpose infra nodes; tighten to 0640 + a group once the locked-down
      # deployer user lands.
      "--write-kubeconfig-mode=0644"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 80 443 ];

  # Trust the homelab step-ca root (ACME/TLS for *.lofi services).
  security.pki.certificateFiles = [ ../../homelab/k8s/cert-manager/step-ca-root.pem ];

  # Node metrics
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true; # opens port 9100
  };
}
