# GitHub Webhook Handler for FiveM Server
# This script handles GitHub webhook POST requests and triggers auto-pull

param(
    [string]$Port = 8080,
    [string]$Secret = "",  # GitHub webhook secret (optional but recommended)
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptPath

# HTTP listener for GitHub webhooks
$Listener = New-Object System.Net.HttpListener

# Try to listen on all interfaces (requires admin for ports > 1024)
# If that fails, fall back to localhost
try {
    $Listener.Prefixes.Add("http://+:$Port/")  # Listen on all interfaces
    $Listener.Start()
    Write-Host "Webhook handler listening on ALL interfaces (port $Port)" -ForegroundColor Green
    Write-Host "Note: For external access, ensure firewall allows port $Port" -ForegroundColor Yellow
} catch {
    Write-Host "Failed to bind to all interfaces. Trying localhost only..." -ForegroundColor Yellow
    $Listener.Prefixes.Clear()
    $Listener.Prefixes.Add("http://localhost:$Port/")
    $Listener.Start()
    Write-Host "Webhook handler listening on localhost only (port $Port)" -ForegroundColor Yellow
    Write-Host "For GitHub webhooks, you may need to:" -ForegroundColor Yellow
    Write-Host "  1. Run PowerShell as Administrator, OR" -ForegroundColor Yellow
    Write-Host "  2. Use a reverse proxy, OR" -ForegroundColor Yellow
    Write-Host "  3. Use ngrok: ngrok http $Port" -ForegroundColor Yellow
}

Write-Host "GitHub Webhook Handler started on port $Port"
Write-Host "Listening for webhook events..."
Write-Host "Press Ctrl+C to stop"

function Process-Webhook {
    param([string]$Payload, [hashtable]$Headers)
    
    try {
        $Event = $Headers["X-GitHub-Event"]
        $Signature = $Headers["X-Hub-Signature-256"]
        
        Write-Host "Received webhook event: $Event"
        
        # Verify signature if secret is provided
        if ($Secret) {
            $PayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($Payload)
            $HMAC = New-Object System.Security.Cryptography.HMACSHA256
            $HMAC.Key = [System.Text.Encoding]::UTF8.GetBytes($Secret)
            $Hash = $HMAC.ComputeHash($PayloadBytes)
            $ComputedSignature = "sha256=" + ([System.BitConverter]::ToString($Hash) -replace "-", "").ToLower()
            
            if ($Signature -ne $ComputedSignature) {
                Write-Host "Invalid signature. Rejecting webhook." -ForegroundColor Red
                return @{ StatusCode = 401; Body = "Unauthorized" }
            }
        }
        
        # Parse JSON payload
        $Data = $Payload | ConvertFrom-Json
        
        # Only process push events to the specified branch
        if ($Event -eq "push") {
            $Ref = $Data.ref
            if ($Ref -eq "refs/heads/$Branch") {
                # Extract commit information
                $Commits = $Data.commits
                $Pusher = $Data.pusher.name
                $CompareUrl = $Data.compare
                $CommitCount = $Commits.Count
                
                Write-Host "========================================" -ForegroundColor Cyan
                Write-Host "Push detected to $Branch branch!" -ForegroundColor Green
                Write-Host "Pusher: $Pusher" -ForegroundColor Yellow
                Write-Host "Commits: $CommitCount" -ForegroundColor Yellow
                Write-Host "Compare: $CompareUrl" -ForegroundColor Yellow
                
                # Log commit details
                foreach ($Commit in $Commits) {
                    Write-Host "  - $($Commit.message) (by $($Commit.author.name))" -ForegroundColor Gray
                }
                
                Write-Host "Triggering auto-pull..." -ForegroundColor Green
                Write-Host "========================================" -ForegroundColor Cyan
                
                # Create deployment log entry
                $DeployLog = Join-Path $RepoRoot "logs\deployments.log"
                $DeployDir = Split-Path -Parent $DeployLog
                if (-not (Test-Path $DeployDir)) {
                    New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null
                }
                
                $DeployEntry = @{
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Branch = $Branch
                    Pusher = $Pusher
                    CommitCount = $CommitCount
                    Commits = $Commits | ForEach-Object { @{
                        Message = $_.message
                        Author = $_.author.name
                        Id = $_.id.Substring(0, 7)
                    }}
                    CompareUrl = $CompareUrl
                    Status = "Deploying"
                }
                
                Add-Content -Path $DeployLog -Value ($DeployEntry | ConvertTo-Json -Depth 10)
                
                # Trigger auto-pull in background (without restart by default)
                $PullScript = Join-Path $ScriptPath "auto-pull.ps1"
                if (Test-Path $PullScript) {
                    # Check config for restart setting
                    $ConfigFile = Join-Path $RepoRoot "server-config.json"
                    $RestartOnUpdate = $false
                    if (Test-Path $ConfigFile) {
                        try {
                            $Config = Get-Content $ConfigFile | ConvertFrom-Json
                            $RestartOnUpdate = $Config.AutoPull.RestartOnUpdate
                        } catch {}
                    }
                    
                    if ($RestartOnUpdate) {
                        Start-Process powershell.exe -ArgumentList "-File", $PullScript, "-Branch", $Branch, "-RestartServer" -WindowStyle Hidden
                    } else {
                        Start-Process powershell.exe -ArgumentList "-File", $PullScript, "-Branch", $Branch -WindowStyle Hidden
                    }
                }
                
                return @{ StatusCode = 200; Body = "Webhook processed successfully - Deployment initiated" }
            } else {
                Write-Host "Push to different branch: $Ref. Ignoring." -ForegroundColor Yellow
                return @{ StatusCode = 200; Body = "Ignored - different branch" }
            }
        } else {
            Write-Host "Event type '$Event' not handled. Ignoring." -ForegroundColor Yellow
            return @{ StatusCode = 200; Body = "Event ignored" }
        }
        
    } catch {
        Write-Host "Error processing webhook: $_" -ForegroundColor Red
        return @{ StatusCode = 500; Body = "Internal server error" }
    }
}

# Main webhook listener loop
try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response
        
        # Read request body
        $Reader = New-Object System.IO.StreamReader($Request.InputStream)
        $Payload = $Reader.ReadToEnd()
        $Reader.Close()
        
        # Get headers
        $Headers = @{}
        foreach ($Header in $Request.Headers.AllKeys) {
            $Headers[$Header] = $Request.Headers[$Header]
        }
        
        # Process webhook
        $Result = Process-Webhook -Payload $Payload -Headers $Headers
        
        # Send response
        $Response.StatusCode = $Result.StatusCode
        $Response.ContentType = "application/json"
        $ResponseBody = [System.Text.Encoding]::UTF8.GetBytes(($Result.Body | ConvertTo-Json))
        $Response.ContentLength64 = $ResponseBody.Length
        $Response.OutputStream.Write($ResponseBody, 0, $ResponseBody.Length)
        $Response.Close()
    }
} catch {
    Write-Host "Error in webhook listener: $_" -ForegroundColor Red
} finally {
    $Listener.Stop()
    $Listener.Close()
}

