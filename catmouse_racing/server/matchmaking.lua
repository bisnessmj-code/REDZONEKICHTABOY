--[[
    ═══════════════════════════════════════════════════════════
    🔍 SERVEUR - SYSTÈME DE MATCHMAKING
    ═══════════════════════════════════════════════════════════
    
    Gère la file d'attente et le matching des joueurs.
]]

local SOURCE_FILE = 'server/matchmaking.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 STOCKAGE
-- ═══════════════════════════════════════════════════════════

Matchmaking = Matchmaking or {}

-- File d'attente : { { playerId, joinTime, name } }
Matchmaking.Queue = {}

-- ═══════════════════════════════════════════════════════════
-- 🎮 GESTION DE LA FILE
-- ═══════════════════════════════════════════════════════════

--- Vérification si un joueur est dans la queue
---@param playerId number
---@return boolean
function Matchmaking.IsInQueue(playerId)
    for _, entry in ipairs(Matchmaking.Queue) do
        if entry.playerId == playerId then
            return true
        end
    end
    return false
end

--- Rejoindre la file d'attente
---@param playerId number
---@return boolean success
function Matchmaking.JoinQueue(playerId)
    Utils.Trace('Matchmaking.JoinQueue', { playerId = playerId })
    
    -- Vérifications
    if not Config.Matchmaking.enabled then
        Utils.Debug('Matchmaking désactivé', nil, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, playerId, {
            type = Constants.NotificationType.ERROR,
            message = 'Le matchmaking est désactivé.'
        })
        return false
    end
    
    if Matchmaking.IsInQueue(playerId) then
        Utils.Debug('Joueur déjà dans la queue', { playerId = playerId }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, playerId, {
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.queue_already
        })
        return false
    end
    
    if RaceManager.IsPlayerInRace(playerId) then
        Utils.Debug('Joueur déjà en course', { playerId = playerId }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, playerId, {
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.already_in_race
        })
        return false
    end
    
    -- Ajout à la queue
    local entry = {
        playerId = playerId,
        joinTime = Utils.GetTimestamp(),
        name = GetPlayerName(playerId) or 'Joueur'
    }
    
    table.insert(Matchmaking.Queue, entry)
    
    Utils.Info('Joueur rejoint la queue', {
        playerId = playerId,
        name = entry.name,
        queueSize = #Matchmaking.Queue
    })
    
    -- Notification
    TriggerClientEvent(Constants.Events.NOTIFY, playerId, {
        type = Constants.NotificationType.SUCCESS,
        message = Config.Texts.queue_joined
    })
    
    -- Mise à jour UI
    TriggerClientEvent(Constants.Events.QUEUE_UPDATE, playerId, {
        status = Constants.QueueStatus.SEARCHING,
        position = #Matchmaking.Queue,
        queueSize = #Matchmaking.Queue
    })
    
    -- Tenter un match immédiatement
    Matchmaking.TryMatch()
    
    return true
end

--- Quitter la file d'attente
---@param playerId number
---@return boolean success
function Matchmaking.LeaveQueue(playerId)
    Utils.Trace('Matchmaking.LeaveQueue', { playerId = playerId })
    
    for i, entry in ipairs(Matchmaking.Queue) do
        if entry.playerId == playerId then
            table.remove(Matchmaking.Queue, i)
            
            Utils.Debug('Joueur a quitté la queue', {
                playerId = playerId,
                queueSize = #Matchmaking.Queue
            }, SOURCE_FILE)
            
            -- Notification
            TriggerClientEvent(Constants.Events.NOTIFY, playerId, {
                type = Constants.NotificationType.INFO,
                message = Config.Texts.queue_left
            })
            
            -- Mise à jour UI pour cacher le status de queue
            TriggerClientEvent(Constants.Events.QUEUE_UPDATE, playerId, {
                status = Constants.QueueStatus.CANCELLED
            })
            
            return true
        end
    end
    
    Utils.Debug('Joueur non trouvé dans la queue', { playerId = playerId }, SOURCE_FILE)
    return false
end

--- Tentative de match
function Matchmaking.TryMatch()
    Utils.Trace('Matchmaking.TryMatch', { queueSize = #Matchmaking.Queue })
    
    -- Il faut au moins 2 joueurs
    if #Matchmaking.Queue < 2 then
        Utils.Debug('Pas assez de joueurs pour un match', { queueSize = #Matchmaking.Queue }, SOURCE_FILE)
        return
    end
    
    -- Prendre les 2 premiers joueurs
    local player1 = table.remove(Matchmaking.Queue, 1)
    local player2 = table.remove(Matchmaking.Queue, 1)
    
    -- Vérifier que les joueurs sont toujours en ligne
    if GetPlayerPing(player1.playerId) == 0 then
        Utils.Warn('Joueur 1 hors ligne - remise en queue du joueur 2', { playerId = player1.playerId }, SOURCE_FILE)
        table.insert(Matchmaking.Queue, 1, player2)
        return
    end
    
    if GetPlayerPing(player2.playerId) == 0 then
        Utils.Warn('Joueur 2 hors ligne - remise en queue du joueur 1', { playerId = player2.playerId }, SOURCE_FILE)
        table.insert(Matchmaking.Queue, 1, player1)
        return
    end
    
    Utils.Info('Match trouvé !', {
        player1 = player1.name,
        player2 = player2.name
    })
    
    -- CORRECTION: Notifier IMMÉDIATEMENT que la queue est terminée
    TriggerClientEvent(Constants.Events.QUEUE_UPDATE, player1.playerId, {
        status = Constants.QueueStatus.FOUND
    })
    TriggerClientEvent(Constants.Events.QUEUE_UPDATE, player2.playerId, {
        status = Constants.QueueStatus.FOUND
    })
    
    TriggerClientEvent(Constants.Events.NOTIFY, player1.playerId, {
        type = Constants.NotificationType.SUCCESS,
        message = Config.Texts.queue_match_found
    })
    TriggerClientEvent(Constants.Events.NOTIFY, player2.playerId, {
        type = Constants.NotificationType.SUCCESS,
        message = Config.Texts.queue_match_found
    })
    
    -- Jouer un son
    if Config.Matchmaking.soundOnMatch then
        TriggerClientEvent(Constants.Events.MATCH_FOUND, player1.playerId)
        TriggerClientEvent(Constants.Events.MATCH_FOUND, player2.playerId)
    end
    
    -- Créer la session
    Wait(1500) -- Petit délai pour l'UX
    
    local session = RaceManager.CreateSession(player1.playerId, player2.playerId)
    
    if session then
        -- Démarrer le premier round
        RaceManager.StartRound(session.bucketId)
    else
        Utils.Error('Échec de création de session', nil, SOURCE_FILE)
        
        -- Remettre les joueurs en queue
        table.insert(Matchmaking.Queue, 1, player2)
        table.insert(Matchmaking.Queue, 1, player1)
        
        TriggerClientEvent(Constants.Events.NOTIFY, player1.playerId, {
            type = Constants.NotificationType.ERROR,
            message = 'Erreur lors de la création du match. Vous êtes remis en file.'
        })
        TriggerClientEvent(Constants.Events.NOTIFY, player2.playerId, {
            type = Constants.NotificationType.ERROR,
            message = 'Erreur lors de la création du match. Vous êtes remis en file.'
        })
    end
end

--- Nettoyage des joueurs expirés dans la queue
function Matchmaking.CleanupQueue()
    local currentTime = Utils.GetTimestamp()
    local removed = {}
    
    for i = #Matchmaking.Queue, 1, -1 do
        local entry = Matchmaking.Queue[i]
        
        -- Vérifier si le joueur est toujours en ligne
        if GetPlayerPing(entry.playerId) == 0 then
            table.remove(Matchmaking.Queue, i)
            table.insert(removed, entry.name .. ' (déconnecté)')
        
        -- Vérifier le timeout
        elseif currentTime - entry.joinTime > Config.Matchmaking.maxQueueTime then
            table.remove(Matchmaking.Queue, i)
            table.insert(removed, entry.name .. ' (timeout)')
            
            TriggerClientEvent(Constants.Events.NOTIFY, entry.playerId, {
                type = Constants.NotificationType.WARNING,
                message = Config.Texts.queue_timeout
            })
            TriggerClientEvent(Constants.Events.QUEUE_UPDATE, entry.playerId, {
                status = Constants.QueueStatus.TIMEOUT
            })
        -- CORRECTION: Vérifier si le joueur est en course (retirer de la queue)
        elseif RaceManager.IsPlayerInRace(entry.playerId) then
            table.remove(Matchmaking.Queue, i)
            table.insert(removed, entry.name .. ' (en course)')
            Utils.Debug('Joueur retiré de la queue (en course)', { playerId = entry.playerId }, SOURCE_FILE)
        end
    end
    
    if #removed > 0 then
        Utils.Debug('Joueurs retirés de la queue', { players = removed }, SOURCE_FILE)
    end
end

--- Mise à jour des positions dans la queue
function Matchmaking.UpdateQueuePositions()
    for i, entry in ipairs(Matchmaking.Queue) do
        TriggerClientEvent(Constants.Events.QUEUE_UPDATE, entry.playerId, {
            status = Constants.QueueStatus.SEARCHING,
            position = i,
            queueSize = #Matchmaking.Queue,
            waitTime = Utils.GetTimestamp() - entry.joinTime
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- 📡 ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

RegisterNetEvent(Constants.Events.JOIN_QUEUE, function()
    local source = source
    Utils.Debug('Event JOIN_QUEUE reçu', { source = source }, SOURCE_FILE)
    Matchmaking.JoinQueue(source)
end)

RegisterNetEvent(Constants.Events.LEAVE_QUEUE, function()
    local source = source
    Utils.Debug('Event LEAVE_QUEUE reçu', { source = source }, SOURCE_FILE)
    Matchmaking.LeaveQueue(source)
end)

-- Nettoyage quand un joueur se déconnecte
AddEventHandler('playerDropped', function()
    local source = source
    Matchmaking.LeaveQueue(source)
end)

-- ═══════════════════════════════════════════════════════════
-- ⏰ TIMERS
-- ═══════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(Config.Matchmaking.checkInterval)
        
        if Config.Matchmaking.enabled and #Matchmaking.Queue > 0 then
            Matchmaking.CleanupQueue()
            Matchmaking.TryMatch()
            Matchmaking.UpdateQueuePositions()
        end
    end
end)


