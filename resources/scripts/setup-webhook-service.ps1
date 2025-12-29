# Setup Webhook Handler as Windows Service
# This allows the webhook handler to run in the background automatically

param(
    [string]$Port = 8080,
    [string]$Secret = "",
    [string]$Branch = "main"
)

# Check if running as administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Error "This script must be run as Administrator!"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$WebhookScript = Join-Path $ScriptPath "webhook-handler.ps1"
$WorkingDirectory = Split-Path -Parent $ScriptPath

# Check if NSSM is available (Non-Sucking Service Manager)
$NSSMPath = "C:\nssm\nssm.exe"
if (-not (Test-Path $NSSMPath)) {
    Write-Host "NSSM (Non-Sucking Service Manager) is required to run as a service." -ForegroundColor Yellow
    Write-Host "Download from: https://nssm.cc/download" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Alternatively, you can use Task Scheduler to keep it running:" -ForegroundColor Yellow
    Write-Host "1. Open Task Scheduler" -ForegroundColor White
    Write-Host "2. Create Basic Task" -ForegroundColor White
    Write-Host "3. Set trigger: 'When the computer starts'" -ForegroundColor White
    Write-Host "4. Action: Start program" -ForegroundColor White
    Write-Host "5. Program: powershell.exe" -ForegroundColor White
    Write-Host "6. Arguments: -File `"$WebhookScript`" -Port $Port -Secret `"$Secret`" -Branch $Branch" -ForegroundColor White
    exit 1
}

$ServiceName = "FiveM-WebhookHandler"

# Build arguments
$Arguments = "-File `"$WebhookScript`" -Port $Port"
if ($Secret) {
    $Arguments += " -Secret `"$Secret`""
}
$Arguments += " -Branch $Branch"

Write-Host "Setting up webhook handler as Windows Service..." -ForegroundColor Cyan
Write-Host "Service Name: $ServiceName" -ForegroundColor Yellow
Write-Host "Port: $Port" -ForegroundColor Yellow
Write-Host "Branch: $Branch" -ForegroundColor Yellow
Write-Host ""

# Remove existing service if it exists
$ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($ExistingService) {
    Write-Host "Removing existing service..." -ForegroundColor Yellow
    & $NSSMPath stop $ServiceName
    & $NSSMPath remove $ServiceName confirm
}

# Install service
Write-Host "Installing service..." -ForegroundColor Yellow
& $NSSMPath install $ServiceName "powershell.exe" "-ExecutionPolicy Bypass $Arguments"
& $NSSMPath set $ServiceName AppDirectory $WorkingDirectory
& $NSSMPath set $ServiceName Description "GitHub Webhook Handler for FiveM Server Auto-Deployment"
& $NSSMPath set $ServiceName Start SERVICE_AUTO_START
& $NSSMPath set $ServiceName AppStdout "$WorkingDirectory\logs\webhook-service.log"
& $NSSMPath set $ServiceName AppStderr "$WorkingDirectory\logs\webhook-service-error.log"

Write-Host "Starting service..." -ForegroundColor Yellow
& $NSSMPath start $ServiceName

Write-Host ""
Write-Host "Service installed and started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To manage the service:" -ForegroundColor Cyan
Write-Host "  Start:   net start $ServiceName" -ForegroundColor White
Write-Host "  Stop:    net stop $ServiceName" -ForegroundColor White
Write-Host "  Status:  Get-Service $ServiceName" -ForegroundColor White
Write-Host "  Remove:  & `"$NSSMPath`" remove $ServiceName confirm" -ForegroundColor White

