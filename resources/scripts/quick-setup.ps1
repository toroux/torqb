# Quick Setup Script for GitHub Integration
# This script helps you set up GitHub integration quickly

param(
    [string]$GitHubRepo = "",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath

Write-Host "=== FiveM Server GitHub Integration Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
Write-Host "Checking Git installation..." -ForegroundColor Yellow
try {
    $GitVersion = git --version
    Write-Host "✓ Git found: $GitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Check if we're in a git repository
Write-Host "`nChecking Git repository..." -ForegroundColor Yellow
Push-Location $RepoRoot
$IsGitRepo = Test-Path ".git"
if (-not $IsGitRepo) {
    # Check parent directory
    Pop-Location
    Push-Location (Split-Path -Parent $RepoRoot)
    $IsGitRepo = Test-Path ".git"
    if ($IsGitRepo) {
        $RepoRoot = (Split-Path -Parent $RepoRoot)
        Write-Host "✓ Git repository found in parent directory" -ForegroundColor Green
    }
}

if (-not $IsGitRepo) {
    Write-Host "✗ Not a Git repository" -ForegroundColor Red
    Write-Host "`nWould you like to initialize a new Git repository? (Y/N)" -ForegroundColor Yellow
    $Response = Read-Host
    if ($Response -eq "Y" -or $Response -eq "y") {
        git init
        Write-Host "✓ Git repository initialized" -ForegroundColor Green
    } else {
        Pop-Location
        exit 1
    }
} else {
    Write-Host "✓ Git repository found" -ForegroundColor Green
}

# Configure Git
Write-Host "`nConfiguring Git settings..." -ForegroundColor Yellow
git config core.longpaths true
git config core.autocrlf true
Write-Host "✓ Git configured" -ForegroundColor Green

# Set up remote if provided
if ($GitHubRepo) {
    Write-Host "`nSetting up GitHub remote..." -ForegroundColor Yellow
    $ExistingRemote = git remote get-url origin -ErrorAction SilentlyContinue
    if ($ExistingRemote) {
        Write-Host "Remote already exists: $ExistingRemote" -ForegroundColor Yellow
        Write-Host "Update remote? (Y/N)" -ForegroundColor Yellow
        $Response = Read-Host
        if ($Response -eq "Y" -or $Response -eq "y") {
            git remote set-url origin $GitHubRepo
            Write-Host "✓ Remote updated" -ForegroundColor Green
        }
    } else {
        git remote add origin $GitHubRepo
        Write-Host "✓ Remote added: $GitHubRepo" -ForegroundColor Green
    }
} else {
    Write-Host "`nNo GitHub repository URL provided." -ForegroundColor Yellow
    Write-Host "To add a remote later, run:" -ForegroundColor Yellow
    Write-Host "  git remote add origin https://github.com/username/repo.git" -ForegroundColor Cyan
}

# Create server-config.json if it doesn't exist
Write-Host "`nSetting up configuration..." -ForegroundColor Yellow
$ConfigFile = Join-Path $RepoRoot "server-config.json"
$ExampleConfig = Join-Path $RepoRoot "server-config.json.example"

if (-not (Test-Path $ConfigFile) -and (Test-Path $ExampleConfig)) {
    Copy-Item $ExampleConfig $ConfigFile
    Write-Host "✓ Configuration file created: $ConfigFile" -ForegroundColor Green
    Write-Host "  Please edit this file with your server details!" -ForegroundColor Yellow
} elseif (Test-Path $ConfigFile) {
    Write-Host "✓ Configuration file already exists" -ForegroundColor Green
}

# Create logs directory
$LogsDir = Join-Path $RepoRoot "logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
    Write-Host "✓ Logs directory created" -ForegroundColor Green
}

Pop-Location

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit server-config.json with your server path" -ForegroundColor White
Write-Host "2. Set up auto-pull (choose one):" -ForegroundColor White
Write-Host "   - Scheduled Task: .\scripts\setup-scheduled-task.ps1" -ForegroundColor Cyan
Write-Host "   - Webhook: .\scripts\webhook-handler.ps1" -ForegroundColor Cyan
Write-Host "   - Manual: .\scripts\auto-pull.ps1" -ForegroundColor Cyan
Write-Host "3. Read README-GITHUB-SETUP.md for detailed instructions" -ForegroundColor White
Write-Host ""

