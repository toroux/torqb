-- Staff Chat Standalone
-- Created by Torou
-- Version 1.0.0

config = {}

-- Framework Configuration
config.esx = false                        -- Set this to true if using ESX (requires esx_identity)
config.qbcore = true                      -- Set this to true if using QBCore

config.discord = false                    -- Set this to true if using ccDiscordWrapper and want Role Names added as a prefix to the Players Name

-- Staff Chat Configuration
config.staffChat = {
    requireLicense = true,                -- Set to true to require license, false to allow everyone
}

-- Discord Avatar Configuration
config.discordAvatar = {
    useRealAvatars = false,               -- Set to true to use real Discord avatars (requires Discord bot token)
    botToken = "",                        -- Discord bot token (required if useRealAvatars is true)
    useThirdPartyService = false,         -- Use third-party service for avatars (no token needed, but less reliable)
    thirdPartyAPI = "https://api.discord.com/users/", -- Third-party API endpoint (if useThirdPartyService is true)
    -- Test mode: Hardcode avatar for specific Discord ID (for testing)
    testMode = true,                      -- Enable test mode to fetch real avatars for specific IDs
    testDiscordIds = {                    -- List of Discord IDs to fetch real avatars for (testing)
        -- Add Discord IDs here for testing
    },
}

-- UI Configuration
config.UI = {
    LogoURL = "https://r2.fivemanage.com/sGzHhtqV5EyInZxxopmj5/TRANSPARENT.gif", -- Logo image URL
    BaseColor = "#4B0082", -- Base color in hex format (dark purple)
    RGB = false, -- Enable RGB holographic border effect (true/false)
    RGBBorders = true, -- Enable RGB borders on buttons, dropdowns, and tabs (defaults to RGB value if not set)
}

-- License System (for staff permissions)
config.License = {
    -- Add license identifiers here
    -- Example: "license:cee05af2b8cccb4f7c6f7cca07ebe6d94beebac2",
}

-- Discord Webhook (optional - requires ccDiscordWrapper)
config.DiscordWebhook = false             -- Set to true if you would like to log to Discord Webhook ***REQUIRES ccDiscordWrapper!***

-- Anti-Spam (optional - requires cc-chat)
config.antiSpam = false                   -- set this to true if you would like to use the cc chat antispam system

