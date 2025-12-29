local QBCore = exports['qb-core']:GetCoreObject()
local zones = {}
local currentZones = {} -- Track which zones the player is currently in

-- Function to check if a point is inside a polygon defined by 4 corners
-- Uses ray casting algorithm
local function IsPointInPolygon(point, corners)
	if #corners < 3 then return false end
	
	local x, y = point.x, point.y
	local inside = false
	local j = #corners
	
	for i = 1, #corners do
		local xi, yi = corners[i].x, corners[i].y
		local xj, yj = corners[j].x, corners[j].y
		
		local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
		if intersect then
			inside = not inside
		end
		j = i
	end
	
	return inside
end

-- Function to calculate center point of zone from corners
local function CalculateZoneCenter(corners)
	local centerX, centerY, centerZ = 0, 0, 0
	for _, corner in ipairs(corners) do
		centerX = centerX + corner.x
		centerY = centerY + corner.y
		centerZ = centerZ + corner.z
	end
	return {
		x = centerX / #corners,
		y = centerY / #corners,
		z = centerZ / #corners
	}
end

-- Function to show notification (configurable)
local function ShowNotification(message, type)
	type = type or 'primary'
	
	-- Check config for notification type
	local notifyType = config.NotificationType or "qb-core"
	
	if notifyType == "qb-core" then
		-- Use QBCore notification
		if QBCore and QBCore.Functions then
			QBCore.Functions.Notify(message, type)
		else
			-- Fallback to chat message
			TriggerEvent('chat:addMessage', {
				color = {255, 255, 255},
				multiline = true,
				args = {"Zone", message}
			})
		end
	elseif notifyType == "esx" then
		-- Use ESX notification
		if ESX then
			ESX.ShowNotification(message)
		else
			-- Fallback to chat message
			TriggerEvent('chat:addMessage', {
				color = {255, 255, 255},
				multiline = true,
				args = {"Zone", message}
			})
		end
	elseif notifyType == "chat" then
		-- Use chat messages only
		TriggerEvent('chat:addMessage', {
			color = {255, 255, 255},
			multiline = true,
			args = {"Zone", message}
		})
	elseif notifyType == "custom" then
		-- Use custom notification function from config
		if config.CustomNotify and type(config.CustomNotify) == "function" then
			config.CustomNotify(message, type)
		else
			-- Fallback to chat message if custom function not defined
			TriggerEvent('chat:addMessage', {
				color = {255, 255, 255},
				multiline = true,
				args = {"Zone", message}
			})
		end
	else
		-- Default fallback to chat message
		TriggerEvent('chat:addMessage', {
			color = {255, 255, 255},
			multiline = true,
			args = {"Zone", message}
		})
	end
end

-- Initialize zones
Citizen.CreateThread(function()
	Citizen.Wait(1000) -- Wait for QBCore to be ready
	if not config or not config.zones then
		print("[Static Zones] Error: Config not loaded properly")
		return
	end
	
	for i, new_zone in pairs(config.zones) do
		-- Validate that zone has 4 corners
		if not new_zone.corners or #new_zone.corners ~= 4 then
			print("[Static Zones] Error: Zone " .. i .. " must have exactly 4 corners")
			goto continue
		end
		
		-- Store zone data
		local zoneHeight = new_zone.zone.height or 50.0
		local zoneCenter = CalculateZoneCenter(new_zone.corners)
		
		zones[i] = {
			corners = new_zone.corners,
			height = zoneHeight,
			color = new_zone.zone.color or {255, 255, 255, 100},
			name = new_zone.name or "",
			center = zoneCenter
		}
		
		
		::continue::
	end
	
	print("[Static Zones] Loaded " .. #zones .. " zone(s)")
end)

-- Function to reload zones from config
local function ReloadZones()
	-- Clear existing zones
	zones = {}
	currentZones = {} -- Reset current zones
	
	-- Reload config
	Citizen.Wait(100) -- Small delay to ensure config is reloaded
	
	-- Reinitialize zones
	for i, new_zone in pairs(config.zones) do
		-- Validate that zone has 4 corners
		if not new_zone.corners or #new_zone.corners ~= 4 then
			print("[Static Zones] Error: Zone " .. i .. " must have exactly 4 corners")
			goto continue
		end
		
		local zoneHeight = new_zone.zone.height or 50.0
		local zoneCenter = CalculateZoneCenter(new_zone.corners)
		
		zones[i] = {
			corners = new_zone.corners,
			height = zoneHeight,
			color = new_zone.zone.color or {255, 255, 255, 100},
			name = new_zone.name or "",
			exitMessage = new_zone.exitMessage or nil, -- Optional custom exit message
			center = zoneCenter
		}
		
		
		::continue::
	end
end

-- Event to reload zones
RegisterNetEvent('static-zones:reloadZones', function()
	ReloadZones()
end)

-- Zone entry/exit detection thread
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500) -- Check every 500ms for performance
		
		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)
		local playerPos = {x = playerCoords.x, y = playerCoords.y, z = playerCoords.z}
		
		-- Check each zone
		for i, zone in pairs(zones) do
			if not zone.corners or #zone.corners ~= 4 then
				-- Skip invalid zones
			else
				-- Find the lowest Z coordinate (ground level) from all corners
				local baseZ = zone.corners[1].z
				for _, corner in ipairs(zone.corners) do
					if corner.z < baseZ then
						baseZ = corner.z
					end
				end
				
			local zoneHeight = zone.height or 50.0
			local bottomZ = baseZ - 10.0  -- 10 units below ground
			local topZ = baseZ + zoneHeight
			
			-- Check if point is inside the polygon defined by 4 corners (horizontal check)
			local isInPolygon = IsPointInPolygon(playerPos, zone.corners)
			
			-- Check if player is within the vertical bounds (from below ground to top)
			local isInVerticalBounds = playerPos.z >= bottomZ and playerPos.z <= topZ
				
				-- Player is in zone if both horizontal and vertical checks pass
				local isInZone = isInPolygon and isInVerticalBounds
				
				local wasInZone = currentZones[i] == true
				
				-- Player entered zone
				if isInZone and not wasInZone then
					currentZones[i] = true
					if zone.name and zone.name ~= "" then
						-- Check if the name already contains "You have entered" (custom message)
						if zone.name:lower():match("you have entered") then
							ShowNotification(zone.name, 'primary')
						else
							ShowNotification("You have entered the " .. zone.name, 'primary')
						end
					end
				-- Player left zone
				elseif not isInZone and wasInZone then
					currentZones[i] = false
					if zone.name and zone.name ~= "" then
						-- Use custom exit message if provided
						if zone.exitMessage then
							ShowNotification(zone.exitMessage, 'primary')
						-- If entry message is custom (contains "you have entered"), show simple exit message
						elseif zone.name:lower():match("you have entered") then
							-- For custom entry messages, just show a simple exit notification
							ShowNotification("You have left the zone", 'primary')
						else
							-- Normal zone name, show standard exit message
							ShowNotification("You have left the " .. zone.name, 'primary')
						end
					end
				end
			end
		end
	end
end)

-- Draw zones from 4 corner coordinates
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)
		
		for i, zone in pairs(zones) do
			if not zone.corners or #zone.corners ~= 4 then goto continue end
			
			-- Calculate distance to zone center for performance
			local distance = #(playerCoords - vector3(zone.center.x, zone.center.y, zone.center.z))
			
			-- Only draw if player is within reasonable distance (500 units)
			if distance < 500.0 then
				local color = zone.color
				local r, g, b, a = color[1], color[2], color[3], color[4] or 100
				local height = zone.height or 50.0
				
				-- Use the alpha value from config (no forced minimum)
				-- Ensure alpha is within valid range (0-255)
				a = math.max(0, math.min(255, a))
				-- Make outlines slightly brighter for visibility, but still respect config
				local outlineAlpha = math.min(255, a + 30)
				
				local corners = zone.corners
				
				-- Find the lowest Z coordinate (ground level) from all corners
				local baseZ = corners[1].z
				for _, corner in ipairs(corners) do
					if corner.z < baseZ then
						baseZ = corner.z
					end
				end
				
				-- Extend zone below ground (10 units below the lowest corner) and above
				local bottomZ = baseZ - 10.0  -- 10 units below ground
				local topZ = baseZ + height    -- Height above ground
				
				-- Draw walls between each pair of corners (4 walls total)
				for j = 1, 4 do
					local currentCorner = corners[j]
					local nextCorner = corners[(j % 4) + 1]
					
					-- Draw bottom edge of wall (below ground)
					DrawLine(
						currentCorner.x, currentCorner.y, bottomZ,
						nextCorner.x, nextCorner.y, bottomZ,
						r, g, b, outlineAlpha
					)
					
					-- Draw vertical edge from bottom to top
					DrawLine(
						currentCorner.x, currentCorner.y, bottomZ,
						currentCorner.x, currentCorner.y, topZ,
						r, g, b, outlineAlpha
					)
					
					-- Draw top edge of wall
					DrawLine(
						currentCorner.x, currentCorner.y, topZ,
						nextCorner.x, nextCorner.y, topZ,
						r, g, b, outlineAlpha
					)
					
					-- Draw vertical edge from bottom to top (next corner)
					DrawLine(
						nextCorner.x, nextCorner.y, bottomZ,
						nextCorner.x, nextCorner.y, topZ,
						r, g, b, outlineAlpha
					)
					
					-- Draw filled wall surface (two triangles to form a quad)
					-- Front-facing (visible from outside)
					DrawPoly(
						currentCorner.x, currentCorner.y, bottomZ,
						nextCorner.x, nextCorner.y, bottomZ,
						nextCorner.x, nextCorner.y, topZ,
						r, g, b, a
					)
					DrawPoly(
						currentCorner.x, currentCorner.y, bottomZ,
						nextCorner.x, nextCorner.y, topZ,
						currentCorner.x, currentCorner.y, topZ,
						r, g, b, a
					)
					
					-- Back-facing (visible from inside) - reverse vertex order
					DrawPoly(
						currentCorner.x, currentCorner.y, bottomZ,
						nextCorner.x, nextCorner.y, topZ,
						nextCorner.x, nextCorner.y, bottomZ,
						r, g, b, a
					)
					DrawPoly(
						currentCorner.x, currentCorner.y, bottomZ,
						currentCorner.x, currentCorner.y, topZ,
						nextCorner.x, nextCorner.y, topZ,
						r, g, b, a
					)
				end
				
				-- Draw filled top plane (roof) - visible from both sides
				for k = 2, 3 do
					-- Top-facing (visible from below/inside)
					DrawPoly(
						corners[1].x, corners[1].y, topZ,
						corners[k].x, corners[k].y, topZ,
						corners[k+1].x, corners[k+1].y, topZ,
						r, g, b, a
					)
					-- Bottom-facing (visible from above/outside) - reverse vertex order
					DrawPoly(
						corners[1].x, corners[1].y, topZ,
						corners[k+1].x, corners[k+1].y, topZ,
						corners[k].x, corners[k].y, topZ,
						r, g, b, a
					)
				end
			end
			::continue::
		end
	end
end)

