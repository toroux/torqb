if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = GetResourceState('ox_inventory') == 'started'

function GetPlayer(id)
    return QBCore.Functions.GetPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('QBCore:Notify', src, text, nType)
end

function GetPlyIdentifier(Player)
    return Player.PlayerData.citizenid
end

function GetSourceFromIdentifier(cid)
    local Player = QBCore.Functions.GetPlayerByCitizenId(cid)
    return Player and Player.PlayerData.source or false
end

function GetCharacterName(Player)
    return Player.PlayerData.charinfo.firstname.. ' ' ..Player.PlayerData.charinfo.lastname
end

function ReturnPhotoEvidence(Player, cid)
    local src = Player.PlayerData.source
    if ox_inv then
        local item = exports.ox_inventory:GetSlotWithItem(src, Config.PhotographItemName)
        if item then
            if Config.Debug then Config.debugShit(json.encode(item, {indent = true})) end
            if item.metadata.photoModel and item.metadata.photoModel == assignedContract[cid].target then
                exports.ox_inventory:RemoveItem(src, item.name, 1)
                exports.ox_inventory:AddItem(src, 'money', item.metadata.giveCash)
                return true, item.metadata.giveCash
            end
        end
    else
        local item = Player.Functions.GetItemByName(Config.PhotographItemName)
        if item then
            if Config.Debug then Config.debugShit(json.encode(item, {indent = true})) end
            if item.info.photoModel and item.info.photoModel == assignedContract[cid].target then
                Player.Functions.RemoveItem(item.name, 1, item.slot)
                TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[item.name], "remove", 1)
                Player.Functions.AddMoney('cash', item.info.giveCash)
                return true, item.info.giveCash
            end
        end
    end
    return false
end

function AddPhotoItem(Player, metadata)
    if ox_inv then
        exports.ox_inventory:AddItem(Player.PlayerData.source, Config.PhotographItemName, 1, metadata)
    else
        Player.Functions.AddItem(Config.PhotographItemName, 1, false, metadata)
        TriggerClientEvent("inventory:client:ItemBox", Player.PlayerData.source, QBCore.Shared.Items[Config.PhotographItemName], "add")
    end
end