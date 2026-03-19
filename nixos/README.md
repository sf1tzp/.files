# NixOS Configuration

Flake-based NixOS config for the Zenbook, with Home Manager integrated as a NixOS module.

## Structure

```
nixos/
├── flake.nix              # Flake definition, inputs, system composition
├── hosts/
│   └── zenbook/
│       ├── default.nix    # Host-specific: boot, users, SSH, firewall
│       └── hardware.nix   # Generated hardware config (disk UUIDs, kernel modules)
├── modules/
│   ├── desktop.nix        # GNOME, PipeWire, fonts, Steam, Firefox
│   ├── development.nix    # Docker, dev tools (go, rust, kubectl, etc.)
│   └── hypervisor.nix     # Libvirt, QEMU/KVM, bridge networking, virt-manager
└── home/
    └── steven.nix         # Home Manager: user packages, dotfiles, shell config
```

## Usage

**Rebuild system (applies both NixOS and Home Manager changes):**
```bash
sudo nixos-rebuild switch --flake ~/.files/nixos#zenbook
```

**Test build without applying:**
```bash
nixos-rebuild build --flake ~/.files/nixos#zenbook
```

**Update flake inputs:**
```bash
nix flake update ~/.files/nixos
```

## Adding Capabilities

To add new roles, create a module in `modules/` and add it to the imports in `flake.nix`:

```nix
modules = [
  ./hosts/zenbook
  ./modules/desktop.nix
  ./modules/development.nix
  ./modules/hypervisor.nix
  # ./modules/kubernetes.nix    # <- add new modules here
  # ...
];
```

## Network Layout

| Host | IP | Role |
|------|----|------|
| Zenbook (br0) | 10.0.0.6 | Hypervisor, k3s control plane |
| k8s-worker-1 (microVM) | 10.0.0.7 | k3s agent |
| k8s-worker-2 (microVM) | 10.0.0.8 | k3s agent |
| Router | 10.0.0.1 | Gateway |
| DNS | 10.0.0.2 | Primary DNS (fallback: 8.8.8.8) |

## Planned Modules

See `NIXOS-HOMELAB-NOTES.md` for detailed notes.

- `kubernetes.nix` — k3s control plane + microvm.nix worker nodes
- `monitoring.nix` — Prometheus, node-exporter, Grafana
- `networking.nix` — WireGuard, firewall rules for k3s/VM traffic
