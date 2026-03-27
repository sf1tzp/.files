# Postgres Password Rotation Runbook

## Overview

This runbook covers rotating the shared Postgres user password across a three-VM setup:

| Host | Role |
|---|---|
| `db-vm` | Runs the Postgres instance |
| `services-vm` | Runs container services via Docker Compose |
| `devbox` | Management node; secrets managed with SOPS |

**Downtime expectation:** Brief (~seconds to low minutes, depending on number of services to bounce).

---

## Prerequisites

- SSH access to `db-vm` and `services-vm` from devbox
- SOPS access (key available and `sops` binary installed on devbox)
- `psql` available on devbox or db-vm
- All service env files tracked as SOPS-encrypted files on devbox

---

## Step 1 — Generate a New Password

On devbox, generate a strong password and store it somewhere temporary (e.g. a shell variable — do **not** write it to plaintext disk):

```bash
NEW_PG_PASS=$(openssl rand -base64 32)
echo $NEW_PG_PASS   # verify it looks sane, then don't echo again
```

---

## Step 2 — Update the Password in Postgres

SSH to `db-vm` and rotate the password for the Postgres user (substitute your actual username for `appuser`):

```bash
ssh db-vm
sudo -u postgres psql -c "ALTER USER appuser PASSWORD '$NEW_PG_PASS';"
```

Verify the new credential works before proceeding:

```bash
psql -h localhost -U appuser -d yourdb -c '\conninfo'
# enter the new password when prompted
exit
```

> **Note:** At this point, existing service connections using the old password will begin failing on reconnect. The window between this step and Step 4 is your downtime window.

---

## Step 3 — Update SOPS-Encrypted Secrets on Devbox

For each service that has a connection string, decrypt its env file, update the password, and re-encrypt.

```bash
# Example for a single service
sops path/to/service-a.env.sops

# Inside the editor, find and update the relevant line, e.g.:
# DATABASE_URL=postgres://appuser:OLD_PASS@db-vm:5432/yourdb
# → replace OLD_PASS with $NEW_PG_PASS

# SOPS re-encrypts on save/exit
```

Repeat for each service env file. If your connection strings are consolidated in one secrets file, only one edit is needed.

**Tip:** If you have many services, consider scripting this with `sops --set` or a `sed` pipeline through `sops exec-env`.

---

## Step 4 — Push Updated Env Files to services-vm

```bash
# Decrypt and push each env file
sops --decrypt path/to/service-a.env.sops | ssh services-vm "cat > /path/to/service-a/.env"

# Repeat for each service, or loop:
for svc in service-a service-b service-c; do
  sops --decrypt path/to/${svc}.env.sops \
    | ssh services-vm "cat > /srv/${svc}/.env"
done
```

---

## Step 5 — Bounce All Affected Services

SSH to `services-vm` and restart each service to pick up the new credentials:

```bash
ssh services-vm

# Restart all affected services:
cd /srv/service-a && docker compose down && docker compose up -d
cd /srv/service-b && docker compose down && docker compose up -d
# ... etc

# Or if all services share a compose file:
cd /srv && docker compose down && docker compose up -d
```

---

## Step 6 — Verify

From devbox or services-vm, confirm each service is healthy:

```bash
# Check container statuses
ssh services-vm "docker ps --format 'table {{.Names}}\t{{.Status}}'"

# Tail logs briefly to catch any auth errors
ssh services-vm "docker compose -f /srv/service-a/docker-compose.yml logs --tail=20"
```

Check Postgres for active connections:

```bash
ssh db-vm "sudo -u postgres psql -c 'SELECT count(*) FROM pg_stat_activity WHERE usename = '\''appuser'\'';'"
```

If count > 0 and services are healthy, rotation is complete.

---

## Rollback

If something goes wrong before Step 5:

1. Revert the Postgres password back to the old value (requires knowing it — keep it in your shell history or a temp variable):
   ```bash
   ssh db-vm "sudo -u postgres psql -c \"ALTER USER appuser PASSWORD '$OLD_PG_PASS';\""
   ```
2. No env file changes need to be reverted since services haven't restarted yet.

If you're past Step 5 and a service is broken, the fastest path is:

1. Set Postgres password to the value now in SOPS (i.e. `$NEW_PG_PASS`) — it's already there, so just re-run Steps 2+.
2. Re-push the env and bounce the specific broken service.

---

## Appendix: Migrating to Per-Service Postgres Users

If you want to reduce blast radius for future rotations (and tighten permissions), create a dedicated user per service:

```sql
-- On db-vm as superuser
CREATE USER svc_a WITH PASSWORD 'generated-pass-1';
GRANT CONNECT ON DATABASE yourdb TO svc_a;
GRANT USAGE ON SCHEMA public TO svc_a;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO svc_a;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO svc_a;

-- Repeat for svc_b, svc_c, etc.
```

Each service then gets its own `DATABASE_URL` pointing to its own user. Rotating one service's credential no longer requires touching others, and you can revoke access per-service without affecting the rest.

Once per-service users are in place, this runbook applies identically — just scope Steps 3–5 to the single service being rotated.
