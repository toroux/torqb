# Scheduled Auto-Pull Script
# Run this via Windows Task Scheduler for periodic automatic pulls

param(
    [string]$Branch = "main",
    [int]$IntervalMinutes = 15  # Check every 15 minutes by default
)

$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$PullScript = Join-Path $ScriptPath "auto-pull.ps1"

Write-Host "Scheduled Auto-Pull Script"
Write-Host "Branch: $Branch"
Write-Host "Interval: $IntervalMinutes minutes"
Write-Host ""

# Run auto-pull script
if (Test-Path $PullScript) {
    & $PullScript -Branch $Branch
} else {
    Write-Error "Auto-pull script not found at: $PullScript"
    exit 1
}


