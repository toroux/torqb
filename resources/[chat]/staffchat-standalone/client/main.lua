-- Staff Chat Standalone
-- Created by Torou
-- Version 1.0.0

QBCore = nil
ESX = nil

-- Initialize framework
Citizen.CreateThread(function()
    if config.esx then
        ESX = exports["es_extended"]:getSharedObject()
    elseif config.qbcore then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

-- Staff Chat UI
local staffChatOpen = false
local staffChatMessages = {}

function openStaffChat()
    if staffChatOpen then return end
    
    staffChatOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openStaffChat',
        logoURL = config.UI and config.UI.LogoURL or nil,
        rgbEnabled = config.UI and config.UI.RGB or false,
        rgbBordersEnabled = config.UI and (config.UI.RGBBorders ~= nil and config.UI.RGBBorders or config.UI.RGB) or false,
        currentUserId = currentUserId
    })
end

function closeStaffChat()
    if not staffChatOpen then return end
    
    staffChatOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeStaffChat'
    })
end

-- NUI Callbacks
RegisterNUICallback('closeStaffChat', function(data, cb)
    closeStaffChat()
    cb('ok')
end)

RegisterNUICallback('sendStaffMessage', function(data, cb)
    if data.message and data.message:len() > 0 then
        TriggerServerEvent('staffchat:sendStaffMessage', data.message)
    end
    cb('ok')
end)

RegisterNUICallback('typingStatus', function(data, cb)
    TriggerServerEvent('staffchat:typingStatus', data.typing)
    cb('ok')
end)

RegisterNUICallback('editMessage', function(data, cb)
    if data.messageId and data.newMessage then
        TriggerServerEvent('staffchat:editMessage', data.messageId, data.newMessage)
    end
    cb('ok')
end)

RegisterNUICallback('deleteMessage', function(data, cb)
    if data.messageId then
        TriggerServerEvent('staffchat:deleteMessage', data.messageId)
    end
    cb('ok')
end)

RegisterNUICallback('pinMessage', function(data, cb)
    if data.messageId then
        TriggerServerEvent('staffchat:pinMessage', data.messageId)
    end
    cb('ok')
end)

RegisterNUICallback('toggleReaction', function(data, cb)
    if data.messageId and data.emoji then
        TriggerServerEvent('staffchat:toggleReaction', data.messageId, data.emoji)
    end
    cb('ok')
end)

RegisterNUICallback('requestAvatarSettings', function(data, cb)
    TriggerServerEvent('staffchat:requestAvatarSettings')
    cb('ok')
end)

RegisterNUICallback('saveAvatar', function(data, cb)
    if data.url and data.url:len() > 0 then
        TriggerServerEvent('staffchat:saveAvatar', data.url)
    end
    cb('ok')
end)

RegisterNUICallback('removeAvatar', function(data, cb)
    TriggerServerEvent('staffchat:removeAvatar')
    cb('ok')
end)

RegisterNUICallback('proceedToChat', function(data, cb)
    -- Ensure NUI focus is maintained
    if not staffChatOpen then
        staffChatOpen = true
        SetNuiFocus(true, true)
    end
    SendNUIMessage({
        action = 'openChatRoom',
        logoURL = config.UI and config.UI.LogoURL or nil,
        rgbEnabled = config.UI and config.UI.RGB or false,
        rgbBordersEnabled = config.UI and (config.UI.RGBBorders ~= nil and config.UI.RGBBorders or config.UI.RGB) or false,
        currentUserId = currentUserId
    })
    cb('ok')
end)

-- Get current user ID for client
local currentUserId = nil
CreateThread(function()
    while true do
        Wait(1000)
        if QBCore then
            local Player = QBCore.Functions.GetPlayerData()
            if Player and Player.citizenid then
                currentUserId = Player.citizenid
            end
        end
    end
end)

-- Receive updated message
RegisterNetEvent('staffchat:updateMessage', function(messageId, newMessage, edited)
    SendNUIMessage({
        action = 'updateMessage',
        messageId = messageId,
        newMessage = newMessage,
        edited = edited
    })
end)

-- Receive message deletion
RegisterNetEvent('staffchat:removeMessage', function(messageId)
    SendNUIMessage({
        action = 'removeMessage',
        messageId = messageId
    })
end)

-- Receive reaction updates
RegisterNetEvent('staffchat:updateReactions', function(messageId, reactions)
    SendNUIMessage({
        action = 'updateReactions',
        messageId = messageId,
        reactions = reactions
    })
end)

-- Receive staff list updates
RegisterNetEvent('staffchat:updateStaffList', function(staffList)
    SendNUIMessage({
        action = 'updateStaffList',
        staffList = staffList
    })
end)

-- Receive typing indicator updates
RegisterNetEvent('staffchat:updateTyping', function(typingUsers)
    SendNUIMessage({
        action = 'updateTyping',
        typingUsers = typingUsers
    })
end)

-- Receive avatar settings from server
RegisterNetEvent('staffchat:loadAvatarSettings', function(currentAvatar)
    SendNUIMessage({
        action = 'loadAvatarSettings',
        currentAvatar = currentAvatar
    })
end)

-- Avatar saved confirmation
RegisterNetEvent('staffchat:avatarSaved', function(avatarUrl)
    SendNUIMessage({
        action = 'avatarSaved',
        avatarUrl = avatarUrl
    })
    if lib then
        lib.notify({
            title = 'Profile Picture',
            description = 'Avatar updated successfully!',
            type = 'success',
            duration = 3000
        })
    end
end)

-- Avatar removed confirmation
RegisterNetEvent('staffchat:avatarRemoved', function()
    SendNUIMessage({
        action = 'avatarRemoved'
    })
    if lib then
        lib.notify({
            title = 'Profile Picture',
            description = 'Avatar removed successfully!',
            type = 'success',
            duration = 3000
        })
    end
end)

-- Load staff messages
RegisterNetEvent('staffchat:loadStaffMessages', function(messages)
    if messages and #messages > 0 then
        SendNUIMessage({
            action = 'loadMessages',
            messages = messages
        })
    end
end)

-- Open staff chat from server (updated to request staff list)
RegisterNetEvent('staffchat:openStaffChat', function()
    openStaffChat()
    TriggerServerEvent('staffchat:requestStaffList')
end)

-- Update staff list periodically
CreateThread(function()
    while true do
        Wait(5000) -- Update every 5 seconds
        if staffChatOpen then
            TriggerServerEvent('staffchat:requestStaffList')
        end
    end
end)

-- Receive staff messages
RegisterNetEvent('staffchat:receiveStaffMessage', function(sender, message, time, avatar, messageId, pinned, reactions, edited, fullTimestamp, senderId)
    table.insert(staffChatMessages, {
        sender = sender,
        message = message,
        time = time,
        avatar = avatar,
        id = messageId,
        pinned = pinned,
        reactions = reactions,
        edited = edited,
        fullTimestamp = fullTimestamp,
        senderId = senderId
    })
    
    -- Keep only last 100 messages
    if #staffChatMessages > 100 then
        table.remove(staffChatMessages, 1)
    end
    
    if staffChatOpen then
        SendNUIMessage({
            action = 'addMessage',
            sender = sender,
            message = message,
            time = time,
            avatar = avatar,
            messageId = messageId,
            pinned = pinned,
            reactions = reactions,
            edited = edited,
            fullTimestamp = fullTimestamp,
            senderId = senderId
        })
    else
        -- Show ox_lib notification when chat is closed
        -- Include avatar in the notification description
        local notificationDescription
        if avatar then
            -- Include avatar image in description using HTML-like format
            notificationDescription = '<img src="' .. avatar .. '" style="width:32px;height:32px;border-radius:50%;border:2px solid #FFD700;vertical-align:middle;margin-right:8px;display:inline-block;"> <strong>' .. sender .. '</strong>: ' .. message
        else
            notificationDescription = '<strong>' .. sender .. '</strong>: ' .. message
        end
        
        if lib then
            lib.notify({
                title = 'Staff Chat',
                description = notificationDescription,
                type = 'info',
                position = 'top',
                duration = 5000,
                style = {
                    backgroundColor = '#FFD700',
                    color = '#1a1a1a',
                    ['.description'] = {
                        color = '#1a1a1a',
                    }
                },
                icon = 'shield-halved',
                iconColor = '#1a1a1a'
            })
        end
    end
end)

-- Staff Announcement Notification
RegisterNetEvent('staffchat:staffAnnouncement', function(sender, message, avatar)
    -- Show improved ox_lib notification with better styling
    if lib then
        lib.notify({
            title = '📢 Staff Announcement',
            description = sender .. '\n\n' .. message,
            type = 'info',
            position = 'top',
            duration = 10000, -- 10 seconds for announcements
            style = {
                backgroundColor = '#1a1a1a',
                color = '#FFD700',
                border = '2px solid #FFD700',
                borderRadius = '8px',
                padding = '16px',
                boxShadow = '0 4px 12px rgba(255, 215, 0, 0.3)',
                ['.title'] = {
                    color = '#FFD700',
                    fontWeight = 'bold',
                    fontSize = '16px',
                    marginBottom = '8px'
                },
                ['.description'] = {
                    color = '#ffffff',
                    fontSize = '14px',
                    lineHeight = '1.5',
                    marginTop = '8px'
                }
            },
            icon = 'bullhorn',
            iconColor = '#FFD700'
        })
    end
end)

-- ESC key to close
CreateThread(function()
    while true do
        Wait(0)
        if staffChatOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                closeStaffChat()
            end
        end
    end
end)

