# 🔧 Fix: Changes Not Pulling to Server

## The Problem
Your changes aren't being pulled because:
1. **Git is not installed or not in PATH**
2. **Webhook handler is not running**
3. **Git repository might not be initialized**

## Quick Fix (Choose One)

### Option 1: Install Git (Recommended)

1. **Download Git:**
   - Go to: https://git-scm.com/download/win
   - Download and install Git for Windows
   - **Important:** During installation, select "Add Git to PATH"

2. **Restart PowerShell** after installation

3. **Test Git:**
   ```powershell
   git --version
   ```

4. **Pull changes manually:**
   ```powershell
   cd resources\scripts
   .\pull-now.ps1
   ```

### Option 2: Use GitHub Desktop's Git

If you have GitHub Desktop installed, you can use its Git:

1. **Find GitHub Desktop's Git:**
   - Usually at: `C:\Users\YOUR_USERNAME\AppData\Local\GitHubDesktop\bin\git.exe`

2. **Add to PATH temporarily:**
   ```powershell
   $env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\GitHubDesktop\bin"
   git --version
   ```

3. **Or use the pull script** (it will try to find GitHub Desktop's Git automatically):
   ```powershell
   cd resources\scripts
   powershell.exe -ExecutionPolicy Bypass -File pull-now.ps1
   ```

### Option 3: Manual Pull (If Git is Working)

If Git is installed but webhook isn't working:

1. **Open PowerShell in the repository root:**
   ```powershell
   cd "C:\Users\ser5s\Desktop\FiveM Server\txData\QBCore_D9C04A.base\torqb"
   ```

2. **Pull manually:**
   ```powershell
   git pull origin main
   ```

## Setup Webhook Handler (For Automatic Pulls)

Once Git is working, set up automatic pulls:

### Step 1: Start Webhook Handler

```powershell
cd resources\scripts
.\start-webhook.ps1 -Port 8080
```

**Keep this window open!**

### Step 2: Configure GitHub Webhook

1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://YOUR_IP:8080/` (or use ngrok for testing)
4. Content type: `application/json`
5. Events: "Just the push event"
6. Click "Add webhook"

### Step 3: Test

Make a change, commit, and push:
```bash
git add .
git commit -m "Test"
git push origin main
```

## Troubleshooting

### Check if Git is installed:
```powershell
where.exe git
```

### Check if webhook handler is running:
```powershell
Get-NetTCPConnection -LocalPort 8080
```

### Check Git repository:
```powershell
cd "C:\Users\ser5s\Desktop\FiveM Server\txData\QBCore_D9C04A.base\torqb"
git status
```

### Run troubleshooting script:
```powershell
cd resources\scripts
powershell.exe -ExecutionPolicy Bypass -File troubleshoot-deployment.ps1
```

## Most Common Issues

1. **"git is not recognized"**
   - Install Git and add to PATH
   - Or restart PowerShell after installing

2. **"Git repository not found"**
   - Initialize: `git init`
   - Add remote: `git remote add origin <your-github-url>`

3. **"Webhook handler not running"**
   - Start it: `.\start-webhook.ps1`
   - Keep the window open

4. **"Port 8080 in use"**
   - Use different port: `.\start-webhook.ps1 -Port 8081`
   - Update GitHub webhook URL

## Need More Help?

Run the troubleshooting script:
```powershell
cd resources\scripts
powershell.exe -ExecutionPolicy Bypass -File troubleshoot-deployment.ps1
```

This will check everything and tell you what's wrong!

