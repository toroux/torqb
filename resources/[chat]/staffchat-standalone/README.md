# Staff Chat Standalone

A standalone, feature-rich staff chat system for FiveM servers with an advanced UI.

**Created by Torou**

## Features

- 🎨 Beautiful, modern UI with animations
- 💬 Real-time messaging with typing indicators
- 📌 Message pinning
- ✏️ Message editing and deletion
- 😀 Emoji reactions
- 👥 Online staff list sidebar
- 🖼️ Custom profile pictures
- 📝 Message formatting (bold, italic, code, links)
- @ Mentions with gold highlighting
- ⏰ Full timestamps
- 🎯 Welcome screen with cursor effects

## Installation

1. Place the `staffchat-standalone` folder in your `resources` directory
2. Add `ensure staffchat-standalone` to your `server.cfg`
3. Configure `config.lua` to match your server setup
4. Restart your server

## Dependencies

- **ox_lib** (Required)
- **QBCore** or **ESX** (Required - configure in config.lua)
- **cc-chat** (Optional - only needed if using anti-spam)
- **ccDiscordWrapper** (Optional - only needed for Discord webhooks/role names)

## Configuration

Edit `config.lua` to configure:

- Framework (QBCore/ESX)
- Staff permissions (license system or framework permissions)
- UI settings (logo, colors, RGB effects)
- Discord avatar settings
- Discord webhooks (optional)

## Commands

- `/staff` - Open staff chat UI

## Permissions

Staff permissions are checked using:
1. Framework permissions (QBCore: admin/mod/god, ESX: admin/superadmin/mod)
2. License system (if configured in config.lua)

## Credits

**Created by Torou**

This resource is standalone and created by Torou. All rights reserved.

## Support

For support, contact Torou.

