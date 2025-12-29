# 🚀 Quick Start - Auto-Deploy from GitHub

## One-Command Setup

```powershell
cd resources\scripts
.\start-webhook.ps1 -Port 8080
```

This starts the webhook handler that will automatically pull changes when you push to GitHub.

## Complete Setup (3 Steps)

### Step 1: Start Webhook Handler

```powershell
cd resources\scripts
.\start-webhook.ps1 -Port 8080
```

**Keep this window open!** The handler needs to be running to receive webhooks.

### Step 2: Configure GitHub Webhook

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/hooks`
2. Click **"Add webhook"**
3. Set:
   - **Payload URL**: `http://YOUR_PUBLIC_IP:8080/`
   - **Content type**: `application/json`
   - **Events**: "Just the push event"
4. Click **"Add webhook"**

### Step 3: Test It!

```bash
# Make a small change
echo "test" >> test.txt
git add .
git commit -m "Test auto-deploy"
git push origin main
```

Check the webhook handler window - you should see the deployment happening!

## 📊 View What Was Deployed

```powershell
cd resources\scripts
.\view-deployments.ps1
```

## 🔧 Common Commands

```powershell
# Start webhook handler
.\start-webhook.ps1

# View deployment history
.\view-deployments.ps1

# Manual pull (if webhook is down)
.\auto-pull.ps1

# Restart server with latest changes
.\restart-server.ps1
```

## ⚠️ Important Notes

1. **Keep webhook handler running** - It must be running to receive GitHub events
2. **Port 8080 must be accessible** - GitHub needs to reach your server
3. **For local testing** - Use ngrok: `ngrok http 8080`
4. **For production** - Run as Windows Service (see `setup-webhook-service.ps1`)

## 🎯 That's It!

Now every time you `git push`, your server automatically updates! 🎉

See `DEPLOYMENT-GUIDE.md` for detailed documentation.

