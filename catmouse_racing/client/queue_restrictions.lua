--[[
    ═══════════════════════════════════════════════════════════
    🔒 CLIENT - RESTRICTIONS EN FILE D'ATTENTE (OPTIMISÉ)
    ═══════════════════════════════════════════════════════════
    
    ✅ Désactivation de contrôles uniquement quand nécessaire
    ✅ Pooling des coordonnées
    ✅ Wait adaptatif
]]

local SOURCE_FILE = 'client/queue_restrictions.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES
-- ═══════════════════════════════════════════════════════════

local isProtectedFromOtherScripts = false
local isInQueueState = false
local lastNotificationTime = 0
local NOTIFICATION_COOLDOWN = 3000
local RESTRICTION_DISTANCE = 2.0

-- ✅ NOUVEAU: Cache des coordonnées
local playerPed = 0
local playerCoords = vector3(0, 0, 0)
local lastCacheUpdate = 0
local CACHE_INTERVAL = 500

-- Position du PED (constante)
local pedPos = vector3(
    Config.Ped.coords.x,
    Config.Ped.coords.y,
    Config.Ped.coords.z
)

-- ═══════════════════════════════════════════════════════════
-- 🎮 ACCESSEURS ET EXPORTS
-- ═══════════════════════════════════════════════════════════

function IsPlayerInQueue()
    return isInQueueState
end

function IsProtectedFromScripts()
    return isProtectedFromOtherScripts
end

function CanPlayerInteractWithOtherScripts()
    return not isInQueueState
end

-- ═══════════════════════════════════════════════════════════
-- 📏 CALCUL DE DISTANCE AU PED CATMOUSE (OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════

local function GetDistanceToCatMousePed()
    local currentTime = GetGameTimer()
    
    -- ✅ OPTIMISATION: Mettre à jour le cache seulement si nécessaire
    if currentTime - lastCacheUpdate > CACHE_INTERVAL then
        playerPed = PlayerPedId()
        playerCoords = GetEntityCoords(playerPed)
        lastCacheUpdate = currentTime
    end
    
    return #(playerCoords - pedPos)
end

-- ═══════════════════════════════════════════════════════════
-- 🔔 NOTIFICATION
-- ═══════════════════════════════════════════════════════════

local function ShowRestrictionNotification()
    local currentTime = GetGameTimer()
    
    if currentTime - lastNotificationTime < NOTIFICATION_COOLDOWN then
        return
    end
    
    lastNotificationTime = currentTime
    
    ShowNotification({
        type = Constants.NotificationType.WARNING,
        message = Config.Texts.queue_restriction or '🔒 Recherche en cours ! Tapez /leavequeue pour annuler.'
    })
end

-- ═══════════════════════════════════════════════════════════
-- 🔒 FONCTION: ACTIVER/DÉSACTIVER PROTECTION
-- ═══════════════════════════════════════════════════════════

local function SetScriptProtection(enabled)
    isProtectedFromOtherScripts = enabled
    
    if enabled then
        Utils.Info('🔒 PROTECTION ACTIVÉE - Touches bloquées hors zone PED', nil)
    else
        Utils.Info('🔓 PROTECTION DÉSACTIVÉE', nil)
    end
end

-- ═══════════════════════════════════════════════════════════
-- 🚫 THREAD PRINCIPAL DE BLOCAGE (ULTRA-OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════

CreateThread(function()
    Utils.Info('🔒 Thread de protection démarré', nil)
    
    while true do
        if not isProtectedFromOtherScripts then
            -- ✅ OPTIMISATION: Wait très long si pas de protection active
            Wait(1000)
        else
            local distance = GetDistanceToCatMousePed()
            
            if distance > RESTRICTION_DISTANCE then
                -- ✅ CRITIQUE: Désactiver les contrôles seulement quand loin du PED
                DisableControlAction(0, 51, true)   -- E
                DisableControlAction(0, 38, true)   -- E
                DisableControlAction(0, 46, true)   -- E
                DisableControlAction(0, 177, true)  -- BACKSPACE
                DisableControlAction(0, 23, true)   -- F (véhicule)
                DisableControlAction(0, 75, true)   -- F (sortie véhicule)
                DisableControlAction(0, 44, true)   -- Q
                DisableControlAction(0, 74, true)   -- H
                DisableControlAction(0, 86, true)   -- E (véhicule)
                DisableControlAction(0, 244, true)  -- M
                
                -- Notification si touche pressée
                if IsDisabledControlJustPressed(0, 38) or 
                   IsDisabledControlJustPressed(0, 51) or 
                   IsDisabledControlJustPressed(0, 46) or
                   IsDisabledControlJustPressed(0, 177) then
                    ShowRestrictionNotification()
                end
                
                -- ✅ OPTIMISATION: Wait 0 seulement quand on désactive des contrôles
                Wait(0)
            else
                -- Proche du PED, pas de blocage
                Wait(100)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 GESTION DE L'ÉTAT
-- ═══════════════════════════════════════════════════════════

function SetQueueState(state)
    local oldState = isInQueueState
    
    if oldState == state then return end
    
    Utils.Debug('SetQueueState', { oldState = oldState, newState = state }, SOURCE_FILE)
    
    if state then
        isInQueueState = true
        SetScriptProtection(true)
        
        ShowNotification({
            type = Constants.NotificationType.INFO,
            message = '🔍 Recherche en cours... Tapez /leavequeue pour annuler'
        })
    else
        isInQueueState = false
        SetScriptProtection(false)
    end
end

-- ═══════════════════════════════════════════════════════════
-- 📡 ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

RegisterNetEvent('catmouse:queueJoined', function()
    Utils.Debug('Event catmouse:queueJoined reçu', nil, SOURCE_FILE)
    SetQueueState(true)
end)

RegisterNetEvent('catmouse:queueLeft', function()
    Utils.Debug('Event catmouse:queueLeft reçu', nil, SOURCE_FILE)
    SetQueueState(false)
end)

RegisterNetEvent(Constants.Events.MATCH_FOUND, function()
    Utils.Debug('Match trouvé - Désactivation restrictions', nil, SOURCE_FILE)
    SetQueueState(false)
end)

RegisterNetEvent(Constants.Events.QUEUE_UPDATE, function(data)
    if data.status == Constants.QueueStatus.SEARCHING then
        if not isInQueueState then
            SetQueueState(true)
        end
    elseif data.status == Constants.QueueStatus.FOUND or 
           data.status == Constants.QueueStatus.CANCELLED or 
           data.status == Constants.QueueStatus.TIMEOUT then
        SetQueueState(false)
    end
end)

RegisterNetEvent(Constants.Events.PREPARE_RACE, function()
    Utils.Debug('Préparation course - Désactivation restrictions', nil, SOURCE_FILE)
    SetQueueState(false)
end)

-- ═══════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetQueueState(false)
end)

-- ═══════════════════════════════════════════════════════════
-- 📤 EXPORTS POUR AUTRES SCRIPTS
-- ═══════════════════════════════════════════════════════════

exports('IsPlayerInCatMouseQueue', IsPlayerInQueue)
exports('CanPlayerInteract', CanPlayerInteractWithOtherScripts)
exports('IsProtectedFromScripts', IsProtectedFromScripts)
