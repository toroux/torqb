if GetResourceState('ND_Core') ~= 'started' then return end

local NDCore = exports['ND_Core']

RegisterNetEvent('ND:characterUnloaded', function()
    LocalPlayer.state.isLoggedIn = false
    TriggerEvent('randol_hit:OnPlayerUnload')
end)

RegisterNetEvent('ND:characterLoaded', function(character)
    LocalPlayer.state.isLoggedIn = true
    TriggerEvent('randol_hit:OnPlayerLoaded')
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not LocalPlayer.state.isLoggedIn then return end
    TriggerEvent('randol_hit:onResourceStart')
end)

function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function hasItem(item)
    local count = exports.ox_inventory:Search('count', item)
    return count and count > 0
end

function DoNotification(text, nType)
    local player = NDCore:getPlayer()
    if player then
        player.notify({ title = "Notification", description = text, type = nType })
    end
end