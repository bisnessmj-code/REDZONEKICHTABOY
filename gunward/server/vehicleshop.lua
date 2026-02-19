Gunward.Server.VehicleShop = {}

local playerVehicles = {}

-- Find vehicle config by model name
local function GetVehicleConfig(model)
    for _, veh in ipairs(Config.Vehicles) do
        if veh.model == model then
            return veh
        end
    end
    return nil
end

-- Delete a player's existing vehicle
function Gunward.Server.VehicleShop.DeletePlayerVehicle(source)
    local data = playerVehicles[source]
    if not data then return end

    if data.entity and DoesEntityExist(data.entity) then
        DeleteEntity(data.entity)
    end

    playerVehicles[source] = nil
    Gunward.Debug('Deleted vehicle for player', source)
end

-- Get fixed spawn position for team
local function GetSpawnPosition(source)
    local team = Gunward.Server.Teams.GetPlayerTeam(source)
    if not team or not Config.VehicleSpawnPoints[team] then
        return nil, 0
    end
    local sp = Config.VehicleSpawnPoints[team]
    return vector3(sp.x, sp.y, sp.z), sp.w
end

-- Buy vehicle event
RegisterNetEvent('gunward:server:buyVehicle', function(model)
    local source = source

    -- Validate player is in gunward
    if not Gunward.Server.Teams.IsPlayerInGunward(source) then
        Gunward.Server.Utils.Notify(source, 'Vous devez etre dans le Gunward', 'error')
        return
    end

    -- Validate vehicle exists in config
    local vehConfig = GetVehicleConfig(model)
    if not vehConfig then
        Gunward.Server.Utils.Notify(source, 'Vehicule invalide', 'error')
        return
    end

    -- Check and deduct money (free for privileged groups)
    local price = vehConfig.price
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and Config.PrivilegedGroups[xPlayer.getGroup() or ''] then
        price = 0
    end

    if price > 0 then
        Gunward.Server.Database.RemoveBank(source, price, function(success)
            if not success then
                Gunward.Server.Utils.Notify(source, 'Solde insuffisant', 'error')
                return
            end

            SpawnVehicleForPlayer(source, model)

            Gunward.Server.Database.GetBank(source, function(newBalance)
                TriggerClientEvent('gunward:client:updateBank', source, newBalance)
            end)
        end)
    else
        SpawnVehicleForPlayer(source, model)
    end
end)

function SpawnVehicleForPlayer(source, model)
    -- Supprimer l'ancien véhicule
    Gunward.Server.VehicleShop.DeletePlayerVehicle(source)

    local spawnPos, heading = GetSpawnPosition(source)
    if not spawnPos then
        Gunward.Server.Utils.Notify(source, 'Erreur: position de spawn introuvable', 'error')
        return
    end
    local hash = GetHashKey(model)

    local vehicle = CreateVehicleServerSetter(hash, 'automobile', spawnPos.x, spawnPos.y, spawnPos.z, heading)

    if not vehicle or vehicle == 0 then
        Gunward.Server.Utils.Notify(source, 'Erreur lors du spawn du vehicule', 'error')
        return
    end

    -- Attendre que le véhicule existe côté serveur
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    if not DoesEntityExist(vehicle) then
        Gunward.Server.Utils.Notify(source, 'Erreur: timeout du vehicule', 'error')
        return
    end

    SetEntityRoutingBucket(vehicle, Config.Bucket)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    playerVehicles[source] = {
        entity = vehicle,
        netId = netId,
        model = model,
    }

    -- Envoyer le netId au client pour le boost et la couleur
    TriggerClientEvent('gunward:client:spawnVehicle', source, netId)

    -- Attendre que le client charge le véhicule, puis placer le joueur dedans côté serveur
    Wait(800)

    local playerPed = GetPlayerPed(source)
    if playerPed and playerPed ~= 0 and DoesEntityExist(vehicle) then
        SetPedIntoVehicle(playerPed, vehicle, -1)
    end

    Gunward.Debug('Vehicle', model, 'spawned for player', source, 'netId:', netId)
end

-- Cleanup when player leaves gunward
AddEventHandler('gunward:server:playerLeft', function(source)
    Gunward.Server.VehicleShop.DeletePlayerVehicle(source)
end)

-- Export for external cleanup
function Gunward.Server.VehicleShop.CleanupPlayer(source)
    Gunward.Server.VehicleShop.DeletePlayerVehicle(source)
end
