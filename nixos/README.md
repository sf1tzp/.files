# NixOS Configuration

Flake-based NixOS config for homelab hosts, with Home Manager integrated as a NixOS module. Hosts are built through a shared `mkHost` helper in `flake.nix` that layers opt-in role modules on top of a common base.

## Structure

```
nixos/
├── flake.nix              # Flake definition, inputs, mkHost helper, host list
├── hosts/
│   └── zenbook/
│       ├── default.nix    # Host-specific: boot, hostname, CA trust, backups
│       └── hardware.nix   # Generated hardware config (disk UUIDs, kernel modules)
├── modules/
│   ├── common.nix         # Shared base: user, SSH, nix settings, locale (every host)
│   ├── desktop.nix        # GNOME, PipeWire, fonts, Steam, Firefox
│   ├── development.nix    # Docker, dev tools (go, rust, kubectl, etc.)
│   ├── k3s-server.nix     # Reusable single-node k3s control plane
│   └── k3s-cluster.nix    # Zenbook: bridge networking + microVM workers (imports k3s-server)
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

To add a new role, create a module in `modules/` and add it to a host's `extraModules` in `flake.nix`:

```nix
nixosConfigurations.zenbook = mkHost {
  hostname = "zenbook";
  extraModules = [
    ./modules/development.nix
    ./modules/k3s-cluster.nix
    # ./modules/monitoring.nix    # <- add new modules here
  ];
};
```

## Adding a Host

Every host gets `modules/common.nix` (shared user/SSH/nix/locale) plus its own
`hosts/<name>/` directory, wired up via `mkHost`:

```nix
nixosConfigurations.staging-k3s = mkHost {
  hostname = "staging-k3s";        # -> ./hosts/staging-k3s/{default.nix,secrets.nix}
  home = false;                    # headless infra host: skip Home Manager dotfiles
  extraModules = [
    ./hosts/staging-k3s/secrets.nix  # per-host sops file + age key source
    ./modules/k3s-server.nix         # reusable single-node control plane
  ];
};
```

The host's `default.nix` declares its own networking (static IP), hostname, and
`system.stateVersion`; `hosts/<name>/secrets.nix` points sops at that host's
encrypted file and age key. `common.nix` supplies everything shared.

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

- `monitoring.nix` — Prometheus, node-exporter, Grafana
- `networking.nix` — WireGuard, firewall rules for k3s/VM traffic

---

# K8s cluster notes

## Rebuild

Rebuild the cluster with scripts/teardown-cluster.sh

## Prepare kubeconfig for distribution

```
sudo cp /etc/rancher/k3s/k3s.yaml /tmp/kubeconfig
sudo chown $USER /tmp/kubeconfig
sed -i 's|127.0.0.1|10.0.0.6|' /tmp/kubeconfig

scp /tmp/kubeconfig other-host:~/.kube/config
```
