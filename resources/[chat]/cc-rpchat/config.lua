config = {}

config.esx = false                        -- Set this to true if using ESX (requires esx_identity)

config.qbcore = true                     -- Set this to true if using QBCore

config.discord = false                    -- Set this to true if using ccDiscordWrapper and want Role Names added as a prefix to the Players Name

config.connectionMessages = true          -- set this to true if you would like join and leave messages

config.antiSpam = false                   -- set this to true if you would like to use the cc chat antispam system                      

config.DiscordWebhook = false             -- Set to your true if you would like to log to Discord Webhook ***REQUIRES ccDiscordWrapper!***

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
        "1079852456953004092"             -- Torou - will fetch real avatar
    },
    -- Example Discord ID: 1079852456953004092 (Torou)
    -- Default avatar URL for this ID: https://cdn.discordapp.com/embed/avatars/2.png
    -- Real avatar URL format (requires bot token): https://cdn.discordapp.com/avatars/{user_id}/{avatar_hash}.png
}

-- UI Configuration (copied from al_gundamage)
config.UI = {
    LogoURL = "https://r2.fivemanage.com/sGzHhtqV5EyInZxxopmj5/TRANSPARENT.gif", -- Logo image URL
    BaseColor = "#4B0082", -- Base color in hex format (dark purple)
    RGB = false, -- Enable RGB holographic border effect (true/false)
    RGBBorders = true, -- Enable RGB borders on buttons, dropdowns, and tabs (defaults to RGB value if not set)
}

config.License = {
    -- Example: "license:34d7609d1afd81cef89d575515a04928a582415f",
    "license:cee05af2b8cccb4f7c6f7cca07ebe6d94beebac2", -- Torou
    "license:ba46a2e5d7e5c0c54b43e1bc9035247f0e02154a", -- Ryan
    "license:f4980fb989e35745e2925c1ba5e402a9c06c5e76", -- Teresa
}

-- God Level Permissions
config.godPermissions = {
    enabled = true,                       -- Set to true to enable god permissions setup
    discordIds = {                        -- List of Discord IDs to grant god permissions
        '1079852456953004092'             -- Torou
    }
}

config.emoji = {
    chatMessage = true, -- enable emojis for text (ooc)
    ooc = false, -- enable emojis for /ooc
    me = true, --  enable emojis for /me
    doo = true, --  enable emojis for /do
    news = true, --  enable emojis for /news
    ad = true, --  enable emojis for /ad
    twt = true, --  enable emojis for /twt
    anon = true, --  enable emojis for /anon
}

function import(file) -- require doesnt work without ox_lib so we need to use this to keep this standalone
	local name = ('%s.lua'):format(file)
	local content = LoadResourceFile(GetCurrentResourceName(),name)
	local f, err = load(content)
	return f()
end
