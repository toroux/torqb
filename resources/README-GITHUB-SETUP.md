# FiveM Server GitHub Integration Setup Guide

This guide will help you set up automatic updates and GitHub integration for your FiveM server.

## 📋 Prerequisites

1. **Git installed** on your server
2. **PowerShell** (included with Windows)
3. **GitHub repository** with your server files
4. **Administrator access** (for scheduled tasks)

## 🚀 Quick Start

### 1. Initial Git Setup

If you haven't already, initialize Git and connect to your GitHub repository:

```powershell
# Navigate to your server directory
cd "C:\Users\ser5s\Desktop\FiveM Server\txData\QBCore_D9C04A.base\torqb"

# Initialize Git (if not already done)
git init

# Add your GitHub remote
git remote add origin https://github.com/yourusername/your-repo.git

# Or if using SSH:
git remote add origin git@github.com:yourusername/your-repo.git

# Configure Git for long paths and line endings
git config core.longpaths true
git config core.autocrlf true
```

### 2. Configure Server Settings

1. Copy the example config file:
   ```powershell
   Copy-Item server-config.json.example server-config.json
   ```

2. Edit `server-config.json` with your server details:
   - Set `ServerPath` to your FiveM server executable path
   - Configure other settings as needed

### 3. Set Up Auto-Pull

#### Option A: Scheduled Task (Recommended)

Run the setup script as Administrator:

```powershell
# Open PowerShell as Administrator
cd resources\scripts
.\setup-scheduled-task.ps1 -IntervalMinutes 15 -Branch main
```

This will create a Windows Scheduled Task that automatically pulls updates every 15 minutes.

#### Option B: Manual Pull Script

Run manually whenever you want to pull updates:

```powershell
cd resources\scripts
.\auto-pull.ps1 -Branch main
```

#### Option C: GitHub Webhook (Real-time)

1. **Start the webhook handler:**
   ```powershell
   cd resources\scripts
   .\webhook-handler.ps1 -Port 8080 -Secret "your-secret-key" -Branch main
   ```

2. **Configure GitHub Webhook:**
   - Go to your GitHub repository
   - Navigate to Settings → Webhooks → Add webhook
   - Payload URL: `http://your-server-ip:8080/`
   - Content type: `application/json`
   - Secret: (same as in webhook-handler.ps1)
   - Events: Select "Just the push event"
   - Click "Add webhook"

3. **Keep webhook handler running:**
   - Use a service like NSSM to run it as a Windows service
   - Or use Task Scheduler to keep it running

### 4. Server Restart with Auto-Pull

To restart your server and pull latest changes:

```powershell
cd resources\scripts
.\restart-server.ps1 -Branch main
```

## 📁 Scripts Overview

### `auto-pull.ps1`
- Automatically pulls latest changes from GitHub
- Logs all operations to `logs/auto-pull.log`
- Options:
  - `-Branch`: Branch to pull from (default: main)
  - `-RestartServer`: Restart server after pull
  - `-Force`: Force pull even if up to date

### `restart-server.ps1`
- Stops FiveM server
- Pulls latest changes (optional)
- Restarts server
- Options:
  - `-Branch`: Branch to pull from
  - `-SkipPull`: Skip pulling before restart

### `webhook-handler.ps1`
- Listens for GitHub webhook events
- Automatically triggers pull on push events
- Options:
  - `-Port`: Port to listen on (default: 8080)
  - `-Secret`: GitHub webhook secret
  - `-Branch`: Branch to monitor

### `scheduled-pull.ps1`
- Designed to run via Task Scheduler
- Calls auto-pull script

### `setup-scheduled-task.ps1`
- Sets up Windows Scheduled Task for auto-pull
- Must run as Administrator

## 🔧 Configuration

### server-config.json

```json
{
  "ServerPath": "C:\\FXServer\\FXServer.exe",
  "ServerName": "FiveM Server",
  "RestartDelay": 10,
  "GitBranch": "main",
  "Webhook": {
    "Enabled": false,
    "Port": 8080,
    "Secret": ""
  },
  "AutoPull": {
    "Enabled": true,
    "IntervalMinutes": 15,
    "RestartOnUpdate": false
  }
}
```

## 🔐 Security Considerations

1. **Webhook Secret**: Always use a secret for webhooks in production
2. **Firewall**: Only expose webhook port to GitHub IPs if possible
3. **SSH Keys**: Use SSH keys instead of passwords for Git operations
4. **Permissions**: Run scripts with appropriate permissions

## 📝 Workflow Examples

### Daily Updates
```powershell
# Set up task to check every hour
.\setup-scheduled-task.ps1 -IntervalMinutes 60
```

### Manual Update and Restart
```powershell
.\restart-server.ps1 -Branch main
```

### Test Pull Without Restart
```powershell
.\auto-pull.ps1 -Branch main
```

## 🐛 Troubleshooting

### Git not found
- Ensure Git is installed and in PATH
- Restart PowerShell after installing Git

### Permission denied
- Run PowerShell as Administrator
- Check file permissions

### Webhook not working
- Check firewall settings
- Verify port is not in use
- Check GitHub webhook delivery logs

### Long path errors
- Run: `git config core.longpaths true`
- Enable long paths in Windows (requires admin)

## 📚 Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Webhooks Guide](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [Windows Task Scheduler](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)

## 🎯 Best Practices

1. **Test in a separate branch** before merging to main
2. **Backup your server** before major updates
3. **Monitor logs** regularly (`logs/auto-pull.log`)
4. **Use staging environment** for testing updates
5. **Keep secrets secure** - never commit `server-config.json`

## 💡 Tips

- Use GitHub Actions for automated testing before deployment
- Set up Discord webhooks to notify about updates
- Use feature branches for development
- Tag releases for easy rollback


