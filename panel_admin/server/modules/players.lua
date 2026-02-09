--[[
    Module Players - Panel Admin Fight League
    Gestion des joueurs (liste, recherche, actions)
]]

local Players = {}

-- ══════════════════════════════════════════════════════════════
-- RÉCUPÉRATION DES JOUEURS
-- ══════════════════════════════════════════════════════════════

-- Obtenir la liste des joueurs connectés
function Players.GetOnlinePlayers()
    local players = {}
    local xPlayers = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(xPlayers) do
        local source = xPlayer.source
        local identifiers = Helpers.GetPlayerIdentifiers(source)
        local coords = Helpers.GetPlayerCoords(source)
        local fivemName = GetPlayerName(source) -- Nom FiveM/Steam du joueur

        table.insert(players, {
            id = source,
            name = xPlayer.getName(),
            fivemName = fivemName, -- Nom FiveM/Steam
            identifier = xPlayer.getIdentifier(),
            group = xPlayer.getGroup(),
            job = xPlayer.getJob().name,
            jobLabel = xPlayer.getJob().label,
            money = xPlayer.getMoney(),
            bank = xPlayer.getAccount('bank').money,
            coords = coords and {x = coords.x, y = coords.y, z = coords.z} or nil,
            ping = GetPlayerPing(source),
            steam = identifiers.steam,
            discord = identifiers.discord,
            license = identifiers.license
        })
    end

    return players
end

-- Obtenir les détails d'un joueur
function Players.GetPlayerDetails(targetSource)
    local xPlayer = ESX.GetPlayerFromId(targetSource)
    if not xPlayer then return nil end

    local identifier = xPlayer.getIdentifier()
    local identifiers = Helpers.GetPlayerIdentifiers(targetSource)
    local coords = Helpers.GetPlayerCoords(targetSource)

    -- Récupérer les données supplémentaires de la BDD
    local dbData = Database.SingleAsync([[
        SELECT
            u.firstname, u.lastname, u.dateofbirth, u.sex, u.height,
            (SELECT COUNT(*) FROM panel_sanctions WHERE target_identifier COLLATE utf8mb4_general_ci = u.identifier COLLATE utf8mb4_general_ci) as total_sanctions,
            (SELECT COUNT(*) FROM panel_sanctions WHERE target_identifier COLLATE utf8mb4_general_ci = u.identifier COLLATE utf8mb4_general_ci AND type = 'warn') as warns,
            (SELECT COUNT(*) FROM panel_player_connections WHERE identifier COLLATE utf8mb4_general_ci = u.identifier COLLATE utf8mb4_general_ci) as total_connections
        FROM users u
        WHERE u.identifier = ?
    ]], {identifier})

    -- Récupérer les dernières sanctions
    local sanctions = Database.QueryAsync([[
        SELECT type, reason, staff_name, created_at, status
        FROM panel_sanctions
        WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        ORDER BY created_at DESC
        LIMIT 5
    ]], {identifier})

    -- Récupérer les notes
    local notes = Database.QueryAsync([[
        SELECT content, category, staff_name, created_at
        FROM panel_player_notes
        WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        ORDER BY created_at DESC
        LIMIT 10
    ]], {identifier})

    return {
        id = targetSource,
        name = xPlayer.getName(),
        fivemName = GetPlayerName(targetSource), -- Nom FiveM/Steam
        identifier = identifier,
        group = xPlayer.getGroup(),
        job = {
            name = xPlayer.getJob().name,
            label = xPlayer.getJob().label,
            grade = xPlayer.getJob().grade,
            gradeLabel = xPlayer.getJob().grade_label
        },
        money = {
            cash = xPlayer.getMoney(),
            bank = xPlayer.getAccount('bank').money,
            black = xPlayer.getAccount('black_money').money
        },
        coords = coords and {x = coords.x, y = coords.y, z = coords.z} or nil,
        ping = GetPlayerPing(targetSource),
        identifiers = identifiers,
        character = dbData and {
            firstname = dbData.firstname,
            lastname = dbData.lastname,
            dateofbirth = dbData.dateofbirth,
            sex = dbData.sex,
            height = dbData.height
        } or nil,
        stats = {
            totalSanctions = dbData and dbData.total_sanctions or 0,
            warns = dbData and dbData.warns or 0,
            totalConnections = dbData and dbData.total_connections or 0,
            totalPlaytime = 0
        },
        recentSanctions = sanctions or {},
        notes = notes or {}
    }
end

-- Rechercher des joueurs (connectés + offline)
function Players.SearchPlayers(query, includeOffline)
    local results = {}
    query = query:lower()

    -- Recherche dans les joueurs connectés
    for _, player in ipairs(Players.GetOnlinePlayers()) do
        if string.find(player.name:lower(), query) or
           string.find(player.identifier:lower(), query) or
           (player.steam and string.find(player.steam:lower(), query)) or
           (player.discord and string.find(player.discord:lower(), query)) then
            player.online = true
            table.insert(results, player)
        end
    end

    -- Recherche offline si demandé
    if includeOffline then
        local offlinePlayers = Database.QueryAsync([[
            SELECT identifier, firstname, lastname, accounts, `group`,
                   (SELECT steam_id FROM panel_bans WHERE identifier COLLATE utf8mb4_general_ci = u.identifier COLLATE utf8mb4_general_ci LIMIT 1) as steam_id,
                   (SELECT discord_id FROM panel_bans WHERE identifier COLLATE utf8mb4_general_ci = u.identifier COLLATE utf8mb4_general_ci LIMIT 1) as discord_id
            FROM users u
            WHERE identifier LIKE ?
               OR CONCAT(firstname, ' ', lastname) LIKE ?
            LIMIT 20
        ]], {'%' .. query .. '%', '%' .. query .. '%'})

        for _, player in ipairs(offlinePlayers or {}) do
            -- Vérifier s'il n'est pas déjà dans les résultats (connecté)
            local alreadyAdded = false
            for _, online in ipairs(results) do
                if online.identifier == player.identifier then
                    alreadyAdded = true
                    break
                end
            end

            if not alreadyAdded then
                local accounts = json.decode(player.accounts) or {}
                table.insert(results, {
                    id = nil,
                    name = (player.firstname or '') .. ' ' .. (player.lastname or ''),
                    identifier = player.identifier,
                    group = player.group,
                    money = accounts.money or 0,
                    bank = accounts.bank or 0,
                    steam = player.steam_id,
                    discord = player.discord_id,
                    online = false
                })
            end
        end
    end

    return results
end

-- ══════════════════════════════════════════════════════════════
-- ACTIONS SUR LES JOUEURS
-- ══════════════════════════════════════════════════════════════

-- Revive un joueur
function Players.Revive(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'player.revive') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    TriggerClientEvent('esx_ambulancejob:revive', targetSource)
    TriggerClientEvent('esx:showNotification', targetSource, 'Vous avez été réanimé par un admin')

    -- Log
    local session = Auth.GetSession(staffSource)
    local targetName = GetPlayerName(targetSource)
    Database.AddLog(
        Enums.LogCategory.PLAYER,
        Enums.LogAction.PLAYER_REVIVE,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        targetName, -- Nom FiveM
        nil
    )

    -- Discord webhook
    if Discord and Discord.LogPlayer then
        Discord.LogPlayer('player_revive', session.name, targetName, nil)
    end

    return true
end

-- Heal un joueur
function Players.Heal(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'player.heal') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    TriggerClientEvent('panel:heal', targetSource)
    TriggerClientEvent('esx:showNotification', targetSource, 'Vous avez été soigné par un admin')

    -- Log
    local session = Auth.GetSession(staffSource)
    local targetName = GetPlayerName(targetSource)
    Database.AddLog(
        Enums.LogCategory.PLAYER,
        Enums.LogAction.PLAYER_HEAL,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        targetName, -- Nom FiveM
        nil
    )

    -- Discord webhook
    if Discord and Discord.LogPlayer then
        Discord.LogPlayer('player_heal', session.name, targetName, nil)
    end

    return true
end

-- Freeze/Unfreeze un joueur
function Players.ToggleFreeze(staffSource, targetSource, freeze)
    if not Auth.HasPermission(staffSource, 'player.freeze') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    if not Auth.CanActOn(staffSource, targetSource) then
        return false, Enums.ErrorCode.TARGET_HIGHER_GRADE
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    TriggerClientEvent('panel:freeze', targetSource, freeze)

    local action = freeze and Enums.LogAction.PLAYER_FREEZE or Enums.LogAction.PLAYER_UNFREEZE
    local session = Auth.GetSession(staffSource)
    local targetName = GetPlayerName(targetSource)
    Database.AddLog(
        Enums.LogCategory.PLAYER,
        action,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        targetName, -- Nom FiveM
        nil
    )

    -- Discord webhook
    if Discord and Discord.LogPlayer then
        local discordAction = freeze and 'player_freeze' or 'player_unfreeze'
        Discord.LogPlayer(discordAction, session.name, targetName, nil)
    end

    return true
end

-- Changer le groupe d'un joueur
function Players.SetGroup(staffSource, targetSource, newGroup)
    if not Auth.HasPermission(staffSource, 'player.setgroup') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, group = Validators.Grade(newGroup)
    if not valid then
        return false, Enums.ErrorCode.INVALID_GRADE
    end

    if not Auth.CanActOn(staffSource, targetSource) then
        return false, Enums.ErrorCode.TARGET_HIGHER_GRADE
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    local oldGroup = xTarget.getGroup()
    local targetIdentifier = xTarget.getIdentifier()

    -- Mettre à jour ESX en mémoire
    xTarget.setGroup(group)

    -- Mettre à jour la base de données pour la persistance
    Database.ExecuteAsync([[
        UPDATE users SET `group` = ? WHERE identifier = ?
    ]], {group, targetIdentifier})

    -- Log
    local session = Auth.GetSession(staffSource)
    Database.AddLog(
        Enums.LogCategory.PLAYER,
        Enums.LogAction.PLAYER_SETGROUP,
        session.identifier,
        session.name,
        targetIdentifier,
        GetPlayerName(targetSource), -- Nom FiveM
        {oldGroup = oldGroup, newGroup = group}
    )

    -- Discord webhook
    if Discord and Discord.LogStaffRole then
        Discord.LogStaffRole(
            'change',
            session.name,
            GetPlayerName(targetSource),
            targetIdentifier,
            oldGroup,
            group
        )
    end

    return true
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS
-- ══════════════════════════════════════════════════════════════

-- Callback: Obtenir la liste des joueurs
ESX.RegisterServerCallback('panel:getPlayers', function(source, cb)
    if not Auth.HasPermission(source, 'player.view') then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    cb({success = true, players = Players.GetOnlinePlayers()})
end)

-- Callback: Obtenir les détails d'un joueur
ESX.RegisterServerCallback('panel:getPlayerDetails', function(source, cb, targetId)
    if not Auth.HasPermission(source, 'player.view.details') then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    local details = Players.GetPlayerDetails(targetId)
    if not details then
        cb({success = false, error = Enums.ErrorCode.PLAYER_NOT_FOUND})
        return
    end

    cb({success = true, player = details})
end)

-- Callback: Rechercher des joueurs
ESX.RegisterServerCallback('panel:searchPlayers', function(source, cb, query, includeOffline)
    if not Auth.HasPermission(source, 'player.view') then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    local results = Players.SearchPlayers(query, includeOffline)
    cb({success = true, players = results})
end)

-- Export global
_G.Players = Players
