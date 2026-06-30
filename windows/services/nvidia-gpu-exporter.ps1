#requires -RunAsAdministrator
<#
.SYNOPSIS
    Install utkuozdemir/nvidia_gpu_exporter and run it at boot.
.DESCRIPTION
    Downloads the Windows binary, extracts it to Program Files, and registers a
    scheduled task that runs it at system startup as NT AUTHORITY\SYSTEM (no login
    required). A scheduled task is used rather than sc.exe because the exporter is a
    plain console binary and does not implement the Windows service control protocol.
    It shells out to nvidia-smi (on the system PATH) and listens on :9835.

    Host: win11 (10.0.0.99). Scraped by homelab Prometheus job 'nvidia_gpu_exporter'.
.NOTES
    Run from an elevated PowerShell. Idempotent (-Force re-registers).
#>
param(
    [string]$Version    = '1.4.1',
    [int]   $Port       = 9835,
    [string]$InstallDir = 'C:\Program Files\nvidia_gpu_exporter',
    [string]$TaskName   = 'NVIDIA GPU Exporter'
)
$ErrorActionPreference = 'Stop'

$zip = "nvidia_gpu_exporter_${Version}_windows_x86_64.zip"
$url = "https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v$Version/$zip"
$tmp = Join-Path $env:TEMP $zip

Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $tmp
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Expand-Archive -Path $tmp -DestinationPath $InstallDir -Force
Remove-Item $tmp -Force

$exe = Join-Path $InstallDir 'nvidia_gpu_exporter.exe'
if (-not (Test-Path $exe)) { throw "exe not found after extract: $exe" }

$action    = New-ScheduledTaskAction -Execute $exe -Argument "--web.listen-address=:$Port"
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) `
                -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal `
    -Settings $settings -Description "Prometheus nvidia_gpu_exporter on :$Port (boot, no login)." -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host "Installed nvidia_gpu_exporter $Version -> task '$TaskName' on :$Port"
