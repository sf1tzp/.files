#requires -RunAsAdministrator
<#
.SYNOPSIS
    Register the LM Studio headless API server to start at boot (no login required).
.DESCRIPTION
    Creates a scheduled task that runs `lms server start` at system startup using an
    S4U principal, so it runs whether or not a user is logged on - without storing a
    password. Binds to 0.0.0.0 so the OpenAI-compatible API is reachable on the LAN.

    Host: win11 (10.0.0.99). Consumed by the homelab Prometheus/clients.
.NOTES
    Run from an elevated PowerShell.  Idempotent (-Force re-registers).
#>
param(
    [string]$LmsPath  = "$env:USERPROFILE\scoop\shims\lms.exe",
    [string]$RunAsUser = "$env:USERDOMAIN\$env:USERNAME",
    [int]   $Port     = 11434,
    [string]$Bind     = '0.0.0.0',
    [string]$TaskName = 'LM Studio API Server'
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $LmsPath)) { throw "lms not found at $LmsPath (install LM Studio / scoop)" }

$action    = New-ScheduledTaskAction -Execute $LmsPath -Argument "server start --bind $Bind --port $Port"
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType S4U -RunLevel Limited
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) `
                -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal `
    -Settings $settings -Description 'Starts LM Studio headless API server at VM boot (no login required).' -Force | Out-Null

Write-Host "Registered '$TaskName' -> $LmsPath server start --bind $Bind --port $Port (runs as $RunAsUser, S4U, at startup)"
