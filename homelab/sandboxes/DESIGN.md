# Sandbox Orchestrator

A CLI tool that creates ephemeral multi-VM environments from declarative
topology definitions, provisions them with containers, validates with tests,
and tears everything down.

## Scope

Scenario VMs only. Long-lived VMs (devbox, staging) are managed separately.

## Domain

The hypervisor is a single bare-metal machine running KVM/libvirt. VMs boot
from pre-built qcow2 base images (built by the existing `images/build.py`
pipeline). Cloud-init handles first-boot identity (user, network, SSH keys).
Containers run rootless via nerdctl.

## Core Operations

```
sandbox up   <topology>       # create VMs, provision, deploy containers
sandbox test <topology>       # run test suite against running topology
sandbox down <topology>       # destroy VMs, reclaim disks
sandbox list                  # show running sandboxes
sandbox ssh  <topology> <node># shell into a specific node
```

## Data Model

### Topology

Defines a set of nodes, their resources, and what containers they run.

```yaml
# topologies/web-db.yaml
name: web-db
description: Nginx reverse proxy + Postgres

defaults:
  image: base-24.04
  disk: 25G
  user: deployer

nodes:
  web:
    ip: 10.0.0.40
    vcpus: 2
    memory: 4
    containers:
      - nginx
    expose:
      - "80:80"

  db:
    ip: 10.0.0.41
    vcpus: 2
    memory: 4
    containers:
      - postgres
    expose:
      - "5432:5432"

test: web-db
```

```yaml
# topologies/poller-queue-worker-db.yaml
name: poller-queue-worker-db
description: >
  Async processing: poller feeds work into RabbitMQ, workers consume
  and persist results to Postgres.

defaults:
  image: base-24.04
  disk: 25G
  user: deployer

nodes:
  poller:
    ip: 10.0.0.46
    vcpus: 1
    memory: 2
    containers:
      - nginx
    expose:
      - "80:80"

  queue:
    ip: 10.0.0.47
    vcpus: 2
    memory: 4
    containers:
      - rabbitmq
    expose:
      - "5672:5672"
      - "15672:15672"

  worker:
    ip: 10.0.0.48
    vcpus: 2
    memory: 4

  db:
    ip: 10.0.0.49
    vcpus: 2
    memory: 4
    containers:
      - postgres
    expose:
      - "5432:5432"

test: poller-queue-worker-db
```

### Container Definitions

Nerdctl compose files, one per service. The orchestrator copies the compose
file to the node and runs `nerdctl compose up -d`.

```
containers/
  postgres/compose.yaml
  redis/compose.yaml
  rabbitmq/compose.yaml
  nginx/compose.yaml
```

### Test Suites

k6 test scenarios, one per topology. The orchestrator injects node IPs as
environment variables.

```
tests/
  scenarios/
    web-db.ts
    poller-queue-worker-db.ts
```

## Lifecycle: `sandbox up`

1. **Parse topology** -- read YAML, merge defaults into each node
2. **Create disks** -- for each node, `qemu-img create` backed by base image
3. **Generate cloud-init** -- render userdata (user, SSH keys), network-config
   (static IP), metadata (hostname). Build ISO with `cloud-localds`.
4. **Define VMs** -- render libvirt domain XML, `virsh define`, `virsh start`
5. **Wait for SSH** -- poll each node until SSH responds
6. **Provision containers** -- for each node with containers defined:
   - Ensure rootless container prerequisites (uidmap, subuid/subgid, apparmor,
     sysctl, nerdctl). This can be baked into the base image or applied here.
   - Copy compose file to node
   - `nerdctl compose up -d`
   - Wait for health checks to pass
7. **Report** -- print node IPs, exposed ports, SSH commands

## Lifecycle: `sandbox test`

1. Resolve node IPs from running sandbox state
2. Run k6 with topology-specific scenario, passing IPs as env vars
3. Report results

## Lifecycle: `sandbox down`

1. For each node: `virsh destroy`, `virsh undefine`
2. Remove disk images and cloud-init ISOs
3. Clean up any sandbox state

## State

Running sandbox state needs to be tracked so `test` and `down` know what
exists. Options:

- **Derive from libvirt** -- naming convention `sandbox-{topology}-{node}`
  lets you query `virsh list` and reconstruct state. No state file needed.
- **State file** -- `~/.sandbox/{topology}.json` with node names, IPs,
  status. More explicit but needs cleanup.

Deriving from libvirt is simpler and avoids stale state.

## VM Naming and Networking

- VM names: `sandbox-{topology}-{node}` (e.g., `sandbox-web-db-web`)
- IP range: `10.0.0.40-59` (reserved for sandboxes)
- Each topology's nodes get sequential IPs from the topology definition

## Templates

The tool needs to generate:

- **Cloud-init userdata** -- user, groups, sudo, SSH key import, password
- **Cloud-init network-config** -- static IP, gateway, DNS
- **Cloud-init metadata** -- instance-id, hostname
- **Libvirt domain XML** -- CPU, memory, disk path, cloud-init ISO, network

These are small enough to be string templates embedded in the tool, or
external template files in a `templates/` directory.

## Container Provisioning

The base image may or may not have nerdctl/containerd ready. Two options:

- **Fat image**: `images/specs/containerd.yaml` bakes in all container
  prerequisites. Sandbox nodes just copy compose files and `nerdctl compose up`.
- **Provision at boot**: The orchestrator installs nerdctl + prerequisites
  over SSH before deploying containers.

Fat image is faster for scenarios (less per-VM setup time). Provision at boot
is more flexible but slower. Start with fat image -- build a `sandbox-base`
image spec with containerd baked in.

## Directory Structure

```
homelab/sandboxes/
  DESIGN.md                       # this file
  topologies/
    web-db.yaml
    web-cache-db.yaml
    poller-queue-worker-db.yaml
  containers/
    postgres/compose.yaml
    redis/compose.yaml
    rabbitmq/compose.yaml
    nginx/compose.yaml
  templates/                      # cloud-init + libvirt templates
    userdata.yaml
    network-config.yaml
    metadata.yaml
    domain.xml
  tests/
    package.json
    scenarios/
      web-db.ts
      web-cache-db.ts
      poller-queue-worker-db.ts
```

The CLI tool itself lives outside this directory (its own repo or a
subdirectory with its own build).

## Open Questions

- **Container readiness**: How to detect that a containerized service is
  healthy? Poll a TCP port? nerdctl inspect health status? Topology-defined
  health check commands?
- **Inter-node discovery**: Containers on one node need to reach services on
  another (e.g., web → db). Inject peer IPs via environment variables in the
  compose file? Template the compose files with node IPs?
- **Secrets**: Postgres passwords, RabbitMQ credentials. Generate per-sandbox
  and inject via compose env vars? Or use static defaults for throwaway
  scenarios?
- **Log collection**: Should sandbox nodes ship logs to the monitoring stack,
  or are scenarios too ephemeral for that?
- **Parallel provisioning**: Nodes are independent -- create and provision
  them concurrently for faster `up`.
