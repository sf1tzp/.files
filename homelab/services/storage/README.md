# soundship storage

The 2 TB USB drive on soundship: its mount, the `[Storage]` Samba share
the Macs use for video offload, and a nightly restic backup to Backblaze
B2. Captured from the imperative host config per estate-hub#93.

## Why the share is authenticated-only

Guest access worked from Linux clients and broke from the Macs: macOS
Tahoe (26) requires signed SMB sessions by default, and a guest session
has no session key to sign with. The symptom is a mount that succeeds
while every operation fails — `ls` returns EACCES without the client
ever sending a directory query, and Finder copies die with error 100093
(the server-side trace shows the data write never arrives; only a 0-byte
create lands). A password-authenticated session has a session key, so
signing works and the share behaves.

The share also drops the `fruit`/`streams_xattr` VFS stack: the drive is
exFAT, which has no extended attributes, so every metadata stream
operation failed. macOS handles a stream-less share fine (AppleDouble
`._*` files).

## Mint steps (one-time, by a human)

1. **Samba password** — on soundship:

   ```
   sudo smbpasswd -a steven
   ```

   Use a dedicated password; it goes in the macOS Keychain on each Mac
   (Finder → ⌘K → `smb://soundship/Storage`, connect as `steven`).
   If a Mac auto-connects as Guest, open Keychain Access and delete the
   stored `soundship` entry first.

2. **B2 bucket and application key** — in the Backblaze console, create
   the bucket `sfi-hub-pv-backups` (private, no lifecycle rules —
   restic owns retention), then a key scoped to it with
   `namePrefix soundship/`. Unlike a fort's key (deployments
   docs/infra/backups.md: forts must not be able to erase their offsite
   copy), this key **includes deleteFiles**: soundship is
   hand-configured and runs its own `restic forget --prune`, so
   retention is enforced locally.

3. **Secrets file** — on the controller:

   ```
   cat > ~/.homelab-storage-secrets.yaml <<'EOF'
   storage_b2_key_id: "<keyID>"
   storage_b2_app_key: "<applicationKey>"
   storage_restic_password: "<new random password — this encrypts the repo>"
   EOF
   ansible-vault encrypt ~/.homelab-storage-secrets.yaml --vault-password-file ~/.ansible-password
   ```

   Keep `storage_restic_password` safe outside the vault too (password
   manager): losing it loses the backups.

Then: `just storage` (from `homelab/`). The playbook installs packages,
writes the mount/share/units, initializes the B2 repo, and starts the
timer. It fails with instructions if step 1 was skipped.

## Operating it

```
systemctl list-timers restic-backup-storage.timer   # next run
systemctl start restic-backup-storage.service       # run one now
journalctl -u restic-backup-storage.service -n 50   # last run's log
```

Restore (as root on soundship):

```
set -a; . /etc/restic/storage-b2.env; set +a
restic snapshots
restic restore latest --target /mnt/storage/restore --include '<path>'
```

Retention: 7 daily, 5 weekly, 12 monthly (`forget --prune` runs after
each backup). First backup is ~438 GiB over the WAN — expect it to take
a day or two; later runs are incremental.

## Open ends

- The filesystem stays exFAT until the repave (estate-hub#93 decides the
  reformat; ext4 would give journaling and real ownership, and the
  `force user` workaround in smb.conf could then go).
- Central monitoring covers the backup two ways once the estate-hub
  `soundship-observability` change lands: the s3-exporter probes
  `sfi-hub-pv-backups/soundship/` (B2BackupStale), and the backup service
  publishes `node_pv_backup_last_success_seconds` through node_exporter's
  textfile collector (B2DisagreesWithResticUnit cross-check).
