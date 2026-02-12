--[[
    ═══════════════════════════════════════════════════════════
    🚗 CLIENT - GESTION DES VÉHICULES ET RESTRICTIONS
    ═══════════════════════════════════════════════════════════
    
    Spawn des véhicules, téléportation, et restrictions joueur.
    
    ✅ Utilise le véhicule reçu depuis le serveur
    ✅ Utilise le spawn reçu depuis le serveur
    ✅ Chaque match a un véhicule et spawn unique
]]

local SOURCE_FILE = 'client/race_vehicles.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES LOCALES
-- ═══════════════════════════════════════════════════════════

local currentVehicle = nil
local restrictionsActive = false

-- ═══════════════════════════════════════════════════════════
-- 🚗 SPAWN DE VÉHICULE
-- ═══════════════════════════════════════════════════════════

--- Applique les performances maximales au véhicule
---@param vehicle number Entity handle du véhicule
local function ApplyMaxPerformance(vehicle)
    if not DoesEntityExist(vehicle) then
        Utils.Warn('Impossible d\'appliquer les performances - véhicule inexistant', nil, SOURCE_FILE)
        return
    end

    -- Initialiser le système de modifications
    SetVehicleModKit(vehicle, 0)

    -- Moteur (11) - Niveau 3 (max)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)

    -- Freins (12) - Niveau max
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)

    -- Transmission (13) - Niveau max
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)

    -- Suspension (15) - Niveau max
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false)

    -- Blindage (16) - Niveau max
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)

    -- Turbo
    ToggleVehicleMod(vehicle, 18, true)

    -- Xénon (lumières améliorées)
    ToggleVehicleMod(vehicle, 22, true)

    Utils.Info('Performances maximales appliquées au véhicule', { vehicle = vehicle })
end

--- Spawn un véhicule pour le joueur
---@param role number Constants.Role
---@param vehicleModel string|nil Modèle du véhicule (envoyé par le serveur)
---@param spawnPos vector4|nil Position de spawn (envoyée par le serveur)
---@return number|nil vehicleNetId
function SpawnRaceVehicle(role, vehicleModel, spawnPos)
    Utils.Trace('SpawnRaceVehicle', { role = role, vehicleModel = vehicleModel, spawnPos = spawnPos })
    
    -- ✅ NOUVEAU: Utiliser le spawn reçu du serveur, ou fallback sur la config
    if not spawnPos then
        -- Fallback: utiliser les positions de la config (premier set)
        if role == Constants.Role.RUNNER then
            spawnPos = Config.Positions.spawns[1].runner
        else
            spawnPos = Config.Positions.spawns[1].hunter
        end
        Utils.Warn('Aucun spawn reçu - Utilisation du fallback', { role = Utils.GetRoleName(role) }, SOURCE_FILE)
    end
    
    -- ✅ Utiliser le modèle reçu du serveur, ou fallback sur la config
    local model
    if vehicleModel and vehicleModel ~= '' then
        model = GetHashKey(vehicleModel)
        Utils.Info('🚗 Véhicule reçu du serveur', { model = vehicleModel })
    else
        local fallbackModel = Config.Vehicle.availableModels[1]
        model = GetHashKey(fallbackModel)
        Utils.Warn('Aucun véhicule reçu - Utilisation du fallback', { model = fallbackModel }, SOURCE_FILE)
    end
    
    Utils.Debug('Position de spawn', {
        role = Utils.GetRoleName(role),
        coords = { x = spawnPos.x, y = spawnPos.y, z = spawnPos.z, w = spawnPos.w }
    }, SOURCE_FILE)
    
    -- Charger le modèle
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        Utils.Error('Impossible de charger le modèle véhicule', { model = vehicleModel or 'unknown' }, SOURCE_FILE)
        return nil
    end
    
    Utils.Debug('Modèle véhicule chargé', { model = vehicleModel or 'unknown' }, SOURCE_FILE)
    
    -- Créer le véhicule
    local vehicle = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, true, false)
    
    if not DoesEntityExist(vehicle) then
        Utils.Error('Échec de création du véhicule', nil, SOURCE_FILE)
        SetModelAsNoLongerNeeded(model)
        return nil
    end
    
    Utils.Debug('Véhicule créé', { vehicle = vehicle }, SOURCE_FILE)
    
    -- Configuration du véhicule
    SetVehicleColours(vehicle, Config.Vehicle.primaryColor, Config.Vehicle.secondaryColor)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, Config.Vehicle.engineOn, true, false)

    if Config.Vehicle.lockDoors then
        SetVehicleDoorsLocked(vehicle, 2)
    end

    if Config.Vehicle.invincible then
        SetEntityInvincible(vehicle, true)
    end

    -- ✅ Appliquer les performances maximales si activé
    if Config.Vehicle.fullPerformance then
        ApplyMaxPerformance(vehicle)
    end
    
    -- Éteindre la radio du véhicule
    SetVehicleRadioEnabled(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')

    -- Téléporter le joueur dans le véhicule
    local playerPed = PlayerPedId()
    SetPedIntoVehicle(playerPed, vehicle, -1)
    
    Utils.Debug('Joueur placé dans le véhicule', nil, SOURCE_FILE)
    
    -- Libérer le modèle
    SetModelAsNoLongerNeeded(model)
    
    -- Stocker la référence
    currentVehicle = vehicle
    
    -- Retourner le network ID
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    
    Utils.Info('Véhicule spawné avec succès', {
        vehicle = vehicle,
        netId = netId,
        model = vehicleModel or 'unknown',
        role = Utils.GetRoleName(role),
        location = string.format('vec4(%.2f, %.2f, %.2f, %.2f)', spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w)
    })
    
    return netId
end

--- Suppression du véhicule actuel
function DeleteRaceVehicle()
    Utils.Trace('DeleteRaceVehicle')
    
    if currentVehicle and DoesEntityExist(currentVehicle) then
        -- Faire sortir le joueur d'abord si dedans
        local playerPed = PlayerPedId()
        if GetVehiclePedIsIn(playerPed, false) == currentVehicle then
            TaskLeaveVehicle(playerPed, currentVehicle, 0)
            Wait(500)
        end
        
        -- Supprimer le véhicule
        SetEntityAsMissionEntity(currentVehicle, true, true)
        DeleteVehicle(currentVehicle)
        
        Utils.Debug('Véhicule supprimé', nil, SOURCE_FILE)
    else
        Utils.Debug('Aucun véhicule à supprimer', nil, SOURCE_FILE)
    end
    
    currentVehicle = nil
end

--- Récupération du véhicule actuel
---@return number|nil
function GetCurrentRaceVehicle()
    return currentVehicle
end

-- ═══════════════════════════════════════════════════════════
-- 🔒 RESTRICTIONS JOUEUR
-- ═══════════════════════════════════════════════════════════

--- Activer les restrictions (pas de sortie véhicule, pas d'armes, etc.)
function EnableRestrictions()
    Utils.Trace('EnableRestrictions')
    
    if restrictionsActive then
        Utils.Debug('Restrictions déjà actives', nil, SOURCE_FILE)
        return
    end
    
    restrictionsActive = true
    
    Utils.Info('Restrictions activées', nil)
    
    -- Thread de restrictions
    CreateThread(function()
        while restrictionsActive do
            local playerPed = PlayerPedId()
            
            -- Désactiver les contrôles interdits
            for _, control in ipairs(Constants.DisabledControls) do
                DisableControlAction(0, control, true)
            end
            
            -- Empêcher de sortir du véhicule
            if currentVehicle and DoesEntityExist(currentVehicle) then
                local veh = GetVehiclePedIsIn(playerPed, false)
                
                -- Si le joueur n'est plus dans le véhicule, le remettre dedans
                if veh == 0 then
                    Utils.Debug('Joueur sorti du véhicule - Remise en place', nil, SOURCE_FILE)
                    SetPedIntoVehicle(playerPed, currentVehicle, -1)
                end
            end
            
            -- Désarmer le joueur
            SetPedCanSwitchWeapon(playerPed, false)
            DisablePlayerFiring(playerPed, true)
            
            -- Empêcher le téléphone
            SetMobilePhoneRadioState(false)
            
            Wait(0)
        end
        
        Utils.Debug('Thread de restrictions terminé', nil, SOURCE_FILE)
    end)
end

--- Désactiver les restrictions
function DisableRestrictions()
    Utils.Trace('DisableRestrictions')
    
    if not restrictionsActive then
        Utils.Debug('Restrictions déjà désactivées', nil, SOURCE_FILE)
        return
    end
    
    restrictionsActive = false
    
    -- Réactiver les capacités du joueur
    local playerPed = PlayerPedId()
    SetPedCanSwitchWeapon(playerPed, true)
    DisablePlayerFiring(playerPed, false)
    
    Utils.Info('Restrictions désactivées', nil)
end

--- Vérifier si les restrictions sont actives
---@return boolean
function AreRestrictionsActive()
    return restrictionsActive
end

-- ═══════════════════════════════════════════════════════════
-- 📍 TÉLÉPORTATION
-- ═══════════════════════════════════════════════════════════

--- Téléporter le joueur à la position de sortie
function TeleportToExit()
    Utils.Trace('TeleportToExit')
    
    local playerPed = PlayerPedId()
    local exitPos = Config.Positions.exit
    
    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Téléportation
    SetEntityCoords(playerPed, exitPos.x, exitPos.y, exitPos.z, false, false, false, false)
    SetEntityHeading(playerPed, exitPos.w)
    
    Wait(500)
    
    -- Fade in
    DoScreenFadeIn(500)
    
    Utils.Debug('Joueur téléporté à la sortie', {
        coords = { x = exitPos.x, y = exitPos.y, z = exitPos.z }
    }, SOURCE_FILE)
end

-- ═══════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE COMPLET
-- ═══════════════════════════════════════════════════════════

--- Nettoyage complet en fin de course
function CleanupRace()
    Utils.Trace('CleanupRace')
    
    -- Arrêter la surveillance
    if StopSecurityMonitoring then
        StopSecurityMonitoring()
    end
    
    -- Désactiver les restrictions
    DisableRestrictions()
    
    -- Supprimer le véhicule
    DeleteRaceVehicle()
    
    -- Téléporter à la sortie
    TeleportToExit()
    
    Utils.Info('Nettoyage de course terminé', nil)
end
