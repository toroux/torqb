# Automatic Deployment Guide

This guide explains how to set up automatic deployment from GitHub to your FiveM server.

## 🚀 How It Works

1. **You push changes to GitHub** → GitHub sends a webhook to your server
2. **Webhook handler receives the event** → Triggers auto-pull script
3. **Auto-pull script pulls changes** → Updates your server files automatically
4. **Deployment is logged** → Track all deployments in `logs/deployments.log`

## 📋 Setup Steps

### 1. Start the Webhook Handler

The webhook handler listens for GitHub push events and automatically triggers deployments.

**Option A: Run Manually (for testing)**
```powershell
cd resources\scripts
.\webhook-handler.ps1 -Port 8080
```

**Option B: Run as Background Process**
```powershell
cd resources\scripts
Start-Process powershell.exe -ArgumentList "-File", "webhook-handler.ps1", "-Port", "8080" -WindowStyle Minimized
```

**Option C: Run as Windows Service (Recommended for Production)**
```powershell
# First, download NSSM from https://nssm.cc/download
# Extract to C:\nssm\
cd resources\scripts
.\setup-webhook-service.ps1 -Port 8080 -Branch main
```

### 2. Configure GitHub Webhook

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL**: `http://YOUR_PUBLIC_IP:8080/`
     - For local testing: `http://localhost:8080/`
     - For production: Use your server's public IP or domain
   - **Content type**: `application/json`
   - **Secret**: (Optional but recommended - set a random string)
   - **Events**: Select **"Just the push event"**
   - **Active**: ✓ Checked
4. Click **"Add webhook"**

### 3. Test the Setup

1. Make a small change to any file in your repository
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test deployment"
   git push origin main
   ```
3. Check the webhook handler window - you should see:
   ```
   Push detected to main branch!
   Triggering auto-pull...
   ```
4. Check `logs/auto-pull.log` to see the deployment progress
5. Check `logs/deployments.log` to see deployment history

## 📊 Tracking Deployments

### View Deployment History

```powershell
cd resources\scripts
.\view-deployments.ps1
```

This shows:
- Timestamp of each deployment
- Who pushed the changes
- Number of commits
- Commit messages
- Deployment status

### View Deployment Logs

```powershell
# View auto-pull log
Get-Content ..\logs\auto-pull.log -Tail 50

# View deployment history
Get-Content ..\logs\deployments.log -Tail 20
```

## ⚙️ Configuration Options

Edit `server-config.json`:

```json
{
  "Webhook": {
    "Enabled": true,
    "Port": 8080,
    "Secret": "your-secret-here"
  },
  "AutoPull": {
    "Enabled": true,
    "IntervalMinutes": 15,
    "RestartOnUpdate": false  // Set to true to auto-restart server
  }
}
```

### Auto-Restart Server on Update

If you want the server to automatically restart after pulling updates:

1. Edit `server-config.json`
2. Set `"RestartOnUpdate": true`
3. Make sure `ServerPath` is correctly configured

## 🔒 Security Best Practices

1. **Use a Webhook Secret**
   - Generate a random string
   - Set it in GitHub webhook settings
   - Set it in `server-config.json` or pass it to the handler:
     ```powershell
     .\webhook-handler.ps1 -Port 8080 -Secret "your-secret-here"
     ```

2. **Firewall Configuration**
   - Only allow port 8080 from GitHub IPs if possible
   - Or use a reverse proxy (nginx, IIS) with authentication

3. **HTTPS (Recommended for Production)**
   - Use a reverse proxy with SSL certificate
   - Or use ngrok for testing: `ngrok http 8080`

## 🐛 Troubleshooting

### Webhook Not Receiving Events

1. **Check if handler is running:**
   ```powershell
   Get-NetTCPConnection -LocalPort 8080
   ```

2. **Check GitHub webhook delivery:**
   - Go to repository → Settings → Webhooks
   - Click on your webhook
   - Check "Recent Deliveries" tab
   - Look for failed deliveries and error messages

3. **Check firewall:**
   - Ensure port 8080 is open
   - Check Windows Firewall settings

### Changes Not Being Pulled

1. **Check auto-pull log:**
   ```powershell
   Get-Content logs\auto-pull.log -Tail 50
   ```

2. **Verify Git repository:**
   ```powershell
   cd ..
   git status
   git remote -v
   ```

3. **Test manual pull:**
   ```powershell
   cd resources\scripts
   .\auto-pull.ps1 -Branch main
   ```

### Handler Crashes or Stops

1. **Check for errors in PowerShell window**
2. **Run as service** (more stable):
   ```powershell
   .\setup-webhook-service.ps1 -Port 8080
   ```

3. **Use Task Scheduler** to auto-restart if it crashes

## 📝 Workflow Example

### Daily Development Workflow

1. **Make changes locally**
2. **Test changes**
3. **Commit and push:**
   ```bash
   git add .
   git commit -m "Added new feature"
   git push origin main
   ```
4. **Webhook automatically deploys** to server
5. **Check deployment status:**
   ```powershell
   .\view-deployments.ps1
   ```

### Manual Deployment (if needed)

If webhook is down or you want to deploy manually:

```powershell
cd resources\scripts
.\auto-pull.ps1 -Branch main
```

Or with server restart:

```powershell
.\restart-server.ps1 -Branch main
```

## 🎯 Best Practices

1. **Use feature branches** for development
2. **Test in staging** before pushing to main
3. **Monitor deployment logs** regularly
4. **Keep webhook handler running** (use service or Task Scheduler)
5. **Backup before major updates**
6. **Use deployment history** to track what was deployed when

## 📚 Additional Resources

- [GitHub Webhooks Documentation](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [Git Documentation](https://git-scm.com/doc)
- [NSSM (Service Manager)](https://nssm.cc/)

## ✅ Quick Checklist

- [ ] Webhook handler is running
- [ ] GitHub webhook is configured
- [ ] Port 8080 is accessible
- [ ] Git repository is properly configured
- [ ] `server-config.json` is set up
- [ ] Tested with a small change
- [ ] Deployment logs are working
- [ ] (Optional) Webhook secret is configured
- [ ] (Optional) Auto-restart is configured if needed

---

**You're all set!** Now every time you push to GitHub, your server will automatically update! 🎉

