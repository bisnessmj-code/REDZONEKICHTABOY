--[[
    Module Sanctions - Panel Admin Fight League
    Système de warn/kick/ban
]]

local Sanctions = {}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Avertir un joueur
function Sanctions.Warn(staffSource, targetSource, reason)
    if Config.Debug then print('^3[SANCTIONS DEBUG]^0 Warn appelé - staff: ' .. tostring(staffSource) .. ' | target: ' .. tostring(targetSource)) end

    if not Auth.HasPermission(staffSource, 'sanction.warn') then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Pas de permission sanction.warn') end
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    if not Auth.CanActOn(staffSource, targetSource) then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Grade cible supérieur') end
        return false, Enums.ErrorCode.TARGET_HIGHER_GRADE
    end

    local valid, cleanReason = Validators.Reason(reason)
    if not valid then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Raison invalide: ' .. tostring(cleanReason)) end
        return false, cleanReason
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Joueur non trouvé: ' .. tostring(targetSource)) end
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    if Config.Debug then print('^2[SANCTIONS DEBUG]^0 Toutes les validations OK, application du warn...') end

    local session = Auth.GetSession(staffSource)
    local targetIdentifier = xTarget.getIdentifier()
    local targetName = GetPlayerName(targetSource) -- Nom FiveM

    -- Enregistrer la sanction
    Database.AddSanction({
        type = Enums.SanctionType.WARN,
        targetIdentifier = targetIdentifier,
        targetName = targetName,
        staffIdentifier = session.identifier,
        staffName = session.name,
        reason = cleanReason,
        duration = nil
    }, function(sanctionId)
        -- Notifier le joueur
        TriggerClientEvent('panel:notification', targetSource, {
            type = 'warning',
            title = 'Avertissement',
            message = 'Vous avez reçu un avertissement: ' .. cleanReason
        })

        -- Vérifier les seuils automatiques
        Sanctions.CheckWarnThresholds(targetIdentifier, targetName)
    end)

    -- Log
    Database.AddLog(
        Enums.LogCategory.SANCTION,
        Enums.LogAction.WARN_ADD,
        session.identifier,
        session.name,
        targetIdentifier,
        targetName,
        {reason = cleanReason}
    )

    -- Stats
    Database.UpdateDailyStat('warns_count', 1)

    -- Discord webhook
    if Discord and Discord.LogSanction then
        local identifiers = Helpers.GetPlayerIdentifiers(targetSource)
        local targetData = {
            serverId = targetSource,
            discord = identifiers.discord,
            license = identifiers.license,
            steam = identifiers.steam,
            fivem = identifiers.fivem
        }
        Discord.LogSanction('warn', session.name, targetName, cleanReason, nil, targetData)
    end

    return true
end

-- Expulser un joueur
function Sanctions.Kick(staffSource, targetSource, reason)
    if Config.Debug then print('^3[SANCTIONS DEBUG]^0 Kick appelé - staff: ' .. tostring(staffSource) .. ' | target: ' .. tostring(targetSource)) end

    if not Auth.HasPermission(staffSource, 'sanction.kick') then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Pas de permission sanction.kick') end
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    if staffSource == targetSource then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Tentative de kick soi-même') end
        return false, Enums.ErrorCode.CANNOT_SELF_ACTION
    end

    if not Auth.CanActOn(staffSource, targetSource) then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Grade cible supérieur') end
        return false, Enums.ErrorCode.TARGET_HIGHER_GRADE
    end

    local valid, cleanReason = Validators.Reason(reason)
    if not valid then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Raison invalide: ' .. tostring(cleanReason)) end
        return false, cleanReason
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        if Config.Debug then print('^1[SANCTIONS DEBUG]^0 Joueur non trouvé: ' .. tostring(targetSource)) end
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    if Config.Debug then print('^2[SANCTIONS DEBUG]^0 Toutes les validations OK, application du kick...') end

    local session = Auth.GetSession(staffSource)
    local targetIdentifier = xTarget.getIdentifier()
    local targetName = GetPlayerName(targetSource) -- Nom FiveM

    -- Enregistrer la sanction
    Database.AddSanction({
        type = Enums.SanctionType.KICK,
        targetIdentifier = targetIdentifier,
        targetName = targetName,
        staffIdentifier = session.identifier,
        staffName = session.name,
        reason = cleanReason,
        duration = nil
    })

    -- Log
    Database.AddLog(
        Enums.LogCategory.SANCTION,
        Enums.LogAction.KICK_PLAYER,
        session.identifier,
        session.name,
        targetIdentifier,
        targetName,
        {reason = cleanReason}
    )

    -- Stats
    Database.UpdateDailyStat('kicks_count', 1)

    -- Discord webhook
    if Config.Debug then
        print('^3[KICK DEBUG]^0 Discord exists: ' .. tostring(Discord ~= nil))
        print('^3[KICK DEBUG]^0 Discord.LogSanction exists: ' .. tostring(Discord and Discord.LogSanction ~= nil))
    end
    if Discord and Discord.LogSanction then
        if Config.Debug then print('^2[KICK DEBUG]^0 Envoi du log Discord pour kick...') end
        local identifiers = Helpers.GetPlayerIdentifiers(targetSource)
        local targetData = {
            serverId = targetSource,
            discord = identifiers.discord,
            license = identifiers.license,
            steam = identifiers.steam,
            fivem = identifiers.fivem
        }
        Discord.LogSanction('kick', session.name, targetName, cleanReason, nil, targetData)
    else
        if Config.Debug then print('^1[KICK DEBUG]^0 Discord non disponible!') end
    end

    -- Kick le joueur
    DropPlayer(targetSource, 'Vous avez ete expulse.\n\nRaison: ' .. cleanReason .. '\n\nContestation: discord.gg/fightleague')

    return true
end

-- Bannir un joueur
function Sanctions.Ban(staffSource, targetSource, reason, duration)
    local isPermanent = duration == -1
    local requiredPerm = isPermanent and 'sanction.ban.perm' or 'sanction.ban.temp'

    if not Auth.HasPermission(staffSource, requiredPerm) then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    if staffSource == targetSource then
        return false, Enums.ErrorCode.CANNOT_SELF_ACTION
    end

    if not Auth.CanActOn(staffSource, targetSource) then
        return false, Enums.ErrorCode.TARGET_HIGHER_GRADE
    end

    local valid, cleanReason = Validators.Reason(reason)
    if not valid then return false, cleanReason end

    if not isPermanent then
        valid, duration = Validators.Duration(duration, true)
        if not valid then return false, duration end
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)
    local targetIdentifier = xTarget.getIdentifier()
    local targetName = GetPlayerName(targetSource) -- Nom FiveM
    local identifiers = Helpers.GetPlayerIdentifiers(targetSource)

    -- Generer un ID de deban unique
    local unbanId = Database.GenerateUnbanId()

    -- Vérifier si déjà banni
    Database.IsPlayerBanned(targetIdentifier, function(isBanned)
        if isBanned then return end

        -- Enregistrer dans panel_sanctions
        Database.AddSanction({
            type = isPermanent and Enums.SanctionType.BAN_PERM or Enums.SanctionType.BAN_TEMP,
            targetIdentifier = targetIdentifier,
            targetName = targetName,
            staffIdentifier = session.identifier,
            staffName = session.name,
            reason = cleanReason,
            duration = duration,
            unbanId = unbanId
        })

        -- Enregistrer dans panel_bans (table optimisée)
        Database.AddBan({
            identifier = targetIdentifier,
            playerName = targetName,
            steamId = identifiers.steam,
            discordId = identifiers.discord,
            license = identifiers.license,
            ip = identifiers.ip,
            reason = cleanReason,
            staffIdentifier = session.identifier,
            staffName = session.name,
            duration = duration,
            unbanId = unbanId
        })

        -- Log
        Database.AddLog(
            Enums.LogCategory.SANCTION,
            Enums.LogAction.BAN_ADD,
            session.identifier,
            session.name,
            targetIdentifier,
            targetName,
            {reason = cleanReason, duration = duration, permanent = isPermanent, unbanId = unbanId}
        )

        -- Stats
        Database.UpdateDailyStat('bans_count', 1)

        -- Discord webhook
        if Discord and Discord.LogSanction then
            local sanctionType = isPermanent and 'ban_perm' or 'ban_temp'
            local targetData = {
                serverId = targetSource,
                discord = identifiers.discord,
                license = identifiers.license,
                steam = identifiers.steam,
                fivem = identifiers.fivem,
                unbanId = unbanId
            }
            Discord.LogSanction(sanctionType, session.name, targetName, cleanReason, duration, targetData)
        end

        -- Kick le joueur avec l'ID de deban
        local durationText = isPermanent and 'Permanent' or Helpers.FormatDuration(duration)
        DropPlayer(targetSource,
            'Vous avez ete banni.\n\n' ..
            'Raison: ' .. cleanReason .. '\n' ..
            'Duree: ' .. durationText .. '\n' ..
            'ID de deban: ' .. unbanId .. '\n\n' ..
            'Contestation: discord.gg/fightleague'
        )
    end)

    return true
end

-- Débannir un joueur
function Sanctions.Unban(staffSource, identifier)
    local valid, cleanId = Validators.Identifier(identifier)
    if not valid then return false, cleanId end

    local session = Auth.GetSession(staffSource)
    if not session then return false, Enums.ErrorCode.NO_PERMISSION end

    -- Verifier si le staff a la permission globale de unban (admin/owner)
    local hasGlobalUnban = Auth.HasPermission(staffSource, 'sanction.unban')

    -- Verifier le ban et qui l'a cree
    local p = promise.new()

    Database.IsPlayerBanned(cleanId, function(isBanned, banData)
        if not isBanned then
            p:resolve({success = false, error = 'NOT_BANNED'})
            return
        end

        -- Si le staff a la permission globale OU si c'est lui qui a banni
        local canUnban = hasGlobalUnban or (banData and banData.banned_by == session.identifier)

        if not canUnban then
            p:resolve({success = false, error = Enums.ErrorCode.NO_PERMISSION})
            return
        end

        -- Supprimer le ban
        Database.RemoveBan(cleanId, function()
            -- Mettre à jour le statut dans panel_sanctions
            Database.Execute([[
                UPDATE panel_sanctions
                SET status = 'revoked', revoked_by = ?, revoked_at = NOW()
                WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
                AND type IN ('ban_temp', 'ban_perm')
                AND status = 'active'
            ]], {session.identifier, cleanId})
        end)

        -- Log
        Database.AddLog(
            Enums.LogCategory.SANCTION,
            Enums.LogAction.BAN_REMOVE,
            session.identifier,
            session.name,
            cleanId,
            banData and banData.player_name or 'Inconnu',
            {originalBan = banData, ownBan = (banData and banData.banned_by == session.identifier)}
        )

        -- Discord webhook
        if Discord and Discord.LogUnban then
            Discord.LogUnban(session.name, banData and banData.player_name or 'Inconnu', cleanId)
        end

        p:resolve({success = true})
    end)

    local result = Citizen.Await(p)

    if not result.success then
        return false, result.error
    end

    return true
end

-- ══════════════════════════════════════════════════════════════
-- GESTION DES SEUILS
-- ══════════════════════════════════════════════════════════════

-- Vérifier les seuils d'avertissement
function Sanctions.CheckWarnThresholds(identifier, playerName)
    if not Config.Sanctions.WarnThresholds then return end

    -- Compter les warns actifs
    Database.Scalar([[
        SELECT COUNT(*) FROM panel_sanctions
        WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci AND type = 'warn' AND status = 'active'
    ]], {identifier}, function(warnCount)
        for _, threshold in ipairs(Config.Sanctions.WarnThresholds) do
            if warnCount >= threshold.count then
                if threshold.action == 'kick' then
                    -- Trouver le joueur connecté
                    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
                    if xPlayer then
                        DropPlayer(xPlayer.source, threshold.reason)
                    end
                elseif threshold.action == 'ban_temp' then
                    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
                    if xPlayer then
                        local unbanId = Database.GenerateUnbanId()
                        Database.AddBan({
                            identifier = identifier,
                            playerName = playerName,
                            reason = threshold.reason,
                            staffIdentifier = 'system',
                            staffName = 'Systeme Auto',
                            duration = threshold.duration,
                            unbanId = unbanId
                        })
                        DropPlayer(xPlayer.source, threshold.reason .. '\nID de deban: ' .. unbanId)
                    end
                elseif threshold.action == 'ban_perm' then
                    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
                    if xPlayer then
                        local unbanId = Database.GenerateUnbanId()
                        Database.AddBan({
                            identifier = identifier,
                            playerName = playerName,
                            reason = threshold.reason,
                            staffIdentifier = 'system',
                            staffName = 'Systeme Auto',
                            duration = -1,
                            unbanId = unbanId
                        })
                        DropPlayer(xPlayer.source, threshold.reason .. '\nID de deban: ' .. unbanId)
                    end
                end
                break
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- HISTORIQUE
-- ══════════════════════════════════════════════════════════════

-- Récupérer l'historique des sanctions
function Sanctions.GetHistory(filters, page, perPage)
    page = page or 1
    perPage = perPage or 20
    local offset = (page - 1) * perPage

    local where = {'1=1'}
    local params = {}

    if filters then
        -- Filtre par type de sanction
        if filters.type and filters.type ~= '' then
            table.insert(where, 's.type = ?')
            table.insert(params, filters.type)
        end

        -- Filtre par identifier exact
        if filters.targetIdentifier then
            table.insert(where, 's.target_identifier = ?')
            table.insert(params, filters.targetIdentifier)
        end

        -- Filtre par staff
        if filters.staffIdentifier then
            table.insert(where, 's.staff_identifier = ?')
            table.insert(params, filters.staffIdentifier)
        end

        -- Filtre par statut
        if filters.status and filters.status ~= '' then
            table.insert(where, 's.status = ?')
            table.insert(params, filters.status)
        end

        -- Recherche par nom, license OU Discord ID
        if filters.search and filters.search ~= '' then
            local searchPattern = '%' .. filters.search .. '%'
            -- Recherche dans nom, identifier et discord_id
            table.insert(where, '(s.target_name LIKE ? OR s.target_identifier LIKE ? OR b.discord_id LIKE ? OR b.discord_id = ?)')
            table.insert(params, searchPattern)
            table.insert(params, searchPattern)
            table.insert(params, searchPattern)
            -- Recherche exacte par Discord ID (avec ou sans préfixe discord:)
            local discordSearch = filters.search:gsub('^discord:', '')
            table.insert(params, 'discord:' .. discordSearch)
        end
    end

    table.insert(params, perPage)
    table.insert(params, offset)

    local query = string.format([[
        SELECT s.*, b.discord_id as target_discord
        FROM panel_sanctions s
        LEFT JOIN panel_bans b ON s.target_identifier COLLATE utf8mb4_general_ci = b.identifier COLLATE utf8mb4_general_ci
        WHERE %s
        ORDER BY s.created_at DESC
        LIMIT ? OFFSET ?
    ]], table.concat(where, ' AND '))

    return Database.QueryAsync(query, params)
end

-- Compter le nombre total de sanctions (pour pagination)
function Sanctions.GetCount(filters)
    local where = {'1=1'}
    local params = {}

    if filters then
        if filters.type and filters.type ~= '' then
            table.insert(where, 's.type = ?')
            table.insert(params, filters.type)
        end
        if filters.targetIdentifier then
            table.insert(where, 's.target_identifier = ?')
            table.insert(params, filters.targetIdentifier)
        end
        if filters.staffIdentifier then
            table.insert(where, 's.staff_identifier = ?')
            table.insert(params, filters.staffIdentifier)
        end
        if filters.status and filters.status ~= '' then
            table.insert(where, 's.status = ?')
            table.insert(params, filters.status)
        end
        -- Recherche par nom, license OU Discord ID
        if filters.search and filters.search ~= '' then
            local searchPattern = '%' .. filters.search .. '%'
            table.insert(where, '(s.target_name LIKE ? OR s.target_identifier LIKE ? OR b.discord_id LIKE ? OR b.discord_id = ?)')
            table.insert(params, searchPattern)
            table.insert(params, searchPattern)
            table.insert(params, searchPattern)
            local discordSearch = filters.search:gsub('^discord:', '')
            table.insert(params, 'discord:' .. discordSearch)
        end
    end

    local query = string.format([[
        SELECT COUNT(*) as count FROM panel_sanctions s
        LEFT JOIN panel_bans b ON s.target_identifier COLLATE utf8mb4_general_ci = b.identifier COLLATE utf8mb4_general_ci
        WHERE %s
    ]], table.concat(where, ' AND '))

    local result = Database.ScalarAsync(query, params)
    return result or 0
end

-- ══════════════════════════════════════════════════════════════
-- VÉRIFICATION À LA CONNEXION
-- ══════════════════════════════════════════════════════════════

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    deferrals.update('Verification du ban en cours...')

    if Config.Debug then print('^3[BAN CHECK]^0 Joueur qui se connecte: ' .. name) end

    -- Recuperer tous les identifiants
    local identifiers = Helpers.GetPlayerIdentifiers(source)
    local license = identifiers.license
    local discord = identifiers.discord
    local steam = identifiers.steam

    if Config.Debug then
        print('^3[BAN CHECK]^0 License: ' .. tostring(license))
        print('^3[BAN CHECK]^0 Discord: ' .. tostring(discord))
        print('^3[BAN CHECK]^0 Steam: ' .. tostring(steam))
    end

    if not license and not discord and not steam then
        if Config.Debug then print('^1[BAN CHECK]^0 Pas d identifier trouve!') end
        deferrals.done()
        return
    end

    -- Petit delai pour laisser oxmysql charger
    Wait(100)

    -- Fonction pour verifier les bans avec plusieurs identifiers
    local function checkAllIdentifiers(identifiersToCheck, index, callback)
        if index > #identifiersToCheck then
            callback(false, nil)
            return
        end

        local id = identifiersToCheck[index]
        if not id then
            checkAllIdentifiers(identifiersToCheck, index + 1, callback)
            return
        end

        Database.IsPlayerBanned(id, function(isBanned, banData)
            if isBanned then
                callback(true, banData)
            else
                checkAllIdentifiers(identifiersToCheck, index + 1, callback)
            end
        end)
    end

    -- Liste de tous les identifiers a verifier
    local allIdentifiers = {license, discord, steam}

    -- Aussi extraire les hashs sans prefixe
    if license then
        local hash = license:match(':(.+)')
        if hash then table.insert(allIdentifiers, hash) end
        table.insert(allIdentifiers, 'char0:' .. (hash or license))
    end

    checkAllIdentifiers(allIdentifiers, 1, function(isBanned, banData)
        if Config.Debug then print('^3[BAN CHECK]^0 Resultat ban check: ' .. tostring(isBanned)) end

        if isBanned then
            local reason = banData.reason or 'Non specifie'
            local unbanId = banData.unban_id or 'N/A'

            -- Formater la date d'expiration
            local expiresText = 'Permanent'
            if banData.expires_at then
                -- expires_at est un datetime MySQL, on le formate
                if type(banData.expires_at) == 'string' then
                    expiresText = banData.expires_at
                elseif type(banData.expires_at) == 'number' then
                    expiresText = os.date('%d/%m/%Y a %H:%M', banData.expires_at / 1000)
                end
            end

            if Config.Debug then print('^1[BAN CHECK]^0 JOUEUR BANNI - Refus de connexion! ID de deban: ' .. unbanId) end

            deferrals.done(
                '\n' ..
                '========================================\n' ..
                '       VOUS ETES BANNI DU SERVEUR       \n' ..
                '========================================\n' ..
                '\n' ..
                'Raison: ' .. reason .. '\n' ..
                'Expire: ' .. expiresText .. '\n' ..
                'ID de deban: ' .. unbanId .. '\n' ..
                '\n' ..
                '========================================\n' ..
                'Contestation: discord.gg/fightleague\n' ..
                '========================================'
            )
        else
            if Config.Debug then print('^2[BAN CHECK]^0 Joueur OK - pas banni') end
            deferrals.done()
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
-- EXPORTS
-- ══════════════════════════════════════════════════════════════

exports('isPlayerBanned', function(identifier)
    local p = promise.new()
    Database.IsPlayerBanned(identifier, function(isBanned)
        p:resolve(isBanned)
    end)
    return Citizen.Await(p)
end)

exports('addSanction', function(data)
    Database.AddSanction(data)
end)

exports('getPlayerSanctions', function(identifier)
    return Database.QueryAsync([[
        SELECT * FROM panel_sanctions WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci ORDER BY created_at DESC
    ]], {identifier})
end)

-- Export global
_G.Sanctions = Sanctions
