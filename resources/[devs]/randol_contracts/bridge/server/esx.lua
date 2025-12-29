if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

function GetPlayer(id)
    return ESX.GetPlayerFromId(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('esx:showNotification', src, text, nType)
end

function GetPlyIdentifier(xPlayer)
    return xPlayer.identifier
end

function GetSourceFromIdentifier(cid)
    local xPlayer = ESX.GetPlayerFromIdentifier(cid)
    return xPlayer and xPlayer.source or false
end

function GetCharacterName(xPlayer)
    return xPlayer.getName()
end

function ReturnPhotoEvidence(xPlayer, cid)
    local src = xPlayer.source
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

function AddPhotoItem(xPlayer, metadata)
    exports.ox_inventory:AddItem(xPlayer.source, Config.PhotographItemName, 1, metadata)
end