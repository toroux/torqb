local QBCore = exports['qb-core']:GetCoreObject()
local airDrops = {}
local itemDashboardUsers = {}
local adminsWithUIOpen = {}

local Webhooks = require('server.webhooks')
local sendDiscordWebhook = Webhooks.sendDiscordWebhook
local sendCollectionWebhook = Webhooks.sendCollectionWebhook

local function hasPermission(source, requiredPermission)
    return QBCore.Functions.HasPermission(source, requiredPermission)
end

local function syncAirdropsToAdmins(excludeSource)
    excludeSource = excludeSource or -1
    local airdropsForUI = {}
    for dropId, drop in pairs(airDrops) do
        if drop and drop.coords then
            airdropsForUI[dropId] = {
                dropId = dropId,
                coords = {
                    x = drop.coords.x or drop.coords[1] or 0,
                    y = drop.coords.y or drop.coords[2] or 0,
                    z = drop.coords.z or drop.coords[3] or 0
                },
                unlocked = drop.unlocked or false,
                dropType = drop.dropType or "normal",
                creatorName = drop.creatorName or "Unknown"
            }
        end
    end
    
    for adminSrc, _ in pairs(adminsWithUIOpen) do
        local shouldSend = (excludeSource == -1) or (adminSrc ~= excludeSource)
        if shouldSend then
            if GetPlayerPed(adminSrc) ~= 0 then
                TriggerClientEvent('diro_drops:client:updateAirdrops', adminSrc, airdropsForUI)
            else
                adminsWithUIOpen[adminSrc] = nil
            end
        end
    end
end

local function uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function createDashboardDrop(source, x, y, z, hours, minutes, seconds, rewards, dropType, radius, colorHex, creatorName)
    local dropId = uuid()
    local coords = vector3(tonumber(x), tonumber(y), tonumber(z))
    
    local dummy = {}
    for _, reward in ipairs(rewards) do
        table.insert(dummy, {item = reward.item, quantity = reward.quantity})
    end
    
    local time = ((tonumber(hours) * 3600) + (tonumber(minutes) * 60) + tonumber(seconds)) * 1000
    local dropTypeValue = dropType or "normal"
    local radiusValue = math.max(75.0, radius and tonumber(radius) or 75.0)
    
    airDrops[dropId] = {
        unlocked = false,
        items = dummy,
        coords = coords,
        dropType = dropTypeValue,
        radius = radiusValue,
        colorHex = colorHex,
        creatorName = creatorName or "Unknown",
    }
    
    local dropData = {
        dropId = dropId,
        coords = coords,
        time = time,
        dropType = dropTypeValue,
        radius = radiusValue,
        colorHex = colorHex,
    }
    
    if dropTypeValue == "gold" then
        TriggerClientEvent("dior_airdrop:client:createLootBox", source, dropData)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local playerIdNum = tonumber(playerId)
            if playerIdNum and playerIdNum ~= source then
                local targetPlayer = QBCore.Functions.GetPlayer(playerIdNum)
                if targetPlayer then
                    local gang = targetPlayer.PlayerData.gang
                    local job = targetPlayer.PlayerData.job
                    if (gang and gang.name ~= "none") or (job and (job.name == "police" or job.name == "ambulance")) then
                        TriggerClientEvent("dior_airdrop:client:createLootBox", playerIdNum, dropData)
                    end
                end
            end
        end
    else
        TriggerClientEvent("dior_airdrop:client:createLootBox", -1, dropData)
    end
    
    Citizen.SetTimeout(time, function()
        if airDrops[dropId] then
            airDrops[dropId].unlocked = true
            TriggerClientEvent('dior_airdrop:client:dropUnlocked', -1, dropId)
            syncAirdropsToAdmins(-1)
        end
    end)
    
    TriggerClientEvent('QBCore:Notify', source, "Airdrop created successfully!", "success")
    syncAirdropsToAdmins(-1)
end

RegisterServerEvent('dior_airdrop:server:createCustomDrop')
AddEventHandler('dior_airdrop:server:createCustomDrop', function(data)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    local bypassPermission = itemDashboardUsers[src] == true
    if bypassPermission then
        itemDashboardUsers[src] = nil
    end
    
    if not xPlayer or (not bypassPermission and not hasPermission(src, 'admin')) then
        TriggerClientEvent('QBCore:Notify', src, "You don't have permission to create airdrops.", "error")
        return
    end
    
    if #data.rewards == 0 then
        TriggerClientEvent('dior_airdrop:client:dropCreationError', src, "Error: No items provided for the airdrop.")
        return
    end
    
    local cleanRewards = {}
    local invalidItems = {}
    
    for _, reward in ipairs(data.rewards) do
        local itemName = reward.item
        local quantity = math.max(1, tonumber(reward.quantity) or 1)
        
        local itemExists = false
        if exports.ox_inventory then
            local oxItems = exports.ox_inventory:Items()
            if oxItems and oxItems[itemName] then
                itemExists = true
            else
                local weaponsData = exports.ox_inventory:Weapons()
                if weaponsData and weaponsData[itemName] then
                    itemExists = true
                end
            end
        elseif QBCore.Shared.Items and QBCore.Shared.Items[itemName] then
            itemExists = true
        end
        
        if itemExists then
            table.insert(cleanRewards, {item = itemName, quantity = quantity})
        else
            table.insert(invalidItems, itemName)
        end
    end
    
    if #invalidItems > 0 then
        TriggerClientEvent('dior_airdrop:client:dropCreationError', src, "Invalid items: " .. table.concat(invalidItems, ", "))
        return
    elseif #cleanRewards == 0 then
        TriggerClientEvent('dior_airdrop:client:dropCreationError', src, "Error: No valid items provided for the airdrop.")
        return
    end
    
    local hours = tonumber(data.hours) or 0
    local minutes = tonumber(data.minutes) or 0
    local seconds = tonumber(data.seconds) or 0
    local totalSeconds = hours * 3600 + minutes * 60 + seconds
    
    if totalSeconds == 0 then
        TriggerClientEvent('dior_airdrop:client:dropCreationError', src, "Error: Invalid time provided. Please set a time for the airdrop.")
        return
    end
    
    local adminName = GetPlayerName(src)
    local adminLicense = xPlayer.PlayerData.license
    local dropCoords = vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z))
    local dropType = data.dropType or "normal"
    local radius = data.radius and tonumber(data.radius) or nil
    local colorHex = data.colorHex or nil
    
    sendDiscordWebhook(adminName, src, adminLicense, "airdropdash", dropCoords, 1)
    
    if itemDashboardUsers[src] or hasPermission(src, 'admin') then
        adminsWithUIOpen[src] = true
    end
    
    createDashboardDrop(src, data.x, data.y, data.z, hours, minutes, seconds, cleanRewards, dropType, radius, colorHex, adminName)
end)

RegisterServerEvent("dior_airdrop:server:startClaiming")
AddEventHandler("dior_airdrop:server:startClaiming", function(dropId)
    if not airDrops[dropId] or not airDrops[dropId].coords then return end
    
    local src = source
    local drop = airDrops[dropId]
    local dropCoords = drop.coords
    local radius = drop.radius or 75.0
    local dropType = drop.dropType or "normal"
    
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end
    
    local charInfo = xPlayer.PlayerData.charinfo
    local claimerName = (charInfo.firstname or "") .. " " .. (charInfo.lastname or "")
    if claimerName == " " then
        claimerName = GetPlayerName(src)
    end
    
    local gangName = nil
    if dropType == "gold" then
        local gang = xPlayer.PlayerData.gang
        if gang and gang.name and gang.name ~= "none" then
            gangName = gang.name
        end
    end
    
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdNum = tonumber(playerId)
        if playerIdNum then
            local targetPed = GetPlayerPed(playerIdNum)
            if targetPed ~= 0 then
                local targetCoords = GetEntityCoords(targetPed)
                if #(targetCoords - dropCoords) <= radius then
                    TriggerClientEvent('dior_airdrop:client:claimingNotification', playerIdNum, claimerName, gangName)
                end
            end
        end
    end
end)

RegisterServerEvent("dior_airdrop:server:openCrate", function(dropId)
    local src = source
    local Player = kCore.getPlayer(src)
    local NewPlayer = QBCore.Functions.GetPlayer(src)

    if not airDrops[dropId] then
        return Player.showNotification(kCore.getPhrase("drop-not-found"))
    end

    if not airDrops[dropId].unlocked then
        return Player.showNotification(kCore.getPhrase("time-is-not-up"))
    end

    local dropCoords = airDrops[dropId].coords or vector3(0, 0, 0)
    local receivedItems = {}
    
    for k, v in pairs(airDrops[dropId].items) do
        local itemName = v.item or v[1]
        local quantity = v.quantity or 1
        
        if exports.ox_inventory then
            local isWeapon = itemName:upper():sub(1, 7) == "WEAPON_"
            if isWeapon then
                for i = 1, quantity do
                    exports.ox_inventory:AddItem(src, itemName, 1)
                end
            else
                exports.ox_inventory:AddItem(src, itemName, quantity)
            end
        else
            Player.addItem(itemName, quantity)
        end
        
        Player.showNotification(kCore.getPhrase("collected-item"):format(quantity, itemName))
        table.insert(receivedItems, quantity .. "x " .. itemName)
    end

    if math.random(1, 150) == math.random(1, 150) then
        if exports.ox_inventory then
            exports.ox_inventory:AddItem(src, "pcb", 1)
        else
            Player.addItem("pcb", 1)
        end
        Player.showNotification(kCore.getPhrase("collected-item"):format("PCB", 1))
        table.insert(receivedItems, "1x PCB")
    end

    local playerName = GetPlayerName(src)
    local playerLicense = NewPlayer.PlayerData.license or "Unknown"
    
    local charInfo = NewPlayer.PlayerData.charinfo
    local looterName = (charInfo.firstname or "") .. " " .. (charInfo.lastname or "")
    if looterName == " " then
        looterName = playerName
    end
    
    sendCollectionWebhook(playerName, src, playerLicense, receivedItems, dropCoords)
    
    local dropIdToRemove = dropId
    airDrops[dropId] = nil
    syncAirdropsToAdmins(-1)
    TriggerClientEvent("dior_airdrop:client:dropCollected", -1, dropIdToRemove, looterName)
end)

RegisterServerEvent("dior_airdrop:server:confirmDeletion")
AddEventHandler("dior_airdrop:server:confirmDeletion", function(dropId)
    if airDrops[dropId] then
        airDrops[dropId] = nil
        syncAirdropsToAdmins(-1)
    end
end)

QBCore.Commands.Add("airdropdash", "Open the airdrop creation dashboard - select drop type in UI (Head Admin Only!)", {}, false, function(source, args)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    if xPlayer and hasPermission(src, 'admin') then
        itemDashboardUsers[src] = nil
        adminsWithUIOpen[src] = true
        TriggerClientEvent("dior_airdrop:client:openDashboard", src)
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have permission to use this command.", "error")
    end
end, "admin")

RegisterServerEvent('dior_airdrop:server:useItem')
AddEventHandler('dior_airdrop:server:useItem', function()
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    if xPlayer then
        itemDashboardUsers[src] = true
        if hasPermission(src, 'admin') or itemDashboardUsers[src] then
            adminsWithUIOpen[src] = true
        end
        TriggerClientEvent("dior_airdrop:client:openDashboard", src)
    end
end)

QBCore.Functions.CreateUseableItem("airdropdashboard", function(source, item)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    if xPlayer then
        itemDashboardUsers[src] = true
        if hasPermission(src, 'admin') or itemDashboardUsers[src] then
            adminsWithUIOpen[src] = true
        end
        TriggerClientEvent("dior_airdrop:client:openDashboard", src)
    end
end)

RegisterServerEvent('dior_airdrop:server:closeDashboard')
AddEventHandler('dior_airdrop:server:closeDashboard', function()
    local src = source
    itemDashboardUsers[src] = nil
    adminsWithUIOpen[src] = nil
end)

RegisterServerEvent('diro_drops:server:requestAirdrops')
AddEventHandler('diro_drops:server:requestAirdrops', function()
    local src = source
    if not hasPermission(src, 'admin') and not itemDashboardUsers[src] then return end
    
    adminsWithUIOpen[src] = true
    
    local airdropsForUI = {}
    for dropId, drop in pairs(airDrops) do
        if drop and drop.coords then
            airdropsForUI[dropId] = {
                dropId = dropId,
                coords = {
                    x = drop.coords.x or drop.coords[1] or 0,
                    y = drop.coords.y or drop.coords[2] or 0,
                    z = drop.coords.z or drop.coords[3] or 0
                },
                unlocked = drop.unlocked or false,
                dropType = drop.dropType or "normal",
                creatorName = drop.creatorName or "Unknown"
            }
        end
    end
    TriggerClientEvent('diro_drops:client:updateAirdrops', src, airdropsForUI)
end)

RegisterServerEvent('diro_drops:server:deleteAirdrop')
AddEventHandler('diro_drops:server:deleteAirdrop', function(dropId)
    local src = source
    if not hasPermission(src, 'admin') and not itemDashboardUsers[src] then return end
    
    if not airDrops[dropId] then
        return
    end
    
    local dropIdToRemove = dropId
    airDrops[dropId] = nil
    syncAirdropsToAdmins(-1)
    TriggerClientEvent("dior_airdrop:client:dropCollected", -1, dropIdToRemove)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    airDrops = {}
end)
