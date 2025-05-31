# Homelab Setup

A comprehensive homelab environment using KVM/QEMU virtualization, Ansible automation, and containerized services with WireGuard networking.

## Features

- **VM Management**: Create, delete, and manage both Linux and Windows VMs
- **GPU Passthrough**: Support for GPU passthrough to VMs
- **NVMe Passthrough**: Support for NVMe storage passthrough to VMs
- **USB Peripheral Passthrough**: Pass through USB devices (keyboard, mouse, controllers)
- **Networking**: Internal network using bridge networking and external access via WireGuard VPN
- **Services**: Containerized services including homebridge, lab-proxy, and ollama-chat

## Prerequisites

- Linux host with KVM/QEMU support
- Ansible
- Nerdctl/Docker
- Just command runner
- WireGuard

## Quick Start

### VM Management

```bash
# Create base VM images
just base-images

# Create Linux VMs (defined in vms/create-linux.yaml)
just create-linux

# Create Windows VMs (defined in vms/create-windows.yaml)
just create-windows

# Start a VM
just start <vm-name>

# Stop a VM
just stop <vm-name>

# Pause/resume a VM
just pause <vm-name>
just resume <vm-name>

# Delete VMs
just delete <vm-name1> <vm-name2>

# Access VM password
just decrypt-vm-password

# Set up newly created VMs
just set-up <hostname>

# Configure WireGuard on VMs
just wireguard [hosts]

# Create X11 tunnel to VM
just x11-tunnel <vm-name>
```

### Service Management

#### Homebridge

```bash
cd services/homebridge
just start
just stop
```

#### Lab Proxy

```bash
cd services/lab-proxy
just up
just down
just logs
```

#### Ollama Chat

```bash
cd services/ollama-chat
just up
just down
just logs
```

## VM Specifications

### Linux VMs
Defined in `vms/create-linux.yaml` with defaults:

- **devbox**: General development VM (8 vCPUs, 24GB RAM, 150GB disk)
- **llm-server**: ML/AI server with GPU passthrough (4 vCPUs, 8GB RAM, 150GB disk)
- **lab-proxy**: Network gateway (2 vCPUs, 2GB RAM, 50GB disk)

### Windows VMs
Defined in `vms/create-windows.yaml` with defaults:

- **win11**: Windows 11 VM (10 vCPUs, 24GB RAM, 150GB disk) with GPU and USB peripherals passthrough

## Network Layout

- Internal network: 10.0.0.0/24
- WireGuard VPN: 10.1.0.0/24
- Primary gateway: lab-proxy (10.0.0.5/10.1.0.5)

## Advanced Configuration

Modify VM templates in `vms/templates/` to customize VM configurations:

- `linux-definition.xml.j2`: Linux VM template
- `windows-definition.xml.j2`: Windows VM template
- `wg0.conf.j2`: WireGuard configuration template

## Troubleshooting

For VM-specific issues, check libvirt logs and the VM console.
For service issues, use `just logs` in the service directory.