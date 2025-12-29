kCore = {}
local QBCore = exports['qb-core']:GetCoreObject()

canOpenAirdrop = function(playerPed, dropId)
    local playerData = QBCore.Functions.GetPlayerData()
    local playerGang = playerData.gang
    local playerJob = playerData.job
    
    local isGangMember = playerGang and playerGang.name ~= "none"
    local isPolice = playerJob and playerJob.name == "police"
    local isAmbulance = playerJob and playerJob.name == "ambulance"

    if airDrops[dropId] and airDrops[dropId].dropType == "gold" then
        if not isGangMember and not isPolice and not isAmbulance then
            kCore.showNotification(kCore.getPhrase("gangs-only"))
            return false 
        end
    end

    if airDrops[dropId].collected then
        kCore.showNotification(kCore.getPhrase("already-collected"))
        return false
    end

    if not airDrops[dropId].unlocked then
        kCore.showNotification(kCore.getPhrase("time-is-not-up"))
        return false
    end

    if not IsPedArmed(playerPed, 4) then
        kCore.showNotification(kCore.getPhrase("no-weapon"))
        return false
    end

    if IsEntityDead(playerPed) or IsPedDeadOrDying(playerPed) then
        kCore.showNotification(kCore.getPhrase("cant-while-dead"))
        return false
    end

    if IsPedRagdoll(playerPed) or IsPedFalling(playerPed) or IsPedProne(playerPed) then
        kCore.showNotification(kCore.getPhrase("cant-while-prone"))
        return false
    end

    if IsPedInAnyVehicle(playerPed) then
        kCore.showNotification(kCore.getPhrase("cant-open-in-vehicle"))
        return false
    end

    return true
end

kCore.requestModel = function(model)
    if HasModelLoaded(model) then
        return
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
    end
end

kCore.requestAnim = function(animDict)
    if HasAnimDictLoaded(animDict) then
        return
    end
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
end

kCore.requestParticle = function(particle)
    if not HasNamedPtfxAssetLoaded(particle) then
        RequestNamedPtfxAsset(particle)
        while not HasNamedPtfxAssetLoaded(particle) do 
            Citizen.Wait(10) 
        end
    end
    return SetPtfxAssetNextCall(particle)
end

kCore.showNotification = function(msg)
	BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
	EndTextCommandThefeedPostTicker(false, 1)
end

kCore.getPhrase = function(text)
    return Config.Locales[text] or ("%s - locale not found."):format(text)
end

kCore.progressBar = function(text, time)
    TriggerEvent("mythic_progbar:client:progress", {
        name = "kaves",
        duration = time,
        label = text,
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
    })
end

kCore.drawText = function(x, y, z, scale, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        local camCoords = GetGameplayCamCoord()
        local distance = #(camCoords - vector3(x, y, z))
        local textScale = (200 / (GetGameplayCamFov() * distance)) * scale
        SetTextScale(0.5, textScale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextOutline()
        SetTextCentre(1)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        SetDrawOrigin(x, y, z, 0)
        EndTextCommandDisplayText(0.0, 0.0)
        ClearDrawOrigin()
    end
end

kCore.triggerCallback = function(cbName, cb, data)
    QBCore.Functions.TriggerCallback(cbName, function(output)
        if cb then cb(output) else return output end  
    end, data)
end

exports("getCore", function()
    return kCore
end)
