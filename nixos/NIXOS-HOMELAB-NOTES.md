# NixOS Homelab: 3-Node K8s Cluster

Notes for building a Kubernetes cluster on the Zenbook using NixOS, with the host
as the k3s control plane and two microVM workers — all defined in Nix config.

**Architecture:**
```
┌─────────────────────────────────────────────┐
│  Zenbook (NixOS host)          10.0.0.6     │
│  ├── k3s server (control plane)             │
│  ├── br0 bridge (wired ethernet)            │
│  │                                          │
│  ├── k8s-worker-1 (microVM)    10.0.0.7     │
│  │   └── k3s agent                          │
│  └── k8s-worker-2 (microVM)    10.0.0.8     │
│      └── k3s agent                          │
└─────────────────────────────────────────────┘
```

---

## Current State

### Completed
- **Phase 0:** Flake on nixos-unstable, modular config, Home Manager as NixOS module
- **Phase 1:** Libvirt/QEMU/KVM enabled, bridge networking on br0 (10.0.0.6/24),
  NetworkManager manages WiFi only

### Next Steps
- [ ] Add microvm.nix flake input and define two worker VMs
- [ ] Configure k3s server on the host
- [ ] Configure k3s agent inside each microVM
- [ ] Networking: microVMs bridged to br0 with static IPs
- [ ] Token distribution (shared virtiofs mount, sops-nix, or static token)
- [ ] Test cluster with a simple workload
- [ ] WireGuard peering with soundship
- [ ] Monitoring (node-exporter, Prometheus)

---

## microvm.nix

[microvm.nix](https://github.com/astro/microvm.nix) runs NixOS guests as
lightweight VMs using QEMU, cloud-hypervisor, or kvmtool. Guests are defined
entirely in Nix — no disk images, no cloud-init, no Ansible.

### Why microvm.nix over libvirt + cloud-init

| | microvm.nix | Libvirt + cloud-init |
|---|---|---|
| Guest OS | NixOS only | Any Linux, Windows |
| Definition | Pure Nix | XML + qcow2 + cloud-init |
| Boot time | Seconds | 30-60s |
| Disk images | Optional (virtiofs from host) | Required (qcow2) |
| Rebuild workflow | `nixos-rebuild` updates host + guests | Ansible/virsh separately |
| Rollback | NixOS generations for host and guests | Manual snapshots |

For two static k8s workers running a known config, microvm.nix is ideal — the
entire cluster is a single `nixos-rebuild switch`.

### Flake integration

```nix
inputs.microvm = {
  url = "github:astro/microvm.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add `microvm.nixosModules.host` to the host's module list.

### Defining a microVM

```nix
microvm.vms.k8s-worker-1 = {
  config = { config, pkgs, ... }: {
    microvm = {
      vcpu = 4;
      mem = 8192;
      hypervisor = "qemu";  # or "cloud-hypervisor"

      interfaces = [{
        type = "tap";
        id = "vm-w1";
        bridge = "br0";
      }];

      volumes = [{
        image = "worker-1.img";
        mountPoint = "/";
        size = 51200;  # MB
      }];
    };

    networking.hostName = "k8s-worker-1";
    networking.interfaces.eth0.ipv4.addresses = [{
      address = "10.0.0.7";
      prefixLength = 24;
    }];
    networking.defaultGateway = "10.0.0.1";
    networking.nameservers = [ "10.0.0.2" "8.8.8.8" ];

    services.k3s = {
      enable = true;
      role = "agent";
      serverAddr = "https://10.0.0.6:6443";
      tokenFile = "/var/lib/k3s/token";
    };

    system.stateVersion = "25.11";
  };
};
```

### Key decisions

**Hypervisor backend:** qemu (most compatible, libvirt already configured),
cloud-hypervisor (fastest boot), kvmtool (smallest). Start with qemu.

**Token distribution:** The k3s server generates a join token at
`/var/lib/rancher/k3s/server/token`. Options:
- Shared virtiofs mount from host to guests
- sops-nix to encrypt and distribute a static token
- Set `services.k3s.token` to a shared static value on all nodes

**Storage:** microVMs support `volumes` (block devices, persistent) and
`shares` (virtiofs mounts from host, good for shared data).

---

## k3s on NixOS

### Key module options

| Option | Purpose |
|--------|---------|
| `services.k3s.enable` | Enable k3s |
| `services.k3s.role` | `"server"` or `"agent"` |
| `services.k3s.clusterInit` | Bootstrap HA cluster (etcd) |
| `services.k3s.token` / `tokenFile` | Cluster join token |
| `services.k3s.serverAddr` | Server URL (for agents) |
| `services.k3s.extraFlags` | Additional CLI flags |
| `services.k3s.manifests` | Auto-deploy K8s manifests on startup |
| `services.k3s.gracefulNodeShutdown` | Clean pod eviction on shutdown |

### Example: control plane config

```nix
{
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    extraFlags = [ "--disable=traefik" ];  # if using your own ingress
  };

  networking.firewall.allowedTCPPorts = [ 6443 ];
}
```

---

## Future Considerations

- **Monitoring:** node-exporter on host + workers, Prometheus scraping all nodes
- **WireGuard:** Peer with soundship for cross-network cluster access
- **Secrets:** sops-nix for k3s tokens, WireGuard keys, service credentials
- **Woodpecker CI:** Run on this cluster (resolves containerd/Docker backend issue)

---

## References

- [microvm.nix](https://github.com/astro/microvm.nix)
- [NixOS k3s module](https://search.nixos.org/options?query=services.k3s)
- [NixOS libvirt wiki](https://wiki.nixos.org/wiki/Libvirt)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [NixOS options search](https://search.nixos.org/options)
