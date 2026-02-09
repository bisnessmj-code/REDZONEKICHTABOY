-- ==========================================
-- SERVER EVENTS - GESTION DES ÉVÉNEMENTS
-- VERSION CORRIGÉE - ANTI-FF ROBUSTE
-- ✅ CORRECTION : Cache fiable + vérifications strictes
-- ✅ CORRECTION : quitGDT avec skipTeleport=false (téléporte au PED)
-- ==========================================

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
    
    -- ✅ NOUVEAU : Log de l'ancien et du nouvel équipe
    local oldTeam = playerData.team
    
    
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
-- EXPORTS GLOBAUX
-- ==========================================

_G.GetTeammatesList = GetTeammatesList
_G.SendTeammatesUpdate = SendTeammatesUpdate
_G.UpdateAllTeammatesCache = UpdateAllTeammatesCache