RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "hideCursor"
    })
end)

-- Handle URL opening from NUI
RegisterNUICallback('openUrl', function(data, cb)
    if data.url then
        print("Opening URL: " .. data.url)
        
        -- Try multiple methods to open URL
        local success = false
        
        -- Method 1: Use ShellExecute
        pcall(function()
            os.execute('start "" "' .. data.url .. '"')
            success = true
        end)
        
        -- Method 2: If on Linux/Mac
        if not success then
            pcall(function()
                os.execute('xdg-open "' .. data.url .. '"')
                success = true
            end)
        end
        
        -- Method 3: Alternative Windows method
        if not success then
            pcall(function()
                os.execute('explorer "' .. data.url .. '"')
                success = true
            end)
        end
        
        if success then
            print("URL opened successfully")
        else
            print("Failed to open URL")
        end
    end
    cb('ok')
end)

-- Handle NUI messages for URL opening
RegisterNUICallback('openLink', function(data, cb)
    if data.url then
        print("Received openLink request for: " .. data.url)
        
        -- Direct command execution
        ExecuteCommand('start "" "' .. data.url .. '"')
    end
    cb('ok')
end)

-- Alternative event handler
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    print("Loading screen resource started")
end)
