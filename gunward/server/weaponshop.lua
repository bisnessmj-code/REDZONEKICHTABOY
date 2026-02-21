Gunward.Server.WeaponShop = {}

local playerWeapons = {} -- playerWeapons[source] = { 'weapon_pistol', 'weapon_smg', ... }

-- Find weapon config by weapon name
local function GetWeaponConfig(weapon)
    for _, wep in ipairs(Config.Weapons) do
        if wep.weapon == weapon then
            return wep
        end
    end
    return nil
end

-- Convert WEAPON_PISTOL to weapon_pistol (inventory item name)
local function ToItemName(weapon)
    return weapon:lower()
end

-- Returns the effective buy price for a player (applies discount for privileged groups)
local function GetEffectiveWeaponPrice(source, basePrice)
    if basePrice <= 0 then return 0 end
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and Config.PrivilegedGroups[xPlayer.getGroup() or ''] then
        return math.floor(basePrice * (100 - Config.WeaponDiscount) / 100)
    end
    return basePrice
end

-- Remove all gunward weapons from player inventory
function Gunward.Server.WeaponShop.CleanupPlayerWeapons(source)
    local weapons = playerWeapons[source]
    if not weapons or #weapons == 0 then
        playerWeapons[source] = nil
        return
    end

    for _, itemName in ipairs(weapons) do
        exports['qs-inventory']:RemoveItem(source, itemName, 1)
    end

    Gunward.Debug('Cleaned up', #weapons, 'weapons for player', source)
    playerWeapons[source] = nil
end

-- Callback: retourne les armes achetées par le joueur (via table de suivi) + son solde
ESX.RegisterServerCallback('gunward:server:getPlayerWeapons', function(source, cb)
    if not Gunward.Server.Teams.IsPlayerInGunward(source) then
        cb({weapons = {}, balance = 0})
        return
    end

    local ownedWeapons = {}
    local seen = {}
    local tracked = playerWeapons[source] or {}

    for _, itemName in ipairs(tracked) do
        if not seen[itemName] then
            seen[itemName] = true
            for _, wep in ipairs(Config.Weapons) do
                if ToItemName(wep.weapon) == itemName then
                    local sellPrice = math.floor(wep.price * Config.WeaponSellPercent / 100)
                    ownedWeapons[#ownedWeapons + 1] = {
                        weapon    = wep.weapon,
                        label     = wep.label,
                        buyPrice  = GetEffectiveWeaponPrice(source, wep.price),
                        sellPrice = sellPrice,
                    }
                    break
                end
            end
        end
    end

    Gunward.Server.Database.GetBank(source, function(balance)
        cb({weapons = ownedWeapons, balance = balance})
    end)
end)

-- Sell weapon event
RegisterNetEvent('gunward:server:sellWeapon', function(weapon)
    local source = source

    if not Gunward.Server.Teams.IsPlayerInGunward(source) then
        Gunward.Server.Utils.Notify(source, 'Vous devez etre dans le Gunward', 'error')
        return
    end

    local wepConfig = GetWeaponConfig(weapon)
    if not wepConfig then
        Gunward.Server.Utils.Notify(source, 'Arme invalide', 'error')
        return
    end

    local itemName = ToItemName(weapon)

    -- Vérifier et retirer de la table de suivi
    local found = false
    if playerWeapons[source] then
        for i, w in ipairs(playerWeapons[source]) do
            if w == itemName then
                found = true
                table.remove(playerWeapons[source], i)
                break
            end
        end
    end

    if not found then
        Gunward.Server.Utils.Notify(source, 'Vous n\'avez pas cette arme', 'error')
        return
    end

    exports['qs-inventory']:RemoveItem(source, itemName, 1)

    -- Retirer l'arme du ped physiquement
    TriggerClientEvent('gunward:client:removeSoldWeapon', source, itemName)

    local sellPrice = math.floor(wepConfig.price * Config.WeaponSellPercent / 100)
    if sellPrice > 0 then
        Gunward.Server.Database.AddBank(source, sellPrice)
    end

    Gunward.Server.Utils.Notify(source, 'Arme revendue pour $' .. sellPrice, 'success')

    Gunward.Server.Database.GetBank(source, function(newBalance)
        TriggerClientEvent('gunward:client:updateBank', source, newBalance)
    end)
end)

-- Buy weapon event
RegisterNetEvent('gunward:server:buyWeapon', function(weapon)
    local source = source

    -- Validate player is in gunward
    if not Gunward.Server.Teams.IsPlayerInGunward(source) then
        Gunward.Server.Utils.Notify(source, 'Vous devez etre dans le Gunward', 'error')
        return
    end

    -- Validate weapon exists in config
    local wepConfig = GetWeaponConfig(weapon)
    if not wepConfig then
        Gunward.Server.Utils.Notify(source, 'Arme invalide', 'error')
        return
    end

    local itemName = ToItemName(weapon)

    -- Check and deduct money (discount for privileged groups)
    local price = GetEffectiveWeaponPrice(source, wepConfig.price)
    if price > 0 then
        Gunward.Server.Database.RemoveBank(source, price, function(success)
            if not success then
                Gunward.Server.Utils.Notify(source, 'Solde insuffisant', 'error')
                return
            end

            -- Give weapon via qs-inventory (inventory tracking)
            exports['qs-inventory']:GiveWeaponToPlayer(source, itemName, Config.WeaponAmmo)
            -- Donner directement au PED (CanUseInventory est bloqué en Gunward)
            TriggerClientEvent('gunward:client:giveWeaponToPed', source, itemName, Config.WeaponAmmo)

            -- Track weapon for cleanup on leave
            if not playerWeapons[source] then
                playerWeapons[source] = {}
            end
            playerWeapons[source][#playerWeapons[source] + 1] = itemName

            Gunward.Server.Utils.Notify(source, 'Arme achetee!', 'success')

            -- Send updated balance
            Gunward.Server.Database.GetBank(source, function(newBalance)
                TriggerClientEvent('gunward:client:updateBank', source, newBalance)
            end)
        end)
    else
        -- Free weapon, give directly
        exports['qs-inventory']:GiveWeaponToPlayer(source, itemName, Config.WeaponAmmo)
        TriggerClientEvent('gunward:client:giveWeaponToPed', source, itemName, Config.WeaponAmmo)

        if not playerWeapons[source] then
            playerWeapons[source] = {}
        end
        playerWeapons[source][#playerWeapons[source] + 1] = itemName

        Gunward.Server.Utils.Notify(source, 'Arme achetee!', 'success')
    end
end)

-- Re-donner toutes les armes Gunward au PED après mort/respawn
RegisterNetEvent('gunward:server:requestWeaponRestore', function()
    local source = source
    if not Gunward.Server.Teams.IsPlayerInGunward(source) then return end
    local weapons = playerWeapons[source] or {}
    for _, itemName in ipairs(weapons) do
        TriggerClientEvent('gunward:client:giveWeaponToPed', source, itemName, Config.WeaponAmmo)
    end
end)
