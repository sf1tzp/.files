Yes -- I've read through everything I need. I have a clear picture of the existing infrastructure now. Let me lay out the plan before I start writing code.

## Design

**Core idea:** A `homelab/sandboxes/` directory that defines architecture patterns as YAML topologies. A single Ansible playbook reads a topology, creates the VMs (reusing your existing cloud-init/libvirt patterns), deploys containers via nerdctl compose over SSH, and k6 tests validate the deployment. Teardown is one command.

**Key design decisions:**
- **Sandbox VMs use the `10.0.0.40-59` range** -- clear of your existing allocations
- **VM naming convention:** `sandbox-{arch}-{role}` (e.g., `sandbox-web-db-web`, `sandbox-web-db-db`)
- **Base image:** `sf1tzp-24.04` -- your custom image already has tooling, and VMs get containerd during provisioning
- **Self-contained inventory** -- sandbox playbooks generate their own inventory from the architecture file, no pollution of your main `inventory.yaml`
- **Container compositions per role** -- postgres, redis, rabbitmq, nginx each get a nerdctl compose file
- **k6 scenarios per architecture** -- parameterized with sandbox VM IPs via env vars

**Architecture patterns to define:**
1. `web-db` -- Nginx reverse proxy + Postgres
2. `web-cache-db` -- Nginx + Redis + Postgres
3. `poller-queue-worker-db` -- Poller service + RabbitMQ + Worker + Postgres

**File structure:**
```
homelab/sandboxes/
├── justfile                              # deploy, provision, test, teardown
├── deploy.yaml                           # Create VMs from architecture def
├── provision.yaml                        # SSH in, deploy containers per role
├── teardown.yaml                         # Destroy sandbox VMs + cleanup
├── architectures/
│   ├── web-db.yaml
│   ├── web-cache-db.yaml
│   └── poller-queue-worker-db.yaml
├── containers/
│   ├── postgres/compose.yaml
│   ├── redis/compose.yaml
│   ├── rabbitmq/compose.yaml
│   └── nginx/compose.yaml
└── tests/
    ├── package.json
    ├── helpers.ts                        # Shared k6 utilities
    └── scenarios/
        ├── web-db.ts
        ├── web-cache-db.ts
        └── poller-queue-worker-db.ts
```

