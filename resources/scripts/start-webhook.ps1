# Quick Start Script for Webhook Handler
# This script starts the webhook handler with proper configuration

param(
    [string]$Port = 8080,
    [string]$Secret = "",
    [string]$Branch = "main",
    [switch]$Background = $false
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$WebhookScript = Join-Path $ScriptPath "webhook-handler.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting GitHub Webhook Handler" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor Yellow
Write-Host "Branch: $Branch" -ForegroundColor Yellow
Write-Host "Secret: $(if ($Secret) { 'Configured' } else { 'Not set' })" -ForegroundColor Yellow
Write-Host ""

# Check if port is in use
$PortInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
if ($PortInUse) {
    Write-Host "WARNING: Port $Port is already in use!" -ForegroundColor Red
    Write-Host "Please stop the existing service or choose a different port." -ForegroundColor Yellow
    exit 1
}

# Build arguments
$Arguments = "-File `"$WebhookScript`" -Port $Port -Branch $Branch"
if ($Secret) {
    $Arguments += " -Secret `"$Secret`""
}

if ($Background) {
    Write-Host "Starting webhook handler in background..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList $Arguments -WindowStyle Minimized
    Write-Host "Webhook handler started in background!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To view it, check Task Manager or run:" -ForegroundColor Cyan
    Write-Host "  Get-Process | Where-Object {`$_.ProcessName -eq 'powershell'}" -ForegroundColor White
} else {
    Write-Host "Starting webhook handler..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    & powershell.exe -ArgumentList $Arguments
}


