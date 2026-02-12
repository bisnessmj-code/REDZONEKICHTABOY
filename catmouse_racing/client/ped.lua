--[[
    ═══════════════════════════════════════════════════════════
    🚶 CLIENT - GESTION DU PED NPC (VERSION ULTRA-OPTIMISÉE)
    ═══════════════════════════════════════════════════════════
    
    ✅ PED TOUJOURS PRÉSENT (pas de vérification joueur)
    ✅ Spawn simplifié sans boucles complexes
    ✅ Interaction optimisée avec pooling
    ✅ Thread d'interaction intelligent (Wait adaptatif)
]]

local SOURCE_FILE = 'client/ped.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES
-- ═══════════════════════════════════════════════════════════

local pedEntity = nil
local pedCoords = nil -- Cache des coordonnées du PED

-- ═══════════════════════════════════════════════════════════
-- 📝 TEXTE 3D AU-DESSUS DU PED
-- ═══════════════════════════════════════════════════════════

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 255) -- Blanc
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- ═══════════════════════════════════════════════════════════
-- 🚶 SPAWN DU PED (SIMPLIFIÉ)
-- ═══════════════════════════════════════════════════════════

local function SpawnPed()
    Utils.Trace('SpawnPed')
    
    -- Vérifier si le PED existe déjà
    if pedEntity then
        -- Vérifier si l'entité existe encore dans le jeu
        if DoesEntityExist(pedEntity) and not IsEntityDead(pedEntity) then
            Utils.Debug('PED déjà spawné et valide', { entity = pedEntity }, SOURCE_FILE)
            return true
        else
            -- Le PED a été supprimé, réinitialiser
            Utils.Warn('PED était référencé mais n\'existe plus - Respawn', nil, SOURCE_FILE)
            pedEntity = nil
        end
    end
    
    local pedConfig = Config.Ped
    local model = GetHashKey(pedConfig.model)
    
    -- Charger le modèle
    RequestModel(model)
    
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        Utils.Error('Impossible de charger le modèle PED', { model = pedConfig.model }, SOURCE_FILE)
        SetModelAsNoLongerNeeded(model)
        return false
    end
    
    -- Créer le PED
    pedEntity = CreatePed(
        4,
        model, 
        pedConfig.coords.x, 
        pedConfig.coords.y, 
        pedConfig.coords.z, 
        pedConfig.coords.w, 
        false,
        true
    )
    
    if not DoesEntityExist(pedEntity) then
        Utils.Error('Échec création PED', nil, SOURCE_FILE)
        SetModelAsNoLongerNeeded(model)
        return false
    end
    
    -- Configuration du PED
    SetEntityAsMissionEntity(pedEntity, true, true)
    SetPedAsNoLongerNeeded(pedEntity)
    
    FreezeEntityPosition(pedEntity, pedConfig.freeze)
    SetEntityInvincible(pedEntity, pedConfig.invincible)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    
    SetPedFleeAttributes(pedEntity, 0, false)
    SetPedCombatAttributes(pedEntity, 17, true)
    SetPedSeeingRange(pedEntity, 0.0)
    SetPedHearingRange(pedEntity, 0.0)
    SetPedAlertness(pedEntity, 0)
    SetPedKeepTask(pedEntity, true)
    
    TaskSetBlockingOfNonTemporaryEvents(pedEntity, true)
    SetEntityCanBeDamaged(pedEntity, false)
    SetPedCanRagdollFromPlayerImpact(pedEntity, false)
    SetPedCanRagdoll(pedEntity, false)
    
    if pedConfig.scenario then
        TaskStartScenarioInPlace(pedEntity, pedConfig.scenario, 0, true)
    end
    
    SetModelAsNoLongerNeeded(model)
    
    -- ✅ NOUVEAU: Cacher les coordonnées du PED pour éviter les recalculs
    pedCoords = vector3(pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z)
    
    Utils.Info('✅ PED spawné avec succès', {
        entity = pedEntity,
        model = pedConfig.model
    })
    
    SetupInteraction()
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- 🎯 INTERACTION (OPTIMISÉE)
-- ═══════════════════════════════════════════════════════════

function SetupInteraction()
    Utils.Trace('SetupInteraction')
    
    if Config.Ped.useOxTarget then
        local oxTargetState = GetResourceState('ox_target')
        
        if oxTargetState ~= 'started' then
            Utils.Warn('ox_target non démarré - Fallback vers interaction manuelle', nil)
            Config.Ped.useOxTarget = false
            SetupManualInteraction()
            return
        end
        
        if not exports['ox_target'] then
            Utils.Warn('ox_target exports non disponibles - Fallback vers interaction manuelle', nil)
            Config.Ped.useOxTarget = false
            SetupManualInteraction()
            return
        end
        
        local success, errorMsg = pcall(function()
            exports['ox_target']:addLocalEntity(pedEntity, {
                {
                    name = 'catmouse_racing',
                    icon = Config.Ped.targetIcon,
                    label = Config.Ped.targetLabel,
                    distance = Config.Ped.interactionDistance,
                    onSelect = function()
                        HandlePedInteraction()
                    end
                }
            })
        end)
        
        if success then
            Utils.Info('✅ ox_target configuré avec succès', nil)
        else
            Utils.Warn('ox_target erreur - Fallback vers interaction manuelle', nil)
            Config.Ped.useOxTarget = false
            SetupManualInteraction()
        end
    else
        SetupManualInteraction()
    end
end

--- Gestion de l'interaction avec le PED
function HandlePedInteraction()
    Utils.Debug('HandlePedInteraction appelé', { inQueue = IsPlayerInQueue() }, SOURCE_FILE)
    
    -- Vérifier si le joueur est déjà en course
    if IsInRace() then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.already_in_race
        })
        return
    end
    
    OpenRacingUI()
end

--- Interaction manuelle (touche E) - VERSION ULTRA-OPTIMISÉE
function SetupManualInteraction()
    Utils.Trace('SetupManualInteraction')
    
    CreateThread(function()
        local isNearPed = false
        local playerPed = 0
        local playerCoords = vector3(0, 0, 0)
        local distance = 999999.0
        
        -- ✅ CACHE: Mettre à jour toutes les 500ms au lieu de chaque frame
        local lastCacheUpdate = 0
        local CACHE_INTERVAL = 500
        
        while DoesEntityExist(pedEntity) do
            local currentTime = GetGameTimer()
            
            -- ✅ OPTIMISATION: Mettre à jour le cache seulement toutes les 500ms
            if currentTime - lastCacheUpdate > CACHE_INTERVAL then
                playerPed = PlayerPedId()
                playerCoords = GetEntityCoords(playerPed)
                distance = #(playerCoords - pedCoords)
                lastCacheUpdate = currentTime
            end
            
            if distance < Config.Ped.interactionDistance then
                -- ════════════════════════════════════════════════
                -- JOUEUR PROCHE DU PED
                -- ════════════════════════════════════════════════
                
                if not isNearPed then
                    isNearPed = true
                    Utils.Debug('Joueur proche du PED', { distance = string.format('%.2f', distance) }, SOURCE_FILE)
                end
                
                -- Afficher le help text
                local helpText = 'Appuyez sur ~INPUT_CONTEXT~ pour ' .. Config.Ped.targetLabel
                
                if IsPlayerInQueue() then
                    helpText = 'Appuyez sur ~INPUT_CONTEXT~ pour gérer la file d\'attente'
                end
                
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentString(helpText)
                EndTextCommandDisplayHelp(0, false, true, -1)
                
                -- Détection touche E
                if IsControlJustPressed(0, 51) then
                    Utils.Debug('Interaction PED (touche E)', { inQueue = IsPlayerInQueue() }, SOURCE_FILE)
                    HandlePedInteraction()
                end
                
                -- ✅ OPTIMISATION: Wait réduit mais pas 0
                Wait(0)
                
            else
                -- ════════════════════════════════════════════════
                -- JOUEUR LOIN DU PED
                -- ════════════════════════════════════════════════
                
                if isNearPed then
                    isNearPed = false
                    Utils.Debug('Joueur s\'est éloigné du PED', nil, SOURCE_FILE)
                end
                
                -- ✅ OPTIMISATION: Wait adaptatif selon la distance
                if distance < Config.Ped.interactionDistance * 2 then
                    Wait(250)  -- 4 fois par seconde
                elseif distance < Config.Ped.interactionDistance * 5 then
                    Wait(500)  -- 2 fois par seconde
                else
                    Wait(1000) -- 1 fois par seconde
                end
            end
        end
        
        Utils.Debug('Thread interaction manuelle terminé', nil, SOURCE_FILE)
    end)
    
    Utils.Info('✅ Interaction manuelle configurée', nil)
end

-- ═══════════════════════════════════════════════════════════
-- 🗑️ SUPPRESSION
-- ═══════════════════════════════════════════════════════════

local function DeletePed()
    Utils.Trace('DeletePed')
    
    if pedEntity and DoesEntityExist(pedEntity) then
        if Config.Ped.useOxTarget then
            pcall(function()
                exports['ox_target']:removeLocalEntity(pedEntity, 'catmouse_racing')
            end)
        end
        
        DeleteEntity(pedEntity)
        Utils.Debug('PED supprimé', { entity = pedEntity }, SOURCE_FILE)
    end
    
    pedEntity = nil
    pedCoords = nil
end

-- ═══════════════════════════════════════════════════════════
-- 🎮 ÉVÉNEMENTS & THREADS
-- ═══════════════════════════════════════════════════════════

-- ✅ OPTIMISATION: Spawn immédiat sans attente réseau inutile
CreateThread(function()
    -- Attendre seulement 1 seconde au lieu de vérifier le réseau
    Wait(1000)
    
    Utils.Debug('Spawn du PED...', nil, SOURCE_FILE)
    
    local success = SpawnPed()
    
    if not success then
        Utils.Error('ÉCHEC du spawn PED', nil, SOURCE_FILE)
    end
end)

-- ✅ NOUVEAU: Thread de surveillance pour respawn automatique si le PED disparaît
CreateThread(function()
    while true do
        Wait(5000) -- Vérifier toutes les 5 secondes

        if pedEntity then
            if not DoesEntityExist(pedEntity) or IsEntityDead(pedEntity) then
                Utils.Warn('PED disparu ou mort - Respawn automatique', nil, SOURCE_FILE)
                pedEntity = nil
                Wait(1000)
                SpawnPed()
            end
        else
            -- Aucun PED référencé, tenter de spawner
            Utils.Warn('PED non référencé - Spawn automatique', nil, SOURCE_FILE)
            SpawnPed()
        end
    end
end)

-- ✅ Thread pour afficher le texte 3D au-dessus du PED
CreateThread(function()
    while true do
        if pedEntity and DoesEntityExist(pedEntity) and pedCoords then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - pedCoords)

            -- Afficher le texte seulement si le joueur est assez proche (20 unités)
            if distance < 20.0 then
                DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 2.2 , "[ JEU DE COURSE POURSUITE ]")
                Wait(0)
            else
                Wait(500)
            end
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Debug('Arrêt ressource - Suppression PED', nil, SOURCE_FILE)
    DeletePed()
end)

