# Quick Manual Pull Script
# Use this to manually pull changes from GitHub right now

$ErrorActionPreference = "Continue"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Manual Pull from GitHub" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Try to find Git
$GitFound = $false
$GitPaths = @(
    "git",
    "C:\Program Files\Git\bin\git.exe",
    "C:\Program Files (x86)\Git\bin\git.exe",
    "$env:LOCALAPPDATA\GitHubDesktop\bin\git.exe"
)

foreach ($GitPath in $GitPaths) {
    try {
        if ($GitPath -eq "git") {
            $null = Get-Command git -ErrorAction Stop
            $GitFound = $true
            break
        } elseif (Test-Path $GitPath) {
            $env:PATH += ";$(Split-Path -Parent $GitPath)"
            $GitFound = $true
            break
        }
    } catch {
        continue
    }
}

if (-not $GitFound) {
    Write-Host "ERROR: Git not found!" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Or add Git to your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host "Git found!" -ForegroundColor Green
Write-Host ""

# Find Git repository
$CurrentPath = $RepoRoot
$GitRepoPath = $null

for ($i = 0; $i -lt 5; $i++) {
    if (Test-Path (Join-Path $CurrentPath ".git")) {
        $GitRepoPath = $CurrentPath
        break
    }
    $CurrentPath = Split-Path -Parent $CurrentPath
    if (-not $CurrentPath -or $CurrentPath -eq (Split-Path -Parent $CurrentPath)) {
        break
    }
}

if (-not $GitRepoPath) {
    Write-Host "ERROR: Git repository not found!" -ForegroundColor Red
    Write-Host "Please initialize Git repository first:" -ForegroundColor Yellow
    Write-Host "  git init" -ForegroundColor Cyan
    Write-Host "  git remote add origin <your-github-url>" -ForegroundColor Cyan
    exit 1
}

Write-Host "Repository found at: $GitRepoPath" -ForegroundColor Green
Write-Host ""

# Change to repository
Push-Location $GitRepoPath

try {
    # Check remote
    Write-Host "Checking remote..." -ForegroundColor Yellow
    $Remote = git remote get-url origin 2>&1
    if ($Remote -and $Remote -notmatch "fatal:") {
        Write-Host "Remote: $Remote" -ForegroundColor Green
    } else {
        Write-Host "WARNING: No remote configured!" -ForegroundColor Yellow
        Write-Host "Add remote with: git remote add origin <url>" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "Fetching latest changes..." -ForegroundColor Yellow
    git fetch origin 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Fetch failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host ""
    Write-Host "Checking for updates..." -ForegroundColor Yellow
    
    # Try to get branch name
    $Branch = "main"
    try {
        $CurrentBranch = git branch --show-current 2>&1
        if ($CurrentBranch -and $CurrentBranch -notmatch "fatal:") {
            $Branch = $CurrentBranch.Trim()
        }
    } catch {}
    
    try {
        $LocalCommit = git rev-parse HEAD 2>&1
        $RemoteCommit = git rev-parse "origin/$Branch" 2>&1
        
        if ($LocalCommit -eq $RemoteCommit) {
            Write-Host "Repository is already up to date!" -ForegroundColor Green
            Write-Host "Local:  $($LocalCommit.Substring(0, 7))" -ForegroundColor Gray
        } else {
            Write-Host "Updates available!" -ForegroundColor Yellow
            Write-Host "Local:  $($LocalCommit.Substring(0, 7))" -ForegroundColor Gray
            Write-Host "Remote: $($RemoteCommit.Substring(0, 7))" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Pulling changes..." -ForegroundColor Yellow
            git pull origin $Branch 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "SUCCESS! Changes pulled successfully!" -ForegroundColor Green
                
                # Show what changed
                Write-Host ""
                Write-Host "Recent changes:" -ForegroundColor Cyan
                git log HEAD@{1}..HEAD --oneline 2>&1 | ForEach-Object { 
                    if ($_ -and $_ -notmatch "fatal:") {
                        Write-Host "  $_" -ForegroundColor Gray
                    }
                }
            } else {
                Write-Host "ERROR: Pull failed!" -ForegroundColor Red
                Pop-Location
                exit 1
            }
        }
    } catch {
        Write-Host "WARNING: Could not compare commits. Attempting pull anyway..." -ForegroundColor Yellow
        git pull origin $Branch 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

