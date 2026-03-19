# The lofi Lab


These are the source and configuration files for the VMs and services I run at home.

You could be sleeping on using LLMs to help generate your IAC. A lot of the ansible was vibe-coded, and having this kind of virtualization at your fingertips is kind of incredible.

![Network Map](https://i.imgur.com/GnhIBC1.png)
![Grafana View](https://i.imgur.com/rAeIgVx.png)

## Structure

```
homelab/
  inventory.yaml                  # Ansible inventory -- all hosts, groups, hostvars
  justfile                        # Recipes: create, delete, set-up, deploy, update
  requirements.yaml               # Ansible Galaxy dependencies

  images/                         # Image building (user-agnostic base images)
    build.py                      # Orchestrator: VM lifecycle + ansible invocation
    build-playbook.yaml           # apt upgrade, install spec packages, cleanup, convert
    specs/                        # Declarative image profiles (vars files)
      base.yaml                   #   minimal apt packages
      containerd.yaml             #   base + container runtime prerequisites
      nvidia.yaml                 #   base + GPU driver prerequisites
      full.yaml                   #   everything

  roles/                          # Ansible roles (planned)
    dev_env/                      #   dotfiles, zsh, tmux, fzf, go, neovim, rust
    containerd/                   #   nerdctl, rootless setup, apparmor, sysctl
    nvidia/                       #   drivers, container toolkit, gpu exporter
    monitoring/                   #   node_exporter, fluent-bit, laurel

  vms/                            # VM lifecycle and deployment
    create-linux.yaml             #   cloud-init + libvirt domain creation
    create-windows.yaml           #   windows VM creation
    deploy.yaml                   #   post-boot provisioning (planned, replaces set-up.yaml)
    delete.yaml                   #   destroy + undefine + disk cleanup
    update.yaml                   #   apt upgrade + reboot if needed
    wireguard.yaml                #   WireGuard VPN configuration
    tasks/
      cloud-init.yaml             #   metadata, network-config, userdata → ISO
      users.yaml                  #   user creation, SSH keys, sudoers
      common.yaml                 #   dev tools + dotfiles (being split into roles)
      containerd.yaml             #   rootless containers (being split into roles)
      nvidia.yaml                 #   GPU drivers + toolkit
      monitoring.yaml             #   node_exporter, fluent-bit, laurel
      passwords.yaml              #   generate + vault-encrypt user passwords
    templates/
      userdata.yaml.j2            #   cloud-init user-data
      metadata.yaml.j2            #   cloud-init instance metadata
      network-config.yaml.j2      #   netplan static IP config
      linux-definition.xml.j2     #   libvirt domain XML
      fluent-bit/                 #   log pipeline configs

  sandboxes/                      # Ephemeral architecture scenarios (planned)
    architectures/                #   topology definitions (web-db, queue-worker, etc.)
    containers/                   #   nerdctl compose files per role
    tests/                        #   k6 load test scenarios

  services/                       # Containerized services (nerdctl compose)
    caddy/                        #   reverse proxy, DNS, TLS
    monitoring/                   #   prometheus, loki, grafana, alertmanager
    postgres/                     #   PostgreSQL + pgAdmin
    timescaledb/                  #   TimescaleDB + pgAdmin
    woodpecker/                   #   CI/CD pipeline
    ollama-chat/                  #   LLM inference
    penpot/                       #   design collaboration
    dolibarr/                     #   ERP
    homebridge/                   #   HomeKit bridge
    traggo/                       #   time tracking
    wordpress/                    #   CMS
```

## Workflow

**Build a base image:**
```
./homelab/images/build.py --name base-24.04 --spec base
```

**Create a VM from that image:**
```
just create-linux devbox
```

**Deploy configuration (post-boot):**
```
just set-up devbox
```

## Design

Images are user-agnostic system artifacts. Cloud-init handles identity
(user, hostname, network, SSH keys). Post-boot provisioning applies
environment configuration via Ansible roles.

The deployment path is being refactored from flat task files into Ansible
roles so the same building blocks serve both long-lived dev VMs and
ephemeral sandbox scenarios. See `images/PLAN.md` for details.
