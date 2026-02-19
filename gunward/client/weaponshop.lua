Gunward.Client.WeaponShop = {}

local weaponPed = nil
local weaponShopOpen = false

function Gunward.Client.WeaponShop.CreatePed(teamName)
    Gunward.Client.WeaponShop.DeletePed()

    local coords = Config.WeaponShopPeds[teamName]
    if not coords then return end

    local model = 's_m_y_armymech_01'
    Gunward.Client.Utils.LoadModel(model)
    local hash = GetHashKey(model)

    weaponPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(weaponPed, true)
    SetEntityInvincible(weaponPed, true)
    SetBlockingOfNonTemporaryEvents(weaponPed, true)
    TaskStartScenarioInPlace(weaponPed, 'WORLD_HUMAN_GUARD_STAND', 0, true)
    SetEntityAsMissionEntity(weaponPed, true, true)

    SetModelAsNoLongerNeeded(hash)
    Gunward.Debug('Weapon shop PED created for team', teamName)
end

function Gunward.Client.WeaponShop.DeletePed()
    if weaponPed and DoesEntityExist(weaponPed) then
        DeleteEntity(weaponPed)
    end
    weaponPed = nil
end

function Gunward.Client.WeaponShop.OpenShop()
    if weaponShopOpen then return end

    ESX.TriggerServerCallback('gunward:server:getShopInfo', function(data)
        local balance      = data.balance
        local isPrivileged = data.isPrivileged
        local discount     = Config.WeaponDiscount -- e.g. 30

        -- Build weapons list with effective prices
        local weapons = {}
        for _, cat in ipairs(Config.WeaponCategories) do
            for _, wep in ipairs(Config.Weapons) do
                if wep.category == cat.id then
                    local effectivePrice = wep.price
                    if isPrivileged and effectivePrice > 0 then
                        effectivePrice = math.floor(effectivePrice * (100 - discount) / 100)
                    end
                    weapons[#weapons + 1] = {
                        weapon   = wep.weapon,
                        label    = wep.label,
                        price    = effectivePrice,
                        category = cat.label,
                    }
                end
            end
        end

        weaponShopOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action  = 'openWeaponShop',
            weapons = weapons,
            balance = balance,
        })
    end)
end

function Gunward.Client.WeaponShop.CloseShop()
    if not weaponShopOpen then return end
    weaponShopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeWeaponShop'})
end

-- NUI Callbacks
RegisterNUICallback('buyWeapon', function(data, cb)
    cb('ok')
    Gunward.Client.WeaponShop.CloseShop()
    TriggerServerEvent('gunward:server:buyWeapon', data.weapon)
end)

RegisterNUICallback('closeWeaponShop', function(_, cb)
    cb('ok')
    weaponShopOpen = false
    SetNuiFocus(false, false)
end)

-- Server tells us to remove all weapons from ped (safety net)
RegisterNetEvent('gunward:client:removeWeapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    Gunward.Debug('All weapons removed from ped')
end)

-- Retirer uniquement l'arme vendue du ped
RegisterNetEvent('gunward:client:removeSoldWeapon', function(itemName)
    RemoveWeaponFromPed(PlayerPedId(), GetHashKey(itemName))
end)

-- Interaction thread for weapon shop PED
CreateThread(function()
    while true do
        local sleep = 1000
        local team = Gunward.Client.Teams.GetCurrent()

        if team and Config.WeaponShopPeds[team] then
            local pedCoords = Config.WeaponShopPeds[team]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

            if dist < 15.0 then
                sleep = 0
                Gunward.Client.Utils.DrawText3D(
                    vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0),
                    '~w~Appuyez sur ~r~[E]~w~ - Boutique Armes'
                )

                if dist < 2.5 then
                    if IsControlJustPressed(0, 38) and not weaponShopOpen and not sellShopOpen then
                        Gunward.Client.WeaponShop.OpenShop()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Gunward.Client.WeaponShop.DeletePed()
        Gunward.Client.WeaponShop.DeleteSellPed()
    end
end)

-- =============================================
-- WEAPON SELL PED
-- =============================================

local sellPed = nil
local sellShopOpen = false

function Gunward.Client.WeaponShop.CreateSellPed(teamName)
    Gunward.Client.WeaponShop.DeleteSellPed()

    local coords = Config.WeaponSellPeds[teamName]
    if not coords then return end

    local model = 's_m_y_armymech_01'
    Gunward.Client.Utils.LoadModel(model)
    local hash = GetHashKey(model)

    sellPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(sellPed, true)
    SetEntityInvincible(sellPed, true)
    SetBlockingOfNonTemporaryEvents(sellPed, true)
    TaskStartScenarioInPlace(sellPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetEntityAsMissionEntity(sellPed, true, true)

    SetModelAsNoLongerNeeded(hash)
    Gunward.Debug('Weapon sell PED created for team', teamName)
end

function Gunward.Client.WeaponShop.DeleteSellPed()
    if sellPed and DoesEntityExist(sellPed) then
        DeleteEntity(sellPed)
    end
    sellPed = nil
end

function Gunward.Client.WeaponShop.OpenSellShop()
    if sellShopOpen then return end

    ESX.TriggerServerCallback('gunward:server:getPlayerWeapons', function(data)
        sellShopOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action  = 'openWeaponSell',
            weapons = data.weapons,
            balance = data.balance,
        })
    end)
end

function Gunward.Client.WeaponShop.CloseSellShop()
    if not sellShopOpen then return end
    sellShopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeWeaponSell'})
end

RegisterNUICallback('sellWeapon', function(data, cb)
    cb('ok')
    Gunward.Client.WeaponShop.CloseSellShop()
    TriggerServerEvent('gunward:server:sellWeapon', data.weapon)
end)

RegisterNUICallback('closeWeaponSell', function(_, cb)
    cb('ok')
    sellShopOpen = false
    SetNuiFocus(false, false)
end)

-- Thread d'interaction pour le ped de revente
CreateThread(function()
    while true do
        local sleep = 1000
        local team = Gunward.Client.Teams.GetCurrent()

        if team and Config.WeaponSellPeds[team] then
            local pedCoords = Config.WeaponSellPeds[team]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

            if dist < 15.0 then
                sleep = 0
                Gunward.Client.Utils.DrawText3D(
                    vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0),
                    '~w~Appuyez sur ~r~[E]~w~ - Revente Armes'
                )

                if dist < 2.5 then
                    if IsControlJustPressed(0, 38) and not sellShopOpen and not weaponShopOpen then
                        Gunward.Client.WeaponShop.OpenSellShop()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
