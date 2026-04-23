# WireGuard mesh

Single source of truth for the homelab WireGuard mesh. Consumed by:

- Ansible (`playbook.yaml`) for every VM in the `wireguard:` inventory group.
- Nix (`nixos/modules/wireguard.nix`) for the zenbook host.

## Files

- `peers.json` — per-peer `wg_vpn_ip`, optional `wg_endpoint_ip`, `public_key`. Public keys are not secret; private keys live elsewhere (ansible vault / sops).
- `playbook.yaml` — installs `wireguard-tools`, manages per-host private keys in `~/.homelab-wireguard-keys.yaml` (vault-encrypted), writes derived pubkeys back into `peers.json`, and renders `/etc/wireguard/wg0.conf` from the template.
- `templates/wg0.conf.j2` — Jinja2 template that iterates `peers_data.peers` (mesh) and `peers_data.clients` (roaming).

## Conventions

`wg_endpoint_ip` is **only** set for peers with a stable externally-reachable endpoint:

- Public DNS for remote VMs (e.g. `db2.streetfortress.cloud`).
- LAN IP for always-on LAN VMs (e.g. `10.0.0.31` for staging-web).

Peers behind dynamic NAT with no fixed endpoint (soundship, devbox, zenbook) omit `wg_endpoint_ip`. Other peers learn their endpoint dynamically from the handshakes those hosts initiate; `PersistentKeepalive = 25` keeps the NAT mapping pinned.

`clients` are roaming devices (e.g. macbook-air) — no `wg_endpoint_ip`, no `PersistentKeepalive` on server-side peer entries. They connect inbound via the router's DDNS → soundship port-forward.

## Adding a peer

**VM (ansible-managed):**

1. Add the peer's inventory hostvars to `../inventory.yaml` and put it in the `wireguard:` group.
2. Add an entry under `peers.<name>` in `peers.json` with `wg_vpn_ip` (and `wg_endpoint_ip` if applicable). Leave `public_key` as `""`.
3. Run `just wireguard <name>`. The playbook generates a private key, stores it vault-encrypted, derives the pubkey, writes it back into `peers.json`, and renders `wg0.conf`.
4. Commit the updated `peers.json`.
5. Re-run `just wireguard` against the other hosts so they pick up the new peer.

**Zenbook (nix-managed):**

1. Add `peers.zenbook` in `peers.json` with `wg_vpn_ip` and `public_key: ""`.
2. Generate the private key and store in sops:
   ```sh
   cd nixos
   PRIV=$(wg genkey)
   sops --set "[\"wireguard-private-key\"] \"$PRIV\"" secrets/cluster.yaml
   PUB=$(echo "$PRIV" | wg pubkey)
   jq --arg k "$PUB" '.peers.zenbook.public_key = $k' ../homelab/wireguard/peers.json | sponge ../homelab/wireguard/peers.json
   ```
3. `sudo nixos-rebuild switch --flake .#zenbook`.
4. Commit the updated `peers.json`.
5. Re-run `just wireguard` so VM peers pick up zenbook.
