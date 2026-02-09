--[[
    Module Logs - Panel Admin Fight League
    Système de logging et audit trail
]]

local Logs = {}

-- ══════════════════════════════════════════════════════════════
-- AJOUT DE LOGS
-- ══════════════════════════════════════════════════════════════

-- Ajouter un log (raccourci)
function Logs.Add(category, action, staffId, staffName, targetId, targetName, details, staffServerId, targetServerId)
    if not Config.Logs.Enabled then return end

    Database.AddLog(category, action, staffId, staffName, targetId, targetName, details, staffServerId, targetServerId)
end

-- Log avec source (récupère auto les infos)
function Logs.AddFromSource(source, category, action, targetId, targetName, details, targetServerId)
    if not Config.Logs.Enabled then return end

    local session = Auth.GetSession(source)
    if not session then return end

    Database.AddLog(category, action, session.identifier, session.name, targetId, targetName, details, source, targetServerId)
end

-- ══════════════════════════════════════════════════════════════
-- RÉCUPÉRATION
-- ══════════════════════════════════════════════════════════════

-- Obtenir les logs avec filtres
function Logs.Get(staffSource, filters, page, perPage)
    -- Vérifier les permissions
    local canViewAll = Auth.HasPermission(staffSource, 'logs.view.all')
    local canViewOwn = Auth.HasPermission(staffSource, 'logs.view.own')

    if not canViewAll and not canViewOwn then
        return nil, Enums.ErrorCode.NO_PERMISSION
    end

    page = page or 1
    perPage = perPage or 50
    local offset = (page - 1) * perPage

    local where = {'1=1'}
    local params = {}

    -- Si ne peut voir que ses propres logs
    if not canViewAll then
        local session = Auth.GetSession(staffSource)
        table.insert(where, 'staff_identifier = ?')
        table.insert(params, session.identifier)
    end

    -- Appliquer les filtres
    if filters then
        if filters.category then
            table.insert(where, 'category = ?')
            table.insert(params, filters.category)
        end
        if filters.action then
            table.insert(where, 'action = ?')
            table.insert(params, filters.action)
        end
        if filters.staffIdentifier and canViewAll then
            table.insert(where, 'staff_identifier = ?')
            table.insert(params, filters.staffIdentifier)
        end
        if filters.targetIdentifier then
            table.insert(where, 'target_identifier = ?')
            table.insert(params, filters.targetIdentifier)
        end
        if filters.dateFrom then
            table.insert(where, 'created_at >= ?')
            table.insert(params, filters.dateFrom)
        end
        if filters.dateTo then
            table.insert(where, 'created_at <= ?')
            table.insert(params, filters.dateTo)
        end
        if filters.search then
            -- Verifier si c'est une recherche par ID (nombre seul)
            local searchNum = tonumber(filters.search)
            if searchNum then
                table.insert(where, '(staff_server_id = ? OR target_server_id = ? OR staff_name LIKE ? OR target_name LIKE ?)')
                table.insert(params, searchNum)
                table.insert(params, searchNum)
                local searchPattern = '%' .. filters.search .. '%'
                table.insert(params, searchPattern)
                table.insert(params, searchPattern)
            else
                table.insert(where, '(staff_name LIKE ? OR target_name LIKE ? OR details LIKE ?)')
                local searchPattern = '%' .. filters.search .. '%'
                table.insert(params, searchPattern)
                table.insert(params, searchPattern)
                table.insert(params, searchPattern)
            end
        end
    end

    table.insert(params, perPage)
    table.insert(params, offset)

    local query = string.format([[
        SELECT * FROM panel_logs
        WHERE %s
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    ]], table.concat(where, ' AND '))

    return Database.QueryAsync(query, params)
end

-- Obtenir le nombre total de logs (pour pagination)
function Logs.GetCount(staffSource, filters)
    local canViewAll = Auth.HasPermission(staffSource, 'logs.view.all')

    local where = {'1=1'}
    local params = {}

    if not canViewAll then
        local session = Auth.GetSession(staffSource)
        table.insert(where, 'staff_identifier = ?')
        table.insert(params, session.identifier)
    end

    if filters then
        if filters.category then
            table.insert(where, 'category = ?')
            table.insert(params, filters.category)
        end
    end

    local query = string.format([[
        SELECT COUNT(*) as count FROM panel_logs WHERE %s
    ]], table.concat(where, ' AND '))

    local result = Database.SingleAsync(query, params)
    return result and result.count or 0
end

-- Obtenir les logs récents (pour dashboard)
function Logs.GetRecent(staffSource, limit)
    limit = limit or 10

    local session = Auth.GetSession(staffSource)
    if not session then return {} end

    local canViewAll = Auth.HasPermission(staffSource, 'logs.view.all')

    local query
    local params

    if canViewAll then
        query = [[
            SELECT * FROM panel_logs
            ORDER BY created_at DESC
            LIMIT ?
        ]]
        params = {limit}
    else
        query = [[
            SELECT * FROM panel_logs
            WHERE staff_identifier = ?
            ORDER BY created_at DESC
            LIMIT ?
        ]]
        params = {session.identifier, limit}
    end

    return Database.QueryAsync(query, params)
end

-- ══════════════════════════════════════════════════════════════
-- STATISTIQUES
-- ══════════════════════════════════════════════════════════════

-- Obtenir les stats par catégorie
function Logs.GetStatsByCategory(days)
    days = days or 7
    return Database.QueryAsync([[
        SELECT category, COUNT(*) as count
        FROM panel_logs
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY category
        ORDER BY count DESC
    ]], {days})
end

-- Obtenir les stats par staff
function Logs.GetStatsByStaff(days)
    days = days or 7
    return Database.QueryAsync([[
        SELECT staff_identifier, staff_name, COUNT(*) as count
        FROM panel_logs
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY staff_identifier, staff_name
        ORDER BY count DESC
        LIMIT 20
    ]], {days})
end

-- ══════════════════════════════════════════════════════════════
-- NETTOYAGE
-- ══════════════════════════════════════════════════════════════

-- Supprimer les vieux logs
function Logs.Cleanup()
    local retentionDays = Config.Logs.RetentionDays or 30

    Database.ExecuteAsync([[
        DELETE FROM panel_logs
        WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {retentionDays})

    Helpers.Debug('Logs cleanup: deleted logs older than ' .. retentionDays .. ' days')
end

-- Thread de nettoyage automatique
CreateThread(function()
    while true do
        Wait(86400000) -- Toutes les 24h
        Logs.Cleanup()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- EXPORT
-- ══════════════════════════════════════════════════════════════

exports('addLog', function(category, action, staffId, staffName, targetId, targetName, details)
    Logs.Add(category, action, staffId, staffName, targetId, targetName, details)
end)

-- Export global
_G.Logs = Logs
