# FiveM Server Auto-Pull Script
# This script automatically pulls updates from GitHub

param(
    [string]$Branch = "main",
    [switch]$RestartServer = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath
$LogFile = Join-Path $RepoRoot "logs\auto-pull.log"

# Create logs directory if it doesn't exist
$LogDir = Split-Path -Parent $LogFile
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

function Test-GitInstalled {
    try {
        $null = git --version
        return $true
    } catch {
        return $false
    }
}

function Invoke-GitPull {
    Write-Log "Starting auto-pull from branch: $Branch"
    
    # Change to repository root
    Push-Location $RepoRoot
    
    try {
        # Check if we're in a git repository
        if (-not (Test-Path ".git")) {
            Write-Log "Not a git repository. Checking parent directory..." "WARN"
            Pop-Location
            Push-Location (Split-Path -Parent $RepoRoot)
            if (-not (Test-Path ".git")) {
                throw "Git repository not found"
            }
        }
        
        # Fetch latest changes
        Write-Log "Fetching latest changes from remote..."
        git fetch origin $Branch 2>&1 | ForEach-Object { Write-Log $_ "GIT" }
        
        # Check if there are updates
        $LocalCommit = git rev-parse HEAD
        $RemoteCommit = git rev-parse "origin/$Branch"
        
        if ($LocalCommit -eq $RemoteCommit -and -not $Force) {
            Write-Log "Repository is up to date. No changes to pull."
            Pop-Location
            return $false
        }
        
        # Stash local changes if any (optional - you may want to handle this differently)
        $Status = git status --porcelain
        if ($Status -and -not $Force) {
            Write-Log "Local changes detected. Stashing..." "WARN"
            git stash push -m "Auto-stash before pull $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>&1 | ForEach-Object { Write-Log $_ "GIT" }
        }
        
        # Pull changes
        Write-Log "Pulling changes from origin/$Branch..."
        git pull origin $Branch 2>&1 | ForEach-Object { Write-Log $_ "GIT" }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully pulled latest changes!" "SUCCESS"
            
            # Get latest commit info for logging
            $LatestCommit = git log -1 --pretty=format:"%h - %an: %s" 2>&1
            Write-Log "Latest commit: $LatestCommit" "INFO"
            
            # Update deployment log
            $DeployLog = Join-Path $RepoRoot "logs\deployments.log"
            if (Test-Path $DeployLog) {
                $LastLine = Get-Content $DeployLog -Tail 1
                if ($LastLine) {
                    try {
                        $DeployEntry = $LastLine | ConvertFrom-Json
                        $DeployEntry.Status = "Deployed"
                        $DeployEntry.DeployedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $DeployEntry.LatestCommit = $LatestCommit
                        Add-Content -Path $DeployLog -Value ($DeployEntry | ConvertTo-Json -Depth 10)
                    } catch {}
                }
            }
            
            Pop-Location
            return $true
        } else {
            throw "Git pull failed with exit code $LASTEXITCODE"
        }
        
    } catch {
        Write-Log "Error during git pull: $_" "ERROR"
        Pop-Location
        throw
    } finally {
        Pop-Location
    }
}

# Main execution
try {
    Write-Log "=== Auto-Pull Script Started ==="
    
    # Check if Git is installed
    if (-not (Test-GitInstalled)) {
        throw "Git is not installed or not in PATH"
    }
    
    # Perform pull
    $HasUpdates = Invoke-GitPull
    
    if ($HasUpdates -or $Force) {
        Write-Log "Updates detected or force flag set."
        
        # List changed files
        try {
            $ChangedFiles = git diff --name-only HEAD@{1} HEAD 2>&1
            if ($ChangedFiles) {
                Write-Log "Changed files:" "INFO"
                $ChangedFiles | ForEach-Object {
                    if ($_ -and $_ -notmatch "^fatal:") {
                        Write-Log "  - $_" "INFO"
                    }
                }
            }
        } catch {
            # Ignore errors in file listing
        }
        
        if ($RestartServer) {
            Write-Log "Restart server flag is set. Restarting server..."
            # Call restart script if it exists
            $RestartScript = Join-Path $ScriptPath "restart-server.ps1"
            if (Test-Path $RestartScript) {
                & $RestartScript -SkipPull
            } else {
                Write-Log "Restart script not found at: $RestartScript" "WARN"
            }
        } else {
            Write-Log "Server restart not required. Changes deployed successfully!" "SUCCESS"
            Write-Log "Note: Restart server manually if needed, or enable AutoPull.RestartOnUpdate in server-config.json" "INFO"
        }
    }
    
    Write-Log "=== Auto-Pull Script Completed ==="
    
} catch {
    Write-Log "Fatal error: $_" "ERROR"
    exit 1
}

