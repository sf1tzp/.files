# Hypervisor module: microvm.nix host, bridge networking, k8s worker VMs
{ config, pkgs, ... }:

let
  # Shared worker VM config — avoids repeating the same block twice
  mkWorker = { hostname, address, tapId, mac }: {
    config = {
      microvm = {
        vcpu = 4;
        mem = 4096;
        hypervisor = "qemu";

        interfaces = [{
          type = "bridge";
          id = tapId;
          mac = mac;
          bridge = "br0";
        }];

        # Share host nix store (avoids large disk images)
        shares = [
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            proto = "virtiofs";
          }
          {
            tag = "k3s-token";
            source = "/run/secrets";
            mountPoint = "/run/host-secrets";
            proto = "virtiofs";
          }
        ];

        # Persistent volume for /var (k3s state, logs, etc.)
        volumes = [{
          image = "${hostname}-var.img";
          mountPoint = "/var";
          size = 10240; # 10 GB
        }];
      };

      networking.hostName = hostname;
      networking.useDHCP = false;

      # Match on MAC address — device name varies across hypervisors
      systemd.network.enable = true;
      systemd.network.networks."10-vm" = {
        matchConfig.MACAddress = mac;
        address = [ "${address}/24" ];
        gateway = [ "10.0.0.1" ];
        dns = [ "10.0.0.2" "8.8.8.8" ];
      };

      services.k3s = {
        enable = true;
        role = "agent";
        serverAddr = "https://10.0.0.6:6443";
        tokenFile = "/run/host-secrets/k3s-token";
      };

      services.prometheus.exporters.node = {
        enable = true;
        openFirewall = true;
      };

      system.stateVersion = "25.11";
    };
  };
in
{
  # ── Bridge networking ──────────────────────────────────────────────
  # Keep NetworkManager away from the bridged ethernet interface
  # (NM continues to manage WiFi for desktop use)
  networking.networkmanager.unmanaged = [ "enp116s0f4u1" ];

  networking.bridges.br0 = {
    interfaces = [ "enp116s0f4u1" ];
  };

  networking.interfaces.br0.ipv4.addresses = [{
    address = "10.0.0.6";
    prefixLength = 24;
  }];

  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "10.0.0.2" "8.8.8.8" ];

  # Trust bridge and VM tap traffic
  networking.firewall.trustedInterfaces = [ "br0" ];

  # ── k3s control plane ──────────────────────────────────────────────
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.sops.secrets.k3s-token.path;
    extraFlags = [ "--disable=traefik" ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 ];

  # ── Monitoring ─────────────────────────────────────────────────────
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true; # opens port 9100
  };

  # ── microVM workers ────────────────────────────────────────────────
  microvm.vms = {
    k8s-worker-1 = mkWorker {
      hostname = "k8s-worker-1";
      address = "10.0.0.7";
      tapId = "vm-w1";
      mac = "02:00:00:00:00:01";
    };
    k8s-worker-2 = mkWorker {
      hostname = "k8s-worker-2";
      address = "10.0.0.8";
      tapId = "vm-w2";
      mac = "02:00:00:00:00:02";
    };
  };
}
