if GetResourceState('ND_Core') ~= 'started' then return end

local NDCore = exports['ND_Core']

function GetPlayer(id)
    return NDCore:getPlayer(id)
end

function DoNotification(src, text, nType)
    local player = NDCore:getPlayer(src)
    if not player then return end
    player.notify({ title = text, type = nType })
end

function GetPlyIdentifier(player)
    return player?.id
end

function GetSourceFromIdentifier(cid)
    local players = NDCore:getPlayers() -- old method kept returning false, fuck knows.
    for _, info in pairs(players) do
        if info.id == cid then
            return info.source
        end
    end
    return false
end

function GetCharacterName(player)
    return player?.fullname
end

function ReturnPhotoEvidence(player, cid)
    local src = player?.source
    local item = exports.ox_inventory:GetSlotWithItem(src, Config.PhotographItemName)
    if item then
        if Config.Debug then Config.debugShit(json.encode(item, {indent = true})) end
        
        if item.metadata.photoModel and item.metadata.photoModel == assignedContract[cid].target then
            exports.ox_inventory:RemoveItem(src, item.name, 1)
            exports.ox_inventory:AddItem(src, 'money', item.metadata.giveCash)
            return true, item.metadata.giveCash
        end
    end
    return false
end

function AddPhotoItem(player, metadata)
    exports.ox_inventory:AddItem(player.source, Config.PhotographItemName, 1, metadata)
end