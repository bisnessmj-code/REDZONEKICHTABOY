--[[
    Main Client - Panel Admin Fight League
    Point d'entrée client et gestion des events
]]

ESX = exports['es_extended']:getSharedObject()

-- ══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    while not ESX do
        Wait(100)
        ESX = exports['es_extended']:getSharedObject()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- EVENTS ACTIONS (depuis serveur)
-- ══════════════════════════════════════════════════════════════

-- Téléportation
RegisterNetEvent('panel:teleport', function(x, y, z)
    local playerPed = PlayerPedId()

    -- Si en noclip, mettre a jour la position noclip directement
    if _G.Noclip and _G.Noclip.IsActive() then
        _G.Noclip.SetPosition(x, y, z)
        TriggerEvent('panel:notification', {
            type = 'success',
            title = 'Téléportation',
            message = 'Position noclip mise à jour'
        })
        return
    end

    -- Fade out
    DoScreenFadeOut(300)
    Wait(300)

    -- Téléporter
    SetEntityCoords(playerPed, x, y, z, false, false, false, false)

    -- Attendre le chargement
    Wait(500)

    -- Fade in
    DoScreenFadeIn(300)
end)

-- Heal
RegisterNetEvent('panel:heal', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    SetPedArmour(playerPed, 100)
end)

-- Freeze
RegisterNetEvent('panel:freeze', function(freeze)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, freeze)

    if freeze then
        TriggerEvent('panel:notification', {
            type = 'warning',
            title = 'Freeze',
            message = 'Vous avez été freeze par un admin'
        })
    else
        TriggerEvent('panel:notification', {
            type = 'info',
            title = 'Unfreeze',
            message = 'Vous avez été unfreeze'
        })
    end
end)

-- Toggle Freeze (pour menu rapide)
local isFrozen = false
RegisterNetEvent('panel:toggleFreeze', function()
    local playerPed = PlayerPedId()
    isFrozen = not isFrozen
    FreezeEntityPosition(playerPed, isFrozen)

    if isFrozen then
        TriggerEvent('panel:notification', {
            type = 'warning',
            title = 'Freeze',
            message = 'Vous avez ete freeze par un admin'
        })
    else
        TriggerEvent('panel:notification', {
            type = 'info',
            title = 'Unfreeze',
            message = 'Vous avez ete unfreeze'
        })
    end
end)

-- Spawn véhicule avec options complètes
RegisterNetEvent('panel:spawnVehicle', function(model, options)
    local modelHash = GetHashKey(model)
    options = options or {}

    -- Charger le modèle
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        TriggerEvent('panel:notification', {
            type = 'error',
            title = 'Erreur',
            message = 'Modèle de véhicule invalide: ' .. model
        })
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    -- Calculer la position devant le joueur
    local forwardX = coords.x + (Config.Vehicles.SpawnDistance * math.sin(math.rad(-heading)))
    local forwardY = coords.y + (Config.Vehicles.SpawnDistance * math.cos(math.rad(-heading)))

    -- Créer le véhicule
    local vehicle = CreateVehicle(modelHash, forwardX, forwardY, coords.z, heading, true, false)

    -- Mettre le joueur dedans
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    -- Configurer le véhicule de base
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)

    -- Activer le kit de modifications
    SetVehicleModKit(vehicle, 0)

    -- Appliquer la couleur
    if options.customColor and options.colorR and options.colorG and options.colorB then
        -- Couleur RGB personnalisée
        if Config.Debug then print('[VEHICLE TUNING] Couleur RGB appliquee: R=' .. options.colorR .. ' G=' .. options.colorG .. ' B=' .. options.colorB) end
        SetVehicleCustomPrimaryColour(vehicle, options.colorR, options.colorG, options.colorB)
        SetVehicleCustomSecondaryColour(vehicle, options.colorR, options.colorG, options.colorB)
    else
        -- Couleur prédéfinie GTA
        local color = options.color or 0
        if Config.Debug then print('[VEHICLE TUNING] Couleur GTA appliquee: ' .. tostring(color)) end
        SetVehicleColours(vehicle, color, color)
        SetVehicleExtraColours(vehicle, color, color)
    end

    -- Full Upgrade = appliquer les mods visuelles (sauf liveries et performance)
    if options.fullUpgrade then
        -- Mods visuelles SANS les liveries (48) qui ajoutent des graphiques
        -- 0=Spoilers, 1=Front Bumper, 2=Rear Bumper, 3=Side Skirt, 4=Exhaust, 5=Frame,
        -- 6=Grille, 7=Hood, 8=Fender, 9=Right Fender, 10=Roof
        -- 23-24=Wheels, 25-27=Vanity plates, 28-32=Trim, 33-35=Engine block, etc.
        -- On EXCLUT 48 (Livery) pour garder la couleur unie
        local visualMods = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47}
        for _, modType in ipairs(visualMods) do
            local numMods = GetNumVehicleMods(vehicle, modType)
            if numMods > 0 then
                SetVehicleMod(vehicle, modType, numMods - 1, false)
            end
        end
        -- Retirer toute livery existante
        SetVehicleMod(vehicle, 48, -1, false)
        SetVehicleLivery(vehicle, -1)
    end

    -- Toujours appliquer les mods de performance selon les options
    if Config.Debug then print('[VEHICLE TUNING] Application des mods de performance...') end

    -- Mod 11 = Moteur (0-3)
    local engineLevel = options.engine or 3
    local maxEngine = GetNumVehicleMods(vehicle, 11) - 1
    if engineLevel >= 0 and maxEngine >= 0 then
        local appliedEngine = math.min(engineLevel, maxEngine)
        SetVehicleMod(vehicle, 11, appliedEngine, false)
        if Config.Debug then print('[VEHICLE TUNING] Moteur: niveau ' .. appliedEngine .. ' (max: ' .. maxEngine .. ')') end
    end

    -- Mod 13 = Transmission (0-2)
    local transLevel = options.transmission or 2
    local maxTrans = GetNumVehicleMods(vehicle, 13) - 1
    if transLevel >= 0 and maxTrans >= 0 then
        local appliedTrans = math.min(transLevel, maxTrans)
        SetVehicleMod(vehicle, 13, appliedTrans, false)
        if Config.Debug then print('[VEHICLE TUNING] Transmission: niveau ' .. appliedTrans .. ' (max: ' .. maxTrans .. ')') end
    end

    -- Mod 12 = Freins (0-2)
    local brakesLevel = options.brakes or 2
    local maxBrakes = GetNumVehicleMods(vehicle, 12) - 1
    if brakesLevel >= 0 and maxBrakes >= 0 then
        local appliedBrakes = math.min(brakesLevel, maxBrakes)
        SetVehicleMod(vehicle, 12, appliedBrakes, false)
        if Config.Debug then print('[VEHICLE TUNING] Freins: niveau ' .. appliedBrakes .. ' (max: ' .. maxBrakes .. ')') end
    end

    -- Mod 15 = Suspension (0-3)
    local suspLevel = options.suspension or 3
    local maxSusp = GetNumVehicleMods(vehicle, 15) - 1
    if suspLevel >= 0 and maxSusp >= 0 then
        local appliedSusp = math.min(suspLevel, maxSusp)
        SetVehicleMod(vehicle, 15, appliedSusp, false)
        if Config.Debug then print('[VEHICLE TUNING] Suspension: niveau ' .. appliedSusp .. ' (max: ' .. maxSusp .. ')') end
    end

    -- Mod 16 = Blindage (0-4)
    local armorLevel = options.armor or 4
    local maxArmor = GetNumVehicleMods(vehicle, 16) - 1
    if armorLevel >= 0 and maxArmor >= 0 then
        local appliedArmor = math.min(armorLevel, maxArmor)
        SetVehicleMod(vehicle, 16, appliedArmor, false)
        if Config.Debug then print('[VEHICLE TUNING] Blindage: niveau ' .. appliedArmor .. ' (max: ' .. maxArmor .. ')') end
    end

    -- Turbo (Mod 18)
    if options.turbo then
        ToggleVehicleMod(vehicle, 18, true)
        if Config.Debug then print('[VEHICLE TUNING] Turbo: ACTIVE') end
    end

    -- Phares Xenon (Mod 22)
    if options.xenon then
        ToggleVehicleMod(vehicle, 22, true)
        if Config.Debug then print('[VEHICLE TUNING] Xenon: ACTIVE') end
    end

    -- Néons
    if options.neon then
        -- Activer les néons (0=gauche, 1=droite, 2=avant, 3=arrière)
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        -- Couleur des néons basée sur la couleur du véhicule
        local neonColors = {
            [0] = {255, 255, 255},   -- Blanc pour noir
            [27] = {255, 0, 0},      -- Rouge
            [88] = {0, 0, 255},      -- Bleu
            [53] = {255, 255, 0},    -- Jaune
            [138] = {255, 128, 0},   -- Orange
            [55] = {0, 255, 0},      -- Vert
            [145] = {128, 0, 255},   -- Violet
        }
        local neonColor = neonColors[color] or {255, 0, 255} -- Magenta par défaut
        SetVehicleNeonLightsColour(vehicle, neonColor[1], neonColor[2], neonColor[3])
    end

    -- Plaques personnalisées
    SetVehicleNumberPlateText(vehicle, "ADMIN")
    SetVehicleNumberPlateTextIndex(vehicle, 4) -- Plaque noire

    -- Vitres teintées max
    SetVehicleWindowTint(vehicle, 1)

    -- Libérer le modèle
    SetModelAsNoLongerNeeded(modelHash)

    -- Note: La notification est envoyée par le serveur, pas besoin de doublon ici
end)

-- Supprimer véhicule
RegisterNetEvent('panel:deleteVehicle', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        -- Chercher un véhicule proche
        vehicle = GetClosestVehicle(GetEntityCoords(playerPed), Config.Vehicles.DeleteRadius, 0, 71)
    end

    if vehicle ~= 0 then
        DeleteVehicle(vehicle)
        -- Note: La notification est envoyée par le serveur
    end
    -- Note: Si pas de véhicule, le serveur gère déjà la notification
end)

-- Ejecter le joueur de son vehicule (appele par le serveur)
RegisterNetEvent('panel:ejectFromVehicle', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        TaskLeaveVehicle(playerPed, vehicle, 16) -- 16 = sortie immediate
    end
end)

-- Ejecter tous les joueurs d'un vehicule specifique (par netId)
RegisterNetEvent('panel:ejectAllFromVehicle', function(vehicleNetId)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
        if vehNetId == vehicleNetId then
            TaskLeaveVehicle(playerPed, vehicle, 16)
        end
    end
end)

-- Réparer véhicule
RegisterNetEvent('panel:repairVehicle', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        -- Note: La notification est envoyée par le serveur
    end
    -- Note: Si pas de véhicule, le serveur gère déjà la notification
end)

-- Set Health (Quick Menu)
RegisterNetEvent('panel:setHealth', function(health)
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, health)
end)

-- Set Armor (Quick Menu)
RegisterNetEvent('panel:setArmor', function(armor)
    local playerPed = PlayerPedId()
    SetPedArmour(playerPed, armor)
end)

RegisterNetEvent('panel:displayAdminMessage', function(message)
    -- Afficher le message pendant 8 secondes
    local displayUntil = GetGameTimer() + 8000

    CreateThread(function()
        while GetGameTimer() < displayUntil do
            Wait(0)

            -- Positions calculées (Base + 0.045)
            local yFond    = 0.125 -- (0.08 + 0.045)
            local yBordure = 0.085 -- (0.04 + 0.045)
            local yTitre   = 0.095 -- (0.05 + 0.045)
            local yMessage = 0.130 -- (0.085 + 0.045)

            -- Fond semi-transparent
            DrawRect(0.5, yFond, 0.4, 0.08, 0, 0, 0, 180)

            -- Bordure rouge
            DrawRect(0.5, yBordure, 0.4, 0.003, 255, 50, 50, 255)

            -- Titre "Message Admin"
            SetTextFont(4)
            SetTextScale(0.0, 0.5)
            SetTextColour(255, 50, 50, 255)
            SetTextOutline()
            SetTextCentre(1)
            SetTextEntry('STRING')
            AddTextComponentString('MESSAGE ADMIN')
            DrawText(0.5, yTitre)

            -- Message
            SetTextFont(4)
            SetTextScale(0.0, 0.45)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            SetTextCentre(1)
            SetTextEntry('STRING')
            AddTextComponentString(message)
            DrawText(0.5, yMessage)
        end
    end)
end)

-- Spawn vehicule avec couleur (Quick Menu)
RegisterNetEvent('panel:spawnVehicleWithColor', function(model, color)
    local modelHash = GetHashKey(model)

    -- Charger le modele
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        TriggerEvent('panel:notification', {
            type = 'error',
            title = 'Erreur',
            message = 'Modele de vehicule invalide: ' .. model
        })
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    -- Calculer la position devant le joueur
    local spawnDist = Config.Vehicles and Config.Vehicles.SpawnDistance or 3.0
    local forwardX = coords.x + (spawnDist * math.sin(math.rad(-heading)))
    local forwardY = coords.y + (spawnDist * math.cos(math.rad(-heading)))

    -- Creer le vehicule
    local vehicle = CreateVehicle(modelHash, forwardX, forwardY, coords.z, heading, true, false)

    -- Mettre le joueur dedans
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    -- Configurer le vehicule
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)

    -- Appliquer la couleur
    SetVehicleColours(vehicle, color, color)

    -- Liberer le modele
    SetModelAsNoLongerNeeded(modelHash)

    -- Note: La notification est gérée par l'appelant (Quick Menu)
end)

-- ══════════════════════════════════════════════════════════════
-- BANNIERE D'ANNONCE
-- ══════════════════════════════════════════════════════════════

-- Afficher la banniere d'annonce visuelle
RegisterNetEvent('panel:announceBanner', function(data)
    -- Envoyer au NUI pour afficher la banniere
    SendNUIMessage({
        action = 'showAnnounceBanner',
        data = {
            message = data.message,
            title = data.title or 'ANNONCE',
            priority = data.priority or 'normal',
            duration = data.duration or 5000,
            backgroundImage = data.backgroundImage
        }
    })
end)

-- Jouer le son d'annonce (pour les annonces chat normales)
RegisterNetEvent('panel:playAnnouncementSound', function()
    SendNUIMessage({
        action = 'playAnnouncementSound'
    })
end)

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATIONS LOCALES
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('panel:notification', function(data)
    -- Si le panel est ouvert, utiliser UNIQUEMENT le NUI (plus joli)
    if NUIBridge and NUIBridge.IsOpen() then
        SendNUIMessage({
            action = 'notification',
            data = data
        })
    else
        -- Sinon utiliser le système de notification ESX
        if data.type == 'error' then
            ESX.ShowNotification('' .. (data.title and data.title .. ': ' or '') .. data.message)
        elseif data.type == 'success' then
            ESX.ShowNotification('' .. (data.title and data.title .. ': ' or '') .. data.message)
        elseif data.type == 'warning' then
            ESX.ShowNotification('' .. (data.title and data.title .. ': ' or '') .. data.message)
        else
            ESX.ShowNotification('' .. (data.title and data.title .. ': ' or '') .. data.message)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- UTILITAIRES
-- ══════════════════════════════════════════════════════════════

-- Obtenir le véhicule le plus proche
function GetClosestVehicle(coords, radius, modelHash, flags)
    return GetClosestVehicle(coords.x, coords.y, coords.z, radius, modelHash, flags)
end

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DEBUG
-- ══════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('panel_debug', function()
        print('Panel Debug Info:')
        print('  Is Open: ' .. tostring(NUIBridge and NUIBridge.IsOpen() or false))
        print('  Is Spectating: ' .. tostring(Spectate and Spectate.IsSpectating() or false))
    end, false)
end
