# Windows VM config — `win11` (10.0.0.99)

Boot-time service and firewall setup for the Windows inference/monitoring VM. All
services start **at boot without requiring a login** and bind to all interfaces so
they are reachable on the homelab LAN.

## Services

| Service | Port | Mechanism | Run as | Scraped by |
|---|---|---|---|---|
| LM Studio API (OpenAI-compatible) | 11434 | Scheduled task, `AtStartup` | `win11\sfitz` (S4U, no stored password) | clients |
| Prometheus `windows_exporter` (node metrics) | 9182 | Windows service (MSI) | LocalSystem | Prometheus job `windows_exporter` |
| Prometheus `nvidia_gpu_exporter` (RTX 3060) | 9835 | Scheduled task, `AtStartup` | `NT AUTHORITY\SYSTEM` | Prometheus job `nvidia_gpu_exporter` |

The matching scrape targets already exist in
`homelab/services/monitoring/config/prometheus.yaml` (instance `win11`).

## Why scheduled tasks for two of these?

LM Studio's `lms` CLI and `nvidia_gpu_exporter` are plain console programs that don't
implement the Windows service control protocol, so `sc.exe`/SCM can't manage them
directly. An `AtStartup` scheduled task gives the same "start at boot, no login"
behavior. `windows_exporter` ships a proper MSI, so it's a real service.

- LM Studio runs under an **S4U** principal: it needs the `sfitz` user profile
  (scoop install + model paths) but should run without anyone logged in, and S4U
  achieves that without storing a password.
- `nvidia_gpu_exporter` needs no user profile (it just calls `nvidia-smi` on the
  system PATH), so it runs as **SYSTEM**.

## Setup (run from an elevated PowerShell)

```powershell
# Services
.\services\lmstudio-server.ps1
.\services\windows-exporter.ps1
.\services\nvidia-gpu-exporter.ps1

# Firewall (opens 11434, 9182, 9835)
.\firewall\firewall-rules.ps1
```

Each script is parameterized (version, port, install dir, …) with sensible defaults
and is idempotent — re-running re-registers/repairs.

## Firewall / network profile note

This VM's NIC is classified **Public**, so the firewall rules are scoped to `Any`.
If you switch the connection to Private:

```powershell
Set-NetConnectionProfile -InterfaceAlias "Ethernet Instance 0" -NetworkCategory Private
.\firewall\firewall-rules.ps1 -FirewallProfile Private   # optional: tighten scope
```

> These are open, unauthenticated endpoints. Keep them on the trusted homelab LAN;
> do not expose them to the public internet without auth / a reverse proxy.

## Verify

```powershell
Invoke-RestMethod http://localhost:9182/metrics | Select-Object -First 5
Invoke-RestMethod http://localhost:9835/metrics | Select-Object -First 5
(Invoke-WebRequest http://localhost:11434/v1/models).StatusCode
```

## Manage

```powershell
Get-ScheduledTask 'LM Studio API Server','NVIDIA GPU Exporter'
Get-Service windows_exporter
# Remove:
Unregister-ScheduledTask -TaskName 'NVIDIA GPU Exporter' -Confirm:$false
```
