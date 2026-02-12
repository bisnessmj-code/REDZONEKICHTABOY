--[[
    ═══════════════════════════════════════════════════════════
    🖥️ SERVEUR - GESTION DES SESSIONS DE COURSE
    ═══════════════════════════════════════════════════════════
    
    Gestion des sessions de course, les routing buckets,
    les rounds et les scores.
    
    ✅ Sélection aléatoire du véhicule par match
    ✅ Sélection aléatoire des spawns par match
    ✅ Les deux joueurs ont TOUJOURS le même véhicule et spawn
]]

local SOURCE_FILE = 'server/race_session.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 STOCKAGE DES DONNÉES
-- ═══════════════════════════════════════════════════════════

RaceManager = RaceManager or {}

-- Sessions actives : [bucketId] = RaceSession
RaceManager.ActiveRaces = {}

-- Invitations en attente : [inviteId] = InviteData
RaceManager.PendingInvites = {}

-- Mapping joueur -> bucket : [playerId] = bucketId
RaceManager.PlayerRaces = {}

-- Pool de buckets disponibles
RaceManager.AvailableBuckets = {}

-- ═══════════════════════════════════════════════════════════
-- 🚗 SÉLECTION DU VÉHICULE
-- ═══════════════════════════════════════════════════════════

--- Choisit un véhicule aléatoire dans la liste
---@return string vehicleModel
function RaceManager.SelectRandomVehicle()
    if not Config.Vehicle.randomSelection then
        -- Mode non-aléatoire : toujours le premier véhicule
        local firstVehicle = Config.Vehicle.availableModels[1]
        Utils.Debug('Véhicule fixe sélectionné', { model = firstVehicle }, SOURCE_FILE)
        return firstVehicle
    end
    
    -- Sélection aléatoire
    local vehicleCount = #Config.Vehicle.availableModels
    
    -- Utiliser un seed basé sur le timestamp pour plus d'aléatoire
    local randomSeed = os.time() + GetGameTimer()
    math.randomseed(randomSeed)
    
    -- "Chauffer" le générateur
    for i = 1, 5 do
        math.random()
    end
    
    local randomIndex = math.random(1, vehicleCount)
    local selectedVehicle = Config.Vehicle.availableModels[randomIndex]
    
    Utils.Info('🚗 Véhicule aléatoire sélectionné', { 
        model = selectedVehicle,
        index = randomIndex,
        total = vehicleCount,
        seed = randomSeed,
        availableModels = Config.Vehicle.availableModels
    })
    
    return selectedVehicle
end

-- ═══════════════════════════════════════════════════════════
-- 📍 SÉLECTION DU SPAWN (NOUVEAU)
-- ═══════════════════════════════════════════════════════════

--- Choisit un set de spawns aléatoire dans la liste
---@return table spawnSet { name, runner, hunter }
function RaceManager.SelectRandomSpawn()
    if not Config.Positions.randomSpawns then
        -- Mode non-aléatoire : toujours le premier set
        local firstSpawn = Config.Positions.spawns[1]
        Utils.Debug('Spawn fixe sélectionné', { location = firstSpawn.name }, SOURCE_FILE)
        return firstSpawn
    end
    
    -- Sélection aléatoire
    local spawnCount = #Config.Positions.spawns
    
    -- Utiliser un seed basé sur le timestamp pour plus d'aléatoire
    local randomSeed = os.time() + GetGameTimer()
    math.randomseed(randomSeed)
    
    -- "Chauffer" le générateur
    for i = 1, 5 do
        math.random()
    end
    
    local randomIndex = math.random(1, spawnCount)
    local selectedSpawn = Config.Positions.spawns[randomIndex]
    
    Utils.Info('📍 Spawn aléatoire sélectionné', { 
        location = selectedSpawn.name,
        index = randomIndex,
        total = spawnCount,
        seed = randomSeed
    })
    
    return selectedSpawn
end

-- ═══════════════════════════════════════════════════════════
-- 🏗️ STRUCTURE DES DONNÉES
-- ═══════════════════════════════════════════════════════════

--[[
    RaceSession = {
        bucketId = number,
        status = Constants.RaceStatus,
        currentRound = number,
        maxRounds = number,
        vehicleModel = string,
        spawnLocation = table,    -- { name, runner, hunter }
        players = {
            [1] = {
                id = number,
                name = string,
                identifier = string,
                role = Constants.Role,
                score = number,
                vehicleNetId = number
            },
            [2] = { ... }
        },
        roundStartTime = number,
        roundEndTime = number,
        winner = number | nil
    }
]]

-- ═══════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════

--- Initialisation du pool de buckets
function RaceManager.Initialize()
    Utils.Debug('Initialisation du RaceManager...', nil, SOURCE_FILE)
    
    -- ✅ CRITIQUE: Initialiser le générateur de nombres aléatoires
    math.randomseed(os.time())
    -- Faire quelques appels pour "chauffer" le générateur
    for i = 1, 10 do
        math.random()
    end
    
    RaceManager.AvailableBuckets = {}
    
    for i = Config.Race.bucketRange.min, Config.Race.bucketRange.max do
        table.insert(RaceManager.AvailableBuckets, i)
    end
    
    Utils.Info('Pool de buckets initialisé', { 
        total = #RaceManager.AvailableBuckets,
        range = Config.Race.bucketRange 
    })
    
    -- Vérifier que la config véhicules est valide
    if not Config.Vehicle.availableModels or #Config.Vehicle.availableModels == 0 then
        Utils.Error('❌ ERREUR CRITIQUE: Aucun véhicule configuré !', nil, SOURCE_FILE)
    else
        Utils.Info('Pool de véhicules chargé', {
            count = #Config.Vehicle.availableModels,
            models = Config.Vehicle.availableModels,
            randomMode = Config.Vehicle.randomSelection
        })
    end
    
    -- Vérifier que la config spawns est valide
    if not Config.Positions.spawns or #Config.Positions.spawns == 0 then
        Utils.Error('❌ ERREUR CRITIQUE: Aucun spawn configuré !', nil, SOURCE_FILE)
    else
        Utils.Info('Pool de spawns chargé', {
            count = #Config.Positions.spawns,
            locations = table.concat((function()
                local names = {}
                for _, spawn in ipairs(Config.Positions.spawns) do
                    table.insert(names, spawn.name)
                end
                return names
            end)(), ', '),
            randomMode = Config.Positions.randomSpawns
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- 🪣 GESTION DES BUCKETS
-- ═══════════════════════════════════════════════════════════

--- Récupération d'un bucket disponible
---@return number|nil
function RaceManager.GetAvailableBucket()
    Utils.Trace('RaceManager.GetAvailableBucket')
    
    if #RaceManager.AvailableBuckets == 0 then
        Utils.Warn('Aucun bucket disponible !', nil)
        return nil
    end
    
    local bucketId = table.remove(RaceManager.AvailableBuckets, 1)
    Utils.Debug('Bucket attribué', { bucketId = bucketId, remaining = #RaceManager.AvailableBuckets }, SOURCE_FILE)
    
    return bucketId
end

--- Libération d'un bucket
---@param bucketId number
function RaceManager.ReleaseBucket(bucketId)
    Utils.Trace('RaceManager.ReleaseBucket', { bucketId = bucketId })
    
    if not bucketId then
        Utils.Error('ReleaseBucket appelé sans bucketId', nil, SOURCE_FILE)
        return
    end
    
    -- Récupérer la session avant suppression
    local session = RaceManager.ActiveRaces[bucketId]
    
    if session then
        -- Retourner les joueurs au bucket 0
        for _, player in ipairs(session.players) do
            if player and player.id then
                Utils.Debug('Retour joueur au bucket 0', { playerId = player.id }, SOURCE_FILE)
                SetPlayerRoutingBucket(player.id, 0)
                RaceManager.PlayerRaces[player.id] = nil
            end
        end
    end
    
    -- Nettoyage de la session
    RaceManager.ActiveRaces[bucketId] = nil
    
    -- Remise dans le pool
    table.insert(RaceManager.AvailableBuckets, bucketId)
    
    Utils.Debug('Bucket libéré', { bucketId = bucketId, available = #RaceManager.AvailableBuckets }, SOURCE_FILE)
end

-- ═══════════════════════════════════════════════════════════
-- 🎮 GESTION DES SESSIONS
-- ═══════════════════════════════════════════════════════════

--- Création d'une nouvelle session de course
---@param player1Id number
---@param player2Id number
---@return table|nil session
function RaceManager.CreateSession(player1Id, player2Id)
    Utils.Trace('RaceManager.CreateSession', { player1Id = player1Id, player2Id = player2Id })
    
    -- Vérification des joueurs
    if not Utils.IsValidServerId(player1Id) or not Utils.IsValidServerId(player2Id) then
        Utils.Error('IDs joueurs invalides', { player1Id = player1Id, player2Id = player2Id }, SOURCE_FILE)
        return nil
    end
    
    -- Récupération d'un bucket
    local bucketId = RaceManager.GetAvailableBucket()
    if not bucketId then
        Utils.Error('Impossible de créer la session - pas de bucket', nil, SOURCE_FILE)
        return nil
    end
    
    -- ✅ Sélection du véhicule pour ce match
    local selectedVehicle = RaceManager.SelectRandomVehicle()
    
    -- ✅ NOUVEAU: Sélection du spawn pour ce match
    local selectedSpawn = RaceManager.SelectRandomSpawn()
    
    -- Attribution aléatoire des rôles
    local firstRole = Utils.RandomRole()
    local secondRole = Utils.InvertRole(firstRole)
    
    -- Récupérer les identifiants pour le système ELO
    local player1Identifier = nil
    local player2Identifier = nil
    
    if Config.Elo and Config.Elo.enabled and EloSystem then
        player1Identifier = EloSystem.GetPlayerIdentifier(player1Id)
        player2Identifier = EloSystem.GetPlayerIdentifier(player2Id)
        
        Utils.Debug('Identifiants ELO récupérés', {
            player1 = player1Identifier,
            player2 = player2Identifier
        }, SOURCE_FILE)
    end
    
    -- Création de la session
    local session = {
        bucketId = bucketId,
        status = Constants.RaceStatus.WAITING,
        currentRound = 0,
        maxRounds = Config.Race.maxRounds,
        vehicleModel = selectedVehicle,
        spawnLocation = selectedSpawn,    -- ✅ NOUVEAU: Spawn pour ce match
        players = {
            [1] = {
                id = player1Id,
                name = GetPlayerName(player1Id) or 'Joueur 1',
                identifier = player1Identifier,
                role = firstRole,
                score = 0,
                vehicleNetId = nil
            },
            [2] = {
                id = player2Id,
                name = GetPlayerName(player2Id) or 'Joueur 2',
                identifier = player2Identifier,
                role = secondRole,
                score = 0,
                vehicleNetId = nil
            }
        },
        roundStartTime = nil,
        roundEndTime = nil,
        winner = nil
    }
    
    -- Enregistrement
    RaceManager.ActiveRaces[bucketId] = session
    RaceManager.PlayerRaces[player1Id] = bucketId
    RaceManager.PlayerRaces[player2Id] = bucketId
    
    Utils.Info('Session créée', {
        bucketId = bucketId,
        vehicleModel = selectedVehicle,
        spawnLocation = selectedSpawn.name,    -- ✅ NOUVEAU: Log du spawn
        player1 = session.players[1].name .. ' (' .. Utils.GetRoleName(session.players[1].role) .. ')',
        player2 = session.players[2].name .. ' (' .. Utils.GetRoleName(session.players[2].role) .. ')'
    })
    
    return session
end

--- Récupération de la session d'un joueur
---@param playerId number
---@return table|nil session
function RaceManager.GetPlayerSession(playerId)
    local bucketId = RaceManager.PlayerRaces[playerId]
    if not bucketId then return nil end
    return RaceManager.ActiveRaces[bucketId]
end

--- Vérification si un joueur est en course
---@param playerId number
---@return boolean
function RaceManager.IsPlayerInRace(playerId)
    return RaceManager.PlayerRaces[playerId] ~= nil
end

--- Récupération des données d'un joueur dans une session
---@param session table
---@param playerId number
---@return table|nil playerData
function RaceManager.GetPlayerData(session, playerId)
    if not session then return nil end
    
    for _, player in ipairs(session.players) do
        if player.id == playerId then
            return player
        end
    end
    return nil
end

--- Récupération de l'adversaire d'un joueur
---@param session table
---@param playerId number
---@return table|nil opponentData
function RaceManager.GetOpponent(session, playerId)
    if not session then return nil end
    
    for _, player in ipairs(session.players) do
        if player.id ~= playerId then
            return player
        end
    end
    return nil
end

--- Récupération du joueur par rôle
---@param session table
---@param role number
---@return table|nil playerData
function RaceManager.GetPlayerByRole(session, role)
    if not session then return nil end
    
    for _, player in ipairs(session.players) do
        if player.role == role then
            return player
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- 🔄 GESTION DES ROUNDS
-- ═══════════════════════════════════════════════════════════

--- Démarrage d'un nouveau round
---@param bucketId number
function RaceManager.StartRound(bucketId)
    Utils.Trace('RaceManager.StartRound', { bucketId = bucketId })
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then
        Utils.Error('Session introuvable pour StartRound', { bucketId = bucketId }, SOURCE_FILE)
        return
    end
    
    -- Incrémenter le round
    session.currentRound = session.currentRound + 1
    session.status = Constants.RaceStatus.PREPARING
    
    Utils.Debug('Démarrage round', {
        bucketId = bucketId,
        round = session.currentRound,
        maxRounds = session.maxRounds,
        vehicleModel = session.vehicleModel,
        spawnLocation = session.spawnLocation.name    -- ✅ Log du spawn
    }, SOURCE_FILE)
    
    -- Assigner les joueurs au bucket
    for _, player in ipairs(session.players) do
        SetPlayerRoutingBucket(player.id, bucketId)
        Utils.Debug('Joueur assigné au bucket', { playerId = player.id, bucketId = bucketId }, SOURCE_FILE)
    end
    
    -- ✅ NOUVEAU: Envoyer le modèle de véhicule ET les spawns aux clients
    for _, player in ipairs(session.players) do
        local opponent = RaceManager.GetOpponent(session, player.id)
        
        -- Déterminer le spawn selon le rôle
        local spawnPos = player.role == Constants.Role.RUNNER and session.spawnLocation.runner or session.spawnLocation.hunter
        
        TriggerClientEvent(Constants.Events.PREPARE_RACE, player.id, {
            bucketId = bucketId,
            round = session.currentRound,
            maxRounds = session.maxRounds,
            role = player.role,
            opponentId = opponent.id,
            opponentName = opponent.name,
            vehicleModel = session.vehicleModel,
            spawnPosition = spawnPos,    -- ✅ NOUVEAU: Position de spawn
            spawnLocationName = session.spawnLocation.name    -- Pour info/debug
        })
    end
end

--- Démarrage effectif de la course (après countdown)
---@param bucketId number
function RaceManager.StartRaceActive(bucketId)
    Utils.Trace('RaceManager.StartRaceActive', { bucketId = bucketId })
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then
        Utils.Error('Session introuvable pour StartRaceActive', { bucketId = bucketId }, SOURCE_FILE)
        return
    end
    
    session.status = Constants.RaceStatus.ACTIVE
    session.roundStartTime = Utils.GetTimestamp()
    session.roundEndTime = session.roundStartTime + Config.Race.roundDuration
    
    Utils.Info('Round actif', {
        bucketId = bucketId,
        round = session.currentRound,
        duration = Config.Race.roundDuration / 1000 .. 's',
        vehicleModel = session.vehicleModel,
        spawnLocation = session.spawnLocation.name
    })
    
    for _, player in ipairs(session.players) do
        TriggerClientEvent(Constants.Events.START_RACE, player.id, {
            roundDuration = Config.Race.roundDuration
        })
    end
end

--- Fin d'un round
---@param bucketId number
---@param result number Constants.RoundResult
---@param winnerId number
function RaceManager.EndRound(bucketId, result, winnerId)
    Utils.Trace('RaceManager.EndRound', { bucketId = bucketId, result = result, winnerId = winnerId })
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then
        Utils.Error('Session introuvable pour EndRound', { bucketId = bucketId }, SOURCE_FILE)
        return
    end
    
    session.status = Constants.RaceStatus.ENDING
    
    -- Mise à jour du score
    local winnerData = RaceManager.GetPlayerData(session, winnerId)
    if winnerData then
        winnerData.score = winnerData.score + 1
        Utils.Debug('Score mis à jour', { 
            winner = winnerData.name, 
            score = winnerData.score 
        }, SOURCE_FILE)
    end
    
    -- Notifier les clients
    for _, player in ipairs(session.players) do
        local isWinner = player.id == winnerId
        TriggerClientEvent(Constants.Events.ROUND_RESULT, player.id, {
            round = session.currentRound,
            result = result,
            isWinner = isWinner,
            scores = {
                [session.players[1].id] = session.players[1].score,
                [session.players[2].id] = session.players[2].score
            }
        })
    end
    
    Utils.Info('Round terminé', {
        bucketId = bucketId,
        round = session.currentRound,
        result = Utils.GetResultName(result),
        winner = winnerData and winnerData.name or 'N/A',
        scores = session.players[1].name .. ' ' .. session.players[1].score .. ' - ' .. session.players[2].score .. ' ' .. session.players[2].name
    })
    
    -- Vérifier si le match est terminé
    Wait(Config.Animations.victory.duration + 1000)
    RaceManager.CheckMatchEnd(bucketId)
end

--- Vérification de fin de match
---@param bucketId number
function RaceManager.CheckMatchEnd(bucketId)
    Utils.Trace('RaceManager.CheckMatchEnd', { bucketId = bucketId })
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then return end
    
    local scoreToWin = math.ceil(session.maxRounds / 2)
    local matchWinner = nil
    
    -- Vérifier si un joueur a gagné
    for _, player in ipairs(session.players) do
        if player.score >= scoreToWin then
            matchWinner = player
            break
        end
    end
    
    if matchWinner then
        -- Match terminé
        RaceManager.EndMatch(bucketId, matchWinner.id)
    elseif session.currentRound < session.maxRounds then
        -- Prochain round
        RaceManager.PrepareNextRound(bucketId)
    else
        -- Cas d'égalité (ne devrait pas arriver en best of 3)
        Utils.Warn('Égalité détectée - cas non prévu', { bucketId = bucketId }, SOURCE_FILE)
        RaceManager.EndMatch(bucketId, nil)
    end
end

--- Préparation du round suivant
---@param bucketId number
function RaceManager.PrepareNextRound(bucketId)
    Utils.Trace('RaceManager.PrepareNextRound', { bucketId = bucketId })
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then return end
    
    -- Inverser les rôles
    for _, player in ipairs(session.players) do
        player.role = Utils.InvertRole(player.role)
        player.vehicleNetId = nil
        Utils.Debug('Rôle inversé', { 
            player = player.name, 
            newRole = Utils.GetRoleName(player.role) 
        }, SOURCE_FILE)
    end
    
    -- Attendre que les clients suppriment leurs véhicules
    Utils.Debug('Attente suppression véhicules avant round suivant...', nil, SOURCE_FILE)
    Wait(Config.Animations.victory.duration + 500)
    
    -- Démarrer le prochain round
    RaceManager.StartRound(bucketId)
end

--- Fin du match
---@param bucketId number
---@param winnerId number|nil
function RaceManager.EndMatch(bucketId, winnerId)
    Utils.Trace('RaceManager.EndMatch', { bucketId = bucketId, winnerId = winnerId })
    
    local session = RaceManager.ActiveRaces[bucketId]
    if not session then return end
    
    session.status = Constants.RaceStatus.FINISHED
    session.winner = winnerId
    
    local winnerData = RaceManager.GetPlayerData(session, winnerId)
    local loserData = RaceManager.GetOpponent(session, winnerId)
    
    Utils.Info('Match terminé', {
        bucketId = bucketId,
        winner = winnerData and winnerData.name or 'Aucun',
        finalScore = session.players[1].name .. ' ' .. session.players[1].score .. ' - ' .. session.players[2].score .. ' ' .. session.players[2].name,
        vehicleUsed = session.vehicleModel,
        spawnUsed = session.spawnLocation.name
    })
    
    -- Mise à jour ELO
    if Config.Elo and Config.Elo.enabled and EloSystem and winnerId and winnerData and loserData then
        if winnerData.identifier and loserData.identifier then
            Utils.Debug('Mise à jour ELO en cours...', {
                winner = winnerData.identifier,
                loser = loserData.identifier,
                winnerScore = winnerData.score,
                loserScore = loserData.score
            }, SOURCE_FILE)
            
            EloSystem.UpdateMatchResult(
                winnerData.identifier,
                loserData.identifier,
                winnerData.name,
                loserData.name,
                winnerData.score,
                loserData.score,
                function(success, eloChange, winnerNewElo, loserNewElo)
                    if success then
                        Utils.Info('ELO mis à jour avec succès', {
                            winner = string.format('%s: +%d (→ %d)', winnerData.name, eloChange, winnerNewElo),
                            loser = string.format('%s: -%d (→ %d)', loserData.name, eloChange, loserNewElo)
                        })
                        
                        TriggerClientEvent(Constants.Events.NOTIFY, winnerData.id, {
                            type = Constants.NotificationType.SUCCESS,
                            message = Utils.FormatText(Config.Texts.elo_gain, eloChange, winnerNewElo - eloChange, winnerNewElo)
                        })
                        
                        TriggerClientEvent(Constants.Events.NOTIFY, loserData.id, {
                            type = Constants.NotificationType.INFO,
                            message = Utils.FormatText(Config.Texts.elo_loss, eloChange, loserNewElo + eloChange, loserNewElo)
                        })
                        
                        if InvalidateLeaderboardCache then
                            InvalidateLeaderboardCache()
                        end
                    else
                        Utils.Error('Échec mise à jour ELO', nil, SOURCE_FILE)
                    end
                end
            )
        else
            Utils.Warn('Identifiants manquants pour la mise à jour ELO', {
                winnerIdentifier = winnerData.identifier,
                loserIdentifier = loserData.identifier
            }, SOURCE_FILE)
        end
    end
    
    -- Notifier les clients
    for _, player in ipairs(session.players) do
        local isWinner = player.id == winnerId
        TriggerClientEvent(Constants.Events.END_RACE, player.id, {
            isWinner = isWinner,
            winnerId = winnerId,
            winnerName = winnerData and winnerData.name or 'Personne',
            finalScores = {
                [session.players[1].id] = session.players[1].score,
                [session.players[2].id] = session.players[2].score
            }
        })
    end
    
    -- Nettoyer la session après un délai
    SetTimeout(5000, function()
        RaceManager.ReleaseBucket(bucketId)
    end)
end

-- ═══════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════

--- Nettoyage des invitations expirées
function RaceManager.CleanupExpiredInvites()
    local currentTime = Utils.GetTimestamp()
    local cleaned = 0
    
    for inviteId, inviteData in pairs(RaceManager.PendingInvites) do
        if currentTime - inviteData.timestamp > Config.Race.inviteTimeout then
            if Utils.IsValidServerId(inviteData.sender) then
                TriggerClientEvent(Constants.Events.NOTIFY, inviteData.sender, {
                    type = Constants.NotificationType.WARNING,
                    message = Config.Texts.invite_expired
                })
            end
            
            RaceManager.PendingInvites[inviteId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        Utils.Debug('Invitations expirées nettoyées', { count = cleaned }, SOURCE_FILE)
    end
end

--- Nettoyage des courses inactives
function RaceManager.CleanupInactiveRaces()
    local currentTime = Utils.GetTimestamp()
    local cleaned = 0
    
    for bucketId, session in pairs(RaceManager.ActiveRaces) do
        if session.status == Constants.RaceStatus.ACTIVE and session.roundEndTime then
            if currentTime > session.roundEndTime + 60000 then
                Utils.Warn('Course inactive détectée - Nettoyage', { bucketId = bucketId }, SOURCE_FILE)
                RaceManager.ReleaseBucket(bucketId)
                cleaned = cleaned + 1
            end
        end
    end
    
    if cleaned > 0 then
        Utils.Debug('Courses inactives nettoyées', { count = cleaned }, SOURCE_FILE)
    end
end

-- ═══════════════════════════════════════════════════════════
-- ⏰ TIMERS
-- ═══════════════════════════════════════════════════════════

CreateThread(function()
    RaceManager.Initialize()
    
    while true do
        Wait(Config.Race.cleanupInterval)
        
        if Config.Race.autoCleanup then
            RaceManager.CleanupExpiredInvites()
            RaceManager.CleanupInactiveRaces()
        end
    end
end)

