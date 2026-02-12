--[[
    ═══════════════════════════════════════════════════════════
    📡 SERVEUR - GESTION DES ÉVÉNEMENTS RÉSEAU (SÉCURISÉ)
    ═══════════════════════════════════════════════════════════
    
    ✅ NOUVEAU: Gestion complète des déconnexions
    ✅ Application ELO sur déconnexion (pénalité)
    ✅ Nettoyage automatique des ressources
    ✅ Protection contre les blocages
]]

local SOURCE_FILE = 'server/events.lua'

-- ═══════════════════════════════════════════════════════════
-- 📨 INVITATIONS
-- ═══════════════════════════════════════════════════════════

--- Envoi d'une invitation
RegisterNetEvent(Constants.Events.SEND_INVITATION, function(targetId)
    local source = source
    local targetIdNum = tonumber(targetId)
    
    Utils.Debug('Event SEND_INVITATION', { source = source, target = targetIdNum }, SOURCE_FILE)
    
    -- === VALIDATIONS ===
    
    if not Utils.IsValidServerId(targetIdNum) then
        Utils.Debug('ID cible invalide', { targetId = targetId }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.cmd_invalid_id
        })
        return
    end
    
    if Config.Security.preventSelfInvite and source == targetIdNum then
        Utils.Debug('Auto-invitation bloquée', { source = source }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.cannot_invite_self
        })
        return
    end
    
    if Config.Security.checkPlayerOnline and GetPlayerPing(targetIdNum) == 0 then
        Utils.Debug('Joueur cible hors ligne', { targetId = targetIdNum }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.player_not_found
        })
        return
    end
    
    if Config.Security.checkAlreadyInRace then
        if RaceManager.IsPlayerInRace(source) then
            Utils.Debug('Source déjà en course', { source = source }, SOURCE_FILE)
            TriggerClientEvent(Constants.Events.NOTIFY, source, {
                type = Constants.NotificationType.WARNING,
                message = Config.Texts.already_in_race
            })
            return
        end
        
        if RaceManager.IsPlayerInRace(targetIdNum) then
            Utils.Debug('Cible déjà en course', { targetId = targetIdNum }, SOURCE_FILE)
            TriggerClientEvent(Constants.Events.NOTIFY, source, {
                type = Constants.NotificationType.WARNING,
                message = Config.Texts.target_in_race
            })
            return
        end
    end
    
    if Config.Security.checkAlreadyInQueue then
        if Matchmaking.IsInQueue(source) then
            Utils.Debug('Source déjà en queue', { source = source }, SOURCE_FILE)
            TriggerClientEvent(Constants.Events.NOTIFY, source, {
                type = Constants.NotificationType.WARNING,
                message = Config.Texts.queue_already
            })
            return
        end
    end
    
    -- === CRÉATION DE L'INVITATION ===
    
    local inviteId = Utils.GenerateId()
    local senderName = GetPlayerName(source) or 'Joueur'
    local targetName = GetPlayerName(targetIdNum) or 'Joueur'
    
    RaceManager.PendingInvites[inviteId] = {
        sender = source,
        target = targetIdNum,
        senderName = senderName,
        targetName = targetName,
        timestamp = Utils.GetTimestamp()
    }
    
    Utils.Info('Invitation créée', {
        inviteId = inviteId,
        sender = senderName .. ' (#' .. source .. ')',
        target = targetName .. ' (#' .. targetIdNum .. ')'
    })
    
    -- Notification à l'envoyeur
    TriggerClientEvent(Constants.Events.NOTIFY, source, {
        type = Constants.NotificationType.SUCCESS,
        message = Utils.FormatText(Config.Texts.invite_sent, targetName)
    })
    
    -- Notification au destinataire
    TriggerClientEvent(Constants.Events.RECEIVE_INVITATION, targetIdNum, {
        inviteId = inviteId,
        senderId = source,
        senderName = senderName
    })
end)

--- Acceptation d'une invitation
RegisterNetEvent(Constants.Events.ACCEPT_INVITATION, function(inviteId)
    local source = source
    
    Utils.Debug('Event ACCEPT_INVITATION', { source = source, inviteId = inviteId }, SOURCE_FILE)
    
    local invite = RaceManager.PendingInvites[inviteId]
    
    if not invite then
        Utils.Debug('Invitation introuvable ou expirée', { inviteId = inviteId }, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.invite_expired
        })
        return
    end
    
    -- Vérifier que c'est bien le destinataire
    if invite.target ~= source then
        Utils.Warn('Tentative d\'accepter une invitation non destinée', {
            inviteId = inviteId,
            actualTarget = invite.target,
            source = source
        }, SOURCE_FILE)
        return
    end
    
    -- Vérifications avant lancement
    if RaceManager.IsPlayerInRace(invite.sender) then
        Utils.Debug('L\'envoyeur est maintenant en course', nil, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = 'L\'envoyeur est maintenant en course.'
        })
        RaceManager.PendingInvites[inviteId] = nil
        return
    end
    
    if RaceManager.IsPlayerInRace(source) then
        Utils.Debug('Le destinataire est maintenant en course', nil, SOURCE_FILE)
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.already_in_race
        })
        RaceManager.PendingInvites[inviteId] = nil
        return
    end
    
    -- Supprimer l'invitation
    RaceManager.PendingInvites[inviteId] = nil
    
    Utils.Info('Invitation acceptée', {
        sender = invite.senderName,
        target = invite.targetName
    })
    
    -- Notifier l'envoyeur
    TriggerClientEvent(Constants.Events.NOTIFY, invite.sender, {
        type = Constants.NotificationType.SUCCESS,
        message = Utils.FormatText(Config.Texts.invite_accepted, invite.targetName)
    })
    
    -- Créer la session
    local session = RaceManager.CreateSession(invite.sender, invite.target)
    
    if session then
        -- Démarrer le premier round
        RaceManager.StartRound(session.bucketId)
    else
        Utils.Error('Échec création session après acceptation', nil, SOURCE_FILE)
        
        TriggerClientEvent(Constants.Events.NOTIFY, invite.sender, {
            type = Constants.NotificationType.ERROR,
            message = 'Erreur lors de la création de la partie.'
        })
        TriggerClientEvent(Constants.Events.NOTIFY, source, {
            type = Constants.NotificationType.ERROR,
            message = 'Erreur lors de la création de la partie.'
        })
    end
end)

--- Refus d'une invitation
RegisterNetEvent(Constants.Events.DECLINE_INVITATION, function(inviteId)
    local source = source
    
    Utils.Debug('Event DECLINE_INVITATION', { source = source, inviteId = inviteId }, SOURCE_FILE)
    
    local invite = RaceManager.PendingInvites[inviteId]
    
    if not invite then return end
    
    -- Vérifier que c'est bien le destinataire
    if invite.target ~= source then
        Utils.Warn('Tentative de refuser une invitation non destinée', {
            inviteId = inviteId,
            actualTarget = invite.target,
            source = source
        }, SOURCE_FILE)
        return
    end
    
    -- Supprimer l'invitation
    RaceManager.PendingInvites[inviteId] = nil
    
    Utils.Debug('Invitation refusée', { inviteId = inviteId }, SOURCE_FILE)
    
    -- Notifier l'envoyeur
    TriggerClientEvent(Constants.Events.NOTIFY, invite.sender, {
        type = Constants.NotificationType.WARNING,
        message = Utils.FormatText(Config.Texts.invite_declined, invite.targetName)
    })
end)

-- ═══════════════════════════════════════════════════════════
-- 🏁 COURSE
-- ═══════════════════════════════════════════════════════════

--- Notification que le client est prêt (véhicule spawné)
RegisterNetEvent('catmouse:clientReady', function(vehicleNetId)
    local source = source
    
    Utils.Debug('Event clientReady', { source = source, vehicleNetId = vehicleNetId }, SOURCE_FILE)
    
    local session = RaceManager.GetPlayerSession(source)
    if not session then
        Utils.Error('Session introuvable pour clientReady', { source = source }, SOURCE_FILE)
        return
    end
    
    -- Enregistrer le véhicule
    local playerData = RaceManager.GetPlayerData(session, source)
    if playerData then
        playerData.vehicleNetId = vehicleNetId
    end
    
    -- Vérifier si les deux joueurs sont prêts
    local allReady = true
    for _, player in ipairs(session.players) do
        if not player.vehicleNetId then
            allReady = false
            break
        end
    end
    
    if allReady then
        Utils.Info('Tous les joueurs sont prêts - Démarrage countdown', {
            bucketId = session.bucketId
        })
        
        -- Démarrer le countdown
        session.status = Constants.RaceStatus.COUNTDOWN
        
        for _, player in ipairs(session.players) do
            TriggerClientEvent(Constants.Events.START_COUNTDOWN, player.id, {
                duration = Config.Race.countdownDuration
            })
        end
        
        -- Démarrage immédiat (pas de countdown)
        SetTimeout(500, function()
            RaceManager.StartRaceActive(session.bucketId)
        end)
    end
end)

--- Notification de capture réussie
RegisterNetEvent('catmouse:captureComplete', function()
    local source = source
    
    Utils.Debug('Event captureComplete', { source = source }, SOURCE_FILE)
    
    local session = RaceManager.GetPlayerSession(source)
    if not session then return end
    
    local playerData = RaceManager.GetPlayerData(session, source)
    if not playerData or playerData.role ~= Constants.Role.HUNTER then
        Utils.Warn('captureComplete reçu d\'un non-chasseur', { source = source }, SOURCE_FILE)
        return
    end
    
    -- Le chasseur a capturé le fuyard
    RaceManager.EndRound(session.bucketId, Constants.RoundResult.RUNNER_CAPTURED, source)
end)

--- Notification d'évasion réussie
RegisterNetEvent('catmouse:escapeComplete', function()
    local source = source
    
    Utils.Debug('Event escapeComplete', { source = source }, SOURCE_FILE)
    
    local session = RaceManager.GetPlayerSession(source)
    if not session then return end
    
    local playerData = RaceManager.GetPlayerData(session, source)
    if not playerData or playerData.role ~= Constants.Role.RUNNER then
        Utils.Warn('escapeComplete reçu d\'un non-fuyard', { source = source }, SOURCE_FILE)
        return
    end
    
    -- Le fuyard s'est échappé
    RaceManager.EndRound(session.bucketId, Constants.RoundResult.RUNNER_ESCAPED, source)
end)

--- Notification de fin de timer
RegisterNetEvent('catmouse:timerExpired', function()
    local source = source
    
    Utils.Debug('Event timerExpired', { source = source }, SOURCE_FILE)
    
    local session = RaceManager.GetPlayerSession(source)
    if not session then return end
    
    -- Seul le serveur peut décider de la fin de round
    -- On vérifie que c'est bien le fuyard qui notifie (car c'est lui qui perd)
    local playerData = RaceManager.GetPlayerData(session, source)
    if not playerData then return end
    
    -- Trouver le chasseur (gagnant par défaut)
    local hunter = RaceManager.GetPlayerByRole(session, Constants.Role.HUNTER)
    if hunter then
        RaceManager.EndRound(session.bucketId, Constants.RoundResult.TIME_UP, hunter.id)
    end
end)

--- Quitter la course (AMÉLIORÉ: Gestion ELO)
RegisterNetEvent(Constants.Events.LEAVE_RACE, function()
    local source = source
    local playerName = GetPlayerName(source) or 'Joueur'
    
    Utils.Debug('Event LEAVE_RACE', { source = source, name = playerName }, SOURCE_FILE)
    
    local bucketId = RaceManager.PlayerRaces[source]
    if not bucketId then return end
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then return end
    
    -- Trouver l'adversaire et le joueur qui quitte
    local quitter = RaceManager.GetPlayerData(session, source)
    local opponent = RaceManager.GetOpponent(session, source)
    
    if opponent and quitter then
        Utils.Info('Joueur a quitté volontairement - Victoire par forfait', {
            quitter = playerName,
            winner = opponent.name
        })
        
        -- ════════════════════════════════════════════════════════
        -- 🏆 GESTION ELO POUR ABANDON VOLONTAIRE
        -- ════════════════════════════════════════════════════════
        if Config.Elo and Config.Elo.enabled and EloSystem then
            if quitter.identifier and opponent.identifier then
                Utils.Debug('Application pénalité ELO pour abandon', {
                    quitter = quitter.identifier,
                    winner = opponent.identifier
                }, SOURCE_FILE)
                
                EloSystem.UpdateMatchResult(
                    opponent.identifier,     -- Gagnant
                    quitter.identifier,      -- Perdant (abandon)
                    opponent.name,
                    quitter.name,
                    session.maxRounds,       -- Score max pour le gagnant
                    0,                       -- 0 pour celui qui quitte
                    function(success, eloChange, winnerNewElo, loserNewElo)
                        if success then
                            Utils.Info('ELO mis à jour (abandon)', {
                                winner = string.format('%s: +%d (→ %d)', opponent.name, eloChange, winnerNewElo),
                                quitter = string.format('%s: -%d (→ %d)', quitter.name, eloChange, loserNewElo)
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
            type = Constants.NotificationType.SUCCESS,
            message = playerName .. ' a quitté la partie. Vous gagnez par forfait !'
        })
        
        -- Forcer la fin côté adversaire
        TriggerClientEvent(Constants.Events.END_RACE, opponent.id, {
            isWinner = true,
            winnerId = opponent.id,
            winnerName = opponent.name,
            finalScores = {
                [opponent.id] = session.maxRounds,
                [source] = 0
            },
            forfeit = true,
            quitterName = playerName
        })
        
        -- Fin du match
        RaceManager.ReleaseBucket(bucketId)
    else
        RaceManager.ReleaseBucket(bucketId)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 🔌 DÉCONNEXION SÉCURISÉE (NOUVEAU SYSTÈME)
-- ═══════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source) or 'Joueur'
    
    Utils.Warn('Joueur déconnecté', { 
        playerId = source,
        name = playerName,
        reason = reason 
    }, SOURCE_FILE)
    
    -- ════════════════════════════════════════════════════════
    -- 🧹 NETTOYAGE DES INVITATIONS
    -- ════════════════════════════════════════════════════════
    for inviteId, invite in pairs(RaceManager.PendingInvites) do
        if invite.sender == source or invite.target == source then
            -- Notifier l'autre joueur si en ligne
            local otherPlayer = invite.sender == source and invite.target or invite.sender
            if Utils.IsValidServerId(otherPlayer) and GetPlayerPing(otherPlayer) > 0 then
                TriggerClientEvent(Constants.Events.NOTIFY, otherPlayer, {
                    type = Constants.NotificationType.WARNING,
                    message = playerName .. ' s\'est déconnecté. L\'invitation est annulée.'
                })
            end
            
            RaceManager.PendingInvites[inviteId] = nil
            Utils.Debug('Invitation supprimée (déconnexion)', { inviteId = inviteId }, SOURCE_FILE)
        end
    end
    
    -- ════════════════════════════════════════════════════════
    -- 🏁 GESTION COURSE EN COURS (AVEC ELO)
    -- ════════════════════════════════════════════════════════
    local bucketId = RaceManager.PlayerRaces[source]
    if bucketId then
        local session = RaceManager.ActiveRaces[bucketId]
        
        if session then
            local disconnectedPlayer = RaceManager.GetPlayerData(session, source)
            local opponent = RaceManager.GetOpponent(session, source)
            
            if opponent and disconnectedPlayer then
                Utils.Info('Déconnexion en pleine course - Victoire par forfait', {
                    disconnected = playerName,
                    winner = opponent.name,
                    status = Utils.GetStatusName(session.status),
                    round = session.currentRound .. '/' .. session.maxRounds
                })
                
                -- ════════════════════════════════════════════════
                -- 🏆 GESTION ELO POUR DÉCONNEXION
                -- ════════════════════════════════════════════════
                if Config.Elo and Config.Elo.enabled and EloSystem then
                    if disconnectedPlayer.identifier and opponent.identifier then
                        Utils.Debug('Application pénalité ELO pour déconnexion', {
                            disconnected = disconnectedPlayer.identifier,
                            winner = opponent.identifier
                        }, SOURCE_FILE)
                        
                        -- Le joueur déconnecté PERD l'ELO
                        -- L'adversaire GAGNE l'ELO (victoire par forfait)
                        EloSystem.UpdateMatchResult(
                            opponent.identifier,          -- Gagnant
                            disconnectedPlayer.identifier, -- Perdant (déconnecté)
                            opponent.name,
                            disconnectedPlayer.name,
                            session.maxRounds,            -- Score max pour le gagnant
                            0,                            -- 0 pour le perdant (forfait)
                            function(success, eloChange, winnerNewElo, loserNewElo)
                                if success then
                                    Utils.Info('ELO mis à jour (déconnexion)', {
                                        winner = string.format('%s: +%d (→ %d)', opponent.name, eloChange, winnerNewElo),
                                        disconnected = string.format('%s: -%d (→ %d)', disconnectedPlayer.name, eloChange, loserNewElo)
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
                                else
                                    Utils.Error('Échec mise à jour ELO (déconnexion)', nil, SOURCE_FILE)
                                end
                            end
                        )
                    else
                        Utils.Warn('Identifiants manquants pour ELO (déconnexion)', {
                            disconnectedIdentifier = disconnectedPlayer.identifier,
                            opponentIdentifier = opponent.identifier
                        }, SOURCE_FILE)
                    end
                end
                
                -- ════════════════════════════════════════════════
                -- 📢 NOTIFICATION À L'ADVERSAIRE
                -- ════════════════════════════════════════════════
                TriggerClientEvent(Constants.Events.NOTIFY, opponent.id, {
                    type = Constants.NotificationType.WARNING,
                    message = playerName .. ' s\'est déconnecté. Vous gagnez par forfait !'
                })
                
                -- ════════════════════════════════════════════════
                -- 🧹 NETTOYAGE COMPLET POUR L'ADVERSAIRE
                -- ════════════════════════════════════════════════
                -- Forcer la fin du match côté client de l'adversaire
                TriggerClientEvent(Constants.Events.END_RACE, opponent.id, {
                    isWinner = true,
                    winnerId = opponent.id,
                    winnerName = opponent.name,
                    finalScores = {
                        [opponent.id] = session.maxRounds,
                        [source] = 0
                    },
                    disconnection = true,  -- Flag pour indiquer une déconnexion
                    disconnectedPlayerName = playerName
                })
                
                -- Nettoyer la session immédiatement
                Utils.Debug('Nettoyage session (déconnexion)', { bucketId = bucketId }, SOURCE_FILE)
                RaceManager.ReleaseBucket(bucketId)
                
            else
                -- Pas d'adversaire trouvé (cas rare)
                Utils.Warn('Adversaire introuvable lors de la déconnexion', { bucketId = bucketId }, SOURCE_FILE)
                RaceManager.ReleaseBucket(bucketId)
            end
        else
            -- Session introuvable mais bucket assigné (incohérence)
            Utils.Warn('Session introuvable mais bucket assigné', { 
                playerId = source, 
                bucketId = bucketId 
            }, SOURCE_FILE)
            RaceManager.PlayerRaces[source] = nil
        end
    end
    
    -- ════════════════════════════════════════════════════════
    -- 🔍 NETTOYAGE MATCHMAKING
    -- ════════════════════════════════════════════════════════
    Matchmaking.LeaveQueue(source)
    
    Utils.Debug('Nettoyage complet terminé (déconnexion)', { playerId = source }, SOURCE_FILE)
end)
