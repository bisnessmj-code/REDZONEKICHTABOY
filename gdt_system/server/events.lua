-- ==========================================
-- SERVER EVENTS - GESTION DES ÉVÉNEMENTS
-- VERSION CORRIGÉE - ANTI-FF ROBUSTE
-- ✅ CORRECTION : Cache fiable + vérifications strictes
-- ✅ CORRECTION : quitGDT avec skipTeleport=false (téléporte au PED)
-- ==========================================

-- ==========================================
-- ✅ P3 #12 : GESTION RECONNEXION EN MATCH
-- ==========================================

RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    if not identifier then return end

    local savedData = GDT.DisconnectedPlayers[identifier]
    if not savedData then return end

    -- Vérifier que la partie est toujours en cours
    if not GameManager or not GameManager.gameActive then
        GDT.DisconnectedPlayers[identifier] = nil
        return
    end

    -- Vérifier timeout (5 minutes max)
    if (os.time() - savedData.disconnectedAt) > 300 then
        GDT.DisconnectedPlayers[identifier] = nil
        print('[GDT] Reconnexion expirée pour '..tostring(identifier))
        return
    end

    local source = playerId
    local team = savedData.team
    local originalOutfit = savedData.originalOutfit

    -- Nettoyer les données de déconnexion
    GDT.DisconnectedPlayers[identifier] = nil

    print('[GDT] Reconnexion détectée pour '..tostring(source)..' (equipe: '..tostring(team)..')')

    -- Attendre que le client soit prêt
    Wait(3000)

    -- Remettre dans le bucket GDT
    local bucket = Config.BucketSettings.startBucket
    SetPlayerRoutingBucket(source, bucket)

    -- Réajouter à la table GDT
    AddPlayerToGDT(source, team, bucket, originalOutfit)
    local playerData = GDT.Players[source]

    -- Déterminer l'état selon le round en cours
    local mapId = GameManager.currentMapId or Config.DefaultMapId
    local mapData = Config.Maps[mapId]

    if GameManager.state == Constants.GameState.IN_PROGRESS then
        -- Round en cours : le joueur revient mort (spectateur)
        playerData.state = Constants.PlayerState.DEAD_IN_GAME

        -- Appliquer la tenue d'équipe
        TriggerClientEvent('gdt:client:applyTeamOutfit', source, team)
        Wait(500)

        -- Téléporter au spawn de son équipe
        local spawnPos = GetTeamSpawn(mapData, team)
        if spawnPos then
            TriggerClientEvent('gdt:client:teleportToSpawn', source, spawnPos)
        end

        Wait(1000)

        -- Notifier et lancer spectateur
        TriggerClientEvent('esx:showNotification', source, 'Reconnexion ! Tu es en spectateur pour ce round.')
        TriggerClientEvent('gdt:client:setCombatZone', source, mapData.combatZone)

        -- Mettre en spectateur (il rejoint vivant au prochain round)
        Wait(500)
        TriggerClientEvent('gdt:client:forceSpectator', source, team)
    elseif GameManager.state == Constants.GameState.ROUND_END or GameManager.state == Constants.GameState.STARTING then
        -- Entre les rounds : le joueur sera inclus au prochain round
        playerData.state = Constants.PlayerState.IN_GAME

        TriggerClientEvent('gdt:client:applyTeamOutfit', source, team)
        Wait(500)

        local spawnPos = GetTeamSpawn(mapData, team)
        if spawnPos then
            TriggerClientEvent('gdt:client:teleportToSpawn', source, spawnPos)
        end

        TriggerClientEvent('esx:showNotification', source, 'Reconnexion ! Tu seras dans le prochain round.')
    end

    -- Mettre à jour le cache anti-FF
    UpdateAllTeammatesCache(team)

    TriggerClientEvent('esx:showNotification', source, 'Tu as été reconnecté à la GDT !')
    LogAction(source, 'RECONNECT', 'Joueur reconnecté en equipe '..tostring(team))
end)

-- ==========================================
-- ÉVÉNEMENT : REJOINDRE LE LOBBY
-- ==========================================

RegisterNetEvent('gdt:server:joinLobby', function()
    local source = source
    
    -- Vérifications de sécurité
    if not CheckCooldown(source) then
        return TriggerClientEvent('esx:showNotification', source, Constants.Errors.COOLDOWN_ACTIVE)
    end
    
    if GDT.Players[source] then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.alreadyInGDT)
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Vérification des permissions
    if not Permissions.CanJoinGDT(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    -- Utilisation du bucket global 1000
    local bucket = Config.BucketSettings.startBucket
    
    -- Initialiser le bucket global s'il n'existe pas encore
    if not GDT.Buckets[bucket] then
        GDT.Buckets[bucket] = {
            players = {},
            createdAt = os.time()
        }
        SetRoutingBucketPopulationEnabled(bucket, false)
    end
    
    -- Mise du joueur dans le bucket global
    SetPlayerRoutingBucket(source, bucket)
    
    -- Demande de la tenue actuelle au client
    TriggerClientEvent('gdt:client:requestOutfit', source, bucket)

    
end)

-- ==========================================
-- ÉVÉNEMENT : SAUVEGARDER TENUE ET TÉLÉPORTER
-- ==========================================

RegisterNetEvent('gdt:server:outfitSaved', function(outfit, bucket)
    local source = source
    
    if not outfit or not bucket then return end
    if GDT.Players[source] then return end
    
    -- Ajout à la table GDT
    AddPlayerToGDT(source, Constants.Teams.NONE, bucket, outfit)
    
    -- Téléportation vers le lobby
    TriggerClientEvent('gdt:client:teleportLobby', source)
    TriggerClientEvent('esx:showNotification', source, Config.Notifications.joinedLobby)
end)

-- ==========================================
-- ÉVÉNEMENT : SÉLECTIONNER UNE ÉQUIPE (✅ AMÉLIORÉ)
-- ==========================================

RegisterNetEvent('gdt:server:selectTeam', function(team)
    local source = source
    
    -- Vérifications de sécurité
    if not CheckCooldown(source) then
        return TriggerClientEvent('esx:showNotification', source, Constants.Errors.COOLDOWN_ACTIVE)
    end
    
    if not Utils.IsValidTeam(team) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.invalidTeam)
    end
    
    local playerData = GDT.Players[source]
    if not playerData then
        return TriggerClientEvent('esx:showNotification', source, Constants.Errors.INVALID_STATE)
    end
    
    -- Vérification équipe pleine
    local teamCount = CountPlayersInTeam(team)
    if teamCount >= Config.MaxPlayersPerTeam then
        local message = string.format(Config.Notifications.teamFull, teamCount, Config.MaxPlayersPerTeam)
        return TriggerClientEvent('esx:showNotification', source, message)
    end

    -- ✅ P1 #4 : Bloquer si partie en cours
    if GameManager and GameManager.gameActive then
        return TriggerClientEvent('esx:showNotification', source, 'Impossible de changer d\'équipe en pleine partie')
    end

    -- ✅ P1 #4 : Validation de position serveur (tolérance 10m pour lag réseau)
    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        local playerCoords = GetEntityCoords(ped)
        local zoneCoords = Config.TeamZones[team].coords
        local distance = #(playerCoords - zoneCoords)
        if distance > 10.0 then
            return TriggerClientEvent('esx:showNotification', source, 'Tu es trop loin de la zone')
        end
    end

    -- ✅ P3 #15 : Mettre à jour l'activité
    playerData.lastActivity = os.time()

    -- ✅ NOUVEAU : Log de l'ancien et du nouvel équipe
    local oldTeam = playerData.team

    -- ✅ P1 #5 : Bloquer si déjà dans cette équipe
    if playerData.team == team then
        return TriggerClientEvent('esx:showNotification', source, 'Tu es déjà dans cette équipe')
    end

    -- Changement d'équipe
    if not ChangePlayerTeam(source, team) then return end
    
    -- Application de la tenue
    TriggerClientEvent('gdt:client:applyTeamOutfit', source, team)
    
    local teamName = Utils.GetTeamName(team)
    TriggerClientEvent('esx:showNotification', source, string.format(Config.Notifications.teamSelected, teamName))
    
    -- ✅ NOUVEAU : Mettre à jour TOUTE L'ÉQUIPE
    -- Envoyer la nouvelle liste à tous les membres de la NOUVELLE équipe
    Wait(200) -- Petit délai pour que le changement soit effectif
    UpdateAllTeammatesCache(team)
    
    -- Si changement d'équipe (pas première sélection), mettre à jour l'ancienne équipe aussi
    if oldTeam and oldTeam ~= Constants.Teams.NONE and oldTeam ~= team then
        UpdateAllTeammatesCache(oldTeam)
    end
    
end)

-- ==========================================
-- ÉVÉNEMENT : QUITTER LA GDT (TÉLÉPORTE AU PED)
-- ==========================================
-- ✅ CORRECTION : skipTeleport=false pour téléporter au PED
-- ==========================================

RegisterNetEvent('gdt:server:quitGDT', function()
    local source = source

    
    local playerData = GDT.Players[source]
    
    if not playerData then
        TriggerClientEvent('esx:showNotification', source, 'Tu n\'es pas en GDT')
        
        -- Nettoyage de sécurité
        SetPlayerRoutingBucket(source, 0)
        TriggerClientEvent('gdt:client:restorePlayer', source, nil)
        
        return
    end
    
    local playerName = GetPlayerName(source) or 'Inconnu'
    local wasInGame = playerData.state == Constants.PlayerState.IN_GAME or playerData.state == Constants.PlayerState.DEAD_IN_GAME
    local playerTeam = playerData.team
    
   
    
    -- Notification au joueur
    TriggerClientEvent('esx:showNotification', source, 'Tu as quitté la GDT')
    
    -- ==========================================
    -- ✅ CORRECTION : skipTeleport=false pour téléporter au PED
    -- Le joueur quitte manuellement, donc on le téléporte au PED
    -- ==========================================
    RemovePlayerFromGDT(source, false, false)
    
    -- ✅ NOUVEAU : Mettre à jour le cache de l'équipe quittée
    if playerTeam and playerTeam ~= Constants.Teams.NONE then
        UpdateAllTeammatesCache(playerTeam)
    end
    
    -- Message dans les logs
    if wasInGame then
      
        
        -- Vérifier si ça change l'issue de la partie
        if GameManager and GameManager.gameActive then
            local redAlive = #GameManager.alivePlayers.red
            local blueAlive = #GameManager.alivePlayers.blue
          
        end
    else
        
    end
end)

-- ==========================================
-- ÉVÉNEMENT : PING (VÉRIFICATION PRÉSENCE)
-- ==========================================

RegisterNetEvent('gdt:server:ping', function()
    local source = source
    TriggerClientEvent('gdt:client:pong', source)
end)

-- ==========================================
-- ÉVÉNEMENT : MORT DU JOUEUR EN PARTIE
-- ==========================================

RegisterNetEvent('gdt:server:playerDied', function(killerServerId)
    local source = source
    OnPlayerDeath(source, killerServerId)
end)

-- ==========================================
-- ✅ ÉVÉNEMENT : DEMANDE DE LA LISTE DES COÉQUIPIERS (AMÉLIORÉ)
-- ==========================================

RegisterNetEvent('gdt:server:requestTeammates', function(team)
    local source = source
    
    if not team or team == Constants.Teams.NONE then
    
        return
    end
    

    
    local teammates = GetTeammatesList(source, team)

    
    TriggerClientEvent('gdt:client:updateTeammatesCache', source, teammates)
end)

-- ==========================================
-- ✅ FONCTION : RÉCUPÉRER LA LISTE DES COÉQUIPIERS (AMÉLIORÉE)
-- ==========================================

function GetTeammatesList(excludeSource, team)
    local teammates = {}
    

    
    for playerId, data in pairs(GDT.Players) do
        -- ✅ CRITIQUE : Ne JAMAIS inclure le joueur lui-même
        if playerId ~= excludeSource then
            -- Vérifier si c'est un coéquipier de la même équipe
            if data.team == team then
                local xPlayer = ESX.GetPlayerFromId(playerId)
                if xPlayer then
                    table.insert(teammates, {
                        id = playerId,
                        name = xPlayer.getName()
                    })
                    
                end
            end
        end
    end
    

    return teammates
end

-- ==========================================
-- ✅ FONCTION : ENVOYER LA MISE À JOUR DES COÉQUIPIERS
-- ==========================================

function SendTeammatesUpdate(source, team)
    local teammates = GetTeammatesList(source, team)
    TriggerClientEvent('gdt:client:updateTeammatesCache', source, teammates)
end

-- ==========================================
-- ✅ FONCTION : METTRE À JOUR LE CACHE DE TOUS LES COÉQUIPIERS (AMÉLIORÉE)
-- ==========================================

function UpdateAllTeammatesCache(team)
    if not team or team == Constants.Teams.NONE then return end
    

    
    local teamPlayers = {}
    
    -- Compter les joueurs de l'équipe
    for playerId, data in pairs(GDT.Players) do
        if data.team == team then
            table.insert(teamPlayers, playerId)
        end
    end
    

    
    -- Envoyer à chaque joueur de l'équipe
    for _, playerId in ipairs(teamPlayers) do
        local teammates = GetTeammatesList(playerId, team)
        
  
        
        TriggerClientEvent('gdt:client:updateTeammatesCache', playerId, teammates)
        
        Wait(50) -- Petit délai pour éviter le spam
    end
    
    
end

-- ==========================================
-- ✅ P1 #6 : ÉVÉNEMENTS SPECTATEUR SERVER-SIDE
-- ==========================================

RegisterNetEvent('gdt:server:enterSpectator', function()
    local source = source
    local playerData = GDT.Players[source]
    if not playerData then return end
    if not GameManager or not GameManager.gameActive then return end
    playerData.spectating = true
    playerData.state = Constants.PlayerState.SPECTATING
end)

RegisterNetEvent('gdt:server:exitSpectator', function()
    local source = source
    local playerData = GDT.Players[source]
    if not playerData then return end
    playerData.spectating = false
end)

-- ==========================================
-- ✅ P3 #14 : SYNC PÉRIODIQUE ÉTAT SERVEUR → CLIENT
-- ==========================================
-- Le serveur est la source de vérité. Toutes les 10s,
-- on envoie l'état réel à chaque joueur en GDT pour corriger les desync.
-- ==========================================

Citizen.CreateThread(function()
    while true do
        Wait(10000) -- Toutes les 10 secondes

        for source, data in pairs(GDT.Players) do
            local inGDT = true
            local team = data.team
            local state = data.state
            local gameActive = GameManager and GameManager.gameActive or false

            TriggerClientEvent('gdt:client:syncState', source, {
                inGDT = inGDT,
                team = team,
                state = state,
                gameActive = gameActive
            })
        end
    end
end)

-- ==========================================
-- EXPORTS GLOBAUX
-- ==========================================

_G.GetTeammatesList = GetTeammatesList
_G.SendTeammatesUpdate = SendTeammatesUpdate
_G.UpdateAllTeammatesCache = UpdateAllTeammatesCache