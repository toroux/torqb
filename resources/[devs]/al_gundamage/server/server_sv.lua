local QBCore = exports['qb-core']:GetCoreObject()

function SendDiscordWebhook(adminName, weapon, damage, recoil)
    if Config.Webhook == "" or not Config.Webhook then return end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    local embed = {
        {
            ["title"] = "Weapon Tuning Log",
            ["color"] = 16711680,
            ["fields"] = {
                {
                    ["name"] = "Admin",
                    ["value"] = adminName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Weapon",
                    ["value"] = weapon,
                    ["inline"] = true
                },
                {
                    ["name"] = "Damage",
                    ["value"] = tostring(damage),
                    ["inline"] = true
                },
                {
                    ["name"] = "Recoil",
                    ["value"] = tostring(recoil),
                    ["inline"] = true
                },
                {
                    ["name"] = "Timestamp",
                    ["value"] = timestamp,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Weapon Tuning System"
            }
        }
    }
    
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({username = "Weapon Tuning", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

QBCore.Commands.Add('setWeaponDamage', "Change Weapon Damage (License Only)", {{name='weaponname', help='Name of the weapon (spawncode)'}, {name='damage', help='Damage of the weapon (exmp: 0.8)'}}, false, function(source, args)
    local src = source
    local weaponname = args[1]
    local damage = tonumber(args[2])
    local hasPermission = false
    for k, v in pairs(Config.License) do
        local license = QBCore.Functions.GetPlayer(src).PlayerData.license
        if license == v then
            hasPermission = true
            break
        end
    end
    if hasPermission then
        if weaponname and damage then
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM guns_damage_table WHERE weapon = @weapon', {
                ['@weapon'] = weaponname
            }, function(count)
                if count > 0 then
                    MySQL.Async.execute('UPDATE guns_damage_table SET damage = @damage WHERE weapon = @weapon', {
                        ['@weapon'] = weaponname,
                        ['@damage'] = damage
                    }, function(rowsChanged)
                    end)
                    TriggerClientEvent('QBCore:Notify', src, "You updated the damage for "..weaponname.." to "..damage, 'success')
                else
                    MySQL.Async.execute('INSERT INTO guns_damage_table (weapon, damage) VALUES (@weapon, @damage)', {
                        ['@weapon'] = weaponname,
                        ['@damage'] = damage
                    }, function(rowsChanged)
                    end)
                    TriggerClientEvent('QBCore:Notify', src, "You added damage for "..weaponname.." to "..damage, 'success')
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, "Failed To Set Weapon Damage", 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You do not have permission to use this command.", 'error')
    end
    TriggerClientEvent("derrick_gun_damage:client:setWeaponDamageSolo", -1, {weapon = weaponname, damage = damage})
    
    if hasPermission then
        TriggerClientEvent('QBCore:Notify', src, "The damage for "..weaponname.." was inserted to the database & is ready to go", 'success')
    end
end, 'admin')

QBCore.Commands.Add('setWeaponRecoil', "Change Weapon Recoil (License Only)", {{name='weaponname', help='Name of the weapon (spawncode)'}, {name='recoil', help='Recoil of the weapon (exmp: 0.8)'}}, false, function(source, args)
    local src = source
    local weaponname = args[1]
    local recoil = tonumber(args[2])
    local hasPermission = false
    for k, v in pairs(Config.License) do
        local license = QBCore.Functions.GetPlayer(src).PlayerData.license
        if license == v then
            hasPermission = true
            break
        end
    end
    if hasPermission then
        if weaponname and recoil then
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM guns_recoil_table WHERE weapon = @weapon', {
                ['@weapon'] = weaponname
            }, function(count)
                if count > 0 then
                    MySQL.Async.execute('UPDATE guns_recoil_table SET recoil = @recoil WHERE weapon = @weapon', {
                        ['@weapon'] = weaponname,
                        ['@recoil'] = recoil
                    }, function(rowsChanged)
                    end)
                    TriggerClientEvent('QBCore:Notify', src, "You updated the recoil for "..weaponname.." to "..recoil, 'success')
                else
                    MySQL.Async.execute('INSERT INTO guns_recoil_table (weapon, recoil) VALUES (@weapon, @recoil)', {
                        ['@weapon'] = weaponname,
                        ['@recoil'] = recoil
                    }, function(rowsChanged)
                    end)
                    TriggerClientEvent('QBCore:Notify', src, "You updated the recoil for "..weaponname.." to "..recoil, 'success')
                end
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, "Failed To Set Weapon Recoil", 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You do not have permission to use this command.", 'error')
    end
    TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoilSolo", -1, {weapon = weaponname, recoil = recoil})
end, 'admin')

local cachedWeapons = nil

local function LoadWeaponsFromOxInventory()
    if cachedWeapons then
        return cachedWeapons
    end
    
    local weapons = {}
    
    if GetResourceState('ox_inventory') == 'started' then
        local success, ItemList = pcall(function()
            return exports.ox_inventory:Items()
        end)
        
        if success and ItemList then
            for itemName, itemData in pairs(ItemList) do
                if itemData and itemData.weapon == true then
                    table.insert(weapons, itemName)
                end
            end
        end
    end
    
    if #weapons == 0 then
        local weaponsData = LoadResourceFile('ox_inventory', 'data/weapons.lua')
        if weaponsData then
            local success, result = pcall(function()
                local func = load(weaponsData)
                if func then
                    return func()
                end
            end)
            
            if success and result and result.Weapons then
                for weaponName, _ in pairs(result.Weapons) do
                    table.insert(weapons, weaponName)
                end
            end
        end
    end
    
    table.sort(weapons)
    
    if #weapons > 0 then
        cachedWeapons = weapons
    end
    
    return weapons
end

AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
    CreateThread(function()
        Wait(1000)
        
        LoadWeaponsFromOxInventory()
        
        local weaponData = {}
        MySQL.Async.fetchAll('SELECT weapon, damage FROM guns_damage_table', {}, function(results)
            for _, row in ipairs(results) do
                local weapon = row.weapon
                local damage = tonumber(row.damage)
                table.insert(weaponData, { weapon = weapon, damage = damage })
            end
            TriggerClientEvent("derrick_gun_damage:client:setWeaponDamage", -1, weaponData)
        end)

        MySQL.Async.fetchAll('SELECT weapon, recoil FROM guns_recoil_table', {}, function(results)
            local recoilData = {}
            for _, row in ipairs(results) do
                local weapon = row.weapon
                local recoil = tonumber(row.recoil)
                table.insert(recoilData, { weapon = weapon, recoil = recoil })
            end
            TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoil", -1, recoilData)
        end)
    end)
end)

local damages = {}
local recoilData = {}

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT weapon, damage FROM guns_damage_table', {}, function(results)
        for _, row in ipairs(results) do
            local weapon = row.weapon
            local damage = tonumber(row.damage)
            table.insert(damages, { weapon = weapon, damage = damage })
        end
    end)

    MySQL.Async.fetchAll('SELECT weapon, recoil FROM guns_recoil_table', {}, function(results)
        for _, row in ipairs(results) do
            local weapon = row.weapon
            local recoil = tonumber(row.recoil)
            table.insert(recoilData, { weapon = weapon, recoil = recoil })
        end
    end)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    Wait(4000)
    TriggerClientEvent("derrick_gun_damage:client:setWeaponDamage", Player.PlayerData.source, damages)
    TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoil", Player.PlayerData.source, recoilData)
end)

function fetchGunDurabilities(weaponname)
    local promise = promise.new()
    MySQL.Async.fetchAll('SELECT durability FROM guns_durability_table WHERE weapon = @weapon ', {
        ['@weapon'] = weaponname
    }, function(result)
        if result and #result > 0 then
            promise:resolve(result[1].durability)
        else
            promise:resolve(0.30)
        end
    end)

    return Citizen.Await(promise)
end

exports('fetchGunDurabilities', fetchGunDurabilities)

RegisterNetEvent('derrick_gun_damage:server:getPlayerWeapons', function()
    local src = source
    local weapons = LoadWeaponsFromOxInventory()
    TriggerClientEvent('derrick_gun_damage:client:updateWeaponList', src, weapons)
end)

RegisterNetEvent('derrick_gun_damage:server:getWeaponStats', function(weapon)
    local src = source
    
    MySQL.Async.fetchScalar('SELECT damage FROM guns_damage_table WHERE weapon = @weapon', {
        ['@weapon'] = weapon
    }, function(damage)
        local damageValue = damage and tonumber(damage) or Config.Tuning.DefaultDamage
        
        MySQL.Async.fetchScalar('SELECT recoil FROM guns_recoil_table WHERE weapon = @weapon', {
            ['@weapon'] = weapon
        }, function(recoil)
            local recoilValue = recoil and tonumber(recoil) or Config.Tuning.DefaultRecoil
            
            TriggerClientEvent('derrick_gun_damage:client:weaponStats', src, weapon, damageValue, recoilValue)
        end)
    end)
end)

RegisterNetEvent('derrick_gun_damage:server:applyTuning', function(weapon, damage, recoil)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    damage = math.max(Config.Tuning.MinDamage, math.min(Config.Tuning.MaxDamage, tonumber(damage) or Config.Tuning.DefaultDamage))
    recoil = math.max(Config.Tuning.MinRecoil, math.min(Config.Tuning.MaxRecoil, tonumber(recoil) or Config.Tuning.DefaultRecoil))
    
    local hasPermission = false
    for k, v in pairs(Config.License) do
        local license = Player.PlayerData.license
        if license == v then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        TriggerClientEvent('QBCore:Notify', src, "You do not have permission to tune weapons.", 'error')
        return
    end
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM guns_damage_table WHERE weapon = @weapon', {
        ['@weapon'] = weapon
    }, function(count)
        if count > 0 then
            MySQL.Async.execute('UPDATE guns_damage_table SET damage = @damage WHERE weapon = @weapon', {
                ['@weapon'] = weapon,
                ['@damage'] = damage
            }, function(rowsChanged)
                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM guns_recoil_table WHERE weapon = @weapon', {
                    ['@weapon'] = weapon
                }, function(recoilCount)
                    if recoilCount > 0 then
                        MySQL.Async.execute('UPDATE guns_recoil_table SET recoil = @recoil WHERE weapon = @weapon', {
                            ['@weapon'] = weapon,
                            ['@recoil'] = recoil
                        }, function()
                            LogTuningAction(src, Player, weapon, damage, recoil)
                            
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponDamageSolo", -1, {weapon = weapon, damage = damage})
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoilSolo", -1, {weapon = weapon, recoil = recoil})
                            
                            TriggerClientEvent('QBCore:Notify', src, "Weapon tuning applied successfully!", 'success')
                        end)
                    else
                        MySQL.Async.execute('INSERT INTO guns_recoil_table (weapon, recoil) VALUES (@weapon, @recoil)', {
                            ['@weapon'] = weapon,
                            ['@recoil'] = recoil
                        }, function()
                            LogTuningAction(src, Player, weapon, damage, recoil)
                            
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponDamageSolo", -1, {weapon = weapon, damage = damage})
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoilSolo", -1, {weapon = weapon, recoil = recoil})
                            
                            TriggerClientEvent('QBCore:Notify', src, "Weapon tuning applied successfully!", 'success')
                        end)
                    end
                end)
            end)
        else
            MySQL.Async.execute('INSERT INTO guns_damage_table (weapon, damage) VALUES (@weapon, @damage)', {
                ['@weapon'] = weapon,
                ['@damage'] = damage
            }, function()
                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM guns_recoil_table WHERE weapon = @weapon', {
                    ['@weapon'] = weapon
                }, function(recoilCount)
                    if recoilCount > 0 then
                        MySQL.Async.execute('UPDATE guns_recoil_table SET recoil = @recoil WHERE weapon = @weapon', {
                            ['@weapon'] = weapon,
                            ['@recoil'] = recoil
                        }, function()
                            LogTuningAction(src, Player, weapon, damage, recoil)
                            
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponDamageSolo", -1, {weapon = weapon, damage = damage})
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoilSolo", -1, {weapon = weapon, recoil = recoil})
                            
                            TriggerClientEvent('QBCore:Notify', src, "Weapon tuning applied successfully!", 'success')
                        end)
                    else
                        MySQL.Async.execute('INSERT INTO guns_recoil_table (weapon, recoil) VALUES (@weapon, @recoil)', {
                            ['@weapon'] = weapon,
                            ['@recoil'] = recoil
                        }, function()
                            LogTuningAction(src, Player, weapon, damage, recoil)
                            
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponDamageSolo", -1, {weapon = weapon, damage = damage})
                            TriggerClientEvent("derrick_gun_damage:client:setWeaponRecoilSolo", -1, {weapon = weapon, recoil = recoil})
                            
                            TriggerClientEvent('QBCore:Notify', src, "Weapon tuning applied successfully!", 'success')
                        end)
                    end
                end)
            end)
        end
    end)
end)

RegisterNetEvent('derrick_gun_damage:server:getAllWeapons', function()
    local src = source
    
    local defaultRecoil = Config.Tuning.DefaultRecoil
    MySQL.Async.fetchAll('SELECT d.weapon, d.damage, COALESCE(r.recoil, @defaultRecoil) as recoil FROM guns_damage_table d LEFT JOIN guns_recoil_table r ON d.weapon = r.weapon', {
        ['@defaultRecoil'] = defaultRecoil
    }, function(results)
        local weapons = {}
        for _, row in ipairs(results) do
            table.insert(weapons, {
                weapon = row.weapon,
                name = row.weapon,
                damage = tonumber(row.damage) or Config.Tuning.DefaultDamage,
                recoil = tonumber(row.recoil) or Config.Tuning.DefaultRecoil
            })
        end
        
        TriggerClientEvent('derrick_gun_damage:client:allWeapons', src, weapons)
    end)
end)

RegisterNetEvent('derrick_gun_damage:server:checkPermission', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local hasPermission = false
    for k, v in pairs(Config.License) do
        local license = Player.PlayerData.license
        if license == v then
            hasPermission = true
            break
        end
    end
    
    if hasPermission then
        TriggerClientEvent('derrick_gun_damage:client:permissionGranted', src)
    else
        TriggerClientEvent('derrick_gun_damage:client:permissionDenied', src)
    end
end)

function LogTuningAction(src, Player, weapon, damage, recoil)
    local playerName = GetPlayerName(src)
    local citizenid = Player.PlayerData.citizenid
    local license = Player.PlayerData.license
    
    MySQL.Async.execute('INSERT INTO weapon_tuning_logs (player_name, citizenid, license, weapon, damage, recoil, timestamp) VALUES (@player_name, @citizenid, @license, @weapon, @damage, @recoil, NOW())', {
        ['@player_name'] = playerName,
        ['@citizenid'] = citizenid,
        ['@license'] = license,
        ['@weapon'] = weapon,
        ['@damage'] = damage,
        ['@recoil'] = recoil
    }, function(rowsChanged)
        SendDiscordWebhook(playerName, weapon, damage, recoil)
    end)
end

CreateThread(function()
    Wait(1000)
    
    -- Create guns_damage_table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `guns_damage_table` (
            `weapon` VARCHAR(100) NOT NULL,
            `damage` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
            PRIMARY KEY (`weapon`),
            INDEX `idx_weapon` (`weapon`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {}, function(result)
    end)
    
    -- Create guns_recoil_table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `guns_recoil_table` (
            `weapon` VARCHAR(100) NOT NULL,
            `recoil` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
            PRIMARY KEY (`weapon`),
            INDEX `idx_weapon` (`weapon`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {}, function(result)
    end)
    
    -- Create guns_durability_table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `guns_durability_table` (
            `weapon` VARCHAR(100) NOT NULL,
            `durability` DECIMAL(5,2) NOT NULL DEFAULT 0.30,
            PRIMARY KEY (`weapon`),
            INDEX `idx_weapon` (`weapon`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {}, function(result)
    end)
    
    -- Create weapon_tuning_logs
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS weapon_tuning_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(255) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            license VARCHAR(255) NOT NULL,
            weapon VARCHAR(100) NOT NULL,
            damage DECIMAL(5,2) NOT NULL,
            recoil DECIMAL(5,2) NOT NULL,
            timestamp DATETIME NOT NULL,
            INDEX idx_citizenid (citizenid),
            INDEX idx_weapon (weapon),
            INDEX idx_timestamp (timestamp)
        )
    ]], {}, function(result)
    end)
end)