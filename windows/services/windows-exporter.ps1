#requires -RunAsAdministrator
<#
.SYNOPSIS
    Install prometheus-community/windows_exporter as an auto-start Windows service.
.DESCRIPTION
    Downloads the official MSI and installs it. The MSI registers a LocalSystem
    service ('windows_exporter') set to Automatic start, listening on :9182 and
    bound to all interfaces - the Windows equivalent of node_exporter.

    Host: win11 (10.0.0.99). Scraped by homelab Prometheus job 'windows_exporter'.
.NOTES
    Run from an elevated PowerShell. Re-running upgrades/repairs the install.
#>
param(
    [string]$Version    = '0.31.7',
    [int]   $Port       = 9182,
    [string]$Collectors = ''   # empty => MSI default collector set
)
$ErrorActionPreference = 'Stop'

$msi  = "windows_exporter-$Version-amd64.msi"
$url  = "https://github.com/prometheus-community/windows_exporter/releases/download/v$Version/$msi"
$dest = Join-Path $env:TEMP $msi

Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $dest

$msiArgs = "/i `"$dest`" /qn LISTEN_PORT=$Port"
if ($Collectors) { $msiArgs += " ENABLED_COLLECTORS=$Collectors" }

Write-Host "Installing windows_exporter $Version on :$Port"
$p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList $msiArgs
if ($p.ExitCode -ne 0) { throw "msiexec exited with code $($p.ExitCode)" }
Remove-Item $dest -Force

Start-Sleep -Seconds 2
Get-Service windows_exporter | Format-List Name, Status, StartType
