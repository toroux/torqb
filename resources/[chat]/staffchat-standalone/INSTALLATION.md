# Installation Guide

**Created by Torou**

## Quick Setup

1. **Copy the resource** to your `resources` folder
2. **Add to server.cfg**: `ensure staffchat-standalone`
3. **Configure** `config.lua`:
   - Set your framework (QBCore/ESX)
   - Add staff licenses (if using license system)
   - Configure UI settings (logo URL, colors)
4. **Restart** your server

## Event Name Changes

All events have been renamed from `cc-rpchat:*` to `staffchat:*` to make this resource standalone.

## Optional Dependencies

- **cc-chat**: Only needed if you enable `config.antiSpam = true`
- **ccDiscordWrapper**: Only needed if you enable `config.discord = true` or `config.DiscordWebhook = true`

The resource will work without these dependencies if you disable those features in config.

## ResourceKvp Keys

Custom avatars are stored using: `staffchat:avatar:{license}`

This is separate from any other resources, so there are no conflicts.

