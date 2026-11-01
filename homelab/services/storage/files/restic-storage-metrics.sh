#!/bin/sh
# Freshness metrics for the central backup rules (estate-hub
# flux/apps/sfi-central/monitoring-central/rules-backups-b2.yaml), the
# same shape the forts' pv-backup module writes, published through this
# host's node_exporter textfile collector. Runs as ExecStartPost, so it
# only ever records a run that succeeded.
set -eu
dir=/var/lib/node_exporter
tmp=$(mktemp "$dir/.restic-storage.prom.XXXXXX")
{
  echo '# HELP node_pv_backup_last_success_seconds Unix time of the last successful restic backup run.'
  echo '# TYPE node_pv_backup_last_success_seconds gauge'
  echo "node_pv_backup_last_success_seconds{target=\"b2\"} $(date +%s)"
  echo '# HELP node_pv_backup_max_age_seconds Oldest a successful run may be before this target counts as stale (2x its cadence).'
  echo '# TYPE node_pv_backup_max_age_seconds gauge'
  echo 'node_pv_backup_max_age_seconds{target="b2"} 172800'
} > "$tmp"
# 0644 or node_exporter (unprivileged) reports textfile scrape errors.
chmod 0644 "$tmp"
mv "$tmp" "$dir/restic-storage.prom"
