--[[
    ═══════════════════════════════════════════════════════════
    💻 CLIENT - POINT D'ENTRÉE PRINCIPAL
    ═══════════════════════════════════════════════════════════
    
    Initialisation du client et commandes.
]]

local SOURCE_FILE = 'client/main.lua'

-- ═══════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    
    Utils.Info('=== CatMouse Racing - Client ===')
    Utils.Info('Version: 1.0.0')
    Utils.Info('Debug: ' .. (Config.Debug and 'ACTIVÉ' or 'DÉSACTIVÉ'))
    Utils.Info('=================================')
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 COMMANDES
-- ═══════════════════════════════════════════════════════════

--- Commande /1v1course
RegisterCommand('1v1course', function(source, args)
    Utils.Debug('Commande 1v1course', { args = args }, SOURCE_FILE)
    
    if #args < 1 then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.cmd_usage
        })
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId or targetId < 1 then
        ShowNotification({
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.cmd_invalid_id
        })
        return
    end
    
    TriggerServerEvent(Constants.Events.SEND_INVITATION, targetId)
end, false)

TriggerEvent('chat:addSuggestion', '/1v1course', 'Inviter un joueur en 1v1 course', {
    { name = 'ID', help = 'ID du joueur à inviter' }
})

-- ═══════════════════════════════════════════════════════════
-- 🚫 ÉVÉNEMENT DE KICK FORCÉ (ADMIN)
-- ═══════════════════════════════════════════════════════════

--- Kick forcé par un admin - Nettoyage complet
RegisterNetEvent('catmouse:forceKick', function()
    Utils.Info('Expulsion forcée par un admin - Nettoyage...', nil)
    
    -- Arrêter la surveillance de sécurité si active
    if StopSecurityMonitoring then
        StopSecurityMonitoring()
    end
    
    -- Arrêter la game loop
    if StopGameLoop then
        StopGameLoop()
    end
    
    -- Désactiver les restrictions
    DisableRestrictions()
    
    -- Supprimer le véhicule
    DeleteRaceVehicle()
    
    -- Masquer tous les HUD
    if IsMainUIOpen() then
        CloseRacingUI()
    end
    
    if IsRaceHUDVisible() then
        HideRaceHUD()
    end
    
    SendNUIMessage({ action = 'hideRoundTransition' })
    SendNUIMessage({ action = 'hideRaceHUD' })
    SendNUIMessage({ action = 'hideCountdown' })
    SendNUIMessage({ action = 'showCaptureBar', data = { show = false } })
    
    -- Téléporter à la sortie
    TeleportToExit()
    
    -- Reset de l'état local
    if ResetRaceState then
        ResetRaceState()
    end
    
    Utils.Info('Nettoyage complet terminé (kick admin)', nil)
end)

-- ═══════════════════════════════════════════════════════════
-- 🐛 COMMANDES DEBUG
-- ═══════════════════════════════════════════════════════════

if Config.Debug then
    -- Afficher l'état local
    RegisterCommand('race_local_status', function()
        local state = GetRaceState()
        
        Utils.Info('=== ÉTAT LOCAL ===')
        Utils.Info('En course: ' .. tostring(state.isInRace))
        Utils.Info('Status: ' .. Utils.GetStatusName(state.status))
        Utils.Info('Role: ' .. Utils.GetRoleName(state.role))
        Utils.Info('Round: ' .. state.currentRound .. '/' .. state.maxRounds)
        Utils.Info('Adversaire: ' .. (state.opponentName or 'N/A'))
        Utils.Info('Distance: ' .. string.format('%.2f', state.distanceToOpponent) .. 'm')
        Utils.Info('Capture: ' .. string.format('%.2f', state.captureProgress) .. '%')
        Utils.Info('Timer restant: ' .. Utils.FormatTime(state.remainingTime))
    end, false)
    
    -- Ouvrir l'UI de test
    RegisterCommand('race_ui', function()
        OpenRacingUI()
    end, false)
    
    -- Tester une notification
    RegisterCommand('race_notif', function(source, args)
        local notifType = args[1] or 'info'
        ShowNotification({
            type = notifType,
            message = 'Test notification de type: ' .. notifType
        })
    end, false)
    
    -- Afficher les coordonnées actuelles
    RegisterCommand('race_coords', function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        local formatted = string.format('vec4(%.6f, %.6f, %.6f, %.6f)', coords.x, coords.y, coords.z, heading)
        Utils.Info('Coordonnées: ' .. formatted)
        
    end, false)
    
    TriggerEvent('chat:addSuggestion', '/race_local_status', 'Afficher l\'état local de la course')
    TriggerEvent('chat:addSuggestion', '/race_ui', 'Ouvrir l\'interface de course')
    TriggerEvent('chat:addSuggestion', '/race_notif', 'Tester une notification', {
        { name = 'type', help = 'info, success, warning, error, invite' }
    })
    TriggerEvent('chat:addSuggestion', '/race_coords', 'Afficher les coordonnées actuelles')
end

-- ═══════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Debug('Resource arrêtée - Nettoyage...', nil, SOURCE_FILE)
    
    -- Fermer l'UI si ouverte
    if IsMainUIOpen() then
        CloseRacingUI()
    end
    
    -- Quitter la course si en cours
    if IsInRace() then
        TriggerServerEvent(Constants.Events.LEAVE_RACE)
    end
end)
