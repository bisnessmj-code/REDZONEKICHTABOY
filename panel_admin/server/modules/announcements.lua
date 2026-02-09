--[[
    Module Announcements - Panel Admin Fight League
    Système d'annonces serveur
]]

local Announcements = {}

-- ══════════════════════════════════════════════════════════════
-- ENVOI D'ANNONCES
-- ══════════════════════════════════════════════════════════════

-- Envoyer une annonce immédiate
function Announcements.Send(staffSource, message, announceType, priority, title)
    if not Auth.HasPermission(staffSource, 'announce.send') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, cleanType = Validators.AnnounceType(announceType or 'chat')
    if not valid then return false, cleanType end

    local session = Auth.GetSession(staffSource)

    -- Enregistrer en BDD
    local announceId = Database.InsertAsync([[
        INSERT INTO panel_announcements
        (title, message, type, priority, created_by, created_by_name, is_sent, sent_at)
        VALUES (?, ?, ?, ?, ?, ?, 1, NOW())
    ]], {
        title,
        message,
        cleanType,
        priority or 'normal',
        session.identifier,
        session.name
    })

    -- Diffuser l'annonce
    Announcements.Broadcast(message, cleanType, priority, title)

    -- Log
    Database.AddLog(
        'system',
        Enums.LogAction.ANNOUNCE_SEND,
        session.identifier,
        session.name,
        nil, nil,
        {type = cleanType, priority = priority, title = title}
    )

    return true, announceId
end

-- Programmer une annonce
function Announcements.Schedule(staffSource, message, announceType, scheduledAt, priority, title)
    if not Auth.HasPermission(staffSource, 'announce.schedule') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, cleanType = Validators.AnnounceType(announceType or 'chat')
    if not valid then return false, cleanType end

    local session = Auth.GetSession(staffSource)

    local announceId = Database.InsertAsync([[
        INSERT INTO panel_announcements
        (title, message, type, priority, created_by, created_by_name, is_scheduled, scheduled_at)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    ]], {
        title,
        message,
        cleanType,
        priority or 'normal',
        session.identifier,
        session.name,
        scheduledAt
    })

    Database.AddLog(
        'system',
        Enums.LogAction.ANNOUNCE_SCHEDULE,
        session.identifier,
        session.name,
        nil, nil,
        {type = cleanType, scheduledAt = scheduledAt}
    )

    return true, announceId
end

-- ══════════════════════════════════════════════════════════════
-- DIFFUSION
-- ══════════════════════════════════════════════════════════════

-- Diffuser une annonce à tous les joueurs
function Announcements.Broadcast(message, announceType, priority, title)
    local data = {
        message = message,
        type = announceType,
        priority = priority,
        title = title
    }

    -- Envoyer selon le type
    if announceType == 'chat' or announceType == 'all' then
        -- Message dans le chat
        TriggerClientEvent('chat:addMessage', -1, {
            color = Announcements.GetPriorityColor(priority),
            multiline = true,
            args = {'[ANNONCE]', message}
        })

        -- Jouer le son pour toutes les annonces chat
        TriggerClientEvent('panel:playAnnouncementSound', -1)

        -- Bannière visuelle UNIQUEMENT pour les annonces urgentes
        if priority == 'urgent' then
            TriggerClientEvent('panel:announceBanner', -1, {
                message = message,
                title = title or 'ANNONCE',
                priority = priority,
                duration = Announcements.GetPriorityDuration(priority)
            })
        end
    end

    if announceType == 'notification' or announceType == 'all' then
        TriggerClientEvent('panel:notification', -1, {
            type = 'info',
            title = title or 'Annonce',
            message = message,
            duration = Announcements.GetPriorityDuration(priority)
        })
    end

    if announceType == 'popup' or announceType == 'all' then
        TriggerClientEvent('panel:popup', -1, {
            title = title or 'Annonce',
            message = message,
            priority = priority
        })
    end
end

-- Obtenir la couleur selon la priorité
function Announcements.GetPriorityColor(priority)
    local colors = {
        low = {100, 100, 100},
        normal = {255, 255, 255},
        high = {255, 59, 48},      -- Rouge Apple
        urgent = {255, 0, 0}
    }
    return colors[priority] or colors.normal
end

-- Obtenir la durée d'affichage selon la priorité
function Announcements.GetPriorityDuration(priority)
    local durations = {
        low = 3000,
        normal = 5000,
        high = 8000,
        urgent = 12000
    }
    return durations[priority] or durations.normal
end

-- ══════════════════════════════════════════════════════════════
-- ANNONCES PROGRAMMÉES
-- ══════════════════════════════════════════════════════════════

-- Vérifier et envoyer les annonces programmées
function Announcements.CheckScheduled()
    local scheduled = Database.QueryAsync([[
        SELECT * FROM panel_announcements
        WHERE is_scheduled = 1
        AND is_sent = 0
        AND scheduled_at <= NOW()
    ]], {})

    for _, announce in ipairs(scheduled or {}) do
        Announcements.Broadcast(announce.message, announce.type, announce.priority, announce.title)

        -- Marquer comme envoyée
        Database.ExecuteAsync([[
            UPDATE panel_announcements
            SET is_sent = 1, sent_at = NOW()
            WHERE id = ?
        ]], {announce.id})

        -- Gérer la récurrence
        if announce.is_recurring == 1 and announce.recurrence_interval then
            Database.ExecuteAsync([[
                UPDATE panel_announcements
                SET scheduled_at = DATE_ADD(scheduled_at, INTERVAL ? MINUTE), is_sent = 0
                WHERE id = ?
            ]], {announce.recurrence_interval, announce.id})
        end
    end
end

-- Thread de vérification des annonces programmées
CreateThread(function()
    while true do
        Wait(60000) -- Vérifier toutes les minutes
        Announcements.CheckScheduled()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- RÉCUPÉRATION
-- ══════════════════════════════════════════════════════════════

-- Obtenir les dernières annonces
function Announcements.GetRecent(limit)
    limit = limit or 20
    return Database.QueryAsync([[
        SELECT * FROM panel_announcements
        ORDER BY created_at DESC
        LIMIT ?
    ]], {limit})
end

-- Obtenir les annonces programmées
function Announcements.GetScheduled()
    return Database.QueryAsync([[
        SELECT * FROM panel_announcements
        WHERE is_scheduled = 1 AND is_sent = 0
        ORDER BY scheduled_at ASC
    ]], {})
end

-- Export global
_G.Announcements = Announcements
