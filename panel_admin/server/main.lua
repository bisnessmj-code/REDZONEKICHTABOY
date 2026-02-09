--[[
    Main Serveur - Panel Admin Fight League
    Point d'entrée et enregistrement des events/callbacks
]]

ESX = exports['es_extended']:getSharedObject()

-- ══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    if Config.Debug then
        print('^2[PANEL ADMIN]^0 Démarrage du Panel Administration Fight League v' .. Config.PanelVersion)
        print('^2[PANEL ADMIN]^0 Serveur: ' .. Config.ServerName)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- EVENTS NUI -> SERVEUR
-- ══════════════════════════════════════════════════════════════

-- Ouvrir le panel
RegisterNetEvent('panel:open', function()
    local source = source
    if not Auth.CanAccessPanel(source) then return end

    local session = Auth.InitSession(source)
    if session then
        TriggerClientEvent('panel:openNUI', source, session)
    end
end)

-- Fermer le panel
RegisterNetEvent('panel:close', function()
    local source = source
    Auth.EndSession(source)
end)

-- Ouvrir le panel directement sur l'onglet Reports
RegisterNetEvent('panel:openReports', function()
    local source = source
    if not Auth.CanAccessPanel(source) then return end

    local session = Auth.InitSession(source)
    if session then
        TriggerClientEvent('panel:openNUIReports', source, session)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS GÉNÉRAUX
-- ══════════════════════════════════════════════════════════════

-- Obtenir les données initiales du panel
ESX.RegisterServerCallback('panel:init', function(source, cb)
    if not Auth.CanAccessPanel(source) then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    local session = Auth.InitSession(source)
    if not session then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    -- Récupérer les données dashboard
    local dashboardData = {
        playersOnline = #Helpers.GetAllPlayers(),
        staffOnline = 0,
        activeEvents = 0,
        sanctionsToday = 0
    }

    -- Compter le staff en ligne
    for _, playerId in ipairs(Helpers.GetAllPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and Permissions.Grades[xPlayer.getGroup()] then
            dashboardData.staffOnline = dashboardData.staffOnline + 1
        end
    end

    -- Stats du jour
    Database.GetDailyStats(function(stats)
        if stats then
            dashboardData.sanctionsToday = (stats.warns_count or 0) + (stats.kicks_count or 0) + (stats.bans_count or 0)
            dashboardData.activeEvents = stats.events_held or 0
        end

        cb({
            success = true,
            session = {
                identifier = session.identifier,
                name = session.name,
                group = session.group,
                level = session.level,
                abilities = session.abilities
            },
            dashboard = dashboardData,
            config = {
                ui = Config.UI,
                sanctions = Config.Sanctions,
                teleport = Config.Teleport,
                vehicles = Config.Vehicles
            }
        })
    end)
end)

-- Obtenir les logs récents
ESX.RegisterServerCallback('panel:getRecentLogs', function(source, cb, limit)
    local logs = Logs.GetRecent(source, limit or 10)
    cb({success = true, logs = logs})
end)

-- Obtenir les activités récentes pour le dashboard
ESX.RegisterServerCallback('panel:getRecentActivity', function(source, cb, limit)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    limit = limit or 20

    -- Récupérer les logs récents
    local logs = Database.QueryAsync([[
        SELECT
            l.category,
            l.action,
            l.staff_identifier,
            l.staff_name,
            l.target_identifier,
            l.target_name,
            l.details,
            l.created_at
        FROM panel_logs l
        WHERE l.category IN ('sanction', 'teleport', 'vehicle', 'auth', 'economy', 'event', 'player')
        ORDER BY l.created_at DESC
        LIMIT ?
    ]], {limit})

    if not logs then
        cb({success = false, error = 'DATABASE_ERROR'})
        return
    end

    -- Formater les activités
    local activities = {}
    for _, log in ipairs(logs) do
        -- Parser les details JSON
        local details = {}
        if log.details and log.details ~= '' then
            local success, parsed = pcall(json.decode, log.details)
            if success then
                details = parsed
            end
        end

        -- Mapper category/action vers type/action pour le frontend
        local activityType = log.category
        local activityAction = log.action

        -- Récupérer le groupe du staff depuis les sessions actives ou depuis l'identifier
        local staffGroup = nil
        for _, playerId in ipairs(Helpers.GetAllPlayers()) do
            local sess = Auth.GetSession(playerId)
            if sess and sess.identifier == log.staff_identifier then
                staffGroup = sess.group
                break
            end
        end

        table.insert(activities, {
            type = activityType,
            action = activityAction,
            staff_identifier = log.staff_identifier,
            staff_name = log.staff_name,
            staff_group = staffGroup,
            target_identifier = log.target_identifier,
            target_name = log.target_name,
            details = details,
            created_at = log.created_at
        })
    end

    cb({success = true, activities = activities})
end)

-- Obtenir les logs avec filtres
ESX.RegisterServerCallback('panel:getLogs', function(source, cb, filters, page, perPage)
    local logs, err = Logs.Get(source, filters, page, perPage)
    if err then
        cb({success = false, error = err})
        return
    end
    cb({success = true, logs = logs})
end)

-- Obtenir les comptes des joueurs en ligne (Owner/Admin uniquement)
ESX.RegisterServerCallback('panel:getAccounts', function(source, cb)
    local accounts, err = Economy.GetAllPlayersAccounts(source)

    if err then
        cb({success = false, error = err})
        return
    end

    cb({success = true, accounts = accounts or {}})
end)

-- Obtenir l'historique des sanctions avec filtres
ESX.RegisterServerCallback('panel:getSanctions', function(source, cb, filters, page, perPage)
    if not Auth.HasPermission(source, 'sanction.view') and not Auth.HasPermission(source, 'logs.view.all') then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    local sanctions = Sanctions.GetHistory(filters, page, perPage)

    if not sanctions then
        cb({success = false, error = 'DATABASE_ERROR'})
        return
    end

    -- Compter le total pour la pagination
    local totalCount = Sanctions.GetCount(filters)

    cb({
        success = true,
        sanctions = sanctions,
        total = totalCount,
        page = page or 1,
        perPage = perPage or 20
    })
end)

-- Obtenir la liste des bans
ESX.RegisterServerCallback('panel:getBans', function(source, cb)
    if Config.Debug then print('^5[BANS DEBUG]^0 ===== CALLBACK APPELE PAR SOURCE: ' .. tostring(source) .. ' =====') end
    -- D'abord recuperer/creer la session
    local session = Auth.GetSession(source)
    if not session then
        session = Auth.InitSession(source)
    end

    if not session then
        if Config.Debug then print('^1[BANS]^0 Impossible de creer une session pour ' .. tostring(source)) end
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    if Config.Debug then print('^3[BANS]^0 Verification permissions pour ' .. session.name .. ' (' .. session.group .. ')') end

    -- Verifier les permissions
    local hasUnbanPerm = session.abilities['*'] or session.abilities['sanction.unban']
    local hasViewPerm = session.abilities['*'] or session.abilities['sanction.view']

    if Config.Debug then print('^3[BANS]^0 sanction.unban: ' .. tostring(hasUnbanPerm) .. ', sanction.view: ' .. tostring(hasViewPerm)) end

    if not hasUnbanPerm and not hasViewPerm then
        if Config.Debug then print('^1[BANS]^0 Permission refusee pour ' .. session.name) end
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    if Config.Debug then print('^2[BANS]^0 Permission accordee pour ' .. session.name) end
    local staffIdentifier = session and session.identifier or nil
    local staffGroup = session and session.group or nil

    -- Recuperer tous les bans actifs
    local bans = Database.QueryAsync([[
        SELECT * FROM panel_bans
        WHERE (expires_at IS NULL OR expires_at > NOW())
        ORDER BY created_at DESC
    ]], {})

    -- Ajouter le flag can_unban pour chaque ban
    for _, ban in ipairs(bans) do
        -- Owner et admin peuvent debannir tout le monde
        if staffGroup == 'owner' or staffGroup == 'admin' then
            ban.can_unban = true
        -- Les autres peuvent seulement debannir les joueurs qu'ils ont bannis
        elseif ban.banned_by == staffIdentifier then
            ban.can_unban = true
        else
            ban.can_unban = false
        end
    end

    cb({success = true, bans = bans})
end)

-- Debannir un joueur
ESX.RegisterServerCallback('panel:unbanPlayer', function(source, cb, identifier)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    local staffIdentifier = session.identifier
    local staffGroup = session.group
    local hasGlobalUnban = Auth.HasPermission(source, 'sanction.unban')

    -- Verifier si le ban existe
    local ban = Database.SingleAsync([[
        SELECT * FROM panel_bans WHERE identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci AND (expires_at IS NULL OR expires_at > NOW())
    ]], {identifier})

    if not ban then
        cb({success = false, error = 'NOT_BANNED'})
        return
    end

    -- Verifier si le staff peut debannir ce joueur
    -- Admin/Owner peuvent debannir tout le monde (permission sanction.unban)
    -- Les autres peuvent debannir seulement leurs propres bans
    local canUnban = false
    if hasGlobalUnban then
        canUnban = true
    elseif ban.banned_by == staffIdentifier then
        canUnban = true
    end

    if not canUnban then
        cb({success = false, error = 'NO_PERMISSION'})
        return
    end

    -- Supprimer le ban
    Database.Execute([[DELETE FROM panel_bans WHERE identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci]], {identifier})

    -- Mettre a jour le statut dans panel_sanctions
    Database.Execute([[
        UPDATE panel_sanctions
        SET status = 'revoked', revoked_by = ?, revoked_at = NOW()
        WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        AND type IN ('ban_temp', 'ban_perm')
        AND status = 'active'
    ]], {staffIdentifier, identifier})

    -- Log
    Database.AddLog(
        Enums.LogCategory.SANCTION,
        Enums.LogAction.BAN_REMOVE,
        session.identifier,
        session.name,
        identifier,
        ban.player_name or 'Inconnu',
        {reason = 'Debannissement manuel'}
    )

    if Config.Debug then print('^2[PANEL ADMIN]^0 ' .. session.name .. ' a debanni ' .. (ban.player_name or identifier)) end

    cb({success = true})
end)

-- Ban par identifier (joueur hors-ligne)
ESX.RegisterServerCallback('panel:banByIdentifier', function(source, cb, identifier, reason, duration)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    -- Verifier la permission de ban
    local isPermanent = duration == -1
    local requiredPerm = isPermanent and 'sanction.ban.perm' or 'sanction.ban.temp'

    if not Auth.HasPermission(source, requiredPerm) then
        cb({success = false, error = 'NO_PERMISSION'})
        return
    end

    -- Valider l'identifier
    if not identifier or identifier == '' then
        cb({success = false, error = 'Identifier invalide'})
        return
    end

    -- Valider la raison
    if not reason or reason == '' then
        cb({success = false, error = 'Raison invalide'})
        return
    end

    -- Extraire le hash de l'identifier pour la recherche
    local identifierHash = identifier
    if identifier:find(':') then
        identifierHash = identifier:match(':(.+)') or identifier
    end

    -- Verifier la hierarchie des grades
    -- D'abord verifier si le joueur est en ligne
    local staffGrade = Helpers.GetPlayerGrade(source)
    local targetOnline = false
    local targetGrade = 'user'

    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        local playerIdentifier = xPlayer.getIdentifier()
        local playerHash = playerIdentifier:match(':(.+)') or playerIdentifier

        if playerIdentifier == identifier or
           playerHash == identifierHash or
           identifierHash == playerHash then
            targetOnline = true
            targetGrade = xPlayer.getGroup() or 'user'
            break
        end
    end

    -- Si pas en ligne, verifier dans la base de donnees
    if not targetOnline then
        -- Chercher le joueur dans la table users avec plusieurs variations d'identifier
        local userData = Database.SingleAsync([[
            SELECT `group` FROM users
            WHERE identifier = ?
               OR identifier = ?
               OR identifier LIKE ?
               OR identifier LIKE ?
            LIMIT 1
        ]], {identifier, identifierHash, '%:' .. identifierHash, identifierHash .. '%'})

        if userData and userData.group then
            targetGrade = userData.group
        end
    end

    -- Verifier si le staff peut agir sur ce grade
    if not Helpers.CanActOnGrade(staffGrade, targetGrade) then
        cb({success = false, error = 'Vous ne pouvez pas bannir un membre de grade egal ou superieur'})
        return
    end

    -- Verifier si deja banni
    local existingBan = Database.SingleAsync([[
        SELECT * FROM panel_bans WHERE identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci AND (expires_at IS NULL OR expires_at > NOW())
    ]], {identifier})

    if existingBan then
        cb({success = false, error = 'Ce joueur est deja banni'})
        return
    end

    -- Calculer la date d'expiration
    local expiresAt = nil
    if not isPermanent and duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 3600))
    end

    -- Generer un ID de deban unique
    local unbanId = Database.GenerateUnbanId()

    -- Ajouter le ban dans panel_bans
    Database.Execute([[
        INSERT INTO panel_bans (identifier, player_name, reason, banned_by, banned_by_name, expires_at, unban_id, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {identifier, 'Inconnu (ban manuel)', reason, session.identifier, session.name, expiresAt, unbanId})

    -- Ajouter dans panel_sanctions
    local sanctionType = isPermanent and 'ban_perm' or 'ban_temp'
    Database.Execute([[
        INSERT INTO panel_sanctions (type, target_identifier, target_name, staff_identifier, staff_name, reason, duration_hours, expires_at, status, unban_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)
    ]], {sanctionType, identifier, 'Inconnu (ban manuel)', session.identifier, session.name, reason, duration, expiresAt, unbanId})

    -- Log
    Database.AddLog(
        Enums.LogCategory.SANCTION,
        Enums.LogAction.BAN_ADD,
        session.identifier,
        session.name,
        identifier,
        'Inconnu (ban manuel)',
        {reason = reason, duration = duration, permanent = isPermanent, method = 'ban_by_identifier', unbanId = unbanId}
    )

    -- Discord webhook
    if Discord and Discord.LogSanction then
        -- Pour un ban par identifier, on n'a que l'identifier fourni
        local targetData = {
            serverId = nil,
            license = identifier:find('license:') and identifier or nil,
            discord = identifier:find('discord:') and identifier or nil,
            steam = identifier:find('steam:') and identifier or nil,
            fivem = identifier:find('fivem:') and identifier or nil,
            unbanId = unbanId
        }
        -- Si c'est un hash sans prefixe, on le met en license par defaut
        if not identifier:find(':') then
            targetData.license = 'license:' .. identifier
        end
        Discord.LogSanction(sanctionType, session.name, 'Inconnu (ban manuel)', reason, duration, targetData)
    end

    -- Kick le joueur s'il est connecte avec cet identifier
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        local playerIdentifier = xPlayer.getIdentifier()
        -- Verifier si l'identifier correspond (avec ou sans prefixe)
        if playerIdentifier == identifier or
           playerIdentifier == 'license:' .. identifier or
           identifier == 'license:' .. playerIdentifier or
           string.find(playerIdentifier, identifier, 1, true) or
           string.find(identifier, playerIdentifier, 1, true) then

            local durationText = isPermanent and 'Permanent' or Helpers.FormatDuration(duration)
            DropPlayer(xPlayer.source,
                'Vous avez ete banni.\n\n' ..
                'Raison: ' .. reason .. '\n' ..
                'Duree: ' .. durationText .. '\n' ..
                'ID de deban: ' .. unbanId .. '\n\n' ..
                'Contestation: discord.gg/fightleague'
            )
            if Config.Debug then print('^2[PANEL ADMIN]^0 Joueur ' .. GetPlayerName(xPlayer.source) .. ' kick car banni par identifier (ID deban: ' .. unbanId .. ')') end
            break
        end
    end

    if Config.Debug then print('^2[PANEL ADMIN]^0 ' .. session.name .. ' a banni ' .. identifier .. ' par identifier (duree: ' .. tostring(duration) .. 'h, ID deban: ' .. unbanId .. ')') end

    cb({success = true, unbanId = unbanId})
end)

-- ══════════════════════════════════════════════════════════════
-- SPECTATE - GESTION DES INSTANCES
-- ══════════════════════════════════════════════════════════════

-- Callback pour demarrer le spectate (gere les instances)
ESX.RegisterServerCallback('panel:spectateStart', function(source, cb, targetId)
    -- Verifier les permissions
    if not Auth.HasPermission(source, 'player.spectate') then
        cb({success = false, error = 'Pas de permission'})
        return
    end

    -- Verifier que la cible existe
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb({success = false, error = 'Joueur non trouve'})
        return
    end

    -- Recuperer les coordonnees de la cible depuis le serveur
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))

    -- Recuperer les buckets
    local staffBucket = GetPlayerRoutingBucket(source)
    local targetBucket = GetPlayerRoutingBucket(targetId)

    if Config.Debug then
        print('^3[SPECTATE]^0 Staff ' .. source .. ' (bucket ' .. staffBucket .. ') veut spectate ' .. targetId .. ' (bucket ' .. targetBucket .. ')')
        print('^3[SPECTATE]^0 Coords cible: ' .. targetCoords.x .. ', ' .. targetCoords.y .. ', ' .. targetCoords.z)
    end

    -- Changer le bucket du staff si necessaire
    if staffBucket ~= targetBucket then
        SetPlayerRoutingBucket(source, targetBucket)
        if Config.Debug then print('^3[SPECTATE]^0 Staff ' .. source .. ' deplace dans instance ' .. targetBucket) end
    end

    cb({
        success = true,
        originalBucket = staffBucket,
        targetBucket = targetBucket,
        targetCoords = {
            x = targetCoords.x,
            y = targetCoords.y,
            z = targetCoords.z
        }
    })
end)

-- ══════════════════════════════════════════════════════════════
-- NOCLIP - VERIFICATION PERMISSION
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('panel:checkNoclipPermission', function()
    local source = source

    -- Verifier si le joueur a acces au panel (donc est staff)
    if Auth.CanAccessPanel(source) then
        -- Verifier permission specifique noclip ou teleport.self
        if Auth.HasPermission(source, 'teleport.self') then
            TriggerClientEvent('panel:noclipAllowed', source)

            -- Log
            local session = Auth.GetSession(source)
            if session then
                Database.AddLog(
                    Enums.LogCategory.TELEPORT,
                    'noclip_toggle',
                    session.identifier,
                    session.name,
                    session.identifier,
                    session.name,
                    nil
                )

                -- Discord webhook
                if Discord and Discord.LogAdminMode then
                    Discord.LogAdminMode('noclip_toggle', session.name)
                end
            end
        else
            TriggerClientEvent('panel:noclipDenied', source)
        end
    else
        TriggerClientEvent('panel:noclipDenied', source)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- NOCLIP - PERMISSION SUPPRESSION OBJETS (ADMIN UNIQUEMENT)
-- ══════════════════════════════════════════════════════════════

-- Callback pour verifier si le joueur peut supprimer des objets
ESX.RegisterServerCallback('panel:canDeleteObject', function(source, cb)
    -- Seuls les admins (niveau 80+) peuvent supprimer des objets
    if Auth.HasPermission(source, 'object.delete') then
        cb(true)
    else
        cb(false)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- ESP - VERIFICATION PERMISSION ET GRADES
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('panel:checkEspPermission', function()
    local source = source

    -- Verifier si le joueur a acces au panel (donc est staff)
    if Auth.CanAccessPanel(source) then
        TriggerClientEvent('panel:espAllowed', source)

        -- Log
        local session = Auth.GetSession(source)
        if session then
            Database.AddLog(
                Enums.LogCategory.PLAYER,
                'esp_toggle',
                session.identifier,
                session.name,
                session.identifier,
                session.name,
                nil
            )

            -- Discord webhook
            if Discord and Discord.LogAdminMode then
                Discord.LogAdminMode('esp_toggle', session.name)
            end
        end
    else
        TriggerClientEvent('panel:espDenied', source)
    end
end)

-- Envoyer les grades de tous les joueurs
RegisterNetEvent('panel:requestPlayerGrades', function()
    local source = source

    -- Verifier permission
    if not Auth.CanAccessPanel(source) then return end

    local grades = {}

    for _, playerId in ipairs(Helpers.GetAllPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            local group = xPlayer.getGroup()
            -- Mapper les grades ESX aux grades d'affichage
            if group == 'superadmin' or group == 'owner' then
                grades[playerId] = 'owner'
            elseif group == 'admin' then
                grades[playerId] = 'admin'
            elseif group == 'responsable' then
                grades[playerId] = 'responsable'
            elseif group == 'organisateur' then
                grades[playerId] = 'organisateur'
            elseif group == 'staff' or group == 'moderator' or group == 'mod' or group == 'support' or group == 'helper' then
                grades[playerId] = 'staff'
            else
                grades[playerId] = 'default'
            end
        end
    end

    TriggerClientEvent('panel:receivePlayerGrades', source, grades)
end)

-- ══════════════════════════════════════════════════════════════
-- QUICK MENU ACTIONS (NOCLIP)
-- ══════════════════════════════════════════════════════════════

-- Callback pour TP vers un joueur (noclip)
ESX.RegisterServerCallback('panel:gotoPlayer', function(source, cb, targetId)
    if not Auth.CanAccessPanel(source) then
        cb({success = false})
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed then
        cb({success = false, error = 'Joueur introuvable'})
        return
    end

    local targetCoords = GetEntityCoords(targetPed)

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.TELEPORT,
            'goto_player',
            session.identifier,
            session.name,
            tostring(targetId),
            GetPlayerName(targetId),
            nil
        )
    end

    cb({
        success = true,
        coords = {x = targetCoords.x, y = targetCoords.y, z = targetCoords.z}
    })
end)

-- Event pour amener un joueur (depuis noclip)
RegisterNetEvent('panel:bringPlayer', function(targetId, coords)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Sauvegarder la position du joueur avant de le TP
    local prevCoords = GetEntityCoords(targetPed)
    local prevBucket = GetPlayerRoutingBucket(targetId)

    -- Stocker pour le return
    if not _G.playerPreviousPositions then
        _G.playerPreviousPositions = {}
    end
    _G.playerPreviousPositions[targetId] = {
        x = prevCoords.x,
        y = prevCoords.y,
        z = prevCoords.z,
        bucket = prevBucket
    }

    -- Changer l'instance si necessaire
    local staffBucket = GetPlayerRoutingBucket(source)
    if staffBucket ~= prevBucket then
        SetPlayerRoutingBucket(targetId, staffBucket)
    end

    -- Teleporter le joueur
    TriggerClientEvent('panel:teleport', targetId, coords.x, coords.y, coords.z)

    -- Notifications
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Teleportation',
        message = targetName .. ' a ete teleporte vers vous'
    })
    TriggerClientEvent('panel:notification', targetId, {
        type = 'info',
        title = 'Teleportation',
        message = 'Vous avez ete teleporte par un admin'
    })

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.TELEPORT,
            'bring_player',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            nil
        )
    end
end)

-- Event pour retourner un joueur a sa position precedente
RegisterNetEvent('panel:returnPlayer', function(targetId)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    if not _G.playerPreviousPositions or not _G.playerPreviousPositions[targetId] then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Aucune position precedente pour ce joueur'
        })
        return
    end

    local prevPos = _G.playerPreviousPositions[targetId]

    -- Changer l'instance si necessaire
    local currentBucket = GetPlayerRoutingBucket(targetId)
    if currentBucket ~= prevPos.bucket then
        SetPlayerRoutingBucket(targetId, prevPos.bucket)
    end

    -- Teleporter le joueur
    TriggerClientEvent('panel:teleport', targetId, prevPos.x, prevPos.y, prevPos.z)

    -- Notifications
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Return',
        message = targetName .. ' a ete retourne a sa position'
    })
    TriggerClientEvent('panel:notification', targetId, {
        type = 'info',
        title = 'Teleportation',
        message = 'Vous avez ete retourne a votre position'
    })

    -- Nettoyer
    _G.playerPreviousPositions[targetId] = nil

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.TELEPORT,
            'return_player',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            nil
        )
    end
end)

-- Event pour kick un joueur
RegisterNetEvent('panel:kickPlayer', function(targetId, reason)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Verification de la hierarchie des grades
    local staffGrade = Helpers.GetPlayerGrade(source)
    local targetGrade = Helpers.GetPlayerGrade(targetId)

    if not Helpers.CanActOnGrade(staffGrade, targetGrade) then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Permission refusee',
            message = 'Vous ne pouvez pas kick un membre de grade egal ou superieur'
        })
        return
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.SANCTION,
            'kick',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            {reason = reason}
        )
    end

    -- Kick le joueur
    DropPlayer(targetId, 'Vous avez ete kick: ' .. (reason or 'Aucune raison'))

    -- Notification au staff
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Kick',
        message = targetName .. ' a ete kick'
    })
end)

-- Event pour freeze un joueur depuis le menu rapide
RegisterNetEvent('panel:freezePlayer', function(targetId)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Verification de la hierarchie des grades
    local staffGrade = Helpers.GetPlayerGrade(source)
    local targetGrade = Helpers.GetPlayerGrade(targetId)

    if not Helpers.CanActOnGrade(staffGrade, targetGrade) then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Permission refusee',
            message = 'Vous ne pouvez pas freeze un membre de grade egal ou superieur'
        })
        return
    end

    -- Toggle freeze sur le client cible
    TriggerClientEvent('panel:toggleFreeze', targetId)

    -- Notification au staff
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Freeze',
        message = 'Joueur ' .. targetName .. ' freeze toggle'
    })

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.PLAYER,
            'freeze_player',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            nil
        )
    end
end)

-- Event pour restaurer l'instance apres spectate
RegisterNetEvent('panel:spectateRestore', function(originalBucket)
    local source = source
    local currentBucket = GetPlayerRoutingBucket(source)

    if currentBucket ~= originalBucket then
        SetPlayerRoutingBucket(source, originalBucket)
        if Config.Debug then print('^3[SPECTATE]^0 Staff ' .. source .. ' retourne dans instance ' .. originalBucket) end
    end
end)

-- Event pour heal un joueur depuis le quick menu
RegisterNetEvent('panel:healPlayer', function(targetId)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Heal le joueur
    TriggerClientEvent('panel:setHealth', targetId, 200)

    -- Notifications
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Heal',
        message = targetName .. ' a ete soigne'
    })
    TriggerClientEvent('panel:notification', targetId, {
        type = 'success',
        title = 'Heal',
        message = 'Vous avez ete soigne par un admin'
    })

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.PLAYER,
            'heal_player',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            nil
        )
    end
end)

-- Event pour donner de l'armure depuis le quick menu
RegisterNetEvent('panel:armorPlayer', function(targetId)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Donner l'armure
    TriggerClientEvent('panel:setArmor', targetId, 100)

    -- Notifications
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Armure',
        message = targetName .. ' a recu de l\'armure'
    })
    TriggerClientEvent('panel:notification', targetId, {
        type = 'success',
        title = 'Armure',
        message = 'Vous avez recu de l\'armure'
    })

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.PLAYER,
            'armor_player',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            nil
        )
    end
end)

-- Event pour envoyer un message a un joueur (affiche en haut de l'ecran)
RegisterNetEvent('panel:sendMessageToPlayer', function(targetId, message)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    if not message or message == '' then return end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Envoyer le message au joueur
    TriggerClientEvent('panel:displayAdminMessage', targetId, message)

    -- Notification au staff
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Message',
        message = 'Message envoye a ' .. targetName
    })

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(
            Enums.LogCategory.PLAYER,
            'message_player',
            session.identifier,
            session.name,
            tostring(targetId),
            targetName,
            {message = message}
        )
    end
end)

-- Event pour ban depuis le quick menu
RegisterNetEvent('panel:banPlayerFromQuickMenu', function(targetId, reason, duration)
    local source = source

    if not Auth.CanAccessPanel(source) then return end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Verification de la hierarchie des grades
    local staffGrade = Helpers.GetPlayerGrade(source)
    local targetGrade = Helpers.GetPlayerGrade(targetId)

    if not Helpers.CanActOnGrade(staffGrade, targetGrade) then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Permission refusee',
            message = 'Vous ne pouvez pas bannir un membre de grade egal ou superieur'
        })
        return
    end

    -- Convertir la duree en heures (Sanctions.Ban attend des heures)
    local durationHours = nil
    if duration ~= 'permanent' then
        local num = tonumber(duration:match('%d+'))
        local unit = duration:match('%a+')
        if unit == 'h' then
            durationHours = num -- Deja en heures
        elseif unit == 'd' then
            durationHours = num * 24 -- Convertir jours en heures
        end
    else
        durationHours = -1 -- Permanent
    end

    -- Utiliser le systeme de sanctions existant
    local result, err = Sanctions.Ban(source, targetId, reason, durationHours)

    if result then
        TriggerClientEvent('panel:notification', source, {
            type = 'success',
            title = 'Ban',
            message = targetName .. ' a ete banni'
        })
    else
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = err or 'Erreur lors du ban'
        })
    end
end)

-- Event pour spawn un vehicule pour un joueur depuis le quick menu
RegisterNetEvent('panel:spawnVehicleForPlayer', function(targetId, model, color)
    local source = source

    -- Verifier permissions - organisateur minimum
    local session = Auth.GetSession(source)
    if not session then return end

    local allowedGroups = {'organisateur', 'responsable', 'admin', 'owner'}
    local hasPermission = false
    for _, group in ipairs(allowedGroups) do
        if session.group == group then
            hasPermission = true
            break
        end
    end

    if not hasPermission then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Permission insuffisante'
        })
        return
    end

    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = 'Joueur introuvable'
        })
        return
    end

    -- Spawn le vehicule cote client du joueur cible
    TriggerClientEvent('panel:spawnVehicleWithColor', targetId, model, color or 5)

    -- Notifications
    TriggerClientEvent('panel:notification', source, {
        type = 'success',
        title = 'Vehicule',
        message = 'Vehicule ' .. model .. ' spawn pour ' .. targetName
    })
    TriggerClientEvent('panel:notification', targetId, {
        type = 'success',
        title = 'Vehicule',
        message = 'Un admin vous a donne un vehicule'
    })

    -- Log
    Database.AddLog(
        Enums.LogCategory.VEHICLE,
        'spawn_for_player',
        session.identifier,
        session.name,
        tostring(targetId),
        targetName,
        {model = model, color = color}
    )

    -- Discord webhook
    if Discord and Discord.LogVehicle then
        Discord.LogVehicle('vehicle_spawn', session.name, targetName, {model = model})
    end
end)

-- ══════════════════════════════════════════════════════════════
-- EVENTS ACTIONS
-- ══════════════════════════════════════════════════════════════

-- Actions joueur
RegisterNetEvent('panel:playerAction', function(action, targetId, data)
    local source = source
    if not Auth.CheckRateLimit(source) then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = _L('error'),
            message = Helpers.FormatError('RATE_LIMITED')
        })
        return
    end

    local result, err

    if action == 'revive' then
        result, err = Players.Revive(source, targetId)
    elseif action == 'heal' then
        result, err = Players.Heal(source, targetId)
    elseif action == 'freeze' then
        result, err = Players.ToggleFreeze(source, targetId, true)
    elseif action == 'unfreeze' then
        result, err = Players.ToggleFreeze(source, targetId, false)
    elseif action == 'setgroup' then
        result, err = Players.SetGroup(source, targetId, data.group)
    end

    if not result then
        TriggerClientEvent('panel:notification', source, {
            type = 'error',
            title = 'Erreur',
            message = Helpers.FormatError(err)
        })
    else
        TriggerClientEvent('panel:notification', source, {
            type = 'success',
            title = 'Succès',
            message = 'Action effectuée'
        })
    end
end)

-- Actions sanctions
RegisterNetEvent('panel:sanctionAction', function(action, targetId, data)
    local source = source
    if not Auth.CheckRateLimit(source) then return end

    if Config.Debug then
        print('^5═══════════════════════════════════════════════════════════════^0')
        print('^3[PANEL SANCTION]^0 Action: ' .. tostring(action))
        print('^3[PANEL SANCTION]^0 Staff Source: ' .. tostring(source))
        print('^3[PANEL SANCTION]^0 Target ID: ' .. tostring(targetId))
        print('^3[PANEL SANCTION]^0 Data: ' .. json.encode(data or {}))

        -- Vérifier le groupe du staff
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            print('^3[PANEL SANCTION]^0 Staff Group: ' .. tostring(xPlayer.getGroup()))
            print('^3[PANEL SANCTION]^0 Staff Name: ' .. tostring(xPlayer.getName()))
        else
            print('^1[PANEL SANCTION]^0 ERREUR: Staff ESX player non trouvé!')
        end
        print('^5═══════════════════════════════════════════════════════════════^0')
    end

    local result, err

    if action == 'warn' then
        result, err = Sanctions.Warn(source, targetId, data.reason)
    elseif action == 'kick' then
        result, err = Sanctions.Kick(source, targetId, data.reason)
    elseif action == 'ban' then
        result, err = Sanctions.Ban(source, targetId, data.reason, data.duration)
    elseif action == 'unban' then
        result, err = Sanctions.Unban(source, data.identifier)
    end

    if Config.Debug then
        print('^5═══════════════════════════════════════════════════════════════^0')
        if result then
            print('^2[PANEL SANCTION]^0 SUCCES: ' .. action .. ' appliqué!')
        else
            print('^1[PANEL SANCTION]^0 ECHEC: ' .. tostring(err))
        end
        print('^5═══════════════════════════════════════════════════════════════^0')
    end

    TriggerClientEvent('panel:notification', source, {
        type = result and 'success' or 'error',
        title = result and 'Succès' or 'Erreur',
        message = result and Helpers.FormatSuccess(action) or Helpers.FormatError(err)
    })
end)

-- Actions économie
RegisterNetEvent('panel:economyAction', function(action, targetId, data)
    local source = source
    if not Auth.CheckRateLimit(source) then return end

    local result, err

    if action == 'add' then
        result, err = Economy.AddMoney(source, targetId, data.amount, data.type, data.reason)
    elseif action == 'remove' then
        result, err = Economy.RemoveMoney(source, targetId, data.amount, data.type, data.reason)
    elseif action == 'set' then
        result, err = Economy.SetMoney(source, targetId, data.amount, data.type, data.reason)
    end

    TriggerClientEvent('panel:notification', source, {
        type = result and 'success' or 'error',
        title = result and 'Succès' or 'Erreur',
        message = result and _L('success_money') or (type(err) == 'table' and table.concat(err, ', ') or Helpers.FormatError(err))
    })
end)

-- Actions téléportation
RegisterNetEvent('panel:teleportAction', function(action, targetId, data)
    local source = source
    if not Auth.CheckRateLimit(source) then return end

    local result, err

    if action == 'coords' then
        result, err = Teleport.ToCoords(source, targetId, data.x, data.y, data.z)
    elseif action == 'self' then
        result, err = Teleport.Self(source, data.x, data.y, data.z)
    elseif action == 'goto' then
        result, err = Teleport.Goto(source, targetId)
    elseif action == 'bring' then
        result, err = Teleport.Bring(source, targetId)
    elseif action == 'return' then
        result, err = Teleport.Return(source)
    elseif action == 'returnPlayer' then
        result, err = Teleport.ReturnPlayer(source, targetId)
    end

    TriggerClientEvent('panel:notification', source, {
        type = result and 'success' or 'error',
        title = result and 'Succes' or 'Erreur',
        message = result and _L('success_teleport') or Helpers.FormatError(err)
    })
end)

-- Actions véhicules
RegisterNetEvent('panel:vehicleAction', function(action, targetId, data)
    local source = source
    if not Auth.CheckRateLimit(source) then return end

    local result, err

    if action == 'spawn' then
        local options = {
            color = data.color,
            customColor = data.customColor,
            colorR = data.colorR,
            colorG = data.colorG,
            colorB = data.colorB,
            engine = data.engine,
            transmission = data.transmission,
            brakes = data.brakes,
            suspension = data.suspension,
            armor = data.armor,
            turbo = data.turbo,
            neon = data.neon,
            xenon = data.xenon,
            fullUpgrade = data.fullUpgrade
        }
        if Config.Debug then print('[VEHICLE ACTION] Options reçues - customColor: ' .. tostring(data.customColor) .. ', R: ' .. tostring(data.colorR) .. ', G: ' .. tostring(data.colorG) .. ', B: ' .. tostring(data.colorB)) end
        result, err = Vehicles.Spawn(source, targetId or source, data.model, options)
    elseif action == 'delete' then
        result, err = Vehicles.Delete(source, targetId or source)
    elseif action == 'repair' then
        result, err = Vehicles.Repair(source, targetId or source)
    end

    TriggerClientEvent('panel:notification', source, {
        type = result and 'success' or 'error',
        title = result and 'Succès' or 'Erreur',
        message = result and _L('success_vehicle') or Helpers.FormatError(err)
    })
end)

-- Action annonce
RegisterNetEvent('panel:announceAction', function(data)
    local source = source
    if not Auth.CheckRateLimit(source) then return end

    if Config.Debug then
        print('^5═══════════════════════════════════════════════════════════════^0')
        print('^3[PANEL ANNOUNCE]^0 Message: ' .. tostring(data.message))
        print('^3[PANEL ANNOUNCE]^0 Type: ' .. tostring(data.type))
        print('^3[PANEL ANNOUNCE]^0 Priority: ' .. tostring(data.priority))
        print('^3[PANEL ANNOUNCE]^0 Staff Source: ' .. tostring(source))

        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            print('^3[PANEL ANNOUNCE]^0 Staff Group: ' .. tostring(xPlayer.getGroup()))
        end
        print('^5═══════════════════════════════════════════════════════════════^0')
    end

    local result, err = Announcements.Send(source, data.message, data.type, data.priority, data.title)

    if Config.Debug then
        print('^5═══════════════════════════════════════════════════════════════^0')
        if result then
            print('^2[PANEL ANNOUNCE]^0 SUCCES: Annonce envoyée!')
        else
            print('^1[PANEL ANNOUNCE]^0 ECHEC: ' .. tostring(err))
        end
        print('^5═══════════════════════════════════════════════════════════════^0')
    end

    TriggerClientEvent('panel:notification', source, {
        type = result and 'success' or 'error',
        title = result and 'Succès' or 'Erreur',
        message = result and _L('success_announce') or Helpers.FormatError(err)
    })
end)

-- ══════════════════════════════════════════════════════════════
-- DEATH LOG
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('panel:playerDeath', function(data)
    local victimSource = source
    if Config.Debug then print('^3[DEATH LOG SERVER]^0 Event recu de source: ' .. tostring(victimSource)) end

    local xVictim = ESX.GetPlayerFromId(victimSource)
    if not xVictim then
        if Config.Debug then print('^1[DEATH LOG SERVER]^0 Victime non trouvee!') end
        return
    end

    local victimName = xVictim.getName()
    local victimIdentifier = xVictim.getIdentifier()

    local killerName = nil
    local killerIdentifier = nil
    local action = 'death_environment'
    local details = {
        cause = data.deathCause or 'Inconnu',
        isSuicide = data.isSuicide or false
    }

    -- Si c'est un kill par un autre joueur
    if data.killerServerId and data.killerServerId ~= victimSource then
        local xKiller = ESX.GetPlayerFromId(data.killerServerId)
        if xKiller then
            killerName = xKiller.getName()
            killerIdentifier = xKiller.getIdentifier()
            action = 'death_pvp'
            details.killerName = killerName
        end
    elseif data.isSuicide then
        action = 'death_suicide'
    end

    if Config.Debug then
        print('^3[DEATH LOG SERVER]^0 Action: ' .. action)
        print('^3[DEATH LOG SERVER]^0 Victime: ' .. victimName)
        print('^3[DEATH LOG SERVER]^0 Tueur: ' .. tostring(killerName))
        print('^3[DEATH LOG SERVER]^0 Cause: ' .. tostring(data.deathCause))
    end

    -- Log dans la base de donnees avec server IDs
    local killerServerId = data.killerServerId or 0
    Database.Execute([[
        INSERT INTO panel_logs (category, action, staff_identifier, staff_name, target_identifier, target_name, details, staff_server_id, target_server_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        'death',
        action,
        killerIdentifier,
        killerName,
        victimIdentifier,
        victimName,
        json.encode(details),
        killerServerId,
        victimSource
    }, function(rowsChanged)
        if Config.Debug then print('^2[DEATH LOG SERVER]^0 Insert OK, rows: ' .. tostring(rowsChanged)) end
    end)

    if Config.Debug then
        if action == 'death_pvp' then
            print('^3[DEATH LOG]^0 ' .. killerName .. ' a tue ' .. victimName .. ' (' .. data.deathCause .. ')')
        elseif action == 'death_suicide' then
            print('^3[DEATH LOG]^0 ' .. victimName .. ' s\'est suicide (' .. data.deathCause .. ')')
        else
            print('^3[DEATH LOG]^0 ' .. victimName .. ' est mort (' .. data.deathCause .. ')')
        end
    end

    -- Envoyer sur Discord pour toutes les morts
    if Discord and Discord.LogDeath then
        local killerData = nil

        -- Si c'est un kill PVP, récupérer les identifiants du tueur
        if action == 'death_pvp' and data.killerServerId then
            local killerIdentifiers = Helpers.GetPlayerIdentifiers(data.killerServerId)
            killerData = {
                name = killerName,
                serverId = data.killerServerId,
                discord = killerIdentifiers.discord and killerIdentifiers.discord:gsub('discord:', '') or nil,
                fivem = killerIdentifiers.fivem and killerIdentifiers.fivem:gsub('fivem:', '') or nil,
                license = killerIdentifiers.license and killerIdentifiers.license:gsub('license:', '') or nil,
                steam = killerIdentifiers.steam and killerIdentifiers.steam:gsub('steam:', '') or nil,
                xbl = killerIdentifiers.xbl and killerIdentifiers.xbl:gsub('xbl:', '') or nil
            }
        end

        -- Récupérer les identifiants de la victime
        local victimIdentifiers = Helpers.GetPlayerIdentifiers(victimSource)
        local victimData = {
            name = victimName,
            serverId = victimSource,
            discord = victimIdentifiers.discord and victimIdentifiers.discord:gsub('discord:', '') or nil,
            fivem = victimIdentifiers.fivem and victimIdentifiers.fivem:gsub('fivem:', '') or nil,
            license = victimIdentifiers.license and victimIdentifiers.license:gsub('license:', '') or nil,
            steam = victimIdentifiers.steam and victimIdentifiers.steam:gsub('steam:', '') or nil,
            xbl = victimIdentifiers.xbl and victimIdentifiers.xbl:gsub('xbl:', '') or nil
        }

        Discord.LogDeath(killerData, victimData, data.deathCause, action)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- DISCONNECT LOG - Logs de deconnexion avec fantomes
-- ══════════════════════════════════════════════════════════════

-- Cache des joueurs connectes (pour garder leurs infos apres deconnexion)
local connectedPlayersCache = {}

-- Stocker les infos des joueurs quand ils se connectent
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source

    -- Attendre que le joueur soit completement connecte
    CreateThread(function()
        Wait(5000) -- Attendre 5 secondes pour que tous les identifiants soient charges

        if GetPlayerName(source) then
            local identifiers = Helpers.GetPlayerIdentifiers(source)
            local coords = Helpers.GetPlayerCoords(source) or vector3(0, 0, 0)
            local fivemName = GetPlayerName(source)

            -- Mettre a jour le nom FiveM dans la table users
            if identifiers.license then
                Database.ExecuteAsync([[
                    UPDATE users SET fivem_name = ? WHERE identifier = ?
                ]], {fivemName, identifiers.license})

                if Config.Debug then
                    print('^2[FIVEM NAME]^0 Nom FiveM mis a jour pour: ' .. fivemName .. ' (' .. identifiers.license .. ')')
                end
            end

            connectedPlayersCache[source] = {
                serverId = source,
                name = fivemName,
                discord = identifiers.discord and identifiers.discord:gsub('discord:', '') or nil,
                fivem = identifiers.fivem and identifiers.fivem:gsub('fivem:', '') or nil,
                license = identifiers.license and identifiers.license:gsub('license:', '') or nil,
                steam = identifiers.steam and identifiers.steam:gsub('steam:', '') or nil,
                coords = coords
            }

            if Config.Debug then
                print('^2[DISCONNECT]^0 Joueur cache: ' .. fivemName .. ' (ID: ' .. source .. ')')
            end
        end
    end)
end)

-- Mettre a jour les coordonnees periodiquement
CreateThread(function()
    while true do
        Wait(30000) -- Toutes les 30 secondes

        for _, playerId in ipairs(Helpers.GetAllPlayers()) do
            if connectedPlayersCache[playerId] then
                local coords = Helpers.GetPlayerCoords(playerId)
                if coords then
                    connectedPlayersCache[playerId].coords = coords
                end
            else
                -- Joueur pas encore en cache, l'ajouter
                local identifiers = Helpers.GetPlayerIdentifiers(playerId)
                local coords = Helpers.GetPlayerCoords(playerId) or vector3(0, 0, 0)

                connectedPlayersCache[playerId] = {
                    serverId = playerId,
                    name = GetPlayerName(playerId),
                    discord = identifiers.discord and identifiers.discord:gsub('discord:', '') or nil,
                    fivem = identifiers.fivem and identifiers.fivem:gsub('fivem:', '') or nil,
                    license = identifiers.license and identifiers.license:gsub('license:', '') or nil,
                    steam = identifiers.steam and identifiers.steam:gsub('steam:', '') or nil,
                    coords = coords
                }
            end
        end
    end
end)

-- Event de deconnexion
AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source)

    -- Recuperer les infos depuis le cache ou les collecter maintenant
    local playerData = connectedPlayersCache[source]
    local coords = nil

    if playerData then
        coords = playerData.coords
    else
        -- Fallback: essayer de recuperer les infos directement
        local identifiers = Helpers.GetPlayerIdentifiers(source)
        playerData = {
            serverId = source,
            name = playerName or 'Inconnu',
            discord = identifiers.discord and identifiers.discord:gsub('discord:', '') or nil,
            fivem = identifiers.fivem and identifiers.fivem:gsub('fivem:', '') or nil,
            license = identifiers.license and identifiers.license:gsub('license:', '') or nil,
            steam = identifiers.steam and identifiers.steam:gsub('steam:', '') or nil
        }
        coords = Helpers.GetPlayerCoords(source)
    end

    if Config.Debug then
        print('^3[DISCONNECT]^0 Joueur deconnecte: ' .. (playerData.name or 'Inconnu'))
        print('^3[DISCONNECT]^0 ID: ' .. tostring(playerData.serverId))
        print('^3[DISCONNECT]^0 License: ' .. tostring(playerData.license))
        print('^3[DISCONNECT]^0 Discord: ' .. tostring(playerData.discord))
        print('^3[DISCONNECT]^0 Raison: ' .. tostring(reason))
        if coords then
            print('^3[DISCONNECT]^0 Coords: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
        end
    end

    -- Envoyer le log Discord
    if Discord and Discord.LogDisconnect then
        Discord.LogDisconnect(playerData, reason, coords)
    end

    -- Envoyer les infos aux clients staff pour creer le fantome
    if coords then
        local ghostData = {
            serverId = playerData.serverId,
            name = playerData.name or 'Inconnu',
            coords = {x = coords.x, y = coords.y, z = coords.z},
            timestamp = os.time(),
            reason = reason
        }

        -- Envoyer a tous les joueurs staff
        for _, playerId in ipairs(Helpers.GetAllPlayers()) do
            if Auth.CanAccessPanel(playerId) then
                TriggerClientEvent('panel:playerDisconnected', playerId, ghostData)
            end
        end
    end

    -- Nettoyer le cache
    connectedPlayersCache[source] = nil
end)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES
-- ══════════════════════════════════════════════════════════════

-- Commande principale pour ouvrir le panel
RegisterCommand('panel', function(source)
    if source == 0 then return end
    if not Auth.CanAccessPanel(source) then return end

    local session = Auth.InitSession(source)
    if session then
        TriggerClientEvent('panel:openNUI', source, session)
    end
end, false)

-- Alias
RegisterCommand('admin', function(source)
    if source == 0 then return end
    if not Auth.CanAccessPanel(source) then return end

    local session = Auth.InitSession(source)
    if session then
        TriggerClientEvent('panel:openNUI', source, session)
    end
end, false)

-- ══════════════════════════════════════════════════════════════
-- REPAIR KEY - Touche de reparation vehicule
-- ══════════════════════════════════════════════════════════════

-- Envoyer le groupe du joueur au client
RegisterNetEvent('panel:requestPlayerGroup', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        TriggerClientEvent('panel:updatePlayerGroup', source, xPlayer.getGroup())
    end
end)

-- Log de reparation (optionnel)
RegisterNetEvent('panel:logRepairKey', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and Config.Debug then
        print('^3[REPAIR KEY]^0 ' .. GetPlayerName(source) .. ' a repare son vehicule')
    end
end)

if Config.Debug then print('^2[PANEL ADMIN]^0 Chargement terminé') end
