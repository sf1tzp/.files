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
- **Phase 1:** Bridge networking on br0 (10.0.0.6/24), NetworkManager manages WiFi only
- **Phase 2:** microvm.nix added as flake input, two worker VMs defined (k8s-worker-1/2),
  k3s server configured on host, k3s agent configured in each microVM, libvirt removed
- **Phase 3:** sops-nix for secrets management, k3s token distributed via virtiofs share
  from host `/run/secrets` into VMs. Cluster verified: all 3 nodes Ready.

### Next Steps
- [ ] Test cluster with a simple workload
- [ ] WireGuard peering with soundship
- [ ] Monitoring (node-exporter, Prometheus)

---

## microvm.nix

[microvm.nix](https://github.com/microvm-nix/microvm.nix) runs NixOS guests as
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
  url = "github:microvm-nix/microvm.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add `microvm.nixosModules.host` to the host's module list.

### Defining a microVM

See `modules/k3s-cluster.nix` for the full config. Workers are defined with a
`mkWorker` helper — each gets virtiofs shares for `/nix/store` and host secrets,
a persistent `/var` volume, bridge networking with a static MAC/IP, and a k3s
agent pointing at the control plane.

### Key decisions

**Hypervisor backend:** qemu (most compatible), cloud-hypervisor (fastest boot),
kvmtool (smallest). Started with qemu.

**Storage:** microVMs share the host's `/nix/store` via virtiofs (no large root
images needed). Each VM gets a persistent `/var` volume for k3s state, logs, and
containerd layers.

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

---

## Secrets (sops-nix)

[sops-nix](https://github.com/Mic92/sops-nix) decrypts secrets at NixOS
activation time. Encrypted files live in the repo; decrypted secrets appear at
`/run/secrets/<name>` on the host.

### How it works

1. The zenbook's SSH host key (`/etc/ssh/ssh_host_ed25519_key`) is converted to
   an age key. The public half is in `.sops.yaml` as the encryption recipient.
2. `secrets/cluster.yaml` is encrypted with `sops` using that age key. It
   contains `k3s-token` (and any future secrets).
3. On `nixos-rebuild switch`, sops-nix decrypts `cluster.yaml` and writes each
   key as a file under `/run/secrets/`.
4. `modules/secrets.nix` declares which secrets to extract and makes their paths
   available to other modules via `config.sops.secrets.<name>.path`.

### k3s token flow

```
secrets/cluster.yaml (encrypted, in git)
  ↓  sops-nix decrypts at activation
/run/secrets/k3s-token (on host)
  ├── k3s server reads via config.sops.secrets.k3s-token.path
  └── virtiofs share → /run/host-secrets/k3s-token (in each microVM)
      └── k3s agents read via tokenFile
```

### Managing secrets

```bash
# Edit secrets (opens $EDITOR with decrypted yaml, re-encrypts on save)
sops nixos/secrets/cluster.yaml

# Add a new secret: add the key in cluster.yaml, then declare it in secrets.nix:
#   sops.secrets.my-new-secret = {};
# It will appear at /run/secrets/my-new-secret after rebuild.

# If the host SSH key changes, re-derive the age key and update .sops.yaml:
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
sops updatekeys secrets/cluster.yaml
```

---

## kubeconfig

k3s writes a kubeconfig to `/etc/rancher/k3s/k3s.yaml` (root-owned). To use
`kubectl` and other tools as your user:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

The config points at `https://127.0.0.1:6443`. This works because the k3s
server runs on the host. For remote access (e.g. from soundship over
WireGuard), change the server address to `https://10.0.0.6:6443`.

---

## wireguard

zenbook joins the homelab mesh as a regular peer (wg_vpn_ip `10.1.0.6`). Peer metadata lives in `../homelab/wireguard/peers.json`, shared with the Ansible playbook at `../homelab/wireguard/playbook.yaml`. `nixos/modules/wireguard.nix` imports that JSON and configures `networking.wg-quick.interfaces.wg0`. The private key is the only sops-managed value.

Bootstrap:

```sh
nix-shell -p wireguard-tools moreutils # get wg and sponge commands for the steps below:
cd /home/steven/.files/nixos
PRIV=$(wg genkey)
sops --set "[\"wireguard-private-key\"] \"$PRIV\"" secrets/cluster.yaml
PUB=$(echo "$PRIV" | wg pubkey)
jq --arg k "$PUB" '.peers.zenbook.public_key = $k' ../homelab/wireguard/peers.json | sponge ../homelab/wireguard/peers.json
sudo nixos-rebuild switch --flake .#zenbook
```

Then, from the Ansible controller, re-run `just wireguard` so all VM peers pick up zenbook's pubkey.

---

## Future Considerations

- **Monitoring:** node-exporter on host + workers, Prometheus scraping all nodes
- **WireGuard:** Peer with soundship for cross-network cluster access
- **Woodpecker CI:** Run on this cluster (resolves containerd/Docker backend issue)

---

## References

- [microvm.nix](https://github.com/microvm-nix/microvm.nix)
- [NixOS k3s module](https://search.nixos.org/options?query=services.k3s)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [NixOS options search](https://search.nixos.org/options)
