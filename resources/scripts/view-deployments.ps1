# View Deployment History
# Shows all deployments tracked by the webhook system

param(
    [int]$Limit = 20
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath
$DeployLog = Join-Path $RepoRoot "logs\deployments.log"

if (-not (Test-Path $DeployLog)) {
    Write-Host "No deployment history found." -ForegroundColor Yellow
    Write-Host "Deployments will be logged after the first webhook trigger." -ForegroundColor Gray
    exit 0
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment History" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Deployments = Get-Content $DeployLog | Where-Object { $_ -and $_.Trim() } | ForEach-Object {
    try {
        $_ | ConvertFrom-Json
    } catch {
        $null
    }
} | Where-Object { $_ } | Select-Object -Last $Limit

if ($Deployments) {
    $Deployments = $Deployments | Sort-Object -Property Timestamp -Descending
    
    foreach ($Deploy in $Deployments) {
        $StatusColor = if ($Deploy.Status -eq "Deployed") { "Green" } else { "Yellow" }
        
        Write-Host "Timestamp: $($Deploy.Timestamp)" -ForegroundColor White
        Write-Host "Branch: $($Deploy.Branch)" -ForegroundColor Cyan
        Write-Host "Pusher: $($Deploy.Pusher)" -ForegroundColor Yellow
        Write-Host "Commits: $($Deploy.CommitCount)" -ForegroundColor Yellow
        Write-Host "Status: $($Deploy.Status)" -ForegroundColor $StatusColor
        
        if ($Deploy.DeployedAt) {
            Write-Host "Deployed At: $($Deploy.DeployedAt)" -ForegroundColor Gray
        }
        
        if ($Deploy.LatestCommit) {
            Write-Host "Latest: $($Deploy.LatestCommit)" -ForegroundColor Gray
        }
        
        if ($Deploy.Commits) {
            Write-Host "Commit Messages:" -ForegroundColor White
            foreach ($Commit in $Deploy.Commits) {
                Write-Host "  • $($Commit.Message) ($($Commit.Author))" -ForegroundColor Gray
            }
        }
        
        if ($Deploy.CompareUrl) {
            Write-Host "Compare: $($Deploy.CompareUrl)" -ForegroundColor Blue
        }
        
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
    }
} else {
    Write-Host "No deployments found in log." -ForegroundColor Yellow
}

Write-Host "Total deployments shown: $($Deployments.Count)" -ForegroundColor Cyan


