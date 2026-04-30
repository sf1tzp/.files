# Disaster Recovery Runbook — zenbook k3s Cluster

## Quick Reference

| Scenario | Section |
|----------|---------|
| k3s won't start / etcd corruption | [Cluster Corruption](#1-k3s-cluster-corruption) |
| Single PVC data loss (Gitea files, Databasus) | [PVC Restore](#2-single-pvc-loss) |
| Database corruption (databasus-managed DB) | [Database Recovery](#3-database-recovery-databasus-managed-backups) |
| RustFS down (local backup target gone) | [RustFS Loss](#4-rustfs-loss) |
| Disk failure (new drive, same machine) | [Full Disk Failure](#5-full-disk-failure) |
| Machine dead (new hardware entirely) | [Full Host Loss](#6-full-host-loss) |

---

## Prerequisites

Every recovery scenario requires some subset of these. Verify what you have before starting.

**Critical assets:**

| Asset | Location | Backup strategy |
|-------|----------|-----------------|
| Age key (decrypts all sops secrets) | `/home/steven/.config/sops/age/keys.txt` | Must be independently backed up (password manager, USB) |
| NixOS + homelab config | `~/.files` (git) | Push to GitHub mirror |
| Restic repo password | sops: `restic-password` | Recoverable if age key is available |
| S3 credentials | sops: `restic-s3-env-rustfs`, `restic-s3-env-offsite` | Recoverable if age key is available |

**Verify prerequisites (on a running system):**

```bash
# Age key exists
ls -la /home/steven/.config/sops/age/keys.txt

# Sops can decrypt
sops -d ~/.files/nixos/secrets/cluster.yaml | head -5

# Restic password accessible
sudo cat /run/secrets/restic-password

# Offsite S3 reachable
sudo s5cmd-offsite ls s3://zen-cluster-backups/

# Local RustFS reachable (only if RustFS is running)
sudo s5cmd-rustfs ls s3://k3s-backup/
```

**Tools needed:** `restic`, `s5cmd`, `kubectl`, `k3s`, `sops`, `age`, `helm`, `just`

---

## 1. k3s Cluster Corruption

### 1a. Restore from etcd snapshot (preferred)

```bash
# List available snapshots
ls -lt /var/lib/rancher/k3s/server/db/snapshots/

# Stop everything
sudo systemctl stop k3s
sudo systemctl stop microvm@k8s-worker-1

# Restore from a snapshot
sudo k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/<snapshot-file>

# Start k3s
sudo systemctl start k3s

# Wait for control plane to be Ready
sudo k3s kubectl get nodes

# Start worker
sudo systemctl start microvm@k8s-worker-1

# Verify all pods
sudo k3s kubectl get pods -A
```

### 1b. Full cluster rebuild (etcd snapshots also lost)

```bash
# Stop everything
sudo systemctl stop k3s
sudo systemctl stop microvm@k8s-worker-1

# Wipe control plane state
sudo rm -rf /var/lib/rancher/k3s/server/db

# Wipe worker VM persistent volume (will be recreated on boot)
sudo rm -f /var/lib/microvms/k8s-worker-1/k8s-worker-1-var.img

# Do NOT wipe /var/lib/rancher/k3s/storage unless PVCs are also corrupt

# Start control plane
sudo systemctl start k3s

# Wait for Ready
sudo k3s kubectl get nodes

# Start worker
sudo systemctl start microvm@k8s-worker-1

# Redeploy all services
cd ~/.files/homelab/k8s
just deploy-all
```

If PVC storage was preserved, pods will rebind to existing data.
If PVC storage was wiped, follow [PVC Restore](#2-single-pvc-loss) and [Database Restore](#3-gitea-database-corruption).

---

## 2. Single PVC Loss

Restic backs up these PVCs (every 6 hours, 7 daily / 4 weekly / 6 monthly retention):
- `*_gitea_gitea-shared-storage` — Gitea repos, LFS, avatars
- `*_databasus_databasus-storage-databasus-0` — Databasus data

**Not in restic:** PostgreSQL PVC, RustFS PVC, Gitea Actions Runner PVC.
For PostgreSQL, use [Database Restore](#3-gitea-database-corruption) instead.

### Step 1: Identify the PVC directory

```bash
ls /var/lib/rancher/k3s/storage/ | grep <namespace>
# e.g., grep gitea, grep databasus
```

### Step 2: Scale down the workload

```bash
# Gitea:
kubectl -n gitea scale deployment gitea --replicas=0

# Databasus:
kubectl -n databasus scale statefulset databasus --replicas=0
```

### Step 3: Restore from restic

Use offsite (Linode) — it works even if RustFS is down:

```bash
# Set up restic environment (offsite)
export RESTIC_REPOSITORY="s3:https://us-sea-1.linodeobjects.com/zen-cluster-backups/restic"
export RESTIC_PASSWORD_FILE=/run/secrets/restic-password
set -a # set -a will auto-export the variables in this file
source /run/secrets/restic-s3-env-offsite
set +a

# List snapshots
sudo -E restic snapshots

# Browse latest snapshot to confirm paths
sudo -E restic ls latest | head -30

# Restore a specific PVC (example: Gitea)
sudo -E restic restore latest \
  --target / \
  --include "/var/lib/rancher/k3s/storage/*_gitea_gitea-shared-storage"
```

To use the local RustFS target instead (faster, if RustFS is healthy):

```bash
export RESTIC_REPOSITORY="s3:https://s3.zen.lofi/k3s-backup"
export RESTIC_PASSWORD_FILE=/run/secrets/restic-password
set -a # set -a will auto-export the variables in this file
source /run/secrets/restic-s3-env-rustfs
set +a

sudo -E restic restore latest \
  --target / \
  --include "/var/lib/rancher/k3s/storage/*_gitea_gitea-shared-storage"
```

### Step 4: Scale back up

```bash
kubectl -n gitea scale deployment gitea --replicas=1
```

---

## 3. Database Recovery (Databasus-Managed Backups)

Databasus creates daily encrypted `pg_dump` backups at 09:00 to both S3 targets. Retention: 90 days.

- **Offsite:** `s3://zen-cluster-backups/databasus/`
- **Local:** `s3://databasus-operator/`

Backups are AES-256-GCM encrypted using the master key at `/databasus-data/secret.key` within the databasus PV. This key plus all backup metadata are preserved when the databasus PV is restored from restic.

### Approach A: Restore via Databasus UI (preferred)

If databasus itself is healthy or has been rebuilt from its PV backup, use the UI. This is the simplest path — databasus handles decryption, S3 download, and database restore automatically.

**Prerequisites:** The databasus PV must be restored first ([Section 2](#2-single-pvc-loss)) so that `secret.key` and the internal metadata database are available.

1. Ensure databasus is running:

```bash
kubectl -n databasus get pods
# If not running:
kubectl -n databasus scale statefulset databasus --replicas=1
```

2. Access the UI at `https://databasus.zen.lofi`
3. Navigate to the target database, select a backup from the list, and click **Restore**
4. Restart the application that uses the database (e.g., `kubectl -n gitea rollout restart deployment gitea`)

### Approach B: Manual `psql` restore (fallback)

Use this when databasus cannot be rebuilt (PV lost, no restic backup available) but you still have access to the backup files in S3 and the `secret.key`.

For scripted decryption and recovery without the databasus UI, see: https://databasus.com/how-to-recover-without-databasus

#### Step 1: Find the latest backup

```bash
# Offsite (Linode)
sudo s5cmd-offsite ls 's3://zen-cluster-backups/databasus/*'

# Local (RustFS, if available)
sudo s5cmd-rustfs ls 's3://databasus-operator/*'
```

#### Step 2: Download the backup and its metadata file

```bash
sudo s5cmd-offsite cp 's3://zen-cluster-backups/databasus/<backup-file>' /tmp/db-backup.sql.enc
sudo s5cmd-offsite cp 's3://zen-cluster-backups/databasus/<backup-file>.metadata' /tmp/db-backup.sql.enc.metadata
```

#### Step 3: Decrypt the backup

Backups are AES-256-GCM encrypted. You need the backup file, its `.metadata` file, and the `secret.key` from the databasus PV. Follow the upstream decryption procedure: https://databasus.com/how-to-recover-without-databasus

#### Step 4: Restore into PostgreSQL

```bash
# Get the postgres admin password
kubectl -n postgres get secret postgres-credentials \
  -o jsonpath='{.data.postgres-password}' | base64 -d; echo

# Get the database user password
kubectl -n postgres get secret <db>-db-credentials \
  -o jsonpath='{.data.password}' | base64 -d; echo

# Port-forward to postgres
kubectl -n postgres port-forward svc/postgres-postgresql 5432:5432 &

# Drop and recreate the database
PGPASSWORD='<admin-password>' psql -h 127.0.0.1 -U postgres \
  -c "DROP DATABASE IF EXISTS <db>;"
PGPASSWORD='<admin-password>' psql -h 127.0.0.1 -U postgres \
  -c "CREATE DATABASE <db> OWNER <db-user>;"

# Restore the dump
PGPASSWORD='<db-password>' psql -h 127.0.0.1 -U <db-user> -d <db> < /tmp/db-backup.sql

# Kill the port-forward
kill %1
```

#### Step 5: Restart the application

```bash
# e.g., for Gitea:
kubectl -n gitea rollout restart deployment gitea
```

---

## 4. RustFS Loss

**Impact:** Local copies of restic backups (`k3s-backup` bucket), databasus backups (`databasus-operator` bucket), and GHA cache data are lost. **Offsite backups at Linode are unaffected.**

### Step 1: Redeploy RustFS

```bash
cd ~/.files/homelab/k8s
just deploy-rustfs
```

This creates a fresh RustFS instance with a new PVC and initializes the `gha-cache` bucket via the bucket-init job.

### Step 2: Re-initialize the restic repository

```bash
export RESTIC_REPOSITORY="s3:https://s3.zen.lofi/k3s-backup"
export RESTIC_PASSWORD_FILE=/run/secrets/restic-password
set -a # set -a will auto-export the variables in this file
source /run/secrets/restic-s3-env-rustfs
set +a

sudo -E restic init
```

Trigger an immediate backup to repopulate:

```bash
sudo systemctl start restic-backups-k3s-pv-rustfs.service
```

### Step 3: Re-create the databasus-operator bucket

```bash
sudo s5cmd-rustfs mb s3://databasus-operator
```

The next scheduled databasus operator backup (daily at 09:00) will repopulate it.

### What you lose

All local backup history. Offsite (Linode) backups remain intact. GHA cache is ephemeral and will rebuild naturally.

---

## 5. Full Disk Failure

New drive in the same machine. The age key and all local state are gone.

### Step 1: Install NixOS

- Boot from NixOS USB installer
- Partition and format the new drive (EFI + root, matching original layout)
- Mount at `/mnt`

### Step 2: Restore the age key

Retrieve from your independent backup (password manager, encrypted USB, etc.):

```bash
mkdir -p /mnt/home/steven/.config/sops/age
# Copy/paste or transfer the age key into:
# /mnt/home/steven/.config/sops/age/keys.txt
chmod 600 /mnt/home/steven/.config/sops/age/keys.txt
```

### Step 3: Clone the config repo

```bash
mkdir -p /mnt/home/steven
git clone <github-mirror-url> /mnt/home/steven/.files
```

If the repo was only on Gitea and Gitea is down, you need the GitHub mirror or another copy.

### Step 4: Generate hardware config and install

```bash
nixos-generate-config --root /mnt

# Replace hardware.nix with the generated one
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/home/steven/.files/nixos/hosts/zenbook/hardware.nix

# Install
nixos-install --flake /mnt/home/steven/.files/nixos#zenbook
```

### Step 5: Reboot and verify

```bash
# Verify sops decryption works
sudo cat /run/secrets/k3s-token

# k3s will auto-start and bootstrap a fresh cluster
sudo k3s kubectl get nodes

# Worker VM will auto-start (var.img recreated automatically)
```

### Step 6: Redeploy all services

```bash
cd ~/.files/homelab/k8s
just deploy-all
```

### Step 7: Restore data from offsite backups

Services are running but have empty PVCs. Restore in this order:

1. **Gitea PVC** — restic restore from offsite ([Section 2, Step 3](#step-3-restore-from-restic) using the offsite target)

2. **Databasus PVC** — restic restore from offsite (same procedure, different include pattern: `*_databasus_databasus-storage-databasus-0`)

3. **Databases** — once databasus is running, restore databases via the UI ([Section 3](#3-database-recovery-databasus-managed-backups))

4. **RustFS** — starts empty, that's fine. Re-init restic repo ([Section 4, Step 2](#step-2-re-initialize-the-restic-repository))

---

## 6. Full Host Loss

Same as [Full Disk Failure](#5-full-disk-failure) with these additional considerations:

- **hardware.nix** must be fully regenerated (`nixos-generate-config` on new hardware)
- **Ethernet interface name** will differ — update `enp116s0f4u1u1` in `modules/k3s-cluster.nix` line 100 to the new interface name (`ip link show` to find it)
- **Bridge config** (`br0`) may need updating for the new ethernet device
- **WireGuard:** if you regenerate the keypair, update `peers.json` in `~/.files/homelab/wireguard/` and distribute the new public key to all peers
- **MAC addresses** for microVMs can stay the same (software-defined)

---

## Backup Verification

Run these periodically to confirm backups are healthy.

### Restic snapshots exist and are recent

```bash
# Offsite
export RESTIC_REPOSITORY="s3:https://us-sea-1.linodeobjects.com/zen-cluster-backups/restic"
export RESTIC_PASSWORD_FILE=/run/secrets/restic-password
set -a # set -a will auto-export the variables in this file
source /run/secrets/restic-s3-env-offsite
set +a
sudo -E restic snapshots --latest 3

# Local
export RESTIC_REPOSITORY="s3:https://s3.zen.lofi/k3s-backup"
set -a # set -a will auto-export the variables in this file
source /run/secrets/restic-s3-env-rustfs
set +a
sudo -E restic snapshots --latest 3
```

### Restic repository integrity

```bash
sudo -E restic check
```

### Databasus pg_dump backups exist

```bash
sudo s5cmd-offsite ls 's3://zen-cluster-backups/databasus/'
sudo s5cmd-rustfs ls 's3://databasus-operator/'
```

### etcd snapshots

```bash
ls -lt /var/lib/rancher/k3s/server/db/snapshots/ | head -5
```

### Systemd timers are active

```bash
systemctl list-timers 'restic-backups-*' --all

# Check recent backup logs
sudo journalctl -u restic-backups-k3s-pv-offsite.service --since "24 hours ago" --no-pager | tail -20
sudo journalctl -u restic-backups-k3s-pv-rustfs.service --since "24 hours ago" --no-pager | tail -20
```

### Test restore (dry run)

```bash
export RESTIC_REPOSITORY="s3:https://us-sea-1.linodeobjects.com/zen-cluster-backups/restic"
export RESTIC_PASSWORD_FILE=/run/secrets/restic-password
set -a # set -a will auto-export the variables in this file
source /run/secrets/restic-s3-env-offsite
set +a

sudo -E restic restore latest --target /tmp/restic-test \
  --include "/var/lib/rancher/k3s/storage/*_gitea_gitea-shared-storage" --dry-run
```

---

## Known Gaps

| Gap | Risk | Recommendation |
|-----|------|----------------|
| etcd snapshots not backed up offsite | Full disk loss = no quick etcd restore, must full rebuild | Add snapshot dir to restic `includePatterns` |
| PostgreSQL PVC not in restic | Must rely on daily pg_dump (up to 24h RPO) | Add `*_postgres_data-*` to `includePatterns`, or accept the RPO |
| Age key has no automated offsite backup | All sops secrets irrecoverable without it | Store in password manager or encrypted USB |
| `.files` repo may only live on Gitea | Full host loss = can't access config to rebuild | Push to GitHub as a mirror |
| `gha_cache` database has no backup | Lost on PG failure | Low priority — cache is ephemeral, recreated on deploy |

---

## Reference

| Item | Value |
|------|-------|
| **Storage** | |
| k3s PVC storage | `/var/lib/rancher/k3s/storage/` |
| etcd data | `/var/lib/rancher/k3s/server/db/` |
| etcd snapshots | `/var/lib/rancher/k3s/server/db/snapshots/` |
| Worker VM disk | `/var/lib/microvms/k8s-worker-1/k8s-worker-1-var.img` |
| **Secrets** | |
| Age key | `/home/steven/.config/sops/age/keys.txt` |
| Sops secrets file | `~/.files/nixos/secrets/cluster.yaml` |
| Restic password (runtime) | `/run/secrets/restic-password` |
| S3 env rustfs (runtime) | `/run/secrets/restic-s3-env-rustfs` |
| S3 env offsite (runtime) | `/run/secrets/restic-s3-env-offsite` |
| **S3 Endpoints** | |
| RustFS (local) | `https://s3.zen.lofi` / `rustfs-svc.rustfs.svc.cluster.local:9000` |
| Linode (offsite) | `https://us-sea-1.linodeobjects.com` |
| Restic bucket (local) | `k3s-backup` |
| Restic bucket (offsite) | `zen-cluster-backups/restic` |
| Databasus bucket (local) | `databasus-operator` |
| Databasus bucket (offsite) | `zen-cluster-backups/databasus` |
| **Systemd Units** | |
| Restic local backup | `restic-backups-k3s-pv-rustfs.service` |
| Restic offsite backup | `restic-backups-k3s-pv-offsite.service` |
| **Network** | |
| Control plane | `10.0.0.6` (br0) |
| Worker | `10.0.0.7` |
| WireGuard | `10.1.0.6` |
| Bridge interface | `br0` |
| Ethernet interface | `enp116s0f4u1u1` |
| **Config Paths** | |
| NixOS config | `~/.files/nixos/` |
| K8s manifests | `~/.files/homelab/k8s/` |
| Justfile (deploy recipes) | `~/.files/homelab/k8s/justfile` |
| Databasus operator CRs | `~/.files/homelab/k8s/databasus/operator/CRs/` |
| Databasus source | `~/oss/databasus` |
| **Deploy Order** | |
| `just deploy-all` | DNS → Traefik → cert-manager → PostgreSQL → RustFS → GHA Cache → Gitea → Databasus |
