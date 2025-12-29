local ccChat = exports['cc-chat']
ESX = nil
QBCore = nil
local emoji = import 'emoji'


Citizen.CreateThread(function()
    SetConvar('chat_showJoins', '0')
    SetConvar('chat_showQuits', '0')
    if config.esx then
        ESX = exports["es_extended"]:getSharedObject()
        StopResource('esx_rpchat')
    elseif config.qbcore then
        QBCore = exports['qb-core']:GetCoreObject()
        
        -- Setup God Level Permissions
        if config.godPermissions and config.godPermissions.enabled then
            -- Allow all commands for qbcore.god
            ExecuteCommand('add_ace qbcore.god command allow')
            
            -- Assign Discord IDs to god group
            if config.godPermissions.discordIds then
                for _, discordId in ipairs(config.godPermissions.discordIds) do
                    ExecuteCommand(('add_principal identifier.discord:%s qbcore.god'):format(discordId))
                end
            end
        end
    end
end)

-- Function to send the global city message
function sendCityMessage()
    TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fa-solid fa-city', 'Dynasty Roleplay', 'Welcome to Torou\'s Test City', false)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'esx_rpchat' then
        StopResource(resourceName)
    end
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    PerformHttpRequest('https://api.github.com/repos/Concept-Collective/cc-rpchat/releases/latest', function (err, data, headers)
        if data == nil then
            print('An error occurred while checking the version. Your firewall may be blocking access to "github.com". Please check your firewall settings and ensure that "github.com" is allowed to establish connections.')
            return
        end
        
        local data = json.decode(data)
        if data.tag_name ~= 'v'..GetResourceMetadata(GetCurrentResourceName(), 'version', 0) then
            print('\n^1================^0')
            print('^1CC RP Chat ('..GetCurrentResourceName()..') is outdated!^0')
            print('Current version: (^1v'..GetResourceMetadata(GetCurrentResourceName(), 'version', 0)..'^0)')
            print('Latest version: (^2'..data.tag_name..'^0) '..data.html_url)
            print('Release notes: '..data.body)
            print('^1================^0')
        end
    end, 'GET', '')
    
    -- Send message when resource starts
    Wait(2000) -- Wait 2 seconds for all players to be ready
    sendCityMessage()
end)

-- Send message every 15 minutes (900000 milliseconds)
CreateThread(function()
    while true do
        Wait(900000) -- 15 minutes
        sendCityMessage()
    end
end)

AddEventHandler('chatMessage', function(source, name, message)
    CancelEvent()
    -- Only allow commands (messages starting with '/')
    -- Block all regular chat messages
    if message:sub(1, 1) == '/' then
        return
    else
        -- Block all non-command messages - do not process or display them
        return
    end
end)

-- Me
RegisterCommand('me', function(source, args, rawCommand)
    local playerName
    local msg = rawCommand:sub(4)
    if config.emoji.me then
        for _, em in ipairs(emoji) do
            for _, code in ipairs(em[1]) do
                local emojiCode = string.gsub(code, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special characters in the emoji code
                msg = string.gsub(msg, emojiCode, em[2]) -- Replace the emoji code with the corresponding emoji character
            end
        end
    end
    if ccChat:checkSpam(source, msg) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    if config.discord then
        playerName = "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        playerName = xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        playerName = xPlayer.PlayerData.charinfo.firstname .. "," .. xPlayer.PlayerData.charinfo.lastname 
    else
        playerName = GetPlayerName(source)
    end
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." has executed /"..rawCommand:sub(1, 2), '**Command arguments**: '..msg..'\n\n'.."**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
    end
    TriggerClientEvent('cc-rpchat:addProximityMessage', -1, '#FFD700', 'fa-solid fa-person', 'Me | '..playerName, msg, source, GetEntityCoords(GetPlayerPed(source)))
    --TriggerClientEvent('cc-rpchat:addMessage', -1, '#f39c12', 'fa-solid fa-person', 'Me | '..playerName, msg)
end, false)

-- Do
RegisterCommand('do', function(source, args, rawCommand)
    local playerName
    local msg = rawCommand:sub(4)
    if config.emoji.doo then
        for _, em in ipairs(emoji) do
            for _, code in ipairs(em[1]) do
                local emojiCode = string.gsub(code, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special characters in the emoji code
                msg = string.gsub(msg, emojiCode, em[2]) -- Replace the emoji code with the corresponding emoji character
            end
        end
    end
    if ccChat:checkSpam(source, msg) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    if config.discord then
        playerName = "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        playerName = xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        playerName = xPlayer.PlayerData.charinfo.firstname .. "," .. xPlayer.PlayerData.charinfo.lastname 
    else
        playerName = GetPlayerName(source)
    end
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." has executed /"..rawCommand:sub(1, 2), '**Command arguments**: '..msg..'\n\n'.."**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
    end
    TriggerClientEvent('cc-rpchat:addProximityMessage', -1, '#FFD700', 'fa-solid fa-person-digging', 'Do | '..playerName, msg, source, GetEntityCoords(GetPlayerPed(source)))
end, false)

-- News
RegisterCommand('news', function(source, args, rawCommand)
    local playerName
    local msg = rawCommand:sub(5)
    if config.emoji.news then
        for _, em in ipairs(emoji) do
            for _, code in ipairs(em[1]) do
                local emojiCode = string.gsub(code, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special characters in the emoji code
                msg = string.gsub(msg, emojiCode, em[2]) -- Replace the emoji code with the corresponding emoji character
            end
        end
    end
    if ccChat:checkSpam(source, msg) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    if config.discord then
        playerName = "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        playerName = xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        playerName = xPlayer.PlayerData.charinfo.firstname .. "," .. xPlayer.PlayerData.charinfo.lastname 
    else
        playerName = GetPlayerName(source)
    end
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." has executed /"..rawCommand:sub(1, 4), '**Command arguments**: '..msg..'\n\n'.."**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
    end
    TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fa-solid fa-newspaper', 'News | '..playerName, msg)
end, false)

-- Ad
RegisterCommand('ad', function(source, args, rawCommand)
    local playerName
    local msg = rawCommand:sub(4)
    if config.emoji.ad then
        for _, em in ipairs(emoji) do
            for _, code in ipairs(em[1]) do
                local emojiCode = string.gsub(code, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special characters in the emoji code
                msg = string.gsub(msg, emojiCode, em[2]) -- Replace the emoji code with the corresponding emoji character
            end
        end
    end
    if ccChat:checkSpam(source, msg) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    if config.discord then
        playerName = "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        playerName = xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        playerName = xPlayer.PlayerData.charinfo.firstname .. "," .. xPlayer.PlayerData.charinfo.lastname 
    else
        playerName = GetPlayerName(source)
    end
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." has executed /"..rawCommand:sub(1, 2), '**Command arguments**: '..msg..'\n\n'.."**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
    end
    TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fas fa-ad', 'Ad | '..playerName, msg)
end, false)

-- Tweet
RegisterCommand('twt', function(source, args, rawCommand)
    local playerName
    local msg = rawCommand:sub(5)
    if config.emoji.twt then
        for _, em in ipairs(emoji) do
            for _, code in ipairs(em[1]) do
                local emojiCode = string.gsub(code, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special characters in the emoji code
                msg = string.gsub(msg, emojiCode, em[2]) -- Replace the emoji code with the corresponding emoji character
            end
        end
    end
    if ccChat:checkSpam(source, msg) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    if config.discord then
        playerName = "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        playerName = xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        playerName = xPlayer.PlayerData.charinfo.firstname .. "," .. xPlayer.PlayerData.charinfo.lastname 
    else
        playerName = GetPlayerName(source)
    end
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." has executed /"..rawCommand:sub(1, 3), '**Command arguments**: '..msg..'\n\n'.."**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
    end
    TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fa-brands fa-twitter', '@'..playerName, msg)
end, false)

-- Anon
RegisterCommand('anon', function(source, args, rawCommand)
    local playerName
    local msg = rawCommand:sub(5)
    if config.emoji.anon then
        for _, em in ipairs(emoji) do
            for _, code in ipairs(em[1]) do
                local emojiCode = string.gsub(code, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special characters in the emoji code
                msg = string.gsub(msg, emojiCode, em[2]) -- Replace the emoji code with the corresponding emoji character
            end
        end
    end
    if ccChat:checkSpam(source, msg) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    if config.discord then
        playerName = "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        playerName = xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        playerName = xPlayer.PlayerData.charinfo.firstname .. "," .. xPlayer.PlayerData.charinfo.lastname 
    else
        playerName = GetPlayerName(source)
    end
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." has executed /"..rawCommand:sub(1, 4), '**Command arguments**: '..msg..'\n\n'.."**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
    end
    TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fa-solid fa-mask', 'Anonymous | '.. source, msg)
end, false)

-- Pre-fetch Discord avatars when players join (for test mode)
-- Run in a separate thread to avoid blocking player connection
CreateThread(function()
    AddEventHandler('playerJoining', function()
        local source = source
        -- Run in background thread, don't block connection
        CreateThread(function()
            Citizen.Wait(5000) -- Wait longer to ensure player is fully connected
            
            if config.discordAvatar and config.discordAvatar.testMode then
                local discordId = GetPlayerIdentifier(source, 2) -- discord:xxxxx format
                if discordId and discordId:find("discord:") then
                    local userId = discordId:gsub("discord:", "")
                    if userId and userId ~= "" then
                        -- Check if this is a test Discord ID
                        local isTestId = false
                        if config.discordAvatar.testDiscordIds then
                            for _, testId in ipairs(config.discordAvatar.testDiscordIds) do
                                if tostring(userId) == tostring(testId) then
                                    isTestId = true
                                    break
                                end
                            end
                        end
                        
                        if isTestId then
                            print(string.format("[cc-rpchat] Pre-fetching Discord avatar for user %s (test mode)", userId))
                            fetchDiscordAvatar(userId, true)
                        end
                    end
                end
            end
        end)
    end)
end)

-- Player join and leave messages
if config.connectionMessages then
    AddEventHandler('playerJoining', function()
        local playerName
        playerName = GetPlayerName(source)
        TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fa-solid fa-plus', playerName..' joined.', '', false)
        if config.DiscordWebhook then
            sendToDiscord(3329330, playerName.." has joined!", "**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
        end
    end)

    AddEventHandler('playerDropped', function(reason)
        local playerName
        playerName = GetPlayerName(source)
        TriggerClientEvent('cc-rpchat:addMessage', -1, '#FFD700', 'fa-solid fa-minus', playerName..' left (' .. reason .. ')', '', false)
        if config.DiscordWebhook then
            sendToDiscord(13644844, playerName.." has disconnected ("..reason..")!", "**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'add a custom footer')
        end
    end)
end

-- Staff Chat System
local staffChatMessages = {}
local messageIdCounter = 0
local typingUsers = {}
local staffList = {}

-- Generate unique message ID
local function generateMessageId()
    messageIdCounter = messageIdCounter + 1
    return tostring(messageIdCounter) .. "_" .. os.time()
end

-- Get player identifier for message tracking
local function getPlayerIdentifier(source)
    if config.qbcore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid or GetPlayerIdentifier(source, 0)
        end
    end
    return GetPlayerIdentifier(source, 0)
end

-- Update staff list
local function updateStaffList()
    staffList = {}
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
            local playerName = getPlayerName(playerIdNum)
            local avatar = getDiscordAvatar(playerIdNum)
            table.insert(staffList, {
                name = playerName,
                avatar = avatar,
                id = playerIdNum
            })
        end
    end
    
    -- Send to all staff
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
            TriggerClientEvent('cc-rpchat:updateStaffList', playerIdNum, staffList)
        end
    end
end

-- Update typing indicator
local function updateTypingIndicator()
    local typingList = {}
    for source, _ in pairs(typingUsers) do
        if GetPlayerName(source) then
            table.insert(typingList, getPlayerName(source))
        else
            typingUsers[source] = nil
        end
    end
    
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
            TriggerClientEvent('cc-rpchat:updateTyping', playerIdNum, typingList)
        end
    end
end

-- Find message by ID
local function findMessageById(messageId)
    for i, msg in ipairs(staffChatMessages) do
        if msg.id == messageId then
            return i, msg
        end
    end
    return nil, nil
end

-- Function to check if player has staff permission (using QBCore permissions like server.cfg)
function hasStaffPermission(source)
    -- If license check is disabled, allow everyone
    if not config.staffChat or not config.staffChat.requireLicense then
        return true
    end
    
    if config.qbcore then
        -- Check QBCore permissions (admin, mod, god) - matches server.cfg structure
        if QBCore.Functions.HasPermission(source, 'god') or 
           QBCore.Functions.HasPermission(source, 'admin') or 
           QBCore.Functions.HasPermission(source, 'mod') then
            return true
        end
        
        -- Also check license system as fallback
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        local hasPermission = false
        for k, v in pairs(config.License) do
            local license = Player.PlayerData.license
            if license == v then
                hasPermission = true
                break
            end
        end
        return hasPermission
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        local hasPermission = false
        for k, v in pairs(config.License) do
            local license = xPlayer.identifier
            if license == v then
                hasPermission = true
                break
            end
        end
        return hasPermission
    else
        -- Default: check if player has admin ace permission as fallback
        return IsPlayerAceAllowed(source, 'command.staff')
    end
    return false
end

-- Function to check if player has staff permissions (admin/mod/god) for announcements
function hasStaffAnnouncementPermission(source)
    if config.qbcore then
        -- Check QBCore permissions (admin, mod, god) - matches server.cfg structure
        return QBCore.Functions.HasPermission(source, 'god') or 
               QBCore.Functions.HasPermission(source, 'admin') or 
               QBCore.Functions.HasPermission(source, 'mod')
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'mod'
        end
    else
        return IsPlayerAceAllowed(source, 'command.staff')
    end
    return false
end

-- Function to get player name
function getPlayerName(source)
    if config.discord then
        return "["..exports.ccDiscordWrapper:getPlayerDiscordHighestRole(source, "name").."] "..GetPlayerName(source)
    elseif config.esx then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getName()
    elseif config.qbcore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    else
        return GetPlayerName(source)
    end
end

-- Cache for Discord avatars to avoid repeated API calls
local discordAvatarCache = {}

-- Storage for custom profile pictures (using license as key for persistence)
local function getCustomAvatarKey(source)
    local license = GetPlayerIdentifier(source, 0) -- license:xxxxx
    if license then
        return 'cc-rpchat:avatar:' .. license
    end
    return nil
end

local function setCustomAvatar(source, url)
    local key = getCustomAvatarKey(source)
    if key then
        SetResourceKvp(key, url)
        -- Update cache immediately
        local discordId = GetPlayerIdentifier(source, 2)
        if discordId and discordId:find("discord:") then
            local userId = discordId:gsub("discord:", "")
            discordAvatarCache[userId] = url
        end
        return true
    end
    return false
end

local function getCustomAvatar(source)
    local key = getCustomAvatarKey(source)
    if key then
        local avatar = GetResourceKvpString(key)
        if avatar and avatar ~= "" then
            return avatar
        end
    end
    return nil
end

local function removeCustomAvatar(source)
    local key = getCustomAvatarKey(source)
    if key then
        DeleteResourceKvp(key)
        -- Clear from cache
        local discordId = GetPlayerIdentifier(source, 2)
        if discordId and discordId:find("discord:") then
            local userId = discordId:gsub("discord:", "")
            discordAvatarCache[userId] = nil
        end
        return true
    end
    return false
end

-- Validate URL format
local function isValidImageUrl(url)
    if not url or url == "" then
        return false, "URL cannot be empty"
    end
    
    -- Check if it's a valid HTTP/HTTPS URL
    if not url:match("^https?://") then
        return false, "URL must start with http:// or https://"
    end
    
    -- Check for common image extensions
    local imageExtensions = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}
    local hasExtension = false
    for _, ext in ipairs(imageExtensions) do
        if url:lower():match(ext .. "%?") or url:lower():match(ext .. "$") then
            hasExtension = true
            break
        end
    end
    
    -- Allow URLs without extension (some CDNs don't use extensions)
    -- But validate the URL structure
    if not url:match("^https?://[%w%.%-]+") then
        return false, "Invalid URL format"
    end
    
    return true, nil
end

-- Function to fetch Discord avatar from API (for testing)
local function fetchDiscordAvatar(userId, isTestId)
    -- Skip if not a test ID and test mode is enabled
    if config.discordAvatar and config.discordAvatar.testMode and not isTestId then
        return
    end
    
    -- Use a public service that fetches Discord user data
    -- Using lanyard API which provides Discord user information publicly
    local url = "https://api.lanyard.rest/v1/users/" .. userId
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local success, data = pcall(json.decode, response)
            if success and data and data.success and data.data then
                local userData = data.data
                if userData.discord_user and userData.discord_user.avatar then
                    local avatarHash = userData.discord_user.avatar
                    local avatarURL = string.format("https://cdn.discordapp.com/avatars/%s/%s.png?size=128", userId, avatarHash)
                    discordAvatarCache[userId] = avatarURL
                    print(string.format("[cc-rpchat] ✓ Fetched real Discord avatar for user %s: %s", userId, avatarURL))
                    return
                end
            end
        end
        
        -- Fallback: Try direct Discord API (may require bot token, but worth trying)
        local discordUrl = "https://discord.com/api/v10/users/" .. userId
        PerformHttpRequest(discordUrl, function(statusCode2, response2, headers2)
            if statusCode2 == 200 and response2 then
                local success2, data2 = pcall(json.decode, response2)
                if success2 and data2 then
                    if data2.avatar then
                        local avatarHash = data2.avatar
                        local avatarURL = string.format("https://cdn.discordapp.com/avatars/%s/%s.png?size=128", userId, avatarHash)
                        discordAvatarCache[userId] = avatarURL
                        print(string.format("[cc-rpchat] ✓ Fetched real Discord avatar for user %s: %s", userId, avatarURL))
                        return
                    end
                end
            end
            -- Final fallback
            local defaultAvatar = string.format("https://cdn.discordapp.com/embed/avatars/%d.png", tonumber(userId) % 5)
            discordAvatarCache[userId] = defaultAvatar
            print(string.format("[cc-rpchat] Using default avatar for user %s", userId))
        end, 'GET', '', {
            ['Content-Type'] = 'application/json',
            ['User-Agent'] = 'FiveM-Discord-Avatar-Fetcher'
        })
    end, 'GET', '', {
        ['Content-Type'] = 'application/json'
    })
end

-- Function to get Discord avatar URL
-- How it works:
-- 1. Checks for custom profile picture first (set by player)
-- 2. Gets Discord ID from player identifier (discord:xxxxx)
-- 3. Tries to use ccDiscordWrapper if available
-- 4. If test mode is enabled, fetches real avatar for test Discord IDs
-- 5. If useRealAvatars is enabled with bot token, fetches real avatar from Discord API
-- 6. Falls back to default embed avatar (unique per user ID, but not their real profile picture)
function getDiscordAvatar(source)
    -- Check for custom avatar first (player-set profile picture)
    local customAvatar = getCustomAvatar(source)
    if customAvatar then
        return customAvatar
    end
    
    local discordId = GetPlayerIdentifier(source, 2) -- discord:xxxxx format
    if discordId and discordId:find("discord:") then
        local userId = discordId:gsub("discord:", "")
        if userId and userId ~= "" then
            -- Check cache first
            if discordAvatarCache[userId] then
                return discordAvatarCache[userId]
            end
            
            -- Option 1: Try to use ccDiscordWrapper if available (if it has avatar functions)
            if config.discord then
                local success, avatar = pcall(function()
                    -- Check if ccDiscordWrapper has avatar functions
                    if exports.ccDiscordWrapper and exports.ccDiscordWrapper.getPlayerDiscordAvatar then
                        return exports.ccDiscordWrapper:getPlayerDiscordAvatar(source)
                    end
                end)
                if success and avatar then
                    discordAvatarCache[userId] = avatar
                    return avatar
                end
            end
            
            -- Option 2: Test mode - fetch real avatar for specific Discord IDs
            if config.discordAvatar and config.discordAvatar.testMode then
                local isTestId = false
                if config.discordAvatar.testDiscordIds then
                    for _, testId in ipairs(config.discordAvatar.testDiscordIds) do
                        if tostring(userId) == tostring(testId) then
                            isTestId = true
                            break
                        end
                    end
                end
                
                if isTestId then
                    -- Fetch real avatar for this test Discord ID
                    fetchDiscordAvatar(userId, true)
                    -- Return default for now, will be updated in cache on next message
                    -- The avatar will be cached and used automatically on subsequent calls
                end
            end
            
            -- Option 3: Use Discord API with bot token (if configured)
            if config.discordAvatar and config.discordAvatar.useRealAvatars and config.discordAvatar.botToken and config.discordAvatar.botToken ~= "" then
                -- Fetch real avatar from Discord API
                local url = "https://discord.com/api/users/" .. userId
                PerformHttpRequest(url, function(statusCode, response, headers)
                    if statusCode == 200 then
                        local data = json.decode(response)
                        if data and data.avatar then
                            local avatarHash = data.avatar
                            local avatarURL = string.format("https://cdn.discordapp.com/avatars/%s/%s.png?size=128", userId, avatarHash)
                            discordAvatarCache[userId] = avatarURL
                        elseif data and not data.avatar then
                            -- User has default avatar, use embed avatar
                            local defaultAvatar = string.format("https://cdn.discordapp.com/embed/avatars/%d.png", tonumber(userId) % 5)
                            discordAvatarCache[userId] = defaultAvatar
                        end
                    end
                end, 'GET', '', {
                    ['Authorization'] = 'Bot ' .. config.discordAvatar.botToken,
                    ['Content-Type'] = 'application/json'
                })
                
                -- Return cached or default while waiting for API response
                if discordAvatarCache[userId] then
                    return discordAvatarCache[userId]
                end
            end
            
            -- Option 4: Fallback to default embed avatar (current implementation)
            -- This generates a unique default avatar based on user ID
            -- Format: https://cdn.discordapp.com/embed/avatars/{user_id % 5}.png
            -- This is NOT the real profile picture, but a unique default avatar per Discord user
            -- Each Discord user ID will always get the same default avatar (0-4 based on ID)
            local defaultAvatar = string.format("https://cdn.discordapp.com/embed/avatars/%d.png", tonumber(userId) % 5)
            discordAvatarCache[userId] = defaultAvatar
            return defaultAvatar
        end
    end
    return nil
end

-- Staff chat command
RegisterCommand('staff', function(source, args, rawCommand)
    -- Check license only if required in config
    if config.staffChat and config.staffChat.requireLicense then
        if not hasStaffPermission(source) then
            TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "You cannot enter the chat room", '', false)
            return
        end
    end
    
    -- Update staff list
    updateStaffList()
    
    -- Open staff chat UI for the player
    TriggerClientEvent('cc-rpchat:openStaffChat', source)
    
    -- Send recent messages to the player
    if #staffChatMessages > 0 then
        local recentMessages = {}
        local startIndex = math.max(1, #staffChatMessages - 49) -- Last 50 messages
        for i = startIndex, #staffChatMessages do
            table.insert(recentMessages, staffChatMessages[i])
        end
        TriggerClientEvent('cc-rpchat:loadStaffMessages', source, recentMessages)
    end
end, false)

-- Handle staff messages
RegisterNetEvent('cc-rpchat:sendStaffMessage', function(message)
    local source = source
    
    -- Check license only if required in config
    if config.staffChat and config.staffChat.requireLicense then
        if not hasStaffPermission(source) then
            TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "You cannot enter the chat room", '', false)
            return
        end
    end
    
    if not message or message:len() == 0 then
        return
    end
    
    -- Check spam
    if ccChat:checkSpam(source, message) and config.antiSpam == true then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Please Don't Spam", '', false)
        return
    end
    
    -- Stop typing indicator
    typingUsers[source] = nil
    updateTypingIndicator()
    
    local playerName = getPlayerName(source)
    -- 12-hour format with AM/PM
    local hour = tonumber(os.date('%H'))
    local minute = os.date('%M')
    local ampm = hour >= 12 and 'PM' or 'AM'
    local hour12 = hour > 12 and (hour - 12) or (hour == 0 and 12 or hour)
    local timestamp = string.format('%02d:%s %s', hour12, minute, ampm)
    local fullTimestamp = os.date('%Y-%m-%d %H:%M:%S')
    local avatarURL = getDiscordAvatar(source)
    local messageId = generateMessageId()
    local senderId = getPlayerIdentifier(source)
    
    -- Store message
    local messageData = {
        id = messageId,
        sender = playerName,
        message = message,
        time = timestamp,
        fullTimestamp = fullTimestamp,
        avatar = avatarURL,
        senderId = senderId,
        pinned = false,
        reactions = {},
        edited = false
    }
    
    table.insert(staffChatMessages, messageData)
    
    -- Keep only last 100 messages
    if #staffChatMessages > 100 then
        table.remove(staffChatMessages, 1)
    end
    
    -- Send to all staff members (or all players if license not required)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        -- If license is required, only send to players with license. Otherwise send to everyone.
        if not config.staffChat or not config.staffChat.requireLicense then
            TriggerClientEvent('cc-rpchat:receiveStaffMessage', playerIdNum, playerName, message, timestamp, avatarURL, messageId, false, {}, false, fullTimestamp, senderId)
        elseif hasStaffPermission(playerIdNum) then
            TriggerClientEvent('cc-rpchat:receiveStaffMessage', playerIdNum, playerName, message, timestamp, avatarURL, messageId, false, {}, false, fullTimestamp, senderId)
        end
    end
    
    -- Discord webhook if enabled
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." [Staff Chat]", "**Message**: "..message.."\n\n**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'Staff Chat')
    end
end)

-- Typing status
RegisterNetEvent('cc-rpchat:typingStatus', function(typing)
    local source = source
    
    if not hasStaffPermission(source) and config.staffChat and config.staffChat.requireLicense then
        return
    end
    
    if typing then
        typingUsers[source] = true
    else
        typingUsers[source] = nil
    end
    
    updateTypingIndicator()
end)

-- Edit message
RegisterNetEvent('cc-rpchat:editMessage', function(messageId, newMessage)
    local source = source
    
    if not hasStaffPermission(source) and config.staffChat and config.staffChat.requireLicense then
        return
    end
    
    local index, msg = findMessageById(messageId)
    if not msg then return end
    
    -- Check if user owns the message or has staff permission
    local senderId = getPlayerIdentifier(source)
    if msg.senderId ~= senderId and not hasStaffAnnouncementPermission(source) then
        return
    end
    
    if not newMessage or newMessage:len() == 0 then
        return
    end
    
    msg.message = newMessage
    msg.edited = true
    -- 12-hour format with AM/PM
    local hour = tonumber(os.date('%H'))
    local minute = os.date('%M')
    local ampm = hour >= 12 and 'PM' or 'AM'
    local hour12 = hour > 12 and (hour - 12) or (hour == 0 and 12 or hour)
    msg.time = string.format('%02d:%s %s', hour12, minute, ampm)
    msg.fullTimestamp = os.date('%Y-%m-%d %H:%M:%S')
    
    -- Update all clients
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
            TriggerClientEvent('cc-rpchat:updateMessage', playerIdNum, messageId, newMessage, true)
        end
    end
end)

-- Delete message
RegisterNetEvent('cc-rpchat:deleteMessage', function(messageId)
    local source = source
    
    if not messageId or messageId == "" then
        return
    end
    
    -- Check license only if required in config
    if config.staffChat and config.staffChat.requireLicense then
        if not hasStaffPermission(source) then
            return
        end
    end
    
    local success, index, msg = pcall(function()
        return findMessageById(messageId)
    end)
    
    if not success or not index or not msg then
        return
    end
    
    -- Check if user owns the message or has staff permission
    local senderId = getPlayerIdentifier(source)
    if msg.senderId ~= senderId and not hasStaffAnnouncementPermission(source) then
        return
    end
    
    -- Remove message safely
    pcall(function()
        table.remove(staffChatMessages, index)
    end)
    
    -- Update all clients
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if playerIdNum then
            if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
                TriggerClientEvent('cc-rpchat:removeMessage', playerIdNum, messageId)
            end
        end
    end
end)

-- Pin message
RegisterNetEvent('cc-rpchat:pinMessage', function(messageId)
    local source = source
    
    if not messageId or messageId == "" then
        return
    end
    
    -- Check license only if required in config
    if config.staffChat and config.staffChat.requireLicense then
        if not hasStaffPermission(source) then
            return
        end
    end
    
    -- Only staff with announcement permission can pin
    if not hasStaffAnnouncementPermission(source) then
        return
    end
    
    local success, index, msg = pcall(function()
        return findMessageById(messageId)
    end)
    
    if not success or not index or not msg then
        return
    end
    
    msg.pinned = not msg.pinned
    
    -- Reload messages for all clients (in a thread to prevent blocking)
    CreateThread(function()
        local players = GetPlayers()
        local recentMessages = {}
        local startIndex = math.max(1, #staffChatMessages - 49)
        for i = startIndex, #staffChatMessages do
            table.insert(recentMessages, staffChatMessages[i])
        end
        
        for _, playerId in ipairs(players) do
            local playerIdNum = tonumber(playerId)
            if playerIdNum then
                if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
                    TriggerClientEvent('cc-rpchat:loadStaffMessages', playerIdNum, recentMessages)
                end
            end
        end
    end)
end)

-- Toggle reaction
RegisterNetEvent('cc-rpchat:toggleReaction', function(messageId, emoji)
    local source = source
    
    if not hasStaffPermission(source) and config.staffChat and config.staffChat.requireLicense then
        return
    end
    
    local index, msg = findMessageById(messageId)
    if not msg then return end
    
    if not msg.reactions then
        msg.reactions = {}
    end
    
    if not msg.reactions[emoji] then
        msg.reactions[emoji] = {}
    end
    
    local senderId = getPlayerIdentifier(source)
    local found = false
    for i, id in ipairs(msg.reactions[emoji]) do
        if id == senderId then
            table.remove(msg.reactions[emoji], i)
            found = true
            break
        end
    end
    
    if not found then
        table.insert(msg.reactions[emoji], senderId)
    end
    
    -- Remove empty reactions
    if #msg.reactions[emoji] == 0 then
        msg.reactions[emoji] = nil
    end
    
    -- Update all clients
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if not config.staffChat or not config.staffChat.requireLicense or hasStaffPermission(playerIdNum) then
            TriggerClientEvent('cc-rpchat:updateReactions', playerIdNum, messageId, msg.reactions)
        end
    end
end)

-- Request avatar settings from UI
RegisterNetEvent('cc-rpchat:requestAvatarSettings', function()
    local source = source
    local currentAvatar = getCustomAvatar(source)
    TriggerClientEvent('cc-rpchat:loadAvatarSettings', source, currentAvatar or "")
end)

-- Save avatar from UI
RegisterNetEvent('cc-rpchat:saveAvatar', function(url)
    local source = source
    
    if not url or url == "" then
        TriggerClientEvent('cc-rpchat:avatarSaved', source, nil)
        return
    end
    
    -- Validate URL
    local isValid, errorMsg = isValidImageUrl(url)
    if not isValid then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Invalid URL: " .. (errorMsg or "Please provide a valid image URL"), '', false)
        return
    end
    
    -- Set the custom avatar
    if setCustomAvatar(source, url) then
        TriggerClientEvent('cc-rpchat:avatarSaved', source, url)
        print(string.format("[cc-rpchat] Player %s (%s) set custom avatar via UI: %s", GetPlayerName(source), GetPlayerIdentifier(source, 0), url))
    else
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Failed to set profile picture. Please try again.", '', false)
    end
end)

-- Remove avatar from UI
RegisterNetEvent('cc-rpchat:removeAvatar', function()
    local source = source
    if removeCustomAvatar(source) then
        TriggerClientEvent('cc-rpchat:avatarRemoved', source)
        print(string.format("[cc-rpchat] Player %s (%s) removed custom avatar via UI", GetPlayerName(source), GetPlayerIdentifier(source, 0)))
    else
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "No custom avatar to remove.", '', false)
    end
end)

-- Request staff list
RegisterNetEvent('cc-rpchat:requestStaffList', function()
    local source = source
    updateStaffList()
end)

-- Update staff list on player connect/disconnect
AddEventHandler('playerJoining', function()
    Wait(2000)
    updateStaffList()
end)

AddEventHandler('playerDropped', function()
    local source = source
    typingUsers[source] = nil
    updateTypingIndicator()
    Wait(1000)
    updateStaffList()
end)

-- Staff Announcement Command
RegisterCommand('staffannounce', function(source, args, rawCommand)
    if not hasStaffAnnouncementPermission(source) then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "You don't have permission to use this command", '', false)
        return
    end
    
    if not args or #args == 0 then
        TriggerClientEvent('cc-rpchat:addMessage', source, '#e67e22', 'fa-solid fa-triangle-exclamation', "Usage: /staffannounce [message]", '', false)
        return
    end
    
    local message = table.concat(args, ' ')
    local playerName = getPlayerName(source)
    local avatarURL = getDiscordAvatar(source)
    
    -- Send notification to all staff members (admin/mod/god)
    -- Only send notifications, NOT to staff chat
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if hasStaffAnnouncementPermission(playerIdNum) then
            TriggerClientEvent('cc-rpchat:staffAnnouncement', playerIdNum, playerName, message, avatarURL)
        end
    end
    
    -- Discord webhook if enabled
    if config.DiscordWebhook then
        sendToDiscord(16753920, playerName.." [Staff Announcement]", "**Message**: "..message.."\n\n**Identifiers**: \n"..GetPlayerIdentifier(source, 0).."\n"..GetPlayerIdentifier(source, 1).."\n<@"..GetPlayerIdentifier(source, 2):sub(9)..">\n"..GetPlayerIdentifier(source, 3), 'Staff Announcement')
    end
end, false)

-- Discord webhook *** REQUIRED ccDiscordWrapper ***
function sendToDiscord(color, name, message, footer)
    exports["ccDiscordWrapper"]:webhookSendNewMessage(color, name, message, footer)
end

