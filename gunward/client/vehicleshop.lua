Gunward.Client.VehicleShop = {}

local shopPed = nil
local shopOpen = false

function Gunward.Client.VehicleShop.CreatePed(teamName)
    Gunward.Client.VehicleShop.DeletePed()

    local coords = Config.VehicleShopPeds[teamName]
    if not coords then return end

    local model = 's_m_y_marine_03'
    Gunward.Client.Utils.LoadModel(model)
    local hash = GetHashKey(model)

    shopPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(shopPed, true)
    SetEntityInvincible(shopPed, true)
    SetBlockingOfNonTemporaryEvents(shopPed, true)
    TaskStartScenarioInPlace(shopPed, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    SetEntityAsMissionEntity(shopPed, true, true)

    SetModelAsNoLongerNeeded(hash)
    Gunward.Debug('Vehicle shop PED created for team', teamName)
end

function Gunward.Client.VehicleShop.DeletePed()
    if shopPed and DoesEntityExist(shopPed) then
        DeleteEntity(shopPed)
    end
    shopPed = nil
end

function Gunward.Client.VehicleShop.OpenShop()
    if shopOpen then return end

    ESX.TriggerServerCallback('gunward:server:getShopInfo', function(data)
        local balance      = data.balance
        local isPrivileged = data.isPrivileged

        -- Build vehicle list with effective prices
        local vehicles = {}
        for _, veh in ipairs(Config.Vehicles) do
            vehicles[#vehicles + 1] = {
                model  = veh.model,
                label  = veh.label,
                price  = isPrivileged and 0 or veh.price,
            }
        end

        shopOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action   = 'openVehicleShop',
            vehicles = vehicles,
            balance  = balance,
        })
    end)
end

function Gunward.Client.VehicleShop.CloseShop()
    if not shopOpen then return end
    shopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeVehicleShop'})
end

-- NUI Callbacks
RegisterNUICallback('buyVehicle', function(data, cb)
    cb('ok')
    Gunward.Client.VehicleShop.CloseShop()
    TriggerServerEvent('gunward:server:buyVehicle', data.model)
end)

RegisterNUICallback('closeVehicleShop', function(_, cb)
    cb('ok')
    shopOpen = false
    SetNuiFocus(false, false)
end)

-- Receive vehicle from server
RegisterNetEvent('gunward:client:spawnVehicle', function(netId)
    local timeout = 0
    while not NetworkDoesNetworkIdExist(netId) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    if not NetworkDoesNetworkIdExist(netId) then
        Gunward.Client.Utils.Notify('Erreur: vehicule introuvable', 'error')
        return
    end

    local vehicle = NetToVeh(netId)
    local ped = PlayerPedId()
    local team = Gunward.Client.Teams.GetCurrent()

    -- Apply team color
    if team and Config.TeamVehicleColors[team] then
        local colors = Config.TeamVehicleColors[team]
        SetVehicleColours(vehicle, colors.primary, colors.secondary)
    end

    -- Warp player into vehicle
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    Gunward.Client.Utils.Notify('Vehicule spawn!', 'success')
end)

-- Update balance after purchase
RegisterNetEvent('gunward:client:updateBank', function(newBalance)
    SendNUIMessage({
        action = 'updateBalance',
        balance = newBalance,
    })
end)

-- Interaction thread for vehicle shop PED
CreateThread(function()
    while true do
        local sleep = 1000
        local team = Gunward.Client.Teams.GetCurrent()

        if team and Config.VehicleShopPeds[team] then
            local pedCoords = Config.VehicleShopPeds[team]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

            if dist < 15.0 then
                sleep = 0
                Gunward.Client.Utils.DrawText3D(
                    vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0),
                    '~w~Appuyez sur ~r~[E]~w~ - Boutique Vehicules'
                )

                if dist < 2.5 then
                    if IsControlJustPressed(0, 38) and not shopOpen then
                        Gunward.Client.VehicleShop.OpenShop()
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
        Gunward.Client.VehicleShop.DeletePed()
    end
end)
