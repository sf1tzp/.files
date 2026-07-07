```
  homelab/backups/
  ├── .sops.yaml                          # same age keys as homelab/k8s/
  ├── secrets.yaml                        # fill in + encrypt before committing
  ├── playbook.yaml
  └── templates/
      ├── restic-backup.sh.j2
      ├── restic-backup.service.j2
      └── restic-backup.timer.j2
```

Before running the playbook, fill in secrets.yaml with real values, then encrypt it:
  `sops --encrypt --in-place homelab/backups/secrets.yaml`

  To add a second destination, just append to the destinations list in secrets.yaml before encrypting:
```
  destinations:
    - name: primary
      repository: s3:https://...
      ...
    - name: offsite
      repository: s3:https://...
      ...
```

Configurable vars at the top of playbook.yaml:
  - backup_dirs — list of paths to back up (defaults to /mnt/storage)
  - backup_schedule — systemd OnCalendar expression (defaults to *-*-* 02:00:00)
  - retention — restic forget --prune flags (defaults to 7 daily / 4 weekly / 6 monthly)

Then `just backups` deploys it. Each destination gets its own /etc/systemd/system/restic-backup-{name}.{service,timer} and /usr/local/bin/restic-backup-{name} script, so they run independently.
