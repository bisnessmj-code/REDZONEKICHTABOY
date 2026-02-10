-- ==========================================
-- SERVER GAME - GESTION DES ROUNDS (v3.1 FIXED)
-- ==========================================
-- ✅ CORRECTIONS :
-- 1. Système de détection du gagnant AVANT de vérifier l'égalité
-- 2. Délais de stabilisation augmentés et vérifiés
-- 3. Protection contre les race conditions
-- 4. Logs détaillés pour debug
-- 5. ✅ NOUVEAU : skipTeleport dans EndGame pour éviter double TP
-- ==========================================

GameManager = {
    state = Constants.GameState.WAITING,
    currentRound = 0,
    currentMapId = nil,
    swappedSpawns = false,
    scores = {
        red = 0,
        blue = 0
    },
    alivePlayers = {
        red = {},
        blue = {}
    },
    gameActive = false,
    lastWinner = nil,
    roundLocked = false,
    killTracker = {} -- {[source] = {name, team, kills}}
}

-- ==========================================
-- FONCTION UTILITAIRE : RÉCUPÉRER LE SPAWN D'UNE ÉQUIPE
-- ==========================================

function GetTeamSpawn(mapData, team)
    if not mapData or not mapData.spawns then
        return nil
    end
    
    if GameManager.swappedSpawns then
        if team == Constants.Teams.RED then
            return mapData.spawns.blue
        elseif team == Constants.Teams.BLUE then
            return mapData.spawns.red
        end
    end
    
    return mapData.spawns[team]
end

-- ==========================================
-- FONCTION UTILITAIRE : RÉCUPÉRER TOUS LES JOUEURS EN ÉQUIPE
-- ==========================================

function GetAllTeamPlayers()
    local players = {}
    for source, data in pairs(GDT.Players) do
        if data.team == Constants.Teams.RED or data.team == Constants.Teams.BLUE then
            table.insert(players, {
                source = source,
                team = data.team,
                data = data
            })
        end
    end
    return players
end

-- ==========================================
-- DÉMARRER LA PARTIE (AVEC SÉLECTION DE MAP)
-- ==========================================

function StartGame(mapId)
    if GameManager.gameActive then
        return false, "Une partie est déjà en cours"
    end
    
    mapId = mapId or Config.DefaultMapId
    
    if not Config.Maps[mapId] then
        return false, "Map introuvable (ID: "..tostring(mapId)..")"
    end
    
    if not Config.Maps[mapId].enabled then
        return false, "Cette map est désactivée"
    end
    
    local redCount = CountPlayersInTeam(Constants.Teams.RED)
    local blueCount = CountPlayersInTeam(Constants.Teams.BLUE)
    
  
    
    if redCount == 0 then
        return false, "Il faut au moins 1 joueur dans l'équipe ROUGE"
    end
    
    if blueCount == 0 then
        return false, "Il faut au moins 1 joueur dans l'équipe BLEUE"
    end
    
    -- Initialisation
    GameManager.state = Constants.GameState.STARTING
    GameManager.currentRound = 1
    GameManager.currentMapId = mapId
    GameManager.swappedSpawns = false
    GameManager.scores = { red = 0, blue = 0 }
    GameManager.gameActive = true
    GameManager.lastWinner = nil
    GameManager.roundLocked = false
    GameManager.killTracker = {}

    -- Init kill tracker pour chaque joueur en equipe
    for source, data in pairs(GDT.Players) do
        if data.team == Constants.Teams.RED or data.team == Constants.Teams.BLUE then
            GameManager.killTracker[source] = {
                name = GetPlayerName(source) or 'Inconnu',
                team = data.team,
                kills = 0
            }
        end
    end

    local mapName = Config.Maps[mapId].name

    
    -- Mise à jour des caches anti-FF
    UpdateAllTeammatesCache(Constants.Teams.RED)
    UpdateAllTeammatesCache(Constants.Teams.BLUE)
    
    -- Annonces (en parallèle pour tous)
    for playerId, _ in pairs(GDT.Players) do
        TriggerClientEvent('gdt:client:showAnnounce', playerId, 'DEBUT DE LA PARTIE', 3000)
    end
    
    Wait(1500)
    
    for playerId, _ in pairs(GDT.Players) do
        TriggerClientEvent('gdt:client:showAnnounce', playerId, 'MAP: '..mapName:upper(), 3000)
    end
    
    Wait(3000)
    
    StartRound()
    
    return true, "Partie démarrée ! ("..redCount.."v"..blueCount..")"
end

-- ==========================================
-- DÉMARRER UN ROUND (VERSION CORRIGÉE)
-- ==========================================

function StartRound()
    -- ✅ PROTECTION : Reset du lock de round
    GameManager.roundLocked = false
    
    GameManager.state = Constants.GameState.IN_PROGRESS
    GameManager.alivePlayers = { red = {}, blue = {} }
    
    local mapId = GameManager.currentMapId or Config.DefaultMapId
    local mapData = Config.Maps[mapId]
    
    if not mapData then
        return
    end
    
    -- Récupérer tous les joueurs en équipe
    local teamPlayers = GetAllTeamPlayers()
    local playerCount = #teamPlayers
    
    -- ==========================================
    -- ÉTAPE 0: Désactiver le spectateur pour TOUS (parallèle)
    -- ==========================================
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:stopSpectator', player.source)
    end
    Wait(500)
    
    -- ==========================================
    -- LOGIQUE D'INVERSION DES SPAWNS
    -- ==========================================
    if GameManager.currentRound > 1 then
        GameManager.swappedSpawns = not GameManager.swappedSpawns
        local swapStatus = GameManager.swappedSpawns and "INVERSES" or "NORMAUX"
    end
    
    -- ==========================================
    -- ANNONCES (parallèle)
    -- ==========================================
    local announcement = string.format('ROUND %d', GameManager.currentRound)
    for playerId, _ in pairs(GDT.Players) do
        TriggerClientEvent('gdt:client:showAnnounce', playerId, announcement, 3000)
    end
    Wait(2000)
    
    if GameManager.currentRound > 1 then
        local scoreAnnouncement = string.format('SCORE : ROUGE %d - %d BLEU', GameManager.scores.red, GameManager.scores.blue)
        for playerId, _ in pairs(GDT.Players) do
            TriggerClientEvent('gdt:client:showAnnounce', playerId, scoreAnnouncement, 2500)
        end
        Wait(2500)
        
        if GameManager.swappedSpawns then
            for playerId, _ in pairs(GDT.Players) do
                TriggerClientEvent('gdt:client:showAnnounce', playerId, 'CHANGEMENT DE COTE', 2500)
            end
            Wait(2500)
        end
    else
        Wait(1000)
    end
    
    -- ==========================================
    -- MISE À JOUR ANTI-FF (parallèle)
    -- ==========================================
    UpdateAllTeammatesCache(Constants.Teams.RED)
    UpdateAllTeammatesCache(Constants.Teams.BLUE)
    
    -- ==========================================
    -- ÉTAPE 1: TÉLÉPORTATION DE TOUS LES JOUEURS (PARALLÈLE)
    -- ==========================================
 
    
    for _, player in ipairs(teamPlayers) do
        -- Mise à jour de l'état
        player.data.state = Constants.PlayerState.IN_GAME
        
        -- Ajout à la liste des vivants
        table.insert(GameManager.alivePlayers[player.team], player.source)
        
        -- Téléportation
        local spawnPos = GetTeamSpawn(mapData, player.team)
        if spawnPos then
            TriggerClientEvent('gdt:client:teleportToSpawn', player.source, spawnPos)
        else
            print('[GDT] ERREUR: Spawn introuvable pour joueur '..tostring(player.source)..' (equipe: '..tostring(player.team)..')')
            TriggerClientEvent('esx:showNotification', player.source, 'Erreur: spawn introuvable, contacte un admin')
        end
    end
    
    Wait(1500)
    
    -- ==========================================
    -- ÉTAPE 2: RÉANIMATION DE TOUS (PARALLÈLE)
    -- ==========================================
 
    
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:revivePlayer', player.source)
    end
    
    Wait(500)
    
    -- ==========================================
    -- ÉTAPE 3: SOIN DE TOUS (PARALLÈLE)
    -- ==========================================
   
    
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:healPlayer', player.source)
    end
    
    Wait(400)
    
    -- ==========================================
    -- ÉTAPE 4: ARMES POUR TOUS (PARALLÈLE)
    -- ==========================================
    
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:giveWeapon', player.source, Config.StartWeapon.weapon, Config.StartWeapon.ammo)
    end
    
    Wait(1000)
    
    -- ==========================================
    -- ÉTAPE 5: VÉRIFICATION ARMES (PARALLÈLE)
    -- ==========================================
 
    
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:verifyWeapon', player.source, Config.StartWeapon.weapon, Config.StartWeapon.ammo)
    end
    
    Wait(500)
    
    -- ==========================================
    -- ÉTAPE 6: ZONE DE COMBAT POUR TOUS (PARALLÈLE)
    -- ==========================================
 
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:setCombatZone', player.source, mapData.combatZone)
    end
    
    Wait(1000)
    
    for _, player in ipairs(teamPlayers) do
        TriggerClientEvent('gdt:client:startCombatZone', player.source)
    end
    
   
    LogAction(0, 'ROUND_START', 'Round '..GameManager.currentRound..' | '..playerCount..' joueurs | Map: '..mapData.name)
end

-- ==========================================
-- JOUEUR MORT (AVEC TRACKING AMÉLIORÉ)
-- ==========================================

function OnPlayerDeath(source, killerServerId)
    if not GameManager.gameActive then return end
    if GameManager.state ~= Constants.GameState.IN_PROGRESS then return end
    
    -- ✅ PROTECTION : Si round déjà terminé, ignorer
    if GameManager.roundLocked then
    
        return
    end
    
    local playerData = GDT.Players[source]
    if not playerData then return end
    
    local team = playerData.team
    if not team or team == Constants.Teams.NONE then return end
    
    -- Vérification anti-teamkill serveur
    if killerServerId and killerServerId ~= 0 then
        local killerData = GDT.Players[killerServerId]
        if killerData and killerData.team == team then
            
            TriggerClientEvent('gdt:client:revivePlayer', source)
            TriggerClientEvent('gdt:client:healPlayer', source)
            TriggerClientEvent('esx:showNotification', source, 'Tu as été réanimé (teamkill détecté)')
            TriggerClientEvent('esx:showNotification', killerServerId, 'Teamkill détecté !')
            
            return
        end
    end
    
    -- Killfeed
    local victimName = GetPlayerName(source) or 'Inconnu'
    local killerName = 'Inconnu'
    local killerIdFinal = 0
    
    if killerServerId and killerServerId ~= 0 and GDT.Players[killerServerId] then
        killerName = GetPlayerName(killerServerId) or 'Inconnu'
        killerIdFinal = killerServerId
    end
    
    if Config.Killfeed.enabled then
        for playerId, _ in pairs(GDT.Players) do
            TriggerClientEvent('gdt:client:showKillfeed', playerId, killerName, killerIdFinal, victimName, source)
        end
    end

    -- Enregistrer le kill en BDD (async)
    if killerIdFinal ~= 0 then
        Database.AddKill(killerIdFinal)

        -- Tracker in-game
        if GameManager.killTracker[killerIdFinal] then
            GameManager.killTracker[killerIdFinal].kills = GameManager.killTracker[killerIdFinal].kills + 1
        end
    end
    
    -- Retirer de la liste des vivants
    local wasRemoved = false
    for i, playerId in ipairs(GameManager.alivePlayers[team]) do
        if playerId == source then
            table.remove(GameManager.alivePlayers[team], i)
            playerData.state = Constants.PlayerState.DEAD_IN_GAME
            wasRemoved = true
            break
        end
    end
    
    if wasRemoved then
        UpdateAllTeammatesCache(team)
        CheckRoundEnd()
    end
end

-- ==========================================
-- VÉRIFIER FIN DE ROUND (VERSION CORRIGÉE)
-- ==========================================

function CheckRoundEnd()
    -- ✅ PROTECTION : éviter double-exécution
    if GameManager.roundLocked then
        return
    end

    -- ✅ FIX P0 #1 : Lock IMMEDIAT pour éviter race condition
    GameManager.roundLocked = true

    local redAlive = #GameManager.alivePlayers.red
    local blueAlive = #GameManager.alivePlayers.blue

    local winner = nil

    if redAlive == 0 and blueAlive == 0 then
        if GameManager.lastWinner then
            winner = GameManager.lastWinner
        else
            winner = 'draw'
        end
    elseif redAlive == 0 and blueAlive > 0 then
        winner = Constants.Teams.BLUE
        GameManager.lastWinner = Constants.Teams.BLUE
    elseif blueAlive == 0 and redAlive > 0 then
        winner = Constants.Teams.RED
        GameManager.lastWinner = Constants.Teams.RED
    else
        -- Pas de gagnant, débloquer le round
        GameManager.roundLocked = false
        return
    end

    EndRound(winner)
end

-- ==========================================
-- FIN DE ROUND (PARALLÈLE)
-- ==========================================

function EndRound(winner)
    if GameManager.state ~= Constants.GameState.IN_PROGRESS then 
        return 
    end
    
    GameManager.state = Constants.GameState.ROUND_END
    

    
    -- Arrêter spectateur et zone pour tous (parallèle)
    for source, data in pairs(GDT.Players) do
        if data.team == Constants.Teams.RED or data.team == Constants.Teams.BLUE then
            TriggerClientEvent('gdt:client:stopSpectator', source)
            TriggerClientEvent('gdt:client:stopCombatZone', source)
        end
    end
    
    Wait(300)
    
    -- ✅ CORRECTION : Mise à jour des scores AVANT l'animation
    if winner == Constants.Teams.RED then
        GameManager.scores.red = GameManager.scores.red + 1

    elseif winner == Constants.Teams.BLUE then
        GameManager.scores.blue = GameManager.scores.blue + 1

    else
    end
    
    -- Top killers par equipe
    local topRed, topBlue = GetTopKillersPerTeam()

    -- Animation de victoire (parallèle)
    for playerId, _ in pairs(GDT.Players) do
        TriggerClientEvent('gdt:client:showRoundWin', playerId, winner, GameManager.scores, topRed, topBlue)
    end
    
    Wait(Config.GameSettings.roundEndDelay)
    
    -- Vérifier fin de partie
    if GameManager.scores.red >= Config.GameSettings.maxRounds then
        EndGame(Constants.Teams.RED)
    elseif GameManager.scores.blue >= Config.GameSettings.maxRounds then
        EndGame(Constants.Teams.BLUE)
    else
        GameManager.currentRound = GameManager.currentRound + 1
        StartRound()
    end
end

-- ==========================================
-- FIN DE PARTIE (PARALLÈLE OPTIMISÉE - CORRIGÉE)
-- ==========================================
-- ✅ CORRECTION : Utilise skipTeleport=true pour éviter double téléportation
-- ==========================================

function EndGame(winner)
    GameManager.state = Constants.GameState.GAME_END
    
    local mapId = GameManager.currentMapId or Config.DefaultMapId
    local mapData = Config.Maps[mapId]
    local mapName = mapData and mapData.name or 'Inconnue'
    local endLocation = mapData and mapData.endLocation or Config.EndGameLocation

    
    -- Récupérer tous les joueurs
    local allPlayers = {}
    for source, _ in pairs(GDT.Players) do
        table.insert(allPlayers, source)
    end
    local playerCount = #allPlayers
    
    -- ÉTAPE 1: ARRÊTER SPECTATEUR POUR TOUS

    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:stopSpectator', playerId)
    end
    
    Wait(300)
    
    -- Top killers par equipe
    local topRed, topBlue = GetTopKillersPerTeam()

    -- ÉTAPE 2: ANIMATION FINALE POUR TOUS

    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:showGameEnd', playerId, winner, GameManager.scores, topRed, topBlue)
    end
    
    Wait(Config.GameSettings.gameEndDelay)
    
    -- ÉTAPE 3: RÉANIMATION DE TOUS

    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:revivePlayer', playerId)
    end
    
    Wait(400)
    
    -- ÉTAPE 4: TÉLÉPORTATION DE TOUS À endLocation

    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:teleportToEnd', playerId, endLocation)
    end
    
    Wait(1000)
    
    -- ==========================================
    -- ✅ ÉTAPE 5: RETRAIT DE TOUS DE LA GDT (SANS RE-TÉLÉPORTATION)
    -- ==========================================

    for _, playerId in ipairs(allPlayers) do
        -- ✅ CORRECTION : silent=false pour restaurer la tenue, skipTeleport=true pour éviter double TP
        RemovePlayerFromGDT(playerId, false, true)
    end
    
    -- Reset du game manager
    GameManager.state = Constants.GameState.WAITING
    GameManager.gameActive = false
    GameManager.currentRound = 0
    GameManager.currentMapId = nil
    GameManager.swappedSpawns = false
    GameManager.scores = { red = 0, blue = 0 }
    GameManager.alivePlayers = { red = {}, blue = {} }
    GameManager.lastWinner = nil
    GameManager.roundLocked = false

    -- ✅ P3 #12 : Nettoyer les données de reconnexion
    GDT.DisconnectedPlayers = {}

end

-- ==========================================
-- ANNULER LA PARTIE (PARALLÈLE)
-- ==========================================

function CancelGame()
    if not GameManager.gameActive then
        return false, "Aucune partie en cours"
    end
    

    
    local allPlayers = {}
    for source, _ in pairs(GDT.Players) do
        table.insert(allPlayers, source)
    end
    
    local mapId = GameManager.currentMapId or Config.DefaultMapId
    local mapData = Config.Maps[mapId]
    local endLocation = mapData and mapData.endLocation or Config.EndGameLocation
    
    -- Tout en parallèle
    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:stopSpectator', playerId)
        TriggerClientEvent('gdt:client:stopCombatZone', playerId)
    end
    
    Wait(300)
    
    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:revivePlayer', playerId)
    end
    
    Wait(400)
    
    -- Téléportation à endLocation
    for _, playerId in ipairs(allPlayers) do
        TriggerClientEvent('gdt:client:teleportToEnd', playerId, endLocation)
    end
    
    Wait(800)
    
    -- ✅ CORRECTION : skipTeleport=true pour éviter double téléportation
    for _, playerId in ipairs(allPlayers) do
        RemovePlayerFromGDT(playerId, false, true)
    end
    
    -- Reset
    GameManager.state = Constants.GameState.WAITING
    GameManager.gameActive = false
    GameManager.currentRound = 0
    GameManager.currentMapId = nil
    GameManager.swappedSpawns = false
    GameManager.scores = { red = 0, blue = 0 }
    GameManager.alivePlayers = { red = {}, blue = {} }
    GameManager.lastWinner = nil
    GameManager.roundLocked = false

    -- ✅ P3 #12 : Nettoyer les données de reconnexion
    GDT.DisconnectedPlayers = {}

    return true, "Partie annulée"
end

-- ==========================================
-- ÉVÉNEMENT : DEMANDE DES COÉQUIPIERS VIVANTS
-- ==========================================

RegisterNetEvent('gdt:server:requestAliveTeammates', function(team)
    local source = source
    
    if not GameManager.gameActive then return end
    if not Utils.IsValidTeam(team) then return end
    
    local teammates = {}
    
    for _, playerId in ipairs(GameManager.alivePlayers[team]) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and playerId ~= source then
            table.insert(teammates, {
                id = playerId,
                name = xPlayer.getName()
            })
        end
    end
    
    TriggerClientEvent('gdt:client:updateAliveTeammates', source, teammates)
end)

-- ==========================================
-- TOP 3 KILLERS PAR EQUIPE (IN-GAME)
-- ==========================================

function GetTopKillersPerTeam()
    local red = {}
    local blue = {}

    for _, data in pairs(GameManager.killTracker) do
        if data.team == Constants.Teams.RED then
            table.insert(red, { name = data.name, kills = data.kills })
        elseif data.team == Constants.Teams.BLUE then
            table.insert(blue, { name = data.name, kills = data.kills })
        end
    end

    table.sort(red, function(a, b) return a.kills > b.kills end)
    table.sort(blue, function(a, b) return a.kills > b.kills end)

    -- Limiter a 3
    local topRed = {}
    local topBlue = {}
    for i = 1, math.min(3, #red) do topRed[i] = red[i] end
    for i = 1, math.min(3, #blue) do topBlue[i] = blue[i] end

    return topRed, topBlue
end

-- ==========================================
-- GETTERS
-- ==========================================

function GetGameState()
    return {
        state = GameManager.state,
        round = GameManager.currentRound,
        mapId = GameManager.currentMapId,
        mapName = GameManager.currentMapId and Config.Maps[GameManager.currentMapId].name or nil,
        swappedSpawns = GameManager.swappedSpawns,
        scores = GameManager.scores,
        active = GameManager.gameActive,
        lastWinner = GameManager.lastWinner,
        locked = GameManager.roundLocked
    }
end

function IsGameActive()
    return GameManager.gameActive
end

-- ==========================================
-- EXPORTS GLOBAUX
-- ==========================================

_G.StartGame = StartGame
_G.CancelGame = CancelGame
_G.IsGameActive = IsGameActive
_G.GetGameState = GetGameState
_G.OnPlayerDeath = OnPlayerDeath