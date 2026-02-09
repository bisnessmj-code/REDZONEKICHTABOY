-- ==========================================
-- SERVER MAIN - INITIALISATION
-- ==========================================
-- ✅ CORRECTION : RemovePlayerFromGDT avec paramètre skipTeleport
-- ==========================================

ESX = exports["es_extended"]:getSharedObject()

-- Tables de stockage en mémoire
GDT = {
    Players = {},          -- { [source] = { team, bucket, originalOutfit, state } }
    Buckets = {},          -- { [bucketId] = { players = {}, createdAt } }
    Cooldowns = {}         -- { [source] = lastActionTime }
}

-- ==========================================
-- INITIALISATION DU SERVEUR
-- ==========================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Comptage des zones
    local zoneCount = 0
    for _ in pairs(Config.TeamZones) do
        zoneCount = zoneCount + 1
    end

    
    -- Initialisation du bucket global unique
    InitializeGlobalBucket()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    

    
    -- Éjecte tous les joueurs de la GDT
    for source, _ in pairs(GDT.Players) do
        RemovePlayerFromGDT(source, true, false)
    end
    
    -- Réinitialise tous les buckets
    ResetAllBuckets()
end)

-- ==========================================
-- GESTION DES DÉCONNEXIONS
-- ==========================================

AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if GDT.Players[source] then
        RemovePlayerFromGDT(source, true, false)
    end
end)

-- ==========================================
-- FONCTIONS UTILITAIRES
-- ==========================================

-- Vérifie le cooldown d'un joueur
function CheckCooldown(source)
    local now = GetGameTimer()
    local lastAction = GDT.Cooldowns[source] or 0
    
    if (now - lastAction) < Config.ActionCooldown then
        return false
    end
    
    GDT.Cooldowns[source] = now
    return true
end

-- Réinitialise tous les buckets
function ResetAllBuckets()
    for source, _ in pairs(GetPlayers()) do
        SetPlayerRoutingBucket(tonumber(source), 0)
    end
    
    GDT.Buckets = {}

end

-- Initialise le bucket global unique pour la GDT
function InitializeGlobalBucket()
    local bucketId = Config.BucketSettings.startBucket
    
    -- Création du bucket global
    GDT.Buckets[bucketId] = {
        players = {},
        createdAt = os.time()
    }
    
    -- Configuration du bucket (isolation réseau)
    SetRoutingBucketPopulationEnabled(bucketId, false)

end

-- Ajoute un joueur à la GDT
function AddPlayerToGDT(source, team, bucket, originalOutfit)
    GDT.Players[source] = {
        team = team,
        bucket = bucket,
        originalOutfit = originalOutfit,
        state = Constants.PlayerState.IN_LOBBY,
        joinedAt = os.time()
    }
    
    -- Ajout au bucket global
    if GDT.Buckets[bucket] then
        -- Vérifier si le joueur n'est pas déjà dans la liste
        local alreadyInBucket = false
        for _, playerId in ipairs(GDT.Buckets[bucket].players) do
            if playerId == source then
                alreadyInBucket = true
                break
            end
        end
        
        if not alreadyInBucket then
            table.insert(GDT.Buckets[bucket].players, source)
        end
    end

end

-- ==========================================
-- RETIRE UN JOUEUR DE LA GDT (VERSION CORRIGÉE)
-- ==========================================
-- ✅ PARAMÈTRES :
--    - source : ID du joueur
--    - silent : si true, pas de notification/événement client
--    - skipTeleport : si true, ne pas téléporter (déjà fait par EndGame)
-- ==========================================

function RemovePlayerFromGDT(source, silent, skipTeleport)
    local playerData = GDT.Players[source]
    if not playerData then return end
    
    local bucket = playerData.bucket
    local originalOutfit = playerData.originalOutfit
    local wasInGame = playerData.state == Constants.PlayerState.IN_GAME or playerData.state == Constants.PlayerState.DEAD_IN_GAME
    local playerTeam = playerData.team
    
    -- Valeur par défaut pour skipTeleport
    if skipTeleport == nil then
        skipTeleport = false
    end

  

    -- Arrêter le spectateur (PRIORITÉ ABSOLUE)
    TriggerClientEvent('gdt:client:stopSpectator', source)

    -- Arrêter la zone de combat
    TriggerClientEvent('gdt:client:stopCombatZone', source)

    
    -- Réanimer le joueur si mort
    TriggerClientEvent('gdt:client:revivePlayer', source)

    
    Wait(500) -- Attendre que tout soit bien arrêté
    
    -- ==========================================
    -- ÉTAPE 2 : RETRAIT DES LISTES DE JEU
    -- ==========================================
    if wasInGame and GameManager and GameManager.gameActive then

        
        -- Retirer de la liste des vivants si présent
        if playerTeam == Constants.Teams.RED or playerTeam == Constants.Teams.BLUE then
            for i, playerId in ipairs(GameManager.alivePlayers[playerTeam]) do
                if playerId == source then
                    table.remove(GameManager.alivePlayers[playerTeam], i)
                   
                    break
                end
            end
        end
        
        -- Vérifier si ça doit déclencher une fin de round
        CheckRoundEndAfterKick()
    end
    
    -- ==========================================
    -- ÉTAPE 3 : NETTOYAGE SERVEUR
    -- ==========================================

    
    -- Retour au bucket 0
    SetPlayerRoutingBucket(source, 0)

    
    -- Suppression de la table
    GDT.Players[source] = nil

    
    -- Nettoyage du bucket
    if GDT.Buckets[bucket] then
        for i, playerId in ipairs(GDT.Buckets[bucket].players) do
            if playerId == source then
                table.remove(GDT.Buckets[bucket].players, i)

                break
            end
        end
    end
    
    -- ==========================================
    -- ÉTAPE 4 : RESTAURATION DU JOUEUR
    -- ==========================================
    -- ✅ CORRECTION : Ne restaurer QUE si pas silent ET pas skipTeleport
    -- ==========================================

    if not silent then
        if skipTeleport then
            -- ✅ NOUVEAU : Restaurer uniquement la tenue, SANS téléportation
          
            TriggerClientEvent('gdt:client:restoreOutfitOnly', source, originalOutfit)
        else
            -- Comportement normal : restauration complète avec téléportation au PED
           
            TriggerClientEvent('gdt:client:restorePlayer', source, originalOutfit)
        end
    end
end

-- ==========================================
-- VÉRIFIER FIN DE ROUND APRÈS KICK (NOUVEAU)
-- ==========================================

function CheckRoundEndAfterKick()
    if not GameManager or not GameManager.gameActive then return end
    if GameManager.state ~= Constants.GameState.IN_PROGRESS then return end
    
    local redAlive = #GameManager.alivePlayers.red
    local blueAlive = #GameManager.alivePlayers.blue
    

    
    -- Si une équipe n'a plus de joueurs, terminer le round
    if redAlive == 0 and blueAlive > 0 then
    
        Citizen.CreateThread(function()
            Wait(1000) -- Petit délai pour laisser le temps au joueur kické de partir
            CheckRoundEnd()
        end)
    elseif blueAlive == 0 and redAlive > 0 then
       
        Citizen.CreateThread(function()
            Wait(1000)
            CheckRoundEnd()
        end)
    elseif redAlive == 0 and blueAlive == 0 then
      
        Citizen.CreateThread(function()
            Wait(1000)
            CheckRoundEnd()
        end)
    end
end

-- Récupère les données d'un joueur GDT
function GetPlayerGDTData(source)
    return GDT.Players[source]
end

-- Change l'équipe d'un joueur
function ChangePlayerTeam(source, newTeam)
    if not GDT.Players[source] then return false end
    if not Utils.IsValidTeam(newTeam) then return false end
    
    GDT.Players[source].team = newTeam
    
    if newTeam == Constants.Teams.RED then
        GDT.Players[source].state = Constants.PlayerState.IN_TEAM_RED
    else
        GDT.Players[source].state = Constants.PlayerState.IN_TEAM_BLUE
    end
    
    return true
end

-- Log une action serveur
function LogAction(source, action, details)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer and xPlayer.identifier or 'unknown'
    
end

-- Compter joueurs par équipe
function CountPlayersInTeam(team)
    local count = 0
    for _, data in pairs(GDT.Players) do
        if data.team == team then
            count = count + 1
        end
    end
    return count
end