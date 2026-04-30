# Databasus

Database backup and management system.

- **URL**: https://databasus.zen.lofi
- **Chart**: `oci://ghcr.io/databasus/charts/databasus`
- **Source**: https://github.com/databasus/databasus

## Configuration

Backup destinations and database connections are configured through the
web UI after deployment — the Helm chart has no values for these.

### Gitea PostgreSQL connection

| Field    | Value                                                  |
| -------- | ------------------------------------------------------ |
| Host     | `postgres-postgresql.postgres.svc.cluster.local`       |
| Port     | `5432`                                                 |
| Username | `gitea`                                                |
| Password | *(from `gitea-db-credentials` secret in gitea namespace)* |
| Database | `gitea`                                                |

### S3 destination (rustfs)

| Field            | Value                                                    |
| ---------------- | -------------------------------------------------------- |
| Endpoint         | `http://rustfs-svc.rustfs.svc.cluster.local:9000`        |
| Access Key       | *(from `rustfs-credentials` secret in rustfs namespace)*  |
| Secret Key       | *(from `rustfs-credentials` secret in rustfs namespace)*  |
| Region           | `us-east-1`                                              |
| Use SSL          | No (cluster-internal)                                    |

### Notifier (discord)

How to get Discord webhook URL:

1. Create or select a Discord channel
2. Go to channel settings (gear icon)
3. Navigate to Integrations
4. Create a new webhook
5. Copy the webhook URL

Note: make sure make channel private if needed

| Field            | Value                                                    |
| ---------------- | -------------------------------------------------------- |
| Name         | `Discord Notifications`        |
| Channel Webhook URL         | *(from discord channel settings)*        |

## Deploy

```sh
just deploy-databasus
```


---

# databasus-operator

I POC'd a database operator which can be built & deployed from my branch https://github.com/sf1tzp/databasus/tree/operator

PR in https://github.com/databasus/databasus/pull/534

Deploy databasus from helm first, build & deploy the operator and custom resources (just deploy-databasus-operator; requires my branch in ~/oss/databasus).
