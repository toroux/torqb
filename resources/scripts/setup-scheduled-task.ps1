# Setup Windows Scheduled Task for Auto-Pull
# Run this script as Administrator to set up automatic pulls

param(
    [string]$TaskName = "FiveM-AutoPull",
    [int]$IntervalMinutes = 15,
    [string]$Branch = "main"
)

# Check if running as administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Error "This script must be run as Administrator!"
    exit 1
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$PullScript = Join-Path $ScriptPath "scheduled-pull.ps1"
$WorkingDirectory = Split-Path -Parent $ScriptPath

# Create scheduled task action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$PullScript`" -Branch $Branch -IntervalMinutes $IntervalMinutes" `
    -WorkingDirectory $WorkingDirectory

# Create trigger (runs every X minutes)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)

# Create task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create principal (run as current user)
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

# Register the task
try {
    # Remove existing task if it exists
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($ExistingTask) {
        Write-Host "Removing existing task: $TaskName"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    Write-Host "Creating scheduled task: $TaskName"
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Automatically pull updates from GitHub for FiveM server"
    
    Write-Host "Scheduled task created successfully!" -ForegroundColor Green
    Write-Host "Task will run every $IntervalMinutes minutes"
    Write-Host ""
    Write-Host "To view the task, run: Get-ScheduledTask -TaskName $TaskName"
    Write-Host "To remove the task, run: Unregister-ScheduledTask -TaskName $TaskName -Confirm:`$false"
    
} catch {
    Write-Error "Failed to create scheduled task: $_"
    exit 1
}

