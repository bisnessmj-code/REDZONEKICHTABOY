--[[
    Module Reports - Panel Admin Fight League
    Gestion des tickets de support
]]

local Reports = {}

-- Cache local des reports en memoire pour eviter trop de requetes DB
local reportsCache = {}
local lastCacheUpdate = 0
local CACHE_DURATION = 5000 -- 5 secondes

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ══════════════════════════════════════════════════════════════

-- Rafraichir le cache
local function refreshCache()
    local now = GetGameTimer()
    if now - lastCacheUpdate < CACHE_DURATION then
        return reportsCache
    end

    reportsCache = Database.QueryAsync([[
        SELECT r.*,
               CASE WHEN FIND_IN_SET(r.player_id, ?) > 0 THEN 1 ELSE 0 END as is_online
        FROM panel_reports r
        WHERE r.status != 'deleted'
        ORDER BY
            CASE r.status
                WHEN 'pending' THEN 1
                WHEN 'in_progress' THEN 2
                WHEN 'resolved' THEN 3
            END,
            r.created_at DESC
        LIMIT 100
    ]], {table.concat(Helpers.GetAllPlayers(), ',')})

    lastCacheUpdate = now
    return reportsCache
end

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Creer un nouveau report
function Reports.Create(playerSource, message)
    local xPlayer = ESX.GetPlayerFromId(playerSource)
    if not xPlayer then
        return false, 'PLAYER_NOT_FOUND'
    end

    -- Verifier cooldown (1 report par minute max)
    local lastReport = Database.SingleAsync([[
        SELECT created_at FROM panel_reports
        WHERE player_identifier = ? AND created_at > DATE_SUB(NOW(), INTERVAL 1 MINUTE)
        ORDER BY created_at DESC LIMIT 1
    ]], {xPlayer.getIdentifier()})

    if lastReport then
        return false, 'COOLDOWN'
    end

    -- Inserer le report
    local playerName = GetPlayerName(playerSource) -- Nom FiveM
    local reportId = Database.InsertAsync([[
        INSERT INTO panel_reports (player_id, player_identifier, player_name, message, status, created_at)
        VALUES (?, ?, ?, ?, 'pending', NOW())
    ]], {playerSource, xPlayer.getIdentifier(), playerName, message})

    if reportId and reportId > 0 then
        -- Invalider le cache
        lastCacheUpdate = 0

        -- Preparer les donnees du report
        local reportData = {
            id = reportId,
            player_id = playerSource,
            player_identifier = xPlayer.getIdentifier(),
            player_name = playerName,
            message = message,
            status = 'pending',
            created_at = os.date('%Y-%m-%d %H:%M:%S'),
            is_online = true
        }

        -- Notifier tous les staff connectes
        Reports.NotifyStaff(reportData)

        -- Log
        Database.AddLog(
            Enums.LogCategory.REPORT,
            'report_create',
            xPlayer.getIdentifier(),
            playerName,
            nil, nil,
            {message = message}
        )

        return true, reportId
    end

    return false, 'DATABASE_ERROR'
end

-- Obtenir tous les reports
function Reports.GetAll(staffSource)
    if not Auth.CanAccessPanel(staffSource) then
        return nil, Enums.ErrorCode.NO_PERMISSION
    end

    -- Obtenir les IDs des joueurs en ligne
    local onlinePlayers = Helpers.GetAllPlayers()
    local onlineIds = {}
    for _, id in ipairs(onlinePlayers) do
        onlineIds[id] = true
    end

    local reports = Database.QueryAsync([[
        SELECT * FROM panel_reports
        WHERE status != 'deleted'
        ORDER BY
            CASE status
                WHEN 'pending' THEN 1
                WHEN 'in_progress' THEN 2
                WHEN 'resolved' THEN 3
            END,
            created_at DESC
        LIMIT 100
    ]], {})

    -- Ajouter le flag is_online
    for _, report in ipairs(reports) do
        report.is_online = onlineIds[report.player_id] or false
    end

    return reports
end

-- Prendre en charge un report
function Reports.Claim(staffSource, reportId)
    -- Verifier la permission (cree automatiquement une session si necessaire)
    if not Auth.HasPermission(staffSource, 'report.claim') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)
    if not session then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    -- Verifier que le report existe et est en attente
    local report = Database.SingleAsync([[
        SELECT * FROM panel_reports WHERE id = ? AND status = 'pending'
    ]], {reportId})

    if not report then
        return false, 'REPORT_NOT_FOUND'
    end

    -- Mettre a jour le report
    Database.ExecuteAsync([[
        UPDATE panel_reports
        SET status = 'in_progress', claimed_by = ?, claimed_by_name = ?, claimed_at = NOW()
        WHERE id = ?
    ]], {session.identifier, session.name, reportId})

    -- Invalider le cache
    lastCacheUpdate = 0

    -- Log
    Database.AddLog(
        Enums.LogCategory.REPORT,
        'report_claim',
        session.identifier,
        session.name,
        report.player_identifier,
        report.player_name,
        {report_id = reportId}
    )

    -- Notifier le joueur
    if report.player_id then
        local xPlayer = ESX.GetPlayerFromId(report.player_id)
        if xPlayer then
            TriggerClientEvent('panel:notification', report.player_id, {
                type = 'info',
                title = 'Support',
                message = 'Votre ticket est en cours de traitement par ' .. session.name
            })
        end
    end

    return true
end

-- Repondre a un report
function Reports.Respond(staffSource, reportId, response, closeAfter)
    -- Verifier la permission (cree automatiquement une session si necessaire)
    if not Auth.HasPermission(staffSource, 'report.respond') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)
    if not session then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    -- Verifier que le report existe
    local report = Database.SingleAsync([[
        SELECT * FROM panel_reports WHERE id = ? AND status IN ('pending', 'in_progress')
    ]], {reportId})

    if not report then
        return false, 'REPORT_NOT_FOUND'
    end

    -- Mettre a jour le report
    local newStatus = closeAfter and 'resolved' or 'in_progress'
    Database.ExecuteAsync([[
        UPDATE panel_reports
        SET response = ?, responded_by = ?, responded_by_name = ?, responded_at = NOW(),
            status = ?, resolved_at = IF(? = 'resolved', NOW(), resolved_at)
        WHERE id = ?
    ]], {response, session.identifier, session.name, newStatus, newStatus, reportId})

    -- Invalider le cache
    lastCacheUpdate = 0

    -- Log
    Database.AddLog(
        Enums.LogCategory.REPORT,
        'report_respond',
        session.identifier,
        session.name,
        report.player_identifier,
        report.player_name,
        {report_id = reportId, response = response}
    )

    -- Notifier le joueur avec le message en haut de l'ecran (comme le quick menu)
    if report.player_id then
        local xPlayer = ESX.GetPlayerFromId(report.player_id)
        if xPlayer then
            -- Afficher le message admin en haut de l'ecran
            TriggerClientEvent('panel:displayAdminMessage', report.player_id, response)
        end
    end

    return true
end

-- Marquer un report comme resolu
function Reports.Resolve(staffSource, reportId)
    -- Verifier la permission (cree automatiquement une session si necessaire)
    if not Auth.HasPermission(staffSource, 'report.claim') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local session = Auth.GetSession(staffSource)
    if not session then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    -- Verifier que le report existe
    local report = Database.SingleAsync([[
        SELECT * FROM panel_reports WHERE id = ? AND status IN ('pending', 'in_progress')
    ]], {reportId})

    if not report then
        return false, 'REPORT_NOT_FOUND'
    end

    -- Mettre a jour le report
    Database.ExecuteAsync([[
        UPDATE panel_reports
        SET status = 'resolved', resolved_at = NOW()
        WHERE id = ?
    ]], {reportId})

    -- Invalider le cache
    lastCacheUpdate = 0

    -- Log
    Database.AddLog(
        Enums.LogCategory.REPORT,
        'report_resolve',
        session.identifier,
        session.name,
        report.player_identifier,
        report.player_name,
        {report_id = reportId}
    )

    return true
end

-- Supprimer tous les reports (admin/owner uniquement)
function Reports.DeleteAll(staffSource)
    local session = Auth.GetSession(staffSource)
    if not session then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    -- Verifier la permission report.delete (admin/owner uniquement)
    if not Auth.HasPermission(staffSource, 'report.delete') then
        return false, 'NO_PERMISSION'
    end

    -- Compter les reports avant suppression
    local countResult = Database.SingleAsync([[
        SELECT COUNT(*) as total FROM panel_reports WHERE status != 'deleted'
    ]], {})
    local count = countResult and countResult.total or 0

    -- Soft delete de tous les reports
    Database.ExecuteAsync([[
        UPDATE panel_reports
        SET status = 'deleted', deleted_by = ?, deleted_at = NOW()
        WHERE status != 'deleted'
    ]], {session.identifier})

    -- Invalider le cache
    lastCacheUpdate = 0

    -- Log
    Database.AddLog(
        Enums.LogCategory.REPORT,
        'report_delete_all',
        session.identifier,
        session.name,
        nil, nil,
        {count = count}
    )

    return true, count
end

-- Supprimer un report (admin/owner uniquement)
function Reports.Delete(staffSource, reportId)
    local session = Auth.GetSession(staffSource)
    if not session then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    -- Vérifier la permission report.delete (admin/owner uniquement)
    if not Auth.HasPermission(staffSource, 'report.delete') then
        return false, 'NO_PERMISSION'
    end

    -- Verifier que le report existe
    local report = Database.SingleAsync([[
        SELECT * FROM panel_reports WHERE id = ?
    ]], {reportId})

    if not report then
        return false, 'REPORT_NOT_FOUND'
    end

    -- Soft delete
    Database.ExecuteAsync([[
        UPDATE panel_reports
        SET status = 'deleted', deleted_by = ?, deleted_at = NOW()
        WHERE id = ?
    ]], {session.identifier, reportId})

    -- Invalider le cache
    lastCacheUpdate = 0

    -- Log
    Database.AddLog(
        Enums.LogCategory.REPORT,
        'report_delete',
        session.identifier,
        session.name,
        report.player_identifier,
        report.player_name,
        {report_id = reportId}
    )

    return true
end

-- Notifier tous les staff d'un nouveau report
function Reports.NotifyStaff(reportData)
    for _, playerId in ipairs(Helpers.GetAllPlayers()) do
        if Auth.CanAccessPanel(playerId) then
            -- Envoyer la notification NUI
            TriggerClientEvent('panel:sendToNUI', playerId, {
                action = 'newReport',
                data = reportData
            })
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS
-- ══════════════════════════════════════════════════════════════

-- Callback pour obtenir les reports
ESX.RegisterServerCallback('panel:getReports', function(source, cb)
    local reports, err = Reports.GetAll(source)

    if err then
        cb({success = false, error = err})
        return
    end

    cb({success = true, reports = reports or {}})
end)

-- Callback pour les statistiques des reports
ESX.RegisterServerCallback('panel:getReportStats', function(source, cb, timeFilter)
    -- Verifier la permission
    if not Auth.HasPermission(source, 'report.stats') then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    -- Construire la condition de temps
    local timeCondition = ''
    if timeFilter == 'today' then
        timeCondition = 'AND DATE(resolved_at) = CURDATE()'
    elseif timeFilter == 'week' then
        timeCondition = 'AND resolved_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)'
    elseif timeFilter == 'month' then
        timeCondition = 'AND resolved_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)'
    end

    -- Recuperer les stats par staff
    local stats = Database.QueryAsync([[
        SELECT
            claimed_by as staff_identifier,
            claimed_by_name as staff_name,
            COUNT(*) as resolved_count,
            MAX(resolved_at) as last_resolved
        FROM panel_reports
        WHERE status = 'resolved'
        AND claimed_by IS NOT NULL
        ]] .. timeCondition .. [[
        GROUP BY claimed_by, claimed_by_name
        ORDER BY resolved_count DESC
    ]], {})

    -- Ajouter le groupe de chaque staff
    for _, stat in ipairs(stats or {}) do
        local staffInfo = Database.SingleAsync([[
            SELECT staff_group FROM panel_staff WHERE identifier = ?
        ]], {stat.staff_identifier})
        stat.staff_group = staffInfo and staffInfo.staff_group or 'Inconnu'
    end

    -- Calculer les totaux pour le resume
    local totalResult = Database.SingleAsync([[
        SELECT COUNT(*) as total FROM panel_reports WHERE status = 'resolved'
    ]], {})

    local weekResult = Database.SingleAsync([[
        SELECT COUNT(*) as total FROM panel_reports
        WHERE status = 'resolved' AND resolved_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ]], {})

    local todayResult = Database.SingleAsync([[
        SELECT COUNT(*) as total FROM panel_reports
        WHERE status = 'resolved' AND DATE(resolved_at) = CURDATE()
    ]], {})

    cb({
        success = true,
        stats = stats or {},
        summary = {
            total = totalResult and totalResult.total or 0,
            week = weekResult and weekResult.total or 0,
            today = todayResult and todayResult.total or 0
        }
    })
end)

-- Callback pour les actions sur les reports
ESX.RegisterServerCallback('panel:reportAction', function(source, cb, action, reportId, data)
    local result, err

    if action == 'claim' then
        result, err = Reports.Claim(source, reportId)
    elseif action == 'respond' then
        result, err = Reports.Respond(source, reportId, data.response, data.closeAfter)
    elseif action == 'resolve' then
        result, err = Reports.Resolve(source, reportId)
    elseif action == 'delete' then
        result, err = Reports.Delete(source, reportId)
    elseif action == 'deleteAll' then
        result, err = Reports.DeleteAll(source)
        if result then
            cb({success = true, count = err}) -- err contient le count dans ce cas
            return
        end
    else
        cb({success = false, error = 'INVALID_ACTION'})
        return
    end

    if result then
        cb({success = true})
    else
        cb({success = false, error = err or 'UNKNOWN_ERROR'})
    end
end)

-- ══════════════════════════════════════════════════════════════
-- COMMANDE /REPORT
-- ══════════════════════════════════════════════════════════════

RegisterCommand('report', function(source, args)
    if source == 0 then return end

    local message = table.concat(args, ' ')

    if not message or message == '' then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Report',
            message = 'Usage: /report [votre message]'
        })
        return
    end

    if #message < 10 then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Report',
            message = 'Votre message doit contenir au moins 10 caracteres'
        })
        return
    end

    if #message > 500 then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Report',
            message = 'Votre message ne doit pas depasser 500 caracteres'
        })
        return
    end

    local success, result = Reports.Create(source, message)

    if success then
        TriggerClientEvent('panel:notification', source, {
            type = 'success',
            title = 'Report envoye',
            message = 'Votre ticket #' .. result .. ' a ete envoye au staff'
        })
    else
        local errorMsg = 'Impossible d\'envoyer votre report'
        if result == 'COOLDOWN' then
            errorMsg = 'Veuillez attendre 1 minute entre chaque report'
        end
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = errorMsg
        })
    end
end, false)

-- Suggestion de la commande
TriggerEvent('chat:addSuggestion', '/report', 'Envoyer un ticket au staff', {
    {name = 'message', help = 'Description de votre probleme'}
})

-- ══════════════════════════════════════════════════════════════
-- AUTO-RESOLUTION DES TICKETS A LA DECONNEXION
-- ══════════════════════════════════════════════════════════════

-- Resoudre automatiquement les tickets d'un joueur qui se deconnecte
function Reports.AutoResolveOnDisconnect(playerSource, playerIdentifier)
    -- Verifier si le joueur a des tickets en attente ou en cours
    local openTickets = Database.QueryAsync([[
        SELECT id, status FROM panel_reports
        WHERE player_id = ? AND status IN ('pending', 'in_progress')
    ]], {playerSource})

    if not openTickets or #openTickets == 0 then
        return -- Pas de tickets ouverts
    end

    -- Marquer tous les tickets ouverts comme resolus
    local resolvedCount = 0
    for _, ticket in ipairs(openTickets) do
        Database.ExecuteAsync([[
            UPDATE panel_reports
            SET status = 'resolved', resolved_at = NOW(), response = 'Ticket auto-ferme: joueur deconnecte'
            WHERE id = ?
        ]], {ticket.id})
        resolvedCount = resolvedCount + 1
    end

    -- Invalider le cache
    lastCacheUpdate = 0

    if Config.Debug and resolvedCount > 0 then
        print('^3[REPORTS]^0 Auto-resolution de ' .. resolvedCount .. ' ticket(s) pour le joueur deconnecte (source: ' .. tostring(playerSource) .. ')')
    end

    -- Notifier tous les staff connectes du changement
    for _, playerId in ipairs(Helpers.GetAllPlayers()) do
        if Auth.CanAccessPanel(playerId) then
            TriggerClientEvent('panel:sendToNUI', playerId, {
                action = 'refreshReports'
            })
        end
    end
end

-- Event handler pour la deconnexion d'un joueur
AddEventHandler('playerDropped', function(reason)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = nil

    if xPlayer then
        identifier = xPlayer.getIdentifier()
    end

    -- Auto-resoudre les tickets du joueur qui se deconnecte
    Reports.AutoResolveOnDisconnect(source, identifier)
end)

-- Export global
_G.Reports = Reports

if Config.Debug then print('^2[PANEL ADMIN]^0 Module Reports charge') end
