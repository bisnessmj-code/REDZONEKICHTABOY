--[[
    ═══════════════════════════════════════════════════════════
    🔔 CLIENT - SYSTÈME DE NOTIFICATIONS (VERSION FINALE)
    ═══════════════════════════════════════════════════════════
    
    Gestion des notifications visuelles.
    ✅ Intégration complète avec les restrictions de queue
]]

local SOURCE_FILE = 'client/notifications.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES
-- ═══════════════════════════════════════════════════════════

local notificationQueue = {}
local activeNotifications = {}

-- ═══════════════════════════════════════════════════════════
-- 🔔 AFFICHAGE
-- ═══════════════════════════════════════════════════════════

--- Affichage d'une notification
---@param data table {type, message, duration?}
function ShowNotification(data)
    Utils.Trace('ShowNotification', { type = data.type, message = data.message })
    
    local notification = {
        type = data.type or Constants.NotificationType.INFO,
        message = data.message,
        duration = data.duration or Config.Notifications.duration,
        id = Utils.GenerateId()
    }
    
    -- Ajout à la queue
    table.insert(notificationQueue, notification)
    
    -- Traitement
    ProcessNotificationQueue()
end

--- Traitement de la queue
function ProcessNotificationQueue()
    while #activeNotifications < Config.Notifications.maxVisible and #notificationQueue > 0 do
        local notification = table.remove(notificationQueue, 1)
        DisplayNotification(notification)
    end
end

--- Affichage effectif
---@param notification table
function DisplayNotification(notification)
    table.insert(activeNotifications, notification)
    
    -- Envoi à la NUI
    SendNUIMessage({
        action = 'showNotification',
        data = notification
    })
    
    -- Auto-suppression
    SetTimeout(notification.duration, function()
        RemoveNotification(notification.id)
    end)
    
    Utils.Debug('Notification affichée', { id = notification.id, type = notification.type }, SOURCE_FILE)
end

--- Suppression d'une notification
---@param notificationId string
function RemoveNotification(notificationId)
    for i, notif in ipairs(activeNotifications) do
        if notif.id == notificationId then
            table.remove(activeNotifications, i)
            
            SendNUIMessage({
                action = 'removeNotification',
                data = { id = notificationId }
            })
            
            ProcessNotificationQueue()
            break
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- 📡 ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

--- Notification depuis le serveur
RegisterNetEvent(Constants.Events.NOTIFY, function(data)
    Utils.Debug('Event NOTIFY reçu', data, SOURCE_FILE)
    ShowNotification(data)
end)

--- Réception d'une invitation
RegisterNetEvent(Constants.Events.RECEIVE_INVITATION, function(inviteData)
    Utils.Debug('Event RECEIVE_INVITATION reçu', inviteData, SOURCE_FILE)
    
    ShowNotification({
        type = Constants.NotificationType.INVITE,
        message = Utils.FormatText(Config.Texts.invite_received, inviteData.senderName)
    })
    
    -- Stocker l'invitation pour les commandes
    _G.lastInviteId = inviteData.inviteId
    _G.lastInviteSender = inviteData.senderName
    
    ShowNotification({
        type = Constants.NotificationType.INFO,
        message = 'Utilisez /acceptrace ou /declinerace'
    })
end)

--- Mise à jour de la queue (depuis le serveur)
RegisterNetEvent(Constants.Events.QUEUE_UPDATE, function(data)
    Utils.Debug('Event QUEUE_UPDATE reçu', data, SOURCE_FILE)
    
    if data.status == Constants.QueueStatus.SEARCHING then
        -- Mettre à jour l'UI avec la position dans la queue
        SendNUIMessage({
            action = 'updateQueue',
            data = {
                position = data.position,
                queueSize = data.queueSize,
                waitTime = data.waitTime
            }
        })
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 COMMANDES
-- ═══════════════════════════════════════════════════════════

RegisterCommand('acceptrace', function()
    if not _G.lastInviteId then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = 'Aucune invitation en attente.'
        })
        return
    end
    
    Utils.Debug('Commande acceptrace', { inviteId = _G.lastInviteId }, SOURCE_FILE)
    
    TriggerServerEvent(Constants.Events.ACCEPT_INVITATION, _G.lastInviteId)
    _G.lastInviteId = nil
    _G.lastInviteSender = nil
end, false)

RegisterCommand('declinerace', function()
    if not _G.lastInviteId then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = 'Aucune invitation en attente.'
        })
        return
    end
    
    Utils.Debug('Commande declinerace', { inviteId = _G.lastInviteId }, SOURCE_FILE)
    
    TriggerServerEvent(Constants.Events.DECLINE_INVITATION, _G.lastInviteId)
    _G.lastInviteId = nil
    _G.lastInviteSender = nil
end, false)

-- ════════════════════════════════════════════════════════════
-- ✅ COMMANDE JOINQUEUE
-- ════════════════════════════════════════════════════════════
RegisterCommand('joinqueue', function()
    Utils.Debug('Commande joinqueue', nil, SOURCE_FILE)
    
    -- Vérifier si déjà en course
    if IsInRace() then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.already_in_race
        })
        return
    end
    
    -- Vérifier si déjà en queue
    if IsPlayerInQueue() then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.queue_already
        })
        return
    end
    
    -- Envoyer au serveur
    TriggerServerEvent(Constants.Events.JOIN_QUEUE)
    
    -- ✅ IMPORTANT: Déclencher l'événement local pour activer les restrictions
    TriggerEvent('catmouse:queueJoined')
end, false)

-- ════════════════════════════════════════════════════════════
-- ✅ COMMANDE LEAVEQUEUE
-- ════════════════════════════════════════════════════════════
RegisterCommand('leavequeue', function()
    Utils.Debug('Commande leavequeue', nil, SOURCE_FILE)
    
    -- Vérifier si en queue
    if not IsPlayerInQueue() then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = 'Vous n\'êtes pas dans la file d\'attente.'
        })
        return
    end
    
    -- Envoyer au serveur
    TriggerServerEvent(Constants.Events.LEAVE_QUEUE)
    
    -- ✅ IMPORTANT: Déclencher l'événement local pour désactiver les restrictions
    TriggerEvent('catmouse:queueLeft')
end, false)

-- Suggestions de commandes
TriggerEvent('chat:addSuggestion', '/acceptrace', 'Accepter une invitation de course')
TriggerEvent('chat:addSuggestion', '/declinerace', 'Refuser une invitation de course')
TriggerEvent('chat:addSuggestion', '/joinqueue', 'Rejoindre la file d\'attente')
TriggerEvent('chat:addSuggestion', '/leavequeue', 'Quitter la file d\'attente')
