local currentRecoil = {}
local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false

RegisterNetEvent('derrick_gun_damage:client:setWeaponDamage', function(weapons)
    for k, v in pairs(weapons) do
        SetWeaponDamageModifier(v.weapon, v.damage)
    end
    
end)

RegisterNetEvent('derrick_gun_damage:client:setWeaponDamageSolo', function(data)
    SetWeaponDamageModifier(data.weapon, data.damage)
    
end)

RegisterNetEvent('derrick_gun_damage:client:setWeaponRecoilSolo', function(data)
    currentRecoil[data.weapon] = data.recoil
end)

RegisterCommand('tuneweapon', function()
    if isUIOpen then
        CloseUI()
    else
        TriggerServerEvent('derrick_gun_damage:server:checkPermission')
    end
end, false)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('getPlayerWeapons', function(data, cb)
    TriggerServerEvent('derrick_gun_damage:server:getPlayerWeapons')
    cb('ok')
end)

RegisterNUICallback('getWeaponStats', function(data, cb)
    local weapon = data.weapon
    if not weapon then
        cb({})
        return
    end
    
    -- Get current damage and recoil from server
    TriggerServerEvent('derrick_gun_damage:server:getWeaponStats', weapon)
    
    -- We'll receive the stats via a client event
    cb({})
end)

RegisterNUICallback('applyTuning', function(data, cb)
    local weapon = data.weapon
    local damage = data.damage
    local recoil = data.recoil
    
    if weapon and damage and recoil then
        TriggerServerEvent('derrick_gun_damage:server:applyTuning', weapon, damage, recoil)
    end
    
    cb('ok')
end)

RegisterNUICallback('getWeapons', function(data, cb)
    TriggerServerEvent('derrick_gun_damage:server:getAllWeapons')
    cb('ok')
end)

-- Events from server
RegisterNetEvent('derrick_gun_damage:client:weaponStats', function(weapon, damage, recoil)
    SendNUIMessage({
        action = 'updateWeaponStats',
        damage = damage,
        recoil = recoil
    })
end)

RegisterNetEvent('derrick_gun_damage:client:allWeapons', function(weapons)
    SendNUIMessage({
        action = 'updateWeaponsList',
        weapons = weapons
    })
end)

function OpenUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    -- Default RGBBorders to RGB value if not explicitly set
    local rgbBorders = Config.UI.RGBBorders
    if rgbBorders == nil then
        rgbBorders = Config.UI.RGB or false
    end
    
    SendNUIMessage({
        action = 'open',
        logoURL = Config.UI.LogoURL,
        baseColor = Config.UI.BaseColor,
        rgbEnabled = Config.UI.RGB or false,
        rgbBordersEnabled = rgbBorders
    })
    
    -- Request player weapons
    CreateThread(function()
        Wait(100)
        TriggerServerEvent('derrick_gun_damage:server:getPlayerWeapons')
    end)
end

function CloseUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'close'
    })
end

RegisterNetEvent('derrick_gun_damage:client:updateWeaponList', function(weapons)
    SendNUIMessage({
        action = 'updateWeaponList',
        weapons = weapons
    })
end)

RegisterNetEvent('derrick_gun_damage:client:permissionGranted', function()
    OpenUI()
end)

RegisterNetEvent('derrick_gun_damage:client:permissionDenied', function()
    QBCore.Functions.Notify("You do not have permission to use this command.", 'error')
end)


function ApplyRecoil(weaponx, recoil)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == GetHashKey(weaponx) or weapon == weaponx then
        local tv = 0
        if GetFollowPedCamViewMode() ~= 4 then
            repeat 
                Wait(0)
                local p = GetGameplayCamRelativePitch()
                SetGameplayCamRelativePitch(p + 0.1, 0.2)
                tv = tv + 0.1
            until tv >= recoil
        else
            repeat 
                Wait(0)
                local p = GetGameplayCamRelativePitch()
                if recoil > 0.1 then
                    SetGameplayCamRelativePitch(p + 0.6, 1.2)
                    tv = tv + 0.6
                else
                    SetGameplayCamRelativePitch(p + 0.016, 0.333)
                    tv = tv + 0.016
                end
            until tv >= recoil
        end
    end
end

RegisterNetEvent('derrick_gun_damage:client:setWeaponRecoil', function(recoilData)
    for _, data in ipairs(recoilData) do
        local weapon = data.weapon
        local recoil = data.recoil
        currentRecoil[weapon] = recoil
    end
end)

CreateThread(function()
    while true do
        if IsPedShooting(PlayerPedId()) and not IsPedDoingDriveby(PlayerPedId()) then
            for weapon, recoil in pairs(currentRecoil) do
                ApplyRecoil(weapon, recoil)
            end
        end
        Wait(0)
    end
end)