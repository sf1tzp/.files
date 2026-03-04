# NixOS for Homelab: K8s & Hypervisor Duty

Research notes for revisiting the Zenbook NixOS installation and exploring it as
a base layer for Kubernetes and hypervisor workloads.

**Current state:** NixOS 23.11 desktop config (GNOME, dev tools, Docker).
**Goal:** Understand how to evolve this toward a capable secondary hypervisor/k8s
node, while keeping the desktop usable, before committing to migrating workloads
off the Ubuntu-based `soundship` server.

---

## Table of Contents

1. [Catching Up: What Changed Since 23.11](#1-catching-up-what-changed-since-2311)
2. [The Nix Mental Model vs Ansible](#2-the-nix-mental-model-vs-ansible)
3. [Libvirt / QEMU / KVM](#3-libvirt--qemu--kvm)
4. [Kubernetes (k3s)](#4-kubernetes-k3s)
5. [Networking: Bridges, Firewall, WireGuard](#5-networking-bridges-firewall-wireguard)
6. [Containers: Docker vs Podman vs OCI Services](#6-containers-docker-vs-podman-vs-oci-services)
7. [GPU Passthrough (VFIO)](#7-gpu-passthrough-vfio)
8. [Monitoring: Prometheus, Grafana, Node Exporter](#8-monitoring-prometheus-grafana-node-exporter)
9. [Flake Structure for Multi-Role Configs](#9-flake-structure-for-multi-role-configs)
10. [Migration Strategy](#10-migration-strategy)
11. [Action Items](#11-action-items)

---

## 1. Catching Up: What Changed Since 23.11

The flake currently pins `nixos-23.11`. The current stable release is **25.05
"Warbler"**. That's three major releases behind:

| Release | Codename | Highlights relevant to this project |
|---------|----------|-------------------------------------|
| 23.11   | Tapir    | *(current)* GNOME 45, Linux 6.5 default |
| 24.05   | Uakari   | GNOME 46, systemd 255, improved k3s module |
| 24.11   | Vicuña   | GNOME 47, Linux 6.11 default, Prometheus 3.x in unstable |
| 25.05   | Warbler  | *(current stable)* Latest k3s, improved VFIO options |

**Key things that will break or change on upgrade:**
- `sound.enable` was removed — PipeWire config needs updating
- `nerdfonts` package was restructured — the override syntax changed
- `services.xserver.layout` moved to `services.xserver.xkb.layout`
- GNOME subpackage paths changed (e.g., `gnome.gnome-tweaks` → `gnome-tweaks`)
- Home Manager releases track nixpkgs, so bump both together

**Recommendation:** Jump to **24.11** (well-tested, large community) rather than
25.05 (very new). Pin `nixos-24.11` in the flake and `release-24.11` for
home-manager.

---

## 2. The Nix Mental Model vs Ansible

On `soundship` (Ubuntu), the homelab is managed with:
- **Ansible playbooks** for VM lifecycle (create, bootstrap, set-up, delete)
- **Docker Compose / containerd** for services
- **Manual package installs** codified in Ansible tasks
- **Justfile** as the entrypoint for common operations

The NixOS equivalent collapses most of this into the system configuration:

| Ubuntu/Ansible Concept | NixOS Equivalent |
|------------------------|------------------|
| `apt install qemu-kvm libvirt-daemon` | `virtualisation.libvirtd.enable = true;` |
| Ansible role for node_exporter | `services.prometheus.exporters.node.enable = true;` |
| docker-compose.yaml | `virtualisation.oci-containers.containers` |
| Manual `/etc/wireguard/wg0.conf` | `networking.wg-quick.interfaces.wg0 = { ... };` |
| Cloud-init + virsh define | Still useful — NixOS configures the *host*, not guests |
| `justfile` recipes | `nixos-rebuild switch` replaces most of them |
| Ansible vault for secrets | `sops-nix` or `agenix` for encrypted secrets in the repo |

**What Nix does NOT replace:**
- Guest VM provisioning (cloud-init, virsh) — you still need this for non-NixOS guests
- Remote host management (unless all hosts run NixOS and you use `deploy-rs` or `colmena`)
- The Ansible playbooks for `soundship` itself — keep those until/unless soundship becomes NixOS

**Key insight:** NixOS configuration is about *declaring the desired state of a
single machine*. Your Ansible setup manages *multiple machines from a control
node*. These are complementary — NixOS replaces Ansible for hosts that run NixOS,
but you'd still use Ansible (or `deploy-rs`) to push configs to remote machines.

---

## 3. Libvirt / QEMU / KVM

### What you have on Ubuntu (soundship)

Ansible installs `qemu-kvm`, `libvirt-daemon`, manages XML domain definitions,
cloud-init ISOs, GPU passthrough hooks via shell scripts in
`/etc/libvirt/hooks/qemu.d/`.

### The NixOS way

Everything is declarative under `virtualisation.libvirtd`:

```nix
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;                          # TPM emulation (for Win11 guests)
      vhostUserPackages = [ pkgs.virtiofsd ];       # virtio filesystem sharing
      runAsRoot = true;                              # default; needed for bridge networking
    };
    allowedBridges = [ "virbr0" "br0" ];            # bridges QEMU can attach to
    # Declarative libvirt hooks — replaces shell scripts in /etc/libvirt/hooks/
    hooks.qemu = {
      gpu-passthrough = pkgs.writeShellScript "qemu-hook" ''
        # This replaces your Ansible-managed hook scripts
        GUEST_NAME="$1"
        ACTION="$2"
        # ... VFIO bind/unbind logic
      '';
    };
  };

  # User permissions
  users.users.steven.extraGroups = [ "libvirtd" ];

  # GUI management (optional — can also use virsh)
  environment.systemPackages = [ pkgs.virt-manager ];

  # USB passthrough support
  virtualisation.spiceUSBRedirection.enable = true;

  # Nested virtualization (your Zenbook has kvm-amd already)
  boot.extraModprobeConfig = "options kvm_amd nested=1";
}
```

**Key options reference:**

| Option | Purpose |
|--------|---------|
| `virtualisation.libvirtd.enable` | Starts libvirtd systemd service |
| `virtualisation.libvirtd.qemu.package` | Default `pkgs.qemu`; use `pkgs.qemu_kvm` for KVM-only |
| `virtualisation.libvirtd.qemu.swtpm.enable` | TPM 2.0 emulation |
| `virtualisation.libvirtd.qemu.vhostUserPackages` | Packages for virtio user backends |
| `virtualisation.libvirtd.allowedBridges` | Bridges QEMU can use (list of strings) |
| `virtualisation.libvirtd.hooks.qemu` | Attrset of hook scripts (replaces `/etc/libvirt/hooks/`) |
| `virtualisation.spiceUSBRedirection.enable` | USB device passthrough |

**Comparison:**
- Ubuntu: ~20 lines of Ansible tasks + template files + manual group management
- NixOS: ~15 lines of Nix, fully version-controlled, rollback-safe

**Your existing VM workflows (virsh, cloud-init ISOs) still work.** NixOS
configures the hypervisor host; your Ansible playbooks for creating/managing
guest VMs remain valid. You could even run the same `create-linux.yaml` playbook
from the Zenbook against itself.

---

## 4. Kubernetes (k3s)

### NixOS k3s module

k3s has a **first-class NixOS module** with ~36 options. It's actively maintained
and used in production. This is a natural fit for a single-node experiment.

```nix
# Single-node k3s server
{
  networking.firewall.allowedTCPPorts = [ 6443 ];

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;  # first node in an HA cluster (etcd)
    # extraFlags = [ "--disable=traefik" ];  # if you prefer your own ingress
  };
}
```

**Key options:**

| Option | Purpose |
|--------|---------|
| `services.k3s.enable` | Enable k3s |
| `services.k3s.role` | `"server"` or `"agent"` |
| `services.k3s.clusterInit` | Bootstrap new HA cluster (etcd) |
| `services.k3s.token` / `tokenFile` | Cluster join token |
| `services.k3s.serverAddr` | Server address (for agents) |
| `services.k3s.disableAgent` | Server-only mode (no kubelet) |
| `services.k3s.manifests` | Auto-deploy K8s manifests on startup |
| `services.k3s.images` | Pre-load container images |
| `services.k3s.gracefulNodeShutdown` | Clean pod eviction on shutdown |
| `services.k3s.extraFlags` | Additional CLI flags |
| `services.k3s.environmentFile` | Env file for secrets |

**Multi-node scenario (future):**
If `soundship` were also NixOS, you could run k3s agents on VMs with:
```nix
services.k3s = {
  enable = true;
  role = "agent";
  serverAddr = "https://zenbook:6443";
  tokenFile = "/var/lib/k3s/token";
};
```

**Relation to your Woodpecker CI note:** Your `services/woodpecker/` config has
a note saying the containerd-based setup doesn't work with the Docker backend and
you're waiting for a Kubernetes backend. Running Woodpecker on k3s would solve this.

**Pure Nix k8s (bleeding edge):** The `k3s-nix` project (github.com/rorosen/k3s-nix,
March 2025) demonstrates running entire k3s clusters in pure Nix — including
pre-loaded images for Prometheus, Grafana, and workloads. Enables fully
air-gapped deployments. Worth watching but not necessary to start.

---

## 5. Networking: Bridges, Firewall, WireGuard

### Bridge networking for VMs

```nix
{
  # Disable DHCP on physical interface, assign IP to bridge instead
  networking.useDHCP = false;

  networking.bridges.br0 = {
    interfaces = [ "enp1s0" ];   # your physical ethernet interface
  };

  networking.interfaces.br0 = {
    ipv4.addresses = [{
      address = "10.0.0.10";    # static IP for the Zenbook on your lab network
      prefixLength = 24;
    }];
  };

  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Allow libvirt to use this bridge
  virtualisation.libvirtd.allowedBridges = [ "virbr0" "br0" ];
  networking.firewall.trustedInterfaces = [ "virbr0" "br0" ];
}
```

**Gotcha:** NetworkManager (which GNOME uses) can interfere with manual bridge
configs. For a laptop that also uses WiFi, you may want to keep NetworkManager
for WiFi and only bridge the ethernet. Or use `systemd-networkd` for the bridge
and NetworkManager for WiFi.

### Firewall

```nix
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 6443 80 443 ];
    allowedUDPPorts = [ 51820 ];             # WireGuard
    trustedInterfaces = [ "virbr0" "br0" ];  # no filtering on VM bridges
    # Per-interface rules are also supported:
    # interfaces."br0".allowedTCPPorts = [ ... ];
  };
}
```

| Option | Purpose |
|--------|---------|
| `networking.firewall.enable` | iptables firewall (default true) |
| `networking.firewall.allowedTCPPorts` | Global open TCP ports |
| `networking.firewall.allowedUDPPorts` | Global open UDP ports |
| `networking.firewall.interfaces.<name>.allowedTCPPorts` | Per-interface rules |
| `networking.firewall.trustedInterfaces` | Skip all filtering |
| `networking.firewall.checkReversePath` | Reverse path filter — set `"loose"` for WireGuard |
| `networking.nat.enable` | NAT for forwarding (e.g., WireGuard gateway) |

### WireGuard

Your `soundship` WireGuard setup uses Ansible to template `wg0.conf` and manage
keys via vault. On NixOS, WireGuard is declarative:

```nix
{
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.1.0.10/24" ];     # Zenbook's VPN address
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/private-key";  # not in the nix store!

    peers = [
      {
        # soundship (gateway)
        publicKey = "SOUNDSHIP_PUBLIC_KEY_HERE";
        allowedIPs = [ "10.1.0.0/24" "10.0.0.0/24" ];
        endpoint = "soundship.example.com:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
  # Important for WireGuard routing:
  networking.firewall.checkReversePath = "loose";
}
```

**Two approaches for WireGuard on NixOS:**
1. `networking.wg-quick` — simpler, similar to manual `wg-quick up wg0`
2. `systemd.network.netdevs` — more powerful, integrates with networkd

For a peer that connects to `soundship`, `wg-quick` is simpler.

**Secrets management:** Private keys should NOT go in the nix store (it's
world-readable). Options:
- Put the key file at a path outside the store and reference it via `privateKeyFile`
- Use `sops-nix` or `agenix` to encrypt secrets in the repo and decrypt at activation

---

## 6. Containers: Docker vs Podman vs OCI Services

### Current setup

On `soundship`, you use containerd/nerdctl for rootless containers and
Docker Compose for some services (Caddy, monitoring, etc.).

### NixOS container options

| Approach | NixOS Option | When to use |
|----------|-------------|-------------|
| Docker | `virtualisation.docker.enable` | Familiar, wide compat |
| Docker (rootless) | `virtualisation.docker.rootless.enable` | Rootless Docker daemon |
| Podman | `virtualisation.podman.enable` | Daemonless, rootless by default |
| OCI containers | `virtualisation.oci-containers.containers` | Declare containers as systemd services |
| NixOS containers | `containers.<name>` | Lightweight systemd-nspawn, NixOS-native |

### OCI Containers — the "Nix way" to run Docker images

This is probably the most interesting option. Instead of Docker Compose, you
declare containers directly in your NixOS config, and they become systemd
services:

```nix
{
  virtualisation.oci-containers.backend = "podman";  # or "docker"

  virtualisation.oci-containers.containers = {
    caddy = {
      image = "caddy:2-alpine";
      ports = [ "80:80" "443:443" ];
      volumes = [
        "/etc/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"
        "caddy_data:/data"
      ];
      extraOptions = [ "--network=host" ];
    };

    prometheus = {
      image = "prom/prometheus:v3.8.0";
      ports = [ "9090:9090" ];
      volumes = [
        "/etc/prometheus:/etc/prometheus:ro"
        "prometheus_data:/prometheus"
      ];
    };
  };
}
```

Each container becomes a systemd service (`podman-caddy.service`,
`podman-prometheus.service`) — managed by `systemctl`, starts on boot, appears
in journal logs.

**compose2nix:** There's a tool that converts `docker-compose.yaml` to
`oci-containers` Nix config. Useful for migrating your existing compose files.

### But also: native NixOS services

Many things you run as containers on Ubuntu have native NixOS modules. You don't
*need* a Prometheus container if you can just:

```nix
services.prometheus.enable = true;
```

This is covered more in section 8.

---

## 7. GPU Passthrough (VFIO)

### Current setup on soundship

Your Ansible `create-linux.yaml` sets up GPU passthrough for `llm-server` using
VFIO. Hook scripts bind/unbind the GPU from the host driver.

### NixOS VFIO setup

The Zenbook has an AMD iGPU (no discrete GPU to pass through), so this is more
relevant for a future NixOS server build. But here's how it maps:

```nix
{
  # Enable IOMMU
  boot.kernelParams = [
    "amd_iommu=on"
    # "iommu=pt"                          # performance optimization
    # "vfio-pci.ids=10de:xxxx,10de:yyyy"  # bind GPU at boot (PCI vendor:device IDs)
  ];

  boot.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];

  # Ensure VFIO loads before the GPU driver
  boot.initrd.kernelModules = [ "vfio_pci" ];

  # Blacklist the host GPU driver (if passing through)
  # boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];

  # Libvirt hooks for dynamic bind/unbind (like your Ansible hooks)
  virtualisation.libvirtd.hooks.qemu = {
    gpu-passthrough = pkgs.writeShellScript "gpu-hook" ''
      GUEST="$1"
      ACTION="$2"
      SUB_ACTION="$3"
      if [ "$GUEST" = "llm-server" ]; then
        if [ "$ACTION" = "prepare" ] && [ "$SUB_ACTION" = "begin" ]; then
          # Unbind from host driver, bind to vfio-pci
          echo "vfio-pci" > /sys/bus/pci/devices/0000:01:00.0/driver_override
          echo "0000:01:00.0" > /sys/bus/pci/drivers_probe
        elif [ "$ACTION" = "release" ] && [ "$SUB_ACTION" = "end" ]; then
          # Rebind to host driver
          echo "" > /sys/bus/pci/devices/0000:01:00.0/driver_override
          echo "0000:01:00.0" > /sys/bus/pci/drivers_probe
        fi
      fi
    '';
  };
}
```

**NixOS advantage:** Because NixOS has generations, if a VFIO config borks your
display or boot, you can select a previous generation from the bootloader and
roll back. On Ubuntu, a bad VFIO config can leave you at a black screen with no
easy recovery path.

---

## 8. Monitoring: Prometheus, Grafana, Node Exporter

### Current setup on soundship

Docker Compose runs Prometheus, Grafana, Alertmanager, Loki, and Blackbox
Exporter. Node exporter is installed via Ansible on each VM.

### NixOS native services

NixOS has modules for all of these. You can run them as native systemd services
instead of containers:

```nix
{
  # Node exporter — replaces Ansible prometheus.prometheus role
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" "processes" ];
    port = 9100;
  };

  # Prometheus server
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            "localhost:9100"           # self
            "10.0.0.2:9100"            # soundship
            # ... other nodes
          ];
        }];
      }
    ];

    # Alert rules
    rules = [
      (builtins.toJSON {
        groups = [{
          name = "node-alerts";
          rules = [{
            alert = "HighCPU";
            expr = ''100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80'';
            for = "5m";
          }];
        }];
      })
    ];
  };

  # Grafana
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
      };
    };
    # Provisioning datasources and dashboards is also declarative
    provision = {
      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9090";
      }];
    };
  };

  # Loki
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      # ... full loki config
    };
  };

  # Alertmanager
  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;
  };

  # Open ports
  networking.firewall.allowedTCPPorts = [ 9090 9100 3000 3100 ];
}
```

**Key module options:**

| Service | NixOS Option | Notes |
|---------|-------------|-------|
| Node exporter | `services.prometheus.exporters.node.enable` | ~50 collector options |
| Prometheus | `services.prometheus.enable` | Full config including scrape, rules, alerting |
| Grafana | `services.grafana.enable` | Provisioning, datasources, dashboards |
| Alertmanager | `services.prometheus.alertmanager.enable` | Routing, receivers |
| Loki | `services.loki.enable` | Full Loki config as Nix attrset |
| Blackbox | `services.prometheus.exporters.blackbox.enable` | HTTP/TCP/ICMP probes |

**Trade-off:** Running monitoring as NixOS services means they're tightly coupled
to the host. On `soundship`, running in containers makes it easy to blow away and
recreate. For the Zenbook as a secondary node, native services are fine — the
whole system is declarative anyway.

---

## 9. Flake Structure for Multi-Role Configs

### Current structure

```
nixos/
├── flake.nix            # single system (zenbook) + home-manager
├── configuration.nix    # everything in one file
├── home.nix
└── hardware/
    └── zenbook.nix
```

### Recommended evolution

As the Zenbook takes on more roles, split into composable modules:

```
nixos/
├── flake.nix                   # system definitions
├── hosts/
│   └── zenbook/
│       ├── default.nix         # host-specific config (hardware, boot, desktop)
│       └── hardware.nix        # generated hardware config
├── modules/
│   ├── desktop.nix             # GNOME, PipeWire, fonts, Steam
│   ├── development.nix         # dev tools, languages, Docker
│   ├── hypervisor.nix          # libvirt, QEMU, bridge networking
│   ├── kubernetes.nix          # k3s config
│   ├── monitoring.nix          # Prometheus, node-exporter, Grafana
│   ├── networking.nix          # firewall, WireGuard
│   └── containers.nix          # OCI container services
├── home/
│   ├── default.nix             # common home-manager config
│   └── steven.nix              # user-specific config
└── secrets/                    # sops-nix or agenix encrypted secrets
    └── secrets.yaml
```

The flake would compose these modules per host:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.zenbook = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/zenbook
          ./modules/desktop.nix
          ./modules/development.nix
          ./modules/hypervisor.nix      # add/remove roles here
          ./modules/kubernetes.nix
          ./modules/monitoring.nix
          ./modules/networking.nix
          home-manager.nixosModules.home-manager  # HM as NixOS module
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.steven = import ./home/steven.nix;
          }
          sops-nix.nixosModules.sops
        ];
      };

      # Future: add more hosts
      # nixosConfigurations.server = nixpkgs.lib.nixosSystem { ... };
    };
}
```

**Home Manager as NixOS module vs standalone:**
Your current setup runs Home Manager standalone (separate `home-manager switch`
command). Integrating it as a NixOS module means a single `nixos-rebuild switch`
updates everything. Your `nix-rebuild` alias already tries to do both — making HM
a NixOS module eliminates the need for that.

**Secrets:** Both `sops-nix` and `agenix` integrate with flakes. You already use
`age` and `sops` (based on your install script). `sops-nix` would let you commit
encrypted secrets (WireGuard keys, service passwords) directly in the repo and
decrypt them at system activation.

---

## 10. Migration Strategy

### Phase 0: Modernize (no new capabilities)
- [ ] Bump flake to nixos-24.11 and home-manager release-24.11
- [ ] Fix breaking changes (sound.enable, nerdfonts, xkb layout, gnome paths)
- [ ] Restructure into modules (desktop, development, etc.)
- [ ] Integrate Home Manager as a NixOS module
- [ ] Test that `nixos-rebuild switch` works end-to-end

### Phase 1: Hypervisor basics
- [ ] Enable libvirtd with QEMU/KVM
- [ ] Add virt-manager to system packages
- [ ] Test creating a VM using your existing Ansible playbooks
- [ ] Set up bridge networking (at least for wired ethernet)

### Phase 2: Kubernetes exploration
- [ ] Enable k3s in single-node server mode
- [ ] Deploy a test workload (nginx, or your Woodpecker setup)
- [ ] Install kubectl, helm, k9s as system packages (some already present)
- [ ] Experiment with `services.k3s.manifests` for declarative deployments

### Phase 3: Networking & security
- [ ] Configure WireGuard to peer with soundship's VPN
- [ ] Set up firewall rules for k3s and VM traffic
- [ ] Add sops-nix for secrets management

### Phase 4: Monitoring
- [ ] Enable node_exporter on the Zenbook
- [ ] Point soundship's Prometheus at the Zenbook's exporter
- [ ] Optionally run a local Grafana for Zenbook-specific dashboards

### Phase 5: Evaluate
- [ ] Run a real workload (staging service?) on the Zenbook's k3s
- [ ] Compare operational experience with the Ubuntu/Ansible approach
- [ ] Decide whether to migrate soundship to NixOS or keep the split setup

---

## 11. Action Items

**Immediate (before touching the Zenbook):**
1. Read the [24.11 release notes](https://nixos.org/blog/announcements/2024/nixos-2411/)
   to understand breaking changes
2. Read the [NixOS Wiki on Libvirt](https://wiki.nixos.org/wiki/Libvirt) —
   it's comprehensive and well-maintained
3. Look at [compose2nix](https://github.com/aksiksi/compose2nix) for converting
   existing docker-compose files

**First coding session:**
1. Create the modular directory structure
2. Bump the flake inputs
3. Split `configuration.nix` into role-based modules
4. Test with `nixos-rebuild build` (builds without switching — safe dry run)

**References:**
- [NixOS Wiki — Libvirt](https://wiki.nixos.org/wiki/Libvirt)
- [NixOS Wiki — Virt-manager](https://wiki.nixos.org/wiki/Virt-manager)
- [NixOS Wiki — K3s](https://wiki.nixos.org/wiki/K3s)
- [NixOS Wiki — WireGuard](https://wiki.nixos.org/wiki/WireGuard)
- [NixOS Wiki — GPU Passthrough](https://wiki.nixos.org/wiki/VFIO)
- [NixOS Options Search](https://search.nixos.org/options)
- [MyNixOS option browser](https://mynixos.com/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [compose2nix](https://github.com/aksiksi/compose2nix)
- [k3s-nix (pure Nix k8s)](https://github.com/rorosen/k3s-nix)
