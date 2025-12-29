config = {

	-- Notification Function Configuration --
	-- Options: "qb-core", "esx", "chat", or "custom" --
	--   "qb-core" = Uses QBCore.Functions.Notify (default) --
	--   "esx" = Uses ESX.ShowNotification --
	--   "chat" = Uses chat messages --
	--   "custom" = Uses custom function defined below --
	NotificationType = "qb-core",
	
	-- Custom Notification Function (only used if NotificationType = "custom") --
	-- This function will be called with (message, type) parameters --
	-- You can customize this function to use any notification system you want --
	-- Example: --
	CustomNotify = function(message, type)
		-- Convert type to QBCore notification type if needed
		local notifyType = type or 'info'
		if type == 'primary' then notifyType = 'info' end
		if type == 'success' then notifyType = 'success' end
		if type == 'error' then notifyType = 'error' end
		
		TriggerEvent('QBCore:Notify', message, notifyType)
	end,

	-- Blip/Color Reference: --
	-- https://docs.fivem.net/docs/game-references/blips/ --
	
	-- Config Info: --
	-- "corners" = Contains 4 corner coordinates that define the zone boundaries --
		-- Each corner must have x, y, z coordinates --
		-- The 4 corners should form a rectangle/quad --
	-- "zone" = Contains the color and height of the zone. --
		-- "height" = The height of the zone walls (Default = 50.0) --
		-- "color" = The color of the zone. (RGB values: {r, g, b, a}) --
		--   Examples: --
		--     Red: {255, 0, 0, 100} --
		--     Green: {0, 255, 0, 100} --
		--     Blue: {0, 0, 255, 100} --
		--     Yellow: {255, 255, 0, 100} --
		--     Purple: {255, 0, 255, 100} --
		--     Orange: {255, 165, 0, 100} --
		--     White: {255, 255, 255, 100} --
		--     Alpha (transparency): 0 = invisible, 255 = fully opaque --
	-- "name" = The name/message of the zone. Shows when entering the zone. (Leave empty "" to disable notifications) --
	
	zones = {
		{
			corners = {
				{x = -728.38, y = 5755.16, z = 19.21},
				{x = -630.04, y = 5731.88, z = 29.22},
				{x = -645.84, y = 5921.77, z = 16.52},
				{x = -661.99, y = 5900.41, z = 17.03}
			},
			zone = {height = 100.0, color = {255, 0, 0, 35}}, 
			name = "Weekend Drug Zone"
		},
	}
	
}
