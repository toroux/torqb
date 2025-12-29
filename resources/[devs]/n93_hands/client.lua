local activeEffect = nil
local effectThread = nil

local colorEffects = {
    red_hands = { r = 255, g = 0, b = 0 },
    blue_hands = { r = 0, g = 0, b = 255 },
    green_hands = { r = 0, g = 255, b = 0 },
    purple_hands = { r = 128, g = 0, b = 128 },
    yellow_hands = { r = 255, g = 255, b = 0 },
    cyan_hands = { r = 0, g = 255, b = 255 },
    white_hands = { r = 255, g = 255, b = 255 },
    pink_hands = { r = 255, g = 105, b = 180 }
}

local bones = {
    SKEL_L_Hand = 0x49D9,
    SKEL_R_Hand = 0xDEAD,
}

local function getRainbowColor()
    local r, g, b = 255, 0, 0
    local state = 0

    return function()
        if state == 0 then
            g = g + 15
            if g >= 255 then
                g = 255; state = 1
            end
        elseif state == 1 then
            r = r - 15
            if r <= 0 then
                r = 0; state = 2
            end
        elseif state == 2 then
            b = b + 15
            if b >= 255 then
                b = 255; state = 3
            end
        elseif state == 3 then
            g = g - 15
            if g <= 0 then
                g = 0; state = 4
            end
        elseif state == 4 then
            r = r + 15
            if r >= 255 then
                r = 255; state = 5
            end
        elseif state == 5 then
            b = b - 15
            if b <= 0 then
                b = 0; state = 0
            end
        end
        return r / 255, g / 255, b / 255
    end
end

local function stopEffect()
    if effectThread then
        activeEffect = nil
        effectThread = nil
    end
end

local function startEffect(effectType)
    RequestNamedPtfxAsset("scr_rcpaparazzo1")

    local getColor
    if effectType == "rainbow_hands" then
        getColor = getRainbowColor()
    else
        local color = colorEffects[effectType]
        getColor = function() return color.r / 255, color.g / 255, color.b / 255 end
    end

    effectThread = true

    Citizen.CreateThread(function()
        while activeEffect == effectType do
            Citizen.Wait(50)

            if HasNamedPtfxAssetLoaded("scr_rcpaparazzo1") then
                local R, G, B = getColor()
                local ped = PlayerPedId()

                for boneName, boneId in pairs(bones) do
                    SetParticleFxNonLoopedColour(R, G, B)
                    SetParticleFxNonLoopedAlpha(1.0)
                    UseParticleFxAsset("scr_rcpaparazzo1")
                    StartNetworkedParticleFxNonLoopedOnPedBone(
                        "scr_mich4_firework_sparkle_spawn",
                        ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        boneId, 1.5, false, false, false
                    )
                end
            end
        end
    end)
end
exports('useItem', function(data)
    TriggerEvent("handeffects:toggle", data.name)
end)

RegisterNetEvent('handeffects:toggle', function(effectType)
    print("event triggered.")
    if activeEffect == effectType then
        stopEffect()
        print("Hand effect removed")
    elseif activeEffect then
        stopEffect()
        activeEffect = effectType
        startEffect(effectType)
        print("Hand effect changed")
    else
        activeEffect = effectType
        startEffect(effectType)
        print("Hand effect activated")
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        if victim == PlayerPedId() and IsPedDeadOrDying(victim) then
            if activeEffect then
                stopEffect()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if activeEffect then
            stopEffect()
        end
    end
end)
