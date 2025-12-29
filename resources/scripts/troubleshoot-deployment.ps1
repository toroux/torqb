# Troubleshooting Script for Auto-Deployment
# This script diagnoses and fixes common deployment issues

$ErrorActionPreference = "Continue"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Troubleshooting" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Git Installation
Write-Host "1. Checking Git installation..." -ForegroundColor Yellow
try {
    $GitPath = Get-Command git -ErrorAction Stop
    Write-Host "   ✓ Git found at: $($GitPath.Source)" -ForegroundColor Green
    $GitVersion = git --version
    Write-Host "   ✓ $GitVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check 2: Git Repository
Write-Host "`n2. Checking Git repository..." -ForegroundColor Yellow
$GitRepoFound = $false
$CurrentPath = $RepoRoot

# Check current directory and parents
for ($i = 0; $i -lt 5; $i++) {
    if (Test-Path (Join-Path $CurrentPath ".git")) {
        Write-Host "   ✓ Git repository found at: $CurrentPath" -ForegroundColor Green
        $GitRepoFound = $true
        $RepoRoot = $CurrentPath
        break
    }
    $CurrentPath = Split-Path -Parent $CurrentPath
    if (-not $CurrentPath -or $CurrentPath -eq (Split-Path -Parent $CurrentPath)) {
        break
    }
}

if (-not $GitRepoFound) {
    Write-Host "   ✗ Git repository not found" -ForegroundColor Red
    Write-Host "   Would you like to initialize a Git repository? (Y/N)" -ForegroundColor Yellow
    $Response = Read-Host
    if ($Response -eq "Y" -or $Response -eq "y") {
        Push-Location $RepoRoot
        git init
        Write-Host "   ✓ Git repository initialized" -ForegroundColor Green
        Pop-Location
    } else {
        Write-Host "   Please initialize Git repository first" -ForegroundColor Yellow
        exit 1
    }
}

# Check 3: Git Remote
Write-Host "`n3. Checking Git remote..." -ForegroundColor Yellow
Push-Location $RepoRoot
try {
    $Remote = git remote get-url origin 2>&1
    if ($Remote -and $Remote -notmatch "fatal:") {
        Write-Host "   ✓ Remote configured: $Remote" -ForegroundColor Green
    } else {
        Write-Host "   ✗ No remote configured" -ForegroundColor Red
        Write-Host "   Please add a remote:" -ForegroundColor Yellow
        Write-Host "   git remote add origin https://github.com/username/repo.git" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ✗ Error checking remote" -ForegroundColor Red
}
Pop-Location

# Check 4: Webhook Handler
Write-Host "`n4. Checking webhook handler..." -ForegroundColor Yellow
$Port = 8080
$PortInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
if ($PortInUse) {
    Write-Host "   ✓ Webhook handler is running on port $Port" -ForegroundColor Green
} else {
    Write-Host "   ✗ Webhook handler is NOT running" -ForegroundColor Red
    Write-Host "   Start it with: .\start-webhook.ps1" -ForegroundColor Yellow
}

# Check 5: Logs Directory
Write-Host "`n5. Checking logs directory..." -ForegroundColor Yellow
$LogsDir = Join-Path $RepoRoot "logs"
if (Test-Path $LogsDir) {
    Write-Host "   ✓ Logs directory exists" -ForegroundColor Green
    $LogFiles = Get-ChildItem $LogsDir -Filter "*.log" | Select-Object Name, Length, LastWriteTime
    if ($LogFiles) {
        Write-Host "   Log files found:" -ForegroundColor Gray
        foreach ($Log in $LogFiles) {
            Write-Host "     - $($Log.Name) ($([math]::Round($Log.Length/1KB, 2)) KB, Modified: $($Log.LastWriteTime))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "   ✗ Logs directory not found (will be created on first run)" -ForegroundColor Yellow
}

# Check 6: Manual Pull Test
Write-Host "`n6. Testing manual pull..." -ForegroundColor Yellow
Write-Host "   Attempting to pull latest changes..." -ForegroundColor Gray
Push-Location $RepoRoot
try {
    $FetchOutput = git fetch origin 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Fetch successful" -ForegroundColor Green
        
        # Check if there are updates
        try {
            $LocalCommit = git rev-parse HEAD 2>&1
            $RemoteCommit = git rev-parse "origin/main" 2>&1
            
            if ($LocalCommit -eq $RemoteCommit) {
                Write-Host "   ✓ Repository is up to date" -ForegroundColor Green
            } else {
                Write-Host "   ⚠ Updates available on remote" -ForegroundColor Yellow
                Write-Host "   Local:  $($LocalCommit.Substring(0, 7))" -ForegroundColor Gray
                Write-Host "   Remote: $($RemoteCommit.Substring(0, 7))" -ForegroundColor Gray
                Write-Host ""
                Write-Host "   Would you like to pull now? (Y/N)" -ForegroundColor Yellow
                $Response = Read-Host
                if ($Response -eq "Y" -or $Response -eq "y") {
                    git pull origin main
                    Write-Host "   ✓ Pull completed!" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "   ⚠ Could not compare commits (branch might not exist)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ✗ Fetch failed: $FetchOutput" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Error during fetch: $_" -ForegroundColor Red
}
Pop-Location

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To fix deployment issues:" -ForegroundColor Yellow
Write-Host "1. Ensure Git is installed and in PATH" -ForegroundColor White
Write-Host "2. Initialize Git repository if needed" -ForegroundColor White
Write-Host "3. Add GitHub remote: git remote add origin <url>" -ForegroundColor White
Write-Host "4. Start webhook handler: .\start-webhook.ps1" -ForegroundColor White
Write-Host "5. Configure GitHub webhook in repository settings" -ForegroundColor White
Write-Host ""
Write-Host "For manual pull, run: .\auto-pull.ps1" -ForegroundColor Cyan

