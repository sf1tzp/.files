# Logging Configuration

## Overview

This homelab uses Fluent Bit to collect logs from nerdctl containers and system audit logs, then ships them to Loki for centralized logging.

## Configuration

### Inventory Variables

Each host in the monitoring group should have:

- `logging_endpoint_ip`: IP address of the Loki server (defaults to `10.0.0.2`)
- `logging_endpoint_port`: Port for Loki (defaults to `3100`)

Example:
```yaml
staging-web:
  hosts:
    staging-web:
      ansible_host: 10.0.0.31
      ansible_user: deployer
      logging_endpoint_ip: 10.0.0.2
```

### Log Sources

#### 1. Container Logs (nerdctl)

**Location**: `~/.local/share/nerdctl/*/containers/default/*/*-json.log`

**Container name resolution**:
- Checks symlinks in `~/.local/share/nerdctl/*/default/` directory
- Falls back to reading the `hostname` file in the container directory
- Example containers: `caddy`, `auth-service-server`, `dial-in-server`, etc.

**Loki Labels**:
- `job=container`
- `host` - hostname from inventory
- `container_name` - resolved container name
- `container_id` - short (12 char) container ID
- `user` - the user running the container

#### 2. Audit Logs (laurel)

**Location**: `/var/log/laurel/audit.log`

**Loki Labels**:
- `job=audit`
- `host` - hostname from inventory
- `action` - extracted audit action

## Deployment

Run the setup playbook to deploy monitoring configuration:

```bash
cd /home/steven/.files/homelab
ansible-playbook -i inventory.yaml vms/set-up.yaml --limit monitoring
```

Or target specific hosts:

```bash
ansible-playbook -i inventory.yaml vms/set-up.yaml --limit staging-web
```

## Architecture

```
nerdctl containers → JSON logs → Fluent Bit → Loki
                                     ↓
                                 Lua script
                               (name resolution)
```

## Files

- `vms/tasks/monitoring.yaml` - Ansible tasks for installing and configuring Fluent Bit
- `vms/templates/system-logs.yaml.j2` - Fluent Bit pipeline configuration
- `vms/templates/process-container-logs.lua` - Lua script for container name resolution
- `vms/templates/parsers.yaml.j2` - Log parsers (Docker JSON format, audit logs)
- `vms/templates/fluent-bit.yaml.j2` - Main Fluent Bit configuration

## Multi-Environment Support

The configuration supports different logging endpoints per environment:

- **Local homelab** hosts (`10.0.0.x`): Use `logging_endpoint_ip: 10.0.0.2`
- **Cloud hosts** (`*.streetfortress.cloud`): Use `logging_endpoint_ip: logging.streetfortress.cloud`

This allows each environment to have its own centralized logging infrastructure.
