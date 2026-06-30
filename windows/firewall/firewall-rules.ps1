#requires -RunAsAdministrator
<#
.SYNOPSIS
    Inbound Windows Firewall rules for the services this VM exposes to the homelab LAN.
.DESCRIPTION
    Opens the TCP ports used by the LM Studio API and the Prometheus exporters.
    Scoped to 'Any' profile by default because this VM's NIC is classified Public;
    a Private-only rule would not apply. Pass -FirewallProfile Private if you have
    set the connection to Private (Set-NetConnectionProfile ... -NetworkCategory Private).
.NOTES
    Run from an elevated PowerShell. Idempotent (recreates the named rules).
#>
param(
    [ValidateSet('Any', 'Private', 'Domain', 'Public')]
    [string]$FirewallProfile = 'Any'
)
$ErrorActionPreference = 'Stop'

$rules = @(
    @{ Name = 'LM Studio API Server';           Port = 11434 },
    @{ Name = 'Prometheus windows_exporter';    Port = 9182  },
    @{ Name = 'Prometheus nvidia_gpu_exporter'; Port = 9835  }
)

foreach ($r in $rules) {
    Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Protocol TCP `
        -LocalPort $r.Port -Action Allow -Profile $FirewallProfile | Out-Null
    Write-Host "Allowed inbound TCP $($r.Port) [$FirewallProfile] - $($r.Name)"
}
