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
│   └── development.nix    # Docker, dev tools (go, rust, kubectl, etc.)
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
  ./modules/hypervisor.nix    # <- add new modules here
  # ...
];
```

Planned modules (see NIXOS-HOMELAB-NOTES.md):
- `hypervisor.nix` - libvirt/QEMU/KVM
- `kubernetes.nix` - k3s
- `monitoring.nix` - Prometheus, node-exporter, Grafana
- `networking.nix` - WireGuard, bridge networking
