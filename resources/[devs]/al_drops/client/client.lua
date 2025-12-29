local QBCore = exports['qb-core']:GetCoreObject()
airDrops = {}
local progress = false

local function getDropZoneNotification(dropType)
    if dropType == "gold" then
        return {title = "Gang-Only Airdrop", description = "Only gangs can open this drop.", type = "warning"}
    elseif dropType == "green" then
        return {title = "No Robs Airdrop", description = "Robbing is not allowed inside this drop radius.", type = "success"}
    else
        return {title = "Airdrop Zone", description = "KOS is active inside this drop radius.", type = "warning"}
    end
end

CreateThread(function()
    while true do
        local sleep = 1000
        if Config.ShowSphere then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local drawDistance = Config.SphereDrawDistance
            
            for dropId, drop in pairs(airDrops) do
                if drop and drop.coords and not drop.collected then
                    local distance = #(playerCoords - drop.coords)
                    
                    if distance <= drawDistance then
                        sleep = 0
                        local radiusToUse = tonumber(drop.radius) or Config.SphereRadius
                        local insideZone = distance <= radiusToUse
                        local dropType = drop.dropType or "normal"
                        local sphereColor = drop.customColor or (Config.DropTypes[dropType] or Config.DropTypes.normal).sphereColor
                        
                        DrawMarker(28, drop.coords.x, drop.coords.y, drop.coords.z, 
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            radiusToUse, radiusToUse, radiusToUse,
                            sphereColor.r, sphereColor.g, sphereColor.b, sphereColor.a,
                            false, false, 2, false, nil, nil, false)
                        
                        if insideZone and not drop.playerInsideZone then
                            drop.playerInsideZone = true
                            local notif = getDropZoneNotification(dropType)
                            TriggerEvent('showCustomNotification', {
                                title = notif.title,
                                description = notif.description,
                                duration = 10000,
                                type = notif.type
                            })
                        elseif not insideZone and drop.playerInsideZone then
                            drop.playerInsideZone = false
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

local function addTimer(dropId)
    while airDrops[dropId] do
        if airDrops[dropId].time and airDrops[dropId].time > 0 then
            airDrops[dropId].time = airDrops[dropId].time - 1000
        end
        Citizen.Wait(1000)
    end
end

local function secondsToClock(seconds)
    seconds = tonumber(seconds)
    if seconds <= 0 then
        return "00:00"
    else
        local mins = string.format("%02.f", math.floor(seconds / 60))
        local secs = string.format("%02.f", math.floor(seconds - mins * 60))
        return string.format("%s:%s", mins, secs)
    end
end

local function dropCrate(coords, dropId)
    airDrops[dropId].dropped = true

    kCore.requestModel(Config.crateModel)
    kCore.requestModel(Config.parachuteModel)

    airDrops[dropId].crate = CreateObject(Config.crateModel, coords.x, coords.y, coords.z, false, false, false)
    airDrops[dropId].parachute = CreateObject(Config.parachuteModel, coords.x, coords.y, coords.z + 1, false, false, false)

    AttachEntityToEntity(airDrops[dropId].parachute, airDrops[dropId].crate, 0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    SetEntityCollision(airDrops[dropId].crate, false, true)
    SetEntityCollision(airDrops[dropId].parachute, false, true)
    SetEntityLodDist(airDrops[dropId].crate, 9999)
    SetEntityLodDist(airDrops[dropId].parachute, 9999)
    SetEntityDynamic(airDrops[dropId].crate, true)
    SetEntityDynamic(airDrops[dropId].parachute, true)
    ActivatePhysics(airDrops[dropId].crate)
    ActivatePhysics(airDrops[dropId].parachute)
    SetDamping(airDrops[dropId].crate, 2, 0.1) 
    SetDamping(airDrops[dropId].parachute, 2, 0.1) 

    airDrops[dropId].soundID = GetSoundId() 
    PlaySoundFromEntity(airDrops[dropId].soundID, "Crate_Beeps", airDrops[dropId].crate, "MP_CRATE_DROP_SOUNDS", true, 0) 

    if not DoesBlipExist(airDrops[dropId].crateBlip) then
        airDrops[dropId].crateBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(airDrops[dropId].crateBlip, Config.crateBlips.sprite)
        SetBlipColour(airDrops[dropId].crateBlip, Config.crateBlips.color)
        SetBlipFlashes(airDrops[dropId].crateBlip, true)
        SetBlipFlashInterval(airDrops[dropId].crateBlip, 250)
        SetBlipAsShortRange(airDrops[dropId].crateBlip, false)
        SetBlipScale(airDrops[dropId].crateBlip, 1.0)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(kCore.getPhrase("crate-name"))
        EndTextCommandSetBlipName(airDrops[dropId].crateBlip)
    end

    Citizen.SetTimeout(30000, function()
        if airDrops[dropId] then
            local _, posZ = GetGroundZFor_3dCoord(airDrops[dropId].coords.x, airDrops[dropId].coords.y, airDrops[dropId].coords.z, false)
            SetEntityCollision(airDrops[dropId].crate, true, true)
            SetEntityCollision(airDrops[dropId].parachute, true, true)
            DeleteEntity(airDrops[dropId].parachute)
            SetBlipFlashes(airDrops[dropId].crateBlip, false)
            kCore.requestParticle("core")
            SetEntityCoords(airDrops[dropId].crate, airDrops[dropId].coords.x, airDrops[dropId].coords.y, airDrops[dropId].coords.z)
            PlaceObjectOnGroundProperly(airDrops[dropId].crate)
            FreezeEntityPosition(airDrops[dropId].crate, true)
        end
    end)

    Citizen.CreateThread(function()
        while DoesEntityExist(airDrops[dropId].parachute) do
            if GetEntityHeightAboveGround(airDrops[dropId].crate) <= 5 then
                local _, posZ = GetGroundZFor_3dCoord(airDrops[dropId].coords.x, airDrops[dropId].coords.y, airDrops[dropId].coords.z, false)
                SetEntityCollision(airDrops[dropId].crate, true, true)
                SetEntityCollision(airDrops[dropId].parachute, true, true)
                DeleteEntity(airDrops[dropId].parachute)
                SetBlipFlashes(airDrops[dropId].crateBlip, false)
                kCore.requestParticle("core")
                local crateCoords = GetEntityCoords(airDrops[dropId].crate)
                airDrops[dropId].smoke = StartParticleFxLoopedAtCoord("exp_grd_flare", crateCoords.x, crateCoords.y, posZ + 0.2, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
                SetParticleFxLoopedAlpha(airDrops[dropId].smoke, 0.8)
                SetParticleFxLoopedColour(airDrops[dropId].smoke, 1.0, 0.41, 0.71, 0)
                SetEntityCoords(airDrops[dropId].crate, airDrops[dropId].coords.x, airDrops[dropId].coords.y, posZ)
                PlaceObjectOnGroundProperly(airDrops[dropId].crate)
                FreezeEntityPosition(airDrops[dropId].crate, true)
                break
            end
            Wait(100)
        end
        
        while airDrops[dropId] and DoesEntityExist(airDrops[dropId].crate) do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local pCoords = GetEntityCoords(playerPed)
            local crateCoords = GetEntityCoords(airDrops[dropId].crate) 
            local dst = #(pCoords - crateCoords)
            
            if dst <= 50 then
                sleep = 0
                if dst <= 15 then
                    if airDrops[dropId].time and airDrops[dropId].time > 0 and not airDrops[dropId].unlocked then
                        kCore.drawText(crateCoords.x, crateCoords.y, crateCoords.z, 1.0, secondsToClock(airDrops[dropId].time / 1000))
                    end
                end
                if dst <= 3 and airDrops[dropId].unlocked then
                    kCore.drawText(crateCoords.x, crateCoords.y, crateCoords.z, 1.0, kCore.getPhrase("open-crate"))
                    if IsControlJustPressed(0, 38) and canOpenAirdrop(playerPed, dropId) and not progress then
                        progress = true
                        TriggerServerEvent("dior_airdrop:server:startClaiming", dropId)
                        LocalPlayer.state:set("inv_busy", true, true)
                        
                        CreateThread(function()
                            while progress do
                                local ped = PlayerPedId()
                                if IsEntityDead(ped) or IsPedDeadOrDying(ped) or IsPedRagdoll(ped) then
                                    exports['is_ui']:cancelProgressBar()
                                    break
                                end
                                Wait(200)
                            end
                        end)
                        
                        QBCore.Functions.Progressbar("xxxxxxxxxx", "Opening Supply Drop..", math.random(5000, 10000), false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = 'anim@gangops@facility@servers@',
                            anim = 'hotwire',
                            flags = 16,
                        }, {}, {}, function()
                            TriggerServerEvent("dior_airdrop:server:openCrate", dropId)
                            LocalPlayer.state:set("inv_busy", false, true)
                            progress = false
                        end, function()
                            LocalPlayer.state:set("inv_busy", false, true)
                            progress = false
                        end)
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)
end

local function createPlane(coords, dropId)
    dropCrate(coords, dropId)
end

local function hexToRgb(hex)
    if not hex or hex == "" then return nil end
    hex = hex:gsub("%s+", ""):gsub("#", ""):upper()
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then
        return {r = r, g = g, b = b, a = 150}
    end
    return nil
end

RegisterNetEvent("dior_airdrop:client:createLootBox", function(data)
    local dropType = data.dropType or "normal"

    if airDrops[data.dropId] then
        return
    end

    local radiusToUse = data.radius and tonumber(data.radius) or Config.SphereRadius
    if not radiusToUse or radiusToUse <= 0 then
        radiusToUse = Config.SphereRadius
    end
    if radiusToUse > 200 then
        radiusToUse = 199.9
    end
    
    local customColor = nil
    if data.colorHex and data.colorHex ~= "" then
        customColor = hexToRgb(data.colorHex)
        if customColor and (not customColor.a or customColor.a < 100) then
            customColor.a = 100
        end
    end

    airDrops[data.dropId] = {
        coords = data.coords,
        time = data.time,
        unlocked = false,
        spawned = false,
        dropType = dropType,
        radius = radiusToUse,
        colorHex = data.colorHex,
        customColor = customColor,
        playerInsideZone = false
    }

    Citizen.SetTimeout(5000, function()
        if airDrops[data.dropId] then
            if airDrops[data.dropId].time and airDrops[data.dropId].time > 5000 then
                airDrops[data.dropId].time = airDrops[data.dropId].time - 5000
            end
            CreateThread(function()
                addTimer(data.dropId)
            end)
        end
    end)

    local notificationTitle = kCore.getPhrase("drop-coming")
    local notificationDescription = 'Check your map and look for the air crate icon!'
    
    if dropType == "gold" then
        notificationTitle = kCore.getPhrase("drop-coming-gang")
        notificationDescription = 'This is a Gang-Only Airdrop! Check your map and look for the air crate icon!'
    elseif dropType == "green" then
        notificationTitle = kCore.getPhrase("drop-coming-green")
        notificationDescription = 'This drop is No Robs! Check your map and look for the air crate icon!'
    end
    
    TriggerEvent('showCustomNotification', {
        title = notificationTitle,
        description = notificationDescription,
        duration = 30000,
        type = 'warning'
    })

    SendNUIMessage({action = "playSound"})
    
    Citizen.SetTimeout(5000, function()
        createPlane(data.coords, data.dropId) 
    end)
end)

RegisterNetEvent("dior_airdrop:client:dropUnlocked", function(dropId)
    if airDrops[dropId] then
        airDrops[dropId].unlocked = true
        if airDrops[dropId].soundID then
            StopSound(airDrops[dropId].soundID)
            ReleaseSoundId(airDrops[dropId].soundID)
        end
    end
end)

RegisterNetEvent("dior_airdrop:client:dropCollected", function(dropId, looterName)
    if airDrops[dropId] then
        airDrops[dropId].collected = true
        
        if DoesEntityExist(airDrops[dropId].crate) then
            DeleteEntity(airDrops[dropId].crate)
        end
        if airDrops[dropId].parachute and DoesEntityExist(airDrops[dropId].parachute) then
            DeleteEntity(airDrops[dropId].parachute)
        end
        if airDrops[dropId].smoke then
            StopParticleFxLooped(airDrops[dropId].smoke, 0)
            RemoveParticleFx(airDrops[dropId].smoke, true)
            airDrops[dropId].smoke = nil
        end
        
        if DoesBlipExist(airDrops[dropId].crateBlip) then
            RemoveBlip(airDrops[dropId].crateBlip)
        end
        
        if airDrops[dropId].soundID then
            StopSound(airDrops[dropId].soundID)
            ReleaseSoundId(airDrops[dropId].soundID)
            airDrops[dropId].soundID = nil
        end

        local description = 'Airdrop has been looted.'
        if looterName then
            description = looterName .. ' has collected the airdrop!'
        end

        TriggerEvent('showCustomNotification', {
            title = 'Airdrop has been collected!',
            description = description,
            duration = 15000,
            type = 'warning'
        })

        Citizen.SetTimeout(1000, function()
            airDrops[dropId] = nil
            TriggerServerEvent("dior_airdrop:server:confirmDeletion", dropId)
        end)
    end
end)

exports('useAirdropDashboard', function(data, slot)
    TriggerServerEvent('dior_airdrop:server:useItem')
end)

RegisterNetEvent('dior_airdrop:client:openDashboard')
AddEventHandler('dior_airdrop:client:openDashboard', function(dropType)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'toggleDashboard',
        show = true,
        dropType = dropType or "normal"
    })
    TriggerServerEvent('diro_drops:server:requestAirdrops')
end)

RegisterNUICallback('createAirdrop', function(data, cb)
    data.dropType = data.dropType or "normal"
    TriggerServerEvent('dior_airdrop:server:createCustomDrop', data)
    cb('ok')
end)

RegisterNUICallback('closeDashboard', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('dior_airdrop:server:closeDashboard')
    cb('ok')
end)

RegisterNUICallback('getCurrentCoords', function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    SendNUIMessage({
        action = 'updateCoords',
        coords = {
            x = string.format("%.2f", coords.x),
            y = string.format("%.2f", coords.y),
            z = string.format("%.2f", coords.z)
        }
    })
    
    cb('ok')
end)

RegisterNUICallback('requestAirdrops', function(data, cb)
    TriggerServerEvent('diro_drops:server:requestAirdrops')
    cb('ok')
end)

RegisterNUICallback('deleteAirdrop', function(data, cb)
    local dropId = data.dropId
    if dropId then
        TriggerServerEvent('diro_drops:server:deleteAirdrop', dropId)
    end
    cb('ok')
end)

RegisterNetEvent('diro_drops:client:updateAirdrops')
AddEventHandler('diro_drops:client:updateAirdrops', function(airdropsData)
    if type(airdropsData) ~= "table" then
        airdropsData = {}
    end
    
    SendNUIMessage({
        action = 'updateAirdrops',
        airdrops = airdropsData
    })
end)

RegisterNetEvent('showCustomNotification')
AddEventHandler('showCustomNotification', function(data)
    SendNUIMessage({
        action = 'showNotification',
        options = data
    })
end)

RegisterNetEvent('dior_airdrop:client:claimingNotification')
AddEventHandler('dior_airdrop:client:claimingNotification', function(claimerName, gangName)
    local description = claimerName .. ' is opening the airdrop!'
    if gangName then
        description = gangName .. ' (' .. claimerName .. ') is claiming the airdrop!'
    end
    TriggerEvent('showCustomNotification', {
        title = 'Airdrop Being Claimed!',
        description = description,
        duration = 8000,
        type = 'warning'
    })
end)

RegisterNetEvent('dior_airdrop:client:dropCreationError')
AddEventHandler('dior_airdrop:client:dropCreationError', function(errorMessage)
    SendNUIMessage({
        action = 'showNotification',
        options = {
            type = 'error',
            title = 'Airdrop Creation Error',
            description = errorMessage,
            duration = 5000
        }
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for dropId, drop in pairs(airDrops) do
        if drop.crate and DoesEntityExist(drop.crate) then
            DeleteEntity(drop.crate)
        end
        if drop.parachute and DoesEntityExist(drop.parachute) then
            DeleteEntity(drop.parachute)
        end
        if drop.plane and DoesEntityExist(drop.plane) then
            DeleteEntity(drop.plane)
        end
        if drop.pilot and DoesEntityExist(drop.pilot) then
            DeleteEntity(drop.pilot)
        end
        if drop.crateBlip and DoesBlipExist(drop.crateBlip) then
            RemoveBlip(drop.crateBlip)
        end
        if drop.smoke then
            StopParticleFxLooped(drop.smoke, 0)
            RemoveParticleFx(drop.smoke, true)
        end
        if drop.soundID then
            StopSound(drop.soundID)
            ReleaseSoundId(drop.soundID)
        end
    end
    airDrops = {}
end)
