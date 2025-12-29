# FiveM Server Restart Script with Auto-Pull
# This script pulls latest changes and restarts the FiveM server

param(
    [string]$Branch = "main",
    [switch]$SkipPull = $false
)

$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath
$ConfigFile = Join-Path $RepoRoot "server-config.json"

# Load server configuration
$ServerConfig = @{
    ServerPath = ""  # Path to FiveM server executable (e.g., "C:\FXServer\FXServer.exe")
    ServerName = "FiveM Server"
    RestartDelay = 10  # Seconds to wait before restart
}

if (Test-Path $ConfigFile) {
    try {
        $LoadedConfig = Get-Content $ConfigFile | ConvertFrom-Json
        $ServerConfig.ServerPath = $LoadedConfig.ServerPath
        $ServerConfig.ServerName = $LoadedConfig.ServerName
        $ServerConfig.RestartDelay = $LoadedConfig.RestartDelay
    } catch {
        Write-Warning "Failed to load config file. Using defaults."
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
}

function Stop-FiveMServer {
    Write-Log "Stopping FiveM server..."
    
    # Try to find and stop FiveM server process
    $Processes = Get-Process | Where-Object { 
        $_.ProcessName -like "*FXServer*" -or 
        $_.ProcessName -like "*FiveM*" -or
        $_.MainWindowTitle -like "*FiveM*"
    }
    
    if ($Processes) {
        foreach ($Process in $Processes) {
            Write-Log "Stopping process: $($Process.ProcessName) (PID: $($Process.Id))"
            Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    } else {
        Write-Log "No FiveM server process found running." "WARN"
    }
}

function Start-FiveMServer {
    param([string]$ServerPath)
    
    if (-not $ServerPath -or -not (Test-Path $ServerPath)) {
        Write-Log "Server path not configured or not found: $ServerPath" "ERROR"
        Write-Log "Please configure server path in: $ConfigFile" "ERROR"
        return $false
    }
    
    Write-Log "Starting FiveM server: $ServerPath"
    
    try {
        $ServerDir = Split-Path -Parent $ServerPath
        Push-Location $ServerDir
        Start-Process -FilePath $ServerPath -WorkingDirectory $ServerDir
        Pop-Location
        Write-Log "Server started successfully!" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to start server: $_" "ERROR"
        Pop-Location
        return $false
    }
}

# Main execution
try {
    Write-Log "=== Server Restart Script Started ==="
    
    # Pull latest changes if not skipped
    if (-not $SkipPull) {
        Write-Log "Pulling latest changes before restart..."
        $PullScript = Join-Path $ScriptPath "auto-pull.ps1"
        if (Test-Path $PullScript) {
            & $PullScript -Branch $Branch
        } else {
            Write-Log "Auto-pull script not found. Skipping pull..." "WARN"
        }
    }
    
    # Stop server
    Stop-FiveMServer
    
    # Wait before restart
    Write-Log "Waiting $($ServerConfig.RestartDelay) seconds before restart..."
    Start-Sleep -Seconds $ServerConfig.RestartDelay
    
    # Start server
    if ($ServerConfig.ServerPath) {
        Start-FiveMServer -ServerPath $ServerConfig.ServerPath
    } else {
        Write-Log "Server path not configured. Please edit: $ConfigFile" "ERROR"
    }
    
    Write-Log "=== Server Restart Script Completed ==="
    
} catch {
    Write-Log "Fatal error: $_" "ERROR"
    exit 1
}

