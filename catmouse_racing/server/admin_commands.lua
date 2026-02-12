--[[
    ═══════════════════════════════════════════════════════════
    👮 SERVEUR - COMMANDES ADMIN
    ═══════════════════════════════════════════════════════════
    
    Commandes d'administration pour gérer les courses.
    - /kickcourse [id] : Expulser un joueur de la course
    - /kickallcourse : Expulser tous les joueurs en course
    
    ✅ NOUVEAU: Système de groupes (owner, admin, staff, responsable)
]]

local SOURCE_FILE = 'server/admin_commands.lua'

-- ═══════════════════════════════════════════════════════════
-- 🛡️ VÉRIFICATION DES PERMISSIONS
-- ═══════════════════════════════════════════════════════════

--- Vérifie si un joueur a les permissions admin
---@param playerId number
---@return boolean
local function HasAdminPermission(playerId)
    -- ════════════════════════════════════════════════════════
    -- MÉTHODE 1: Vérification des GROUPES (Config.AdminGroups)
    -- ════════════════════════════════════════════════════════
    if Config.AdminGroups then
        for groupName, _ in pairs(Config.AdminGroups) do
            if IsPlayerAceAllowed(playerId, 'group.' .. groupName) then
                Utils.Debug('Permission accordée via groupe', { 
                    playerId = playerId, 
                    group = groupName 
                }, SOURCE_FILE)
                return true
            end
        end
    end
    
    -- ════════════════════════════════════════════════════════
    -- MÉTHODE 2: ACE Permissions directes (fallback)
    -- ════════════════════════════════════════════════════════
    if IsPlayerAceAllowed(playerId, 'command.kickcourse') then
        Utils.Debug('Permission accordée via ACE direct', { playerId = playerId }, SOURCE_FILE)
        return true
    end
    
    -- ════════════════════════════════════════════════════════
    -- MÉTHODE 3: Liste d'identifiants hardcodée (fallback ultime)
    -- ════════════════════════════════════════════════════════
    -- IMPORTANT: Modifier cette liste avec vos identifiants admin
    local adminIdentifiers = {
        -- 'license:XXXXXXXXX',
        -- 'steam:XXXXXXXXXX',
        -- 'discord:XXXXXXXXX'
    }
    
    local playerIdentifiers = GetPlayerIdentifiers(playerId)
    if playerIdentifiers then
        for _, adminId in ipairs(adminIdentifiers) do
            for _, playerId in ipairs(playerIdentifiers) do
                if playerId == adminId then
                    Utils.Debug('Permission accordée via identifiant hardcodé', { 
                        playerId = playerId 
                    }, SOURCE_FILE)
                    return true
                end
            end
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 🚫 FONCTION D'EXPULSION
-- ═══════════════════════════════════════════════════════════

--- Expulse un joueur de la course (nettoyage complet)
---@param targetId number ID du joueur à expulser
---@param adminId number ID de l'admin qui expulse
---@return boolean success
local function KickPlayerFromRace(targetId, adminId)
    local adminName = GetPlayerName(adminId) or 'Admin'
    local targetName = GetPlayerName(targetId) or 'Joueur'
    
    Utils.Debug('Tentative d\'expulsion', {
        admin = adminName,
        target = targetName
    }, SOURCE_FILE)
    
    -- Vérifier si le joueur est en course
    local bucketId = RaceManager.PlayerRaces[targetId]
    
    if not bucketId then
        Utils.Debug('Joueur pas en course', { targetId = targetId }, SOURCE_FILE)
        return false
    end
    
    local session = RaceManager.ActiveRaces[bucketId]
    
    if not session then
        Utils.Debug('Session introuvable', { bucketId = bucketId }, SOURCE_FILE)
        -- Nettoyage de l'incohérence
        RaceManager.PlayerRaces[targetId] = nil
        return false
    end
    
    -- Récupérer les données des joueurs
    local kickedPlayer = RaceManager.GetPlayerData(session, targetId)
    local opponent = RaceManager.GetOpponent(session, targetId)
    
    Utils.Info('Expulsion en cours', {
        admin = adminName,
        kicked = targetName,
        opponent = opponent and opponent.name or 'N/A',
        status = Utils.GetStatusName(session.status),
        round = session.currentRound .. '/' .. session.maxRounds
    })
    
    -- ════════════════════════════════════════════════════════
    -- 📢 NOTIFICATION AU JOUEUR EXPULSÉ
    -- ════════════════════════════════════════════════════════
    TriggerClientEvent(Constants.Events.NOTIFY, targetId, {
        type = Constants.NotificationType.ERROR,
        message = '⚠️ Vous avez été expulsé de la course par un administrateur.'
    })
    
    -- ════════════════════════════════════════════════════════
    -- 🧹 NETTOYAGE COMPLET CÔTÉ CLIENT
    -- ════════════════════════════════════════════════════════
    -- Forcer la fin de course côté client (nettoyage total)
    TriggerClientEvent('catmouse:forceKick', targetId)
    
    -- Retour au bucket 0
    SetPlayerRoutingBucket(targetId, 0)
    RaceManager.PlayerRaces[targetId] = nil
    
    -- ════════════════════════════════════════════════════════
    -- 🏆 GESTION DE L'ADVERSAIRE (si existant)
    -- ════════════════════════════════════════════════════════
    if opponent then
        Utils.Info('Gestion adversaire - Victoire par forfait', {
            winner = opponent.name
        })
        
        -- ════════════════════════════════════════════════════
        -- 💎 APPLICATION ELO (Victoire par forfait admin)
        -- ════════════════════════════════════════════════════
        if Config.Elo and Config.Elo.enabled and EloSystem then
            if kickedPlayer.identifier and opponent.identifier then
                Utils.Debug('Application ELO (expulsion admin)', {
                    kicked = kickedPlayer.identifier,
                    winner = opponent.identifier
                }, SOURCE_FILE)
                
                EloSystem.UpdateMatchResult(
                    opponent.identifier,       -- Gagnant
                    kickedPlayer.identifier,   -- Perdant (expulsé)
                    opponent.name,
                    kickedPlayer.name,
                    session.maxRounds,         -- Score max pour le gagnant
                    0,                         -- 0 pour le perdant
                    function(success, eloChange, winnerNewElo, loserNewElo)
                        if success then
                            Utils.Info('ELO mis à jour (expulsion)', {
                                winner = string.format('%s: +%d (→ %d)', opponent.name, eloChange, winnerNewElo),
                                kicked = string.format('%s: -%d (→ %d)', kickedPlayer.name, eloChange, loserNewElo)
                            })
                            
                            -- Notifier le gagnant
                            TriggerClientEvent(Constants.Events.NOTIFY, opponent.id, {
                                type = Constants.NotificationType.SUCCESS,
                                message = Utils.FormatText(Config.Texts.elo_gain, eloChange, winnerNewElo - eloChange, winnerNewElo)
                            })
                            
                            -- Invalider le cache du leaderboard
                            if InvalidateLeaderboardCache then
                                InvalidateLeaderboardCache()
                            end
                        end
                    end
                )
            end
        end
        
        -- Notifier l'adversaire
        TriggerClientEvent(Constants.Events.NOTIFY, opponent.id, {
            type = Constants.NotificationType.WARNING,
            message = targetName .. ' a été expulsé de la course. Vous gagnez par forfait !'
        })
        
        -- Forcer la fin du match côté adversaire
        TriggerClientEvent(Constants.Events.END_RACE, opponent.id, {
            isWinner = true,
            winnerId = opponent.id,
            winnerName = opponent.name,
            finalScores = {
                [opponent.id] = session.maxRounds,
                [targetId] = 0
            },
            forfeit = true,
            quitterName = targetName,
            adminKick = true  -- Flag spécial pour indiquer kick admin
        })
    end
    
    -- ════════════════════════════════════════════════════════
    -- 🗑️ NETTOYAGE SESSION
    -- ════════════════════════════════════════════════════════
    Utils.Debug('Libération du bucket', { bucketId = bucketId }, SOURCE_FILE)
    RaceManager.ReleaseBucket(bucketId)
    
    return true
end

-- ═══════════════════════════════════════════════════════════
-- 🎮 COMMANDES
-- ═══════════════════════════════════════════════════════════

--- Commande /kickcourse [id]
RegisterCommand('kickcourse', function(source, args)
    local adminId = source
    local adminName = GetPlayerName(adminId) or 'Admin'
    
    Utils.Debug('Commande /kickcourse', { admin = adminName, args = args }, SOURCE_FILE)
    
    -- ════════════════════════════════════════════════════════
    -- 🛡️ VÉRIFICATION PERMISSIONS
    -- ════════════════════════════════════════════════════════
    if not HasAdminPermission(adminId) then
        Utils.Warn('Permission refusée', { playerId = adminId, name = adminName }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.ERROR,
            message = '❌ Vous n\'avez pas la permission d\'utiliser cette commande.'
        })
        return
    end
    
    -- ════════════════════════════════════════════════════════
    -- ✅ VALIDATION DES ARGUMENTS
    -- ════════════════════════════════════════════════════════
    if #args < 1 then
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.WARNING,
            message = '⚠️ Usage: /kickcourse [ID du joueur]'
        })
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId or not Utils.IsValidServerId(targetId) then
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.ERROR,
            message = '❌ ID de joueur invalide.'
        })
        return
    end
    
    -- Vérifier que le joueur existe
    if GetPlayerPing(targetId) == 0 then
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.ERROR,
            message = '❌ Joueur introuvable ou hors ligne.'
        })
        return
    end
    
    -- ════════════════════════════════════════════════════════
    -- 🚫 EXPULSION
    -- ════════════════════════════════════════════════════════
    local success = KickPlayerFromRace(targetId, adminId)
    
    if success then
        local targetName = GetPlayerName(targetId) or 'Joueur'
        
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.SUCCESS,
            message = '✅ ' .. targetName .. ' a été expulsé de la course.'
        })
        
        Utils.Info('Expulsion réussie', {
            admin = adminName,
            kicked = targetName
        })
    else
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.WARNING,
            message = '⚠️ Ce joueur n\'est pas en course.'
        })
    end
end, false)

-- Suggestion de commande
TriggerEvent('chat:addSuggestion', '/kickcourse', 'Expulser un joueur de la course', {
    { name = 'ID', help = 'ID du joueur à expulser' }
})

-- ═══════════════════════════════════════════════════════════
--- Commande /kickallcourse
-- ═══════════════════════════════════════════════════════════

RegisterCommand('kickallcourse', function(source)
    local adminId = source
    local adminName = GetPlayerName(adminId) or 'Admin'
    
    Utils.Debug('Commande /kickallcourse', { admin = adminName }, SOURCE_FILE)
    
    -- ════════════════════════════════════════════════════════
    -- 🛡️ VÉRIFICATION PERMISSIONS
    -- ════════════════════════════════════════════════════════
    if not HasAdminPermission(adminId) then
        Utils.Warn('Permission refusée', { playerId = adminId, name = adminName }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.ERROR,
            message = '❌ Vous n\'avez pas la permission d\'utiliser cette commande.'
        })
        return
    end
    
    -- ════════════════════════════════════════════════════════
    -- 🔍 RÉCUPÉRATION DES JOUEURS EN COURSE
    -- ════════════════════════════════════════════════════════
    local playersToKick = {}
    
    for playerId, bucketId in pairs(RaceManager.PlayerRaces) do
        table.insert(playersToKick, playerId)
    end
    
    if #playersToKick == 0 then
        TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
            type = Constants.NotificationType.WARNING,
            message = '⚠️ Aucun joueur n\'est actuellement en course.'
        })
        return
    end
    
    Utils.Info('Expulsion de tous les joueurs', {
        admin = adminName,
        count = #playersToKick
    })
    
    -- ════════════════════════════════════════════════════════
    -- 🚫 EXPULSION EN MASSE
    -- ════════════════════════════════════════════════════════
    local kickedCount = 0
    
    for _, playerId in ipairs(playersToKick) do
        local success = KickPlayerFromRace(playerId, adminId)
        if success then
            kickedCount = kickedCount + 1
        end
    end
    
    -- ════════════════════════════════════════════════════════
    -- 📢 NOTIFICATION FINALE
    -- ════════════════════════════════════════════════════════
    TriggerClientEvent(Constants.Events.NOTIFY, adminId, {
        type = Constants.NotificationType.SUCCESS,
        message = '✅ ' .. kickedCount .. ' joueur(s) expulsé(s) de toutes les courses.'
    })
    
    Utils.Info('Expulsion massive terminée', {
        admin = adminName,
        kicked = kickedCount,
        total = #playersToKick
    })
end, false)

-- Suggestion de commande
TriggerEvent('chat:addSuggestion', '/kickallcourse', 'Expulser tous les joueurs des courses')

-- ═══════════════════════════════════════════════════════════
-- 🐛 COMMANDE DEBUG (si Config.Debug activé)
-- ═══════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('race_list_players', function(source)
        if not HasAdminPermission(source) then return end
        
        Utils.Info('=== JOUEURS EN COURSE ===')
        
        local count = 0
        for playerId, bucketId in pairs(RaceManager.PlayerRaces) do
            local playerName = GetPlayerName(playerId) or 'Joueur'
            Utils.Info('  - ' .. playerName .. ' (ID: ' .. playerId .. ') | Bucket: ' .. bucketId)
            count = count + 1
        end
        
        if count == 0 then
            Utils.Info('  Aucun joueur en course')
        else
            Utils.Info('Total: ' .. count .. ' joueur(s)')
        end
    end, false)
    
    -- Commande pour tester les permissions
    RegisterCommand('race_test_perms', function(source)
        local playerName = GetPlayerName(source) or 'Joueur'
        
        
        -- Test des groupes
        if Config.AdminGroups then
            for groupName, _ in pairs(Config.AdminGroups) do
                local hasGroup = IsPlayerAceAllowed(source, 'group.' .. groupName)
            end
        end
        
        -- Test ACE direct
        local hasACE = IsPlayerAceAllowed(source, 'command.kickcourse')
        
        -- Résultat final
        local hasPerm = HasAdminPermission(source)
        
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = hasPerm and Constants.NotificationType.SUCCESS or Constants.NotificationType.ERROR,
            message = hasPerm and '✅ Vous avez les permissions admin' or '❌ Vous n\'avez PAS les permissions admin'
        })
    end, false)
    
    TriggerEvent('chat:addSuggestion', '/race_list_players', 'Lister tous les joueurs en course')
    TriggerEvent('chat:addSuggestion', '/race_test_perms', 'Tester vos permissions admin')
end
