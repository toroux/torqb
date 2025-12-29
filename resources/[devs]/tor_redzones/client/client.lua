local QBCore = exports['qb-core']:GetCoreObject()
local activeZones = {}
local zoneData = {}
local isInZone = false
local currentZoneName = nil

function sendNotification(title, description, type, duration)
    lib.notify({
        title = title,
        description = description,
        type = type,
        position = 'top',
        duration = duration or 5000,
        style = {
            backgroundColor = type == 'success' and '#72E68F' or '#ff5a47',
            color = '#2C2C2C',
            ['.description'] = {
                color = '#2C2C2C',
            }
        },
        icon = 'border-all',
        iconColor = '#2C2C2C'
    })
end

function onEnterZone(k)
    if isInZone then return end
    isInZone = true
    currentZoneName = k
    local zone = Config.Zones[k]
    if not zone then return end

    sendNotification(Config.Zones[k].label..' - Red Zone', 'You have entered a redzone - PvP is enabled', 'error')
end

function onExitZone(k)
    if not isInZone then return end
    isInZone = false
    currentZoneName = nil
    local zone = Config.Zones[k]
    if not zone then return end
    sendNotification(Config.Zones[k].label..' - Red Zone', 'You have exited the redzone', 'success')
end

local function drawZoneWithOpacity(zone, zoneConfig)
    if not zone or not zoneConfig then return end
    local r, g, b = zoneConfig.Color[1], zoneConfig.Color[2], zoneConfig.Color[3]
    local opacity = zoneConfig.Opacity or 100
    local minZ = zone.minZ
    local maxZ = zone.maxZ
    if not zone.points then return end
    local points = zone.points
    local numPoints = #points
    if numPoints < 3 then return end
    
    local transformedPoints = {}
    for i = 1, numPoints do
        transformedPoints[i] = zone:TransformPoint(points[i])
    end
    
    local p1 = transformedPoints[1]
    local p1x, p1y = p1.x, p1.y
    local p2, p3, p2x, p2y, p3x, p3y
    for i = 1, numPoints - 2 do
        p2 = transformedPoints[i + 1]
        p3 = transformedPoints[i + 2]
        p2x, p2y, p3x, p3y = p2.x, p2.y, p3.x, p3.y
        DrawPoly(p1x, p1y, maxZ, p2x, p2y, maxZ, p3x, p3y, maxZ, r, g, b, opacity)
        DrawPoly(p1x, p1y, maxZ, p3x, p3y, maxZ, p2x, p2y, maxZ, r, g, b, opacity)
        DrawPoly(p1x, p1y, minZ, p2x, p2y, minZ, p3x, p3y, minZ, r, g, b, opacity)
        DrawPoly(p1x, p1y, minZ, p3x, p3y, minZ, p2x, p2y, minZ, r, g, b, opacity)
    end
    
    for i = 1, numPoints do
        local p1 = transformedPoints[i]
        local p2 = transformedPoints[i == numPoints and 1 or i + 1]
        local p1x, p1y = p1.x, p1.y
        local p2x, p2y = p2.x, p2.y
        DrawPoly(p1x, p1y, minZ, p2x, p2y, minZ, p1x, p1y, maxZ, r, g, b, opacity)
        DrawPoly(p2x, p2y, minZ, p2x, p2y, maxZ, p1x, p1y, maxZ, r, g, b, opacity)
        DrawPoly(p1x, p1y, minZ, p1x, p1y, maxZ, p2x, p2y, minZ, r, g, b, opacity)
        DrawPoly(p2x, p2y, minZ, p1x, p1y, maxZ, p2x, p2y, maxZ, r, g, b, opacity)
    end
end

CreateThread(function()
    for k, v in pairs(Config.Zones) do
        local color = v.Color or {255, 0, 0}
        
        local totalZ = 0
        local totalX = 0
        local totalY = 0
        for i = 1, #v.zone do
            totalZ = totalZ + v.zone[i].z
            totalX = totalX + v.zone[i].x
            totalY = totalY + v.zone[i].y
        end
        local avgZ = totalZ / #v.zone
        local centerX = totalX / #v.zone
        local centerY = totalY / #v.zone
        
        local zoneThickness = v.Thickness or Config.MaxZoneHeight
        local maxHeight = Config.MaxZoneHeight or zoneThickness
        local finalThickness = math.min(zoneThickness, maxHeight)
        
        local minZ = avgZ - (finalThickness / 2)
        local maxZ = avgZ + (finalThickness / 2)
        
        local z = PolyZone:Create(v.zone, { 
            name = v.label, 
            debugPoly = false,
            minZ = minZ,
            maxZ = maxZ
        })
        activeZones[k] = z
        zoneData[k] = {
            Color = color,
            Opacity = v.Opacity or 100,
            Center = vector3(centerX, centerY, avgZ)
        }
        
        z:onPlayerInOut(function(isInside)
            if isInside and not isInZone then
                onEnterZone(k)
            elseif not isInside and isInZone and currentZoneName == k then
                onExitZone(k)
            end
        end)
    end
end)

CreateThread(function()
    local maxDistSquared = (Config.MaxDrawDistance or 15.0) * (Config.MaxDrawDistance or 15.0)
    Wait(1000)
    while true do
        local plyPos = GetEntityCoords(PlayerPedId())
        
        for k, zone in pairs(activeZones) do
            if zone and zoneData[k] then
                local distSquared = #(plyPos - zoneData[k].Center)
                if distSquared <= maxDistSquared then
                    drawZoneWithOpacity(zone, zoneData[k])
                end
            end
        end
        
        Wait(0)
    end
end)