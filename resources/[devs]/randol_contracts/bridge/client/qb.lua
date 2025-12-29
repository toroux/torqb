if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = GetResourceState('ox_inventory') == 'started'
local PlayerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    TriggerEvent('randol_hit:OnPlayerLoaded')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    table.wipe(PlayerData)
    TriggerEvent('randol_hit:OnPlayerUnload')
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not LocalPlayer.state.isLoggedIn then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    TriggerEvent('randol_hit:onResourceStart')
end)

function handleVehicleKeys(veh)
    local plate = GetVehicleNumberPlateText(veh)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
end

function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function hasItem(item)
    if ox_inv then
        local count = exports.ox_inventory:Search('count', item)
        return count and count > 0
    else
        return QBCore.Functions.HasItem(item)
    end
end

function DoNotification(text, nType)
    QBCore.Functions.Notify(text, nType)
end
