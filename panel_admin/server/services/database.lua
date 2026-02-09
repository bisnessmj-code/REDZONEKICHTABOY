--[[
    Service Database - Panel Admin Fight League
    Wrapper MySQL via oxmysql exports
]]

local Database = {}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS DE BASE (via exports oxmysql) avec gestion d'erreurs
-- ══════════════════════════════════════════════════════════════

function Database.Query(query, params, cb)
    local success, err = pcall(function()
        exports.oxmysql:execute(query, params or {}, function(results)
            if cb then cb(results or {}) end
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 Query failed: ' .. tostring(err))
        if cb then cb({}) end
    end
end

function Database.Execute(query, params, cb)
    local success, err = pcall(function()
        exports.oxmysql:execute(query, params or {}, function(affectedRows)
            if cb then cb(affectedRows or 0) end
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 Execute failed: ' .. tostring(err))
        if cb then cb(0) end
    end
end

function Database.Insert(query, params, cb)
    local success, err = pcall(function()
        exports.oxmysql:insert(query, params or {}, function(insertId)
            if cb then cb(insertId or 0) end
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 Insert failed: ' .. tostring(err))
        if cb then cb(0) end
    end
end

function Database.Scalar(query, params, cb)
    local success, err = pcall(function()
        exports.oxmysql:scalar(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 Scalar failed: ' .. tostring(err))
        if cb then cb(nil) end
    end
end

function Database.Single(query, params, cb)
    local success, err = pcall(function()
        exports.oxmysql:single(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 Single failed: ' .. tostring(err))
        if cb then cb(nil) end
    end
end

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS SYNC (avec Citizen.Await) avec gestion d'erreurs
-- ══════════════════════════════════════════════════════════════

function Database.QueryAsync(query, params)
    local p = promise.new()
    local success, err = pcall(function()
        exports.oxmysql:execute(query, params or {}, function(results)
            p:resolve(results or {})
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 QueryAsync failed: ' .. tostring(err))
        p:resolve({})
    end
    return Citizen.Await(p)
end

function Database.ExecuteAsync(query, params)
    local p = promise.new()
    local success, err = pcall(function()
        exports.oxmysql:execute(query, params or {}, function(affectedRows)
            p:resolve(affectedRows or 0)
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 ExecuteAsync failed: ' .. tostring(err))
        p:resolve(0)
    end
    return Citizen.Await(p)
end

function Database.InsertAsync(query, params)
    local p = promise.new()
    local success, err = pcall(function()
        exports.oxmysql:insert(query, params or {}, function(insertId)
            p:resolve(insertId or 0)
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 InsertAsync failed: ' .. tostring(err))
        p:resolve(0)
    end
    return Citizen.Await(p)
end

function Database.SingleAsync(query, params)
    local p = promise.new()
    local success, err = pcall(function()
        exports.oxmysql:single(query, params or {}, function(result)
            p:resolve(result)
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 SingleAsync failed: ' .. tostring(err))
        p:resolve(nil)
    end
    return Citizen.Await(p)
end

function Database.ScalarAsync(query, params)
    local p = promise.new()
    local success, err = pcall(function()
        exports.oxmysql:scalar(query, params or {}, function(result)
            p:resolve(result)
        end)
    end)
    if not success then
        print('^1[DATABASE ERROR]^0 ScalarAsync failed: ' .. tostring(err))
        p:resolve(nil)
    end
    return Citizen.Await(p)
end

-- ══════════════════════════════════════════════════════════════
-- GENERATION ID DE DEBAN
-- ══════════════════════════════════════════════════════════════

-- Generer un ID de deban unique a 5 chiffres
function Database.GenerateUnbanId()
    local maxAttempts = 100
    local attempts = 0

    while attempts < maxAttempts do
        -- Generer un nombre aleatoire a 5 chiffres (00000 a 99999)
        local unbanId = string.format('%05d', math.random(0, 99999))

        -- Verifier si cet ID existe deja dans panel_bans
        local existing = Database.SingleAsync([[
            SELECT unban_id FROM panel_bans WHERE unban_id = ? LIMIT 1
        ]], {unbanId})

        if not existing then
            return unbanId
        end

        attempts = attempts + 1
    end

    -- Fallback: utiliser timestamp + random si on ne trouve pas d'ID unique
    return string.format('%05d', (os.time() % 100000))
end

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PANEL
-- ══════════════════════════════════════════════════════════════

function Database.GetPlayer(identifier, cb)
    local query = [[
        SELECT u.*, ps.preferences, ps.last_panel_access
        FROM users u
        LEFT JOIN panel_staff ps ON ps.identifier COLLATE utf8mb4_general_ci = u.identifier COLLATE utf8mb4_general_ci
        WHERE u.identifier = ?
        LIMIT 1
    ]]
    Database.Single(query, {identifier}, cb)
end

function Database.GetPlayerSanctions(identifier, limit, cb)
    local query = [[
        SELECT * FROM panel_sanctions
        WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        ORDER BY created_at DESC
        LIMIT ?
    ]]
    Database.Query(query, {identifier, limit or 50}, cb)
end

function Database.IsPlayerBanned(identifier, cb)
    -- Extraire le hash de l'identifier (sans le prefixe comme license:, char0:, steam:, etc.)
    local hash = identifier
    if identifier then
        hash = identifier:match(':(.+)') or identifier
    end

    -- Creer des variations de l'identifier pour la recherche
    local variations = {
        identifier,                    -- Original
        hash,                          -- Hash seul
        'license:' .. hash,            -- Format FiveM license
        'char0:' .. hash,              -- Format ESX char0
        'char1:' .. hash,              -- Format ESX char1
        'steam:' .. hash,              -- Format Steam
        'discord:' .. hash             -- Format Discord
    }

    local query = [[
        SELECT * FROM panel_bans
        WHERE (
            identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
            OR license COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR license COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR license COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
            OR steam_id COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR steam_id COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
            OR discord_id COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci OR discord_id COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        )
        AND (expires_at IS NULL OR expires_at > NOW())
        LIMIT 1
    ]]

    Database.Single(query, {
        variations[1], variations[2], variations[3], variations[4], variations[5], variations[6], variations[7],
        variations[1], variations[2], variations[3],
        variations[1], variations[2],
        variations[1], variations[2]
    }, function(result)
        cb(result ~= nil, result)
    end)
end

function Database.AddLog(category, action, staffId, staffName, targetId, targetName, details, staffServerId, targetServerId)
    local query = [[
        INSERT INTO panel_logs (category, action, staff_identifier, staff_name, target_identifier, target_name, details, staff_server_id, target_server_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    Database.Execute(query, {
        category, action, staffId, staffName, targetId, targetName,
        type(details) == 'table' and json.encode(details) or details,
        staffServerId or 0,
        targetServerId or 0
    })
end

function Database.AddSanction(data, cb)
    local query = [[
        INSERT INTO panel_sanctions
        (type, target_identifier, target_name, staff_identifier, staff_name, reason, duration_hours, expires_at, status, unban_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)
    ]]

    local expiresAt = nil
    if data.duration and data.duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (data.duration * 3600))
    end

    Database.Insert(query, {
        data.type,
        data.targetIdentifier,
        data.targetName,
        data.staffIdentifier,
        data.staffName,
        data.reason,
        data.duration,
        expiresAt,
        data.unbanId
    }, cb)
end

function Database.AddBan(data, cb)
    local query = [[
        INSERT INTO panel_bans
        (identifier, player_name, steam_id, discord_id, license, ip, reason, banned_by, banned_by_name, expires_at, unban_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]

    local expiresAt = nil
    if data.duration and data.duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (data.duration * 3600))
    end

    Database.Insert(query, {
        data.identifier,
        data.playerName,
        data.steamId,
        data.discordId,
        data.license,
        data.ip,
        data.reason,
        data.staffIdentifier,
        data.staffName,
        expiresAt,
        data.unbanId
    }, cb)
end

function Database.RemoveBan(identifier, cb)
    local query = [[DELETE FROM panel_bans WHERE identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci]]
    Database.Execute(query, {identifier}, cb)
end

function Database.GetDailyStats(cb)
    local today = os.date('%Y-%m-%d')
    local query = [[SELECT * FROM panel_statistics_daily WHERE date = ?]]
    Database.Single(query, {today}, cb)
end

function Database.UpdateDailyStat(field, increment)
    local today = os.date('%Y-%m-%d')

    -- CORRECTION SÉCURITÉ: Valider le nom de champ pour éviter SQL injection
    local validFields = {
        'unique_players', 'peak_players', 'new_players', 'total_playtime_minutes',
        'warns_count', 'kicks_count', 'bans_count', 'money_added', 'money_removed',
        'vehicles_spawned', 'teleports_count', 'events_held', 'announcements_sent'
    }

    local isValid = false
    for _, validField in ipairs(validFields) do
        if field == validField then
            isValid = true
            break
        end
    end

    if not isValid then
        print('^1[DATABASE ERROR]^0 Nom de champ invalide pour UpdateDailyStat: ' .. tostring(field))
        return
    end

    Database.Execute([[INSERT IGNORE INTO panel_statistics_daily (date) VALUES (?)]], {today}, function()
        -- Utilisation sécurisée de string.format avec un champ validé
        local updateQuery = string.format([[
            UPDATE panel_statistics_daily SET %s = %s + ? WHERE date = ?
        ]], field, field)
        Database.Execute(updateQuery, {increment, today})
    end)
end

-- Export global
_G.Database = Database

if Config.Debug then print('^2[PANEL ADMIN]^0 Database service charge avec oxmysql exports') end
