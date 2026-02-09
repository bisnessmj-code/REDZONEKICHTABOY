--[[
    Module Vehicles - Panel Admin Fight League
    Spawn, delete, repair véhicules
]]

local Vehicles = {}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Spawn un véhicule pour un joueur
function Vehicles.Spawn(staffSource, targetSource, model, options)
    if not Auth.HasPermission(staffSource, 'vehicle.spawn') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, cleanModel = Validators.VehicleModel(model)
    if not valid then return false, cleanModel end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    -- Options par défaut
    local spawnOptions = {
        color = options and options.color or 0,
        customColor = options and options.customColor or false,
        colorR = options and options.colorR or nil,
        colorG = options and options.colorG or nil,
        colorB = options and options.colorB or nil,
        engine = options and options.engine or 3,
        transmission = options and options.transmission or 2,
        brakes = options and options.brakes or 2,
        suspension = options and options.suspension or 3,
        armor = options and options.armor or 4,
        turbo = options and options.turbo ~= false,
        neon = options and options.neon ~= false,
        xenon = options and options.xenon ~= false,
        fullUpgrade = options and options.fullUpgrade ~= false
    }

    if Config.Debug then print('[VEHICLES] Spawn options - customColor: ' .. tostring(spawnOptions.customColor) .. ', R: ' .. tostring(spawnOptions.colorR) .. ', G: ' .. tostring(spawnOptions.colorG) .. ', B: ' .. tostring(spawnOptions.colorB)) end

    -- Demander au client de spawn le véhicule avec les options
    TriggerClientEvent('panel:spawnVehicle', targetSource, cleanModel, spawnOptions)

    -- Log
    local targetName = GetPlayerName(targetSource)
    Database.AddLog(
        Enums.LogCategory.VEHICLE,
        Enums.LogAction.VEHICLE_SPAWN,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        targetName, -- Nom FiveM
        {model = cleanModel, tuning = spawnOptions}
    )

    -- Discord webhook
    if Discord and Discord.LogVehicle then
        Discord.LogVehicle('vehicle_spawn', session.name, targetName, {model = cleanModel})
    end

    return true
end

-- Supprimer le véhicule actuel d'un joueur
function Vehicles.Delete(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'vehicle.delete') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    TriggerClientEvent('panel:deleteVehicle', targetSource)

    Database.AddLog(
        Enums.LogCategory.VEHICLE,
        Enums.LogAction.VEHICLE_DELETE,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(targetSource), -- Nom FiveM
        nil
    )

    return true
end

-- Réparer le véhicule actuel
function Vehicles.Repair(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'vehicle.repair') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    TriggerClientEvent('panel:repairVehicle', targetSource)

    Database.AddLog(
        Enums.LogCategory.VEHICLE,
        Enums.LogAction.VEHICLE_REPAIR,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(targetSource), -- Nom FiveM
        nil
    )

    return true
end

-- ══════════════════════════════════════════════════════════════
-- FAVORIS
-- ══════════════════════════════════════════════════════════════

-- Obtenir les véhicules favoris
function Vehicles.GetFavorites(staffIdentifier)
    -- Favoris globaux + personnels
    return Database.QueryAsync([[
        SELECT * FROM panel_vehicle_favorites
        WHERE is_global = 1 OR staff_identifier = ?
        ORDER BY category, display_name
    ]], {staffIdentifier})
end

-- Ajouter un favori
function Vehicles.AddFavorite(staffIdentifier, spawnName, displayName, category, isGlobal)
    isGlobal = isGlobal and 1 or 0
    return Database.InsertAsync([[
        INSERT INTO panel_vehicle_favorites (spawn_name, display_name, category, is_global, staff_identifier)
        VALUES (?, ?, ?, ?, ?)
    ]], {spawnName, displayName, category, isGlobal, isGlobal == 0 and staffIdentifier or nil})
end

-- Supprimer un favori
function Vehicles.RemoveFavorite(id, staffIdentifier)
    return Database.ExecuteAsync([[
        DELETE FROM panel_vehicle_favorites
        WHERE id = ? AND (is_global = 0 AND staff_identifier = ?)
    ]], {id, staffIdentifier})
end

-- ══════════════════════════════════════════════════════════════
-- SUPPRESSION PAR NETWORK ID (depuis noclip)
-- ══════════════════════════════════════════════════════════════

-- Supprimer un vehicule par son NetworkId
RegisterNetEvent('panel:deleteVehicleByNetId', function(netId)
    local source = source

    -- Verifier les permissions
    if not Auth.HasPermission(source, 'vehicle.delete') then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Pas la permission de supprimer des vehicules'
        })
        return
    end

    if not netId or netId == 0 then return end

    -- Ejecter tous les joueurs de ce vehicule
    TriggerClientEvent('panel:ejectAllFromVehicle', -1, netId)

    -- Attendre que les joueurs sortent puis supprimer
    SetTimeout(500, function()
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)

            local session = Auth.GetSession(source)
            if session then
                Database.AddLog(
                    Enums.LogCategory.VEHICLE,
                    Enums.LogAction.VEHICLE_DELETE,
                    session.identifier,
                    session.name,
                    nil, nil,
                    {method = 'noclip', netId = netId}
                )
            end
        end
    end)
end)

-- Supprimer un objet par son NetworkId
RegisterNetEvent('panel:deleteObjectByNetId', function(netId)
    local source = source

    -- Verifier les permissions (meme permission que delete vehicle)
    if not Auth.HasPermission(source, 'vehicle.delete') then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Pas la permission de supprimer des objets'
        })
        return
    end

    if not netId or netId == 0 then return end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)

        local session = Auth.GetSession(source)
        if session then
            Database.AddLog(
                Enums.LogCategory.VEHICLE,
                Enums.LogAction.VEHICLE_DELETE,
                session.identifier,
                session.name,
                nil, nil,
                {method = 'noclip_object', netId = netId}
            )
        end
    end
end)

-- Export global
_G.Vehicles = Vehicles
