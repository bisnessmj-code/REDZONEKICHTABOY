--[[
    Module Events - Panel Admin Fight League
    Gestion des événements Fight League
]]

local Events = {}

-- Cache des événements actifs
local activeEvents = {}

-- ══════════════════════════════════════════════════════════════
-- GESTION DES ÉVÉNEMENTS
-- ══════════════════════════════════════════════════════════════

-- Créer un événement
function Events.Create(staffSource, data)
    if not Auth.HasPermission(staffSource, 'event.create') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)

    local eventId = Database.InsertAsync([[
        INSERT INTO panel_events
        (name, description, type, status, created_by, created_by_name, max_participants, location_name, location_coords, scheduled_at)
        VALUES (?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?)
    ]], {
        data.name,
        data.description,
        data.type or Enums.EventType.FIGHT,
        session.identifier,
        session.name,
        data.maxParticipants or Config.Events.MaxParticipants,
        data.locationName,
        data.locationCoords,
        data.scheduledAt
    })

    Database.AddLog(
        Enums.LogCategory.EVENT,
        Enums.LogAction.EVENT_CREATE,
        session.identifier,
        session.name,
        nil, nil,
        {eventId = eventId, name = data.name, type = data.type}
    )

    return true, eventId
end

-- Démarrer un événement
function Events.Start(staffSource, eventId)
    if not Auth.HasPermission(staffSource, 'event.manage') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)

    Database.ExecuteAsync([[
        UPDATE panel_events
        SET status = 'active', started_at = NOW()
        WHERE id = ? AND status IN ('draft', 'scheduled')
    ]], {eventId})

    -- Charger en mémoire
    local event = Database.SingleAsync([[
        SELECT * FROM panel_events WHERE id = ?
    ]], {eventId})

    if event then
        activeEvents[eventId] = event
    end

    Database.AddLog(
        Enums.LogCategory.EVENT,
        Enums.LogAction.EVENT_START,
        session.identifier,
        session.name,
        nil, nil,
        {eventId = eventId}
    )

    Database.UpdateDailyStat('events_held', 1)

    return true
end

-- Terminer un événement
function Events.End(staffSource, eventId)
    if not Auth.HasPermission(staffSource, 'event.manage') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)

    Database.ExecuteAsync([[
        UPDATE panel_events
        SET status = 'completed', ended_at = NOW()
        WHERE id = ? AND status = 'active'
    ]], {eventId})

    activeEvents[eventId] = nil

    Database.AddLog(
        Enums.LogCategory.EVENT,
        Enums.LogAction.EVENT_END,
        session.identifier,
        session.name,
        nil, nil,
        {eventId = eventId}
    )

    return true
end

-- Annuler un événement
function Events.Cancel(staffSource, eventId)
    if not Auth.HasPermission(staffSource, 'event.manage') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)

    Database.ExecuteAsync([[
        UPDATE panel_events
        SET status = 'cancelled', ended_at = NOW()
        WHERE id = ? AND status IN ('draft', 'scheduled', 'active')
    ]], {eventId})

    activeEvents[eventId] = nil

    Database.AddLog(
        Enums.LogCategory.EVENT,
        Enums.LogAction.EVENT_CANCEL,
        session.identifier,
        session.name,
        nil, nil,
        {eventId = eventId}
    )

    return true
end

-- ══════════════════════════════════════════════════════════════
-- PARTICIPANTS
-- ══════════════════════════════════════════════════════════════

-- Ajouter un participant
function Events.AddParticipant(eventId, identifier, playerName)
    return Database.InsertAsync([[
        INSERT IGNORE INTO panel_event_participants (event_id, identifier, player_name)
        VALUES (?, ?, ?)
    ]], {eventId, identifier, playerName})
end

-- Mettre à jour le statut d'un participant
function Events.UpdateParticipantStatus(eventId, identifier, status)
    return Database.ExecuteAsync([[
        UPDATE panel_event_participants
        SET status = ?
        WHERE event_id = ? AND identifier = ?
    ]], {status, eventId, identifier})
end

-- Check-in d'un participant
function Events.CheckInParticipant(eventId, identifier)
    return Database.ExecuteAsync([[
        UPDATE panel_event_participants
        SET status = 'checked_in', checked_in_at = NOW()
        WHERE event_id = ? AND identifier = ? AND status = 'registered'
    ]], {eventId, identifier})
end

-- Retirer un participant
function Events.RemoveParticipant(eventId, identifier)
    return Database.ExecuteAsync([[
        DELETE FROM panel_event_participants
        WHERE event_id = ? AND identifier = ?
    ]], {eventId, identifier})
end

-- Obtenir les participants d'un événement
function Events.GetParticipants(eventId)
    return Database.QueryAsync([[
        SELECT * FROM panel_event_participants
        WHERE event_id = ?
        ORDER BY registered_at
    ]], {eventId})
end

-- ══════════════════════════════════════════════════════════════
-- RÉCUPÉRATION
-- ══════════════════════════════════════════════════════════════

-- Obtenir tous les événements
function Events.GetAll(status, limit)
    local query = 'SELECT * FROM panel_events'
    local params = {}

    if status then
        query = query .. ' WHERE status = ?'
        table.insert(params, status)
    end

    query = query .. ' ORDER BY created_at DESC'

    if limit then
        query = query .. ' LIMIT ?'
        table.insert(params, limit)
    end

    return Database.QueryAsync(query, params)
end

-- Obtenir un événement par ID
function Events.GetById(eventId)
    local event = Database.SingleAsync([[
        SELECT * FROM panel_events WHERE id = ?
    ]], {eventId})

    if event then
        event.participants = Events.GetParticipants(eventId)
    end

    return event
end

-- Obtenir les événements actifs
function Events.GetActive()
    return Database.QueryAsync([[
        SELECT * FROM panel_events WHERE status = 'active'
    ]], {})
end

-- ══════════════════════════════════════════════════════════════
-- ROUTING BUCKETS (pour isoler les événements)
-- ══════════════════════════════════════════════════════════════

-- Déplacer un joueur dans un bucket
function Events.SetPlayerBucket(source, bucket)
    SetPlayerRoutingBucket(source, bucket)
end

-- Obtenir le bucket d'un joueur
function Events.GetPlayerBucket(source)
    return GetPlayerRoutingBucket(source)
end

-- Déplacer tous les participants dans un bucket
function Events.MoveParticipantsToBucket(eventId, bucket)
    local participants = Events.GetParticipants(eventId)

    for _, participant in ipairs(participants or {}) do
        local xPlayer = ESX.GetPlayerFromIdentifier(participant.identifier)
        if xPlayer then
            Events.SetPlayerBucket(xPlayer.source, bucket)
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- ANNONCES D'ÉVÉNEMENTS (Discord + In-Game)
-- ══════════════════════════════════════════════════════════════

-- Envoyer une annonce d'événement
function Events.SendAnnouncement(staffSource, data)
    if not Auth.HasPermission(staffSource, 'event.announce') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)
    local eventType = data.eventType -- 'gdt' ou 'cvc'
    local message = data.message
    local time = data.time or ''
    local minReactions = data.minReactions or 20
    local sendDiscord = data.sendDiscord ~= false -- Par défaut true
    local sendIngame = data.sendIngame ~= false -- Par défaut true

    -- Vérifier qu'au moins un canal est sélectionné
    if not sendDiscord and not sendIngame then
        return false, 'NO_CHANNEL_SELECTED'
    end

    -- Envoyer sur Discord si demandé
    if sendDiscord then
        -- Récupérer le webhook depuis server.cfg (sécurisé)
        local webhookUrl = GetConvar('panel_webhook_' .. eventType, '')

        -- Fallback sur la config si pas dans server.cfg
        if webhookUrl == '' and Config.Discord.EventWebhooks then
            webhookUrl = Config.Discord.EventWebhooks[eventType]
        end

        if not webhookUrl or webhookUrl == '' then
            if not sendIngame then
                return false, 'WEBHOOK_NOT_CONFIGURED'
            end
            print('^3[EVENTS]^0 Webhook non configuré pour ' .. eventType .. ', envoi Discord ignoré')
        else
            -- Récupérer l'ID du rôle depuis server.cfg (sécurisé)
            local roleId = GetConvar('panel_role_' .. eventType, '')

            -- Fallback sur la config
            if roleId == '' and Config.Discord.RoleIds then
                roleId = Config.Discord.RoleIds[eventType]
            end

            -- Construire le message Discord avec embed
            local eventTitle = eventType == 'gdt' and '🎮 ANNONCE GDT' or '⚔️ ANNONCE CVC'
            local eventColor = eventType == 'gdt' and 3447003 or 15158332 -- Bleu pour GDT, Rouge pour CVC

            local embedDescription = message
            if time and time ~= '' then
                embedDescription = '**📅 Horaire:** ' .. time .. '\n\n' .. message
            end

            -- Ajouter les infos de réactions minimales
            embedDescription = embedDescription .. '\n\n' ..
                '━━━━━━━━━━━━━━━━━━━━━━\n' ..
                '✅ **Réactions minimum:** ' .. minReactions .. '\n' ..
                '📢 Réagissez pour confirmer votre participation!'

            local discordPayload = {
                content = roleId and roleId ~= '' and ('<@&' .. roleId .. '>') or nil,
                embeds = {
                    {
                        title = eventTitle .. (time ~= '' and (' - ' .. time) or ''),
                        description = embedDescription,
                        color = eventColor,
                        thumbnail = {
                            url = 'https://r2.fivemanage.com/65OINTV6xwj2vOK7XWptj/logo.png'
                        },
                        footer = {
                            text = 'Fight League • Annonce par ' .. session.name
                        },
                        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
                    }
                }
            }

            -- Envoyer sur Discord
            PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
                if statusCode >= 200 and statusCode < 300 then
                    print('^2[EVENTS]^0 Annonce Discord envoyée avec succès (' .. eventType .. ')')
                else
                    print('^1[EVENTS]^0 Erreur envoi Discord: ' .. tostring(statusCode))
                end
            end, 'POST', json.encode(discordPayload), {['Content-Type'] = 'application/json'})
        end
    end

    -- Envoyer l'annonce en jeu si demandé
    if sendIngame then
        local inGameTitle = eventType == 'gdt' and 'ANNONCE GDT' or 'ANNONCE CVC'
        if time and time ~= '' then
            inGameTitle = inGameTitle .. ' - ' .. time
        end

        -- Utiliser le système d'annonces existant (bannière urgente + chat)
        Announcements.Broadcast(message, 'chat', 'urgent', inGameTitle)
    end

    -- Log
    Database.AddLog(
        Enums.LogCategory.EVENT,
        'event_announce',
        session.identifier,
        session.name,
        nil, nil,
        {eventType = eventType, time = time, minReactions = minReactions, message = message, discord = sendDiscord, ingame = sendIngame}
    )

    -- Log Discord sur le webhook "events" (pour les admins)
    if Discord and Discord.LogEventAnnounce then
        Discord.LogEventAnnounce(session.name, eventType, time, message, minReactions, sendDiscord, sendIngame)
    end

    return true
end

-- Callback pour envoyer une annonce d'événement
ESX.RegisterServerCallback('panel:sendEventAnnouncement', function(source, cb, data)
    local success, err = Events.SendAnnouncement(source, data)
    cb({success = success, error = err})
end)

-- ══════════════════════════════════════════════════════════════
-- STATISTIQUES D'ÉVÉNEMENTS
-- ══════════════════════════════════════════════════════════════

-- Obtenir les statistiques d'événements par staff
function Events.GetStats(timeFilter)
    local dateFilter = ''

    if timeFilter == 'today' then
        dateFilter = "AND DATE(l.created_at) = CURDATE()"
    elseif timeFilter == 'week' then
        dateFilter = "AND l.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)"
    elseif timeFilter == 'month' then
        dateFilter = "AND l.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
    end

    -- Récupérer les stats par staff (annonces d'événements)
    local query = string.format([[
        SELECT
            l.staff_name as name,
            COUNT(*) as total_announces,
            SUM(CASE WHEN JSON_EXTRACT(l.details, '$.eventType') = 'gdt' THEN 1 ELSE 0 END) as gdt_count,
            SUM(CASE WHEN JSON_EXTRACT(l.details, '$.eventType') = 'cvc' THEN 1 ELSE 0 END) as cvc_count,
            MAX(l.created_at) as last_announce
        FROM panel_logs l
        WHERE l.action = 'event_announce'
        %s
        GROUP BY l.staff_identifier, l.staff_name
        ORDER BY total_announces DESC
    ]], dateFilter)

    local staffStats = Database.QueryAsync(query, {})

    -- Stats globales
    local globalQuery = string.format([[
        SELECT
            COUNT(*) as total,
            SUM(CASE WHEN JSON_EXTRACT(details, '$.eventType') = 'gdt' THEN 1 ELSE 0 END) as gdt_total,
            SUM(CASE WHEN JSON_EXTRACT(details, '$.eventType') = 'cvc' THEN 1 ELSE 0 END) as cvc_total
        FROM panel_logs
        WHERE action = 'event_announce'
        %s
    ]], dateFilter)

    local globalStats = Database.SingleAsync(globalQuery, {})

    return {
        staff = staffStats or {},
        global = globalStats or {total = 0, gdt_total = 0, cvc_total = 0}
    }
end

-- Callback pour obtenir les stats d'événements
ESX.RegisterServerCallback('panel:getEventStats', function(source, cb, timeFilter)
    if not Auth.HasPermission(source, 'event.stats') then
        cb({success = false, error = 'NO_PERMISSION'})
        return
    end

    local stats = Events.GetStats(timeFilter)
    cb({success = true, data = stats})
end)

-- ══════════════════════════════════════════════════════════════
-- RESET DU CLASSEMENT
-- ══════════════════════════════════════════════════════════════

-- Réinitialiser les statistiques d'événements (supprimer les logs event_announce)
function Events.ResetStats(staffSource, cb)
    if not Auth.HasPermission(staffSource, 'event.stats.reset') then
        if cb then cb(false, Enums.ErrorCode.NO_PERMISSION) end
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)

    -- Supprimer tous les logs d'annonces d'événements
    Database.Execute([[
        DELETE FROM panel_logs WHERE action = 'event_announce'
    ]], {}, function(result)
        -- Extraire le nombre de lignes affectées
        local count = 0
        if type(result) == 'table' and result.affectedRows then
            count = result.affectedRows
        elseif type(result) == 'number' then
            count = result
        end

        print('^3[EVENTS]^0 Classement réinitialisé: ' .. tostring(count) .. ' entrées supprimées par ' .. session.name)

        -- Log de l'action de reset
        Database.AddLog(
            Enums.LogCategory.SYSTEM,
            'event_stats_reset',
            session.identifier,
            session.name,
            nil, nil,
            {resetBy = session.name, deletedCount = count}
        )

        if cb then cb(true) end
    end)

    return true
end

-- Callback pour réinitialiser les stats d'événements
ESX.RegisterServerCallback('panel:resetEventStats', function(source, cb)
    Events.ResetStats(source, function(success, err)
        cb({success = success, error = err})
    end)
end)

-- Export global
_G.Events = Events
