kCore = {}
local QBCore = exports['qb-core']:GetCoreObject()

kCore.registerCallback = QBCore.Functions.CreateCallback
kCore.usableItem = QBCore.Functions.CreateUsableItem

kCore.getPhrase = function(text)
    return Config.Locales[text] or ("%s - locale not found."):format(text)
end

kCore.getPlayer = function(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then
        return nil
    end

    local self = {}

    self.getIdentifier = function()
        return Player.PlayerData.license
    end

    self.getJob = function()
        return Player.PlayerData.job
    end

    self.showNotification = function(msg)
        return TriggerClientEvent("QBCore:Notify", playerId, msg)
    end

    self.getItem = function(itemName)
        return Player.Functions.GetItemByName(itemName)
    end

    self.getInventory = function()
        local dummy = {}
        for k, v in pairs(Player.PlayerData.items) do
            dummy[#dummy + 1] = { name = v.name, count = v.amount}
        end
        return dummy
    end

    self.getItemCount = function(itemName)
        local item = Player.Functions.GetItemByName(itemName)
        return item and item.amount or 0
    end

    self.addItem = function(itemName, count)
        return Player.Functions.AddItem(itemName, count)
    end
    
    self.removeItem = function(itemName, count)
        return Player.Functions.RemoveItem(itemName, count)
    end

    self.getMoney = function(moneyType)
        return Player.PlayerData.money[moneyType or "cash"]
    end

    self.addMoney = function(amount, moneyType)
        return Player.Functions.AddMoney((moneyType or "cash"), amount)
    end

    self.removeMoney = function(amount, moneyType)
        return Player.Functions.RemoveMoney((moneyType or "cash"), amount)
    end

    return self
end
