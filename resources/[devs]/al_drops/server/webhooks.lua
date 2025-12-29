-- Discord Webhook Functions for Airdrop System

-- Discord Webhook Function for Airdrop Creation (Admin Created)
local function sendDiscordWebhook(adminName, adminId, adminLicense, command, coords, count)
    if not Config.DiscordWebhook.enabled then
        return
    end
    
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    local embed = {
        {
            ["color"] = 3447003, -- Blue color
            ["title"] = "🚁 Airdrop Created",
            ["description"] = "An admin has deployed an airdrop!",
            ["fields"] = {
                {
                    ["name"] = "👤 Admin Name",
                    ["value"] = adminName,
                    ["inline"] = true
                },
                {
                    ["name"] = "🆔 Admin Server ID",
                    ["value"] = tostring(adminId),
                    ["inline"] = true
                },
                {
                    ["name"] = "📜 Admin License",
                    ["value"] = adminLicense,
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Command",
                    ["value"] = command,
                    ["inline"] = true
                },
                {
                    ["name"] = "📍 Coordinates",
                    ["value"] = string.format("X: %.2f\nY: %.2f\nZ: %.2f", coords.x, coords.y, coords.z),
                    ["inline"] = true
                },
                {
                    ["name"] = "🔢 Drop Count",
                    ["value"] = tostring(count or 1),
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ Time",
                    ["value"] = currentTime,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Airdrop Hawk",
                ["icon_url"] = Config.DiscordWebhook.botAvatar
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    local payload = {
        ["username"] = Config.DiscordWebhook.botName,
        ["avatar_url"] = Config.DiscordWebhook.botAvatar,
        ["embeds"] = embed
    }

    PerformHttpRequest(Config.DiscordWebhook.url, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Discord Webhook Function for Airdrop Collection
local function sendCollectionWebhook(playerName, playerId, playerLicense, items, coords)
    if not Config.DiscordWebhook.enabled then
        return
    end
    
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    local itemsList = table.concat(items, "\n")
    
    local embed = {
        {
            ["color"] = 65280, -- Green color
            ["title"] = "📦 Airdrop Collected",
            ["description"] = "A player has collected an airdrop!",
            ["fields"] = {
                {
                    ["name"] = "👤 Player Name",
                    ["value"] = playerName,
                    ["inline"] = true
                },
                {
                    ["name"] = "🆔 Server ID",
                    ["value"] = tostring(playerId),
                    ["inline"] = true
                },
                {
                    ["name"] = "📜 License",
                    ["value"] = playerLicense,
                    ["inline"] = true
                },
                {
                    ["name"] = "📍 Coordinates",
                    ["value"] = string.format("X: %.2f\nY: %.2f\nZ: %.2f", coords.x, coords.y, coords.z),
                    ["inline"] = true
                },
                {
                    ["name"] = "🎁 Items Received",
                    ["value"] = itemsList,
                    ["inline"] = false
                },
                {
                    ["name"] = "⏰ Time",
                    ["value"] = currentTime,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Airdrop Hawk",
                ["icon_url"] = Config.DiscordWebhook.botAvatar
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    local payload = {
        ["username"] = Config.DiscordWebhook.botName,
        ["avatar_url"] = Config.DiscordWebhook.botAvatar,
        ["embeds"] = embed
    }

    PerformHttpRequest(Config.DiscordWebhook.url, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Export functions for use in other files
return {
    sendDiscordWebhook = sendDiscordWebhook,
    sendCollectionWebhook = sendCollectionWebhook
}
