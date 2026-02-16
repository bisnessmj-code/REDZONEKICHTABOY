-- ==========================================
-- SERVER TEAMS - COMMANDES ADMIN
-- ==========================================

-- ==========================================
-- ? NOUVELLE COMMANDE : /gtpedopen [true/false]
-- ==========================================

RegisterCommand('gtpedopen', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    if #args < 1 then
        return TriggerClientEvent('esx:showNotification', source, '?? Usage: /gtpedopen [true/false]')
    end
    
    local input = string.lower(args[1])
    local enabled
    
    -- Conversion de l'input en bool�en
    if input == 'true' or input == '1' or input == 'on' or input == 'oui' then
        enabled = true
    elseif input == 'false' or input == '0' or input == 'off' or input == 'non' then
        enabled = false
    else
        return TriggerClientEvent('esx:showNotification', source, '? Valeur invalide (true/false)')
    end
    
    -- Envoyer � TOUS les clients
    TriggerClientEvent('gdt:client:togglePed', -1, enabled)
    
    -- Feedback � l'admin
    local status = enabled and '? ACTIV�' or '? D�SACTIV�'
    TriggerClientEvent('esx:showNotification', source, '^2PED GDT '..status)
    
    -- Message d�taill� dans le chat
    local message = '^5=== PED GDT '..status..' ===^7\n'
    message = message .. '^3�tat: ^7'..(enabled and 'Visible pour tous' or 'Masqu� pour tous')..'\n'
    message = message .. '^3Admin: ^7'..GetPlayerName(source)..'\n'
    message = message .. '^5===============================^7'
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
        args = { message }
    })
    
    -- Log de l'action
    LogAction(source, 'TOGGLE_PED', '�tat: '..(enabled and 'ACTIV�' or 'D�SACTIV�'))
    

end, false)

-- ==========================================
-- COMMANDE : /gteq [id] [rouge/bleu]
-- ==========================================

RegisterCommand('gteq', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    if #args < 2 then
        return TriggerClientEvent('esx:showNotification', source, 'Usage: /gteq [id] [rouge/bleu]')
    end
    
    local targetId = tonumber(args[1])
    local teamInput = string.lower(args[2])
    
    if not targetId or not GetPlayerName(targetId) then
        return TriggerClientEvent('esx:showNotification', source, 'Joueur introuvable')
    end
    
    -- Conversion de l'input en �quipe
    local team
    if teamInput == 'rouge' or teamInput == 'red' then
        team = Constants.Teams.RED
    elseif teamInput == 'bleu' or teamInput == 'blue' then
        team = Constants.Teams.BLUE
    else
        return TriggerClientEvent('esx:showNotification', source, 'equipe invalide (rouge/bleu)')
    end
    
    -- V�rification si le joueur est en GDT
    if not GDT.Players[targetId] then
        return TriggerClientEvent('esx:showNotification', source, 'Ce joueur n\'est pas en GDT')
    end
    
    -- Changement d'�quipe
    if ChangePlayerTeam(targetId, team) then
        TriggerClientEvent('gdt:client:applyTeamOutfit', targetId, team)
        
        local teamName = Utils.GetTeamName(team)
        TriggerClientEvent('esx:showNotification', source, '^2Joueur '..GetPlayerName(targetId)..' chang� vers �quipe '..teamName)
        TriggerClientEvent('esx:showNotification', targetId, '^2Un admin t\'a chang� d\'�quipe : '..teamName)
        
        LogAction(source, 'ADMIN_CHANGE_TEAM', 'Target: '..targetId..' | Team: '..team)
    else
        TriggerClientEvent('esx:showNotification', source, 'Erreur lors du changement d\'�quipe')
    end
end, false)

-- ==========================================
-- COMMANDE : /gtkick [id] (CORRIG�E ET AM�LIOR�E)
-- ==========================================

RegisterCommand('gtkick', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    if #args < 1 then
        return TriggerClientEvent('esx:showNotification', source, 'Usage: /gtkick [id]')
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId or not GetPlayerName(targetId) then
        return TriggerClientEvent('esx:showNotification', source, 'Joueur introuvable')
    end
    
    -- V�rification si le joueur est en GDT
    if not GDT.Players[targetId] then
        return TriggerClientEvent('esx:showNotification', source, 'Ce joueur n\'est pas en GDT')
    end
    
    -- R�cup�rer les infos avant de kick
    local targetName = GetPlayerName(targetId)
    local targetData = GDT.Players[targetId]
    local targetTeam = targetData and targetData.team or 'inconnu'
    local wasInGame = targetData and (targetData.state == Constants.PlayerState.IN_GAME or targetData.state == Constants.PlayerState.DEAD_IN_GAME or targetData.state == Constants.PlayerState.SPECTATING)
    
    
    -- ==========================================
    -- NETTOYAGE COMPLET VIA RemovePlayerFromGDT
    -- ==========================================
    RemovePlayerFromGDT(targetId, false)
    
    -- ==========================================
    -- FEEDBACK
    -- ==========================================
    TriggerClientEvent('esx:showNotification', source, '^2? Joueur '..targetName..' �ject� de la GDT')
    TriggerClientEvent('esx:showNotification', targetId, '? Tu as �t� �ject� de la GDT par un admin')
    
    -- Log d�taill�
    LogAction(source, 'ADMIN_KICK', 'Target: '..targetId..' ('..targetName..') | Team: '..targetTeam..' | InGame: '..tostring(wasInGame))
    
    -- ==========================================
    -- INFO SUPPL�MENTAIRE SI EN PARTIE
    -- ==========================================
    if wasInGame and GameManager and GameManager.gameActive then
        local redAlive = #GameManager.alivePlayers.red
        local blueAlive = #GameManager.alivePlayers.blue
        
        TriggerClientEvent('chat:addMessage', source, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;"><span style="color: #FFA500;">?? INFO:</span> {0}</div>',
            args = { string.format('Joueurs restants - Rouge: %d | Bleu: %d', redAlive, blueAlive) }
        })
        
    end
end, false)

-- ==========================================
-- COMMANDE : /gtkickall (KICK TOUS LES JOUEURS)
-- ==========================================

RegisterCommand('gtkickall', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    
    -- Compter les joueurs par cat�gorie
    local stats = {
        total = 0,
        lobby = 0,
        red = 0,
        blue = 0,
        inGame = 0,
        spectators = 0
    }
    
    -- Cr�er une copie de la table pour �viter les probl�mes d'it�ration
    local playersToKick = {}
    for playerId, data in pairs(GDT.Players) do
        table.insert(playersToKick, {
            id = playerId,
            name = GetPlayerName(playerId),
            team = data.team,
            state = data.state
        })
        
        -- Statistiques
        stats.total = stats.total + 1
        
        if data.team == Constants.Teams.NONE then
            stats.lobby = stats.lobby + 1
        elseif data.team == Constants.Teams.RED then
            stats.red = stats.red + 1
        elseif data.team == Constants.Teams.BLUE then
            stats.blue = stats.blue + 1
        end
        
        if data.state == Constants.PlayerState.IN_GAME then
            stats.inGame = stats.inGame + 1
        elseif data.state == Constants.PlayerState.DEAD_IN_GAME then
            stats.spectators = stats.spectators + 1
        end
    end
    
    -- V�rifier qu'il y a des joueurs
    if stats.total == 0 then
        TriggerClientEvent('esx:showNotification', source, '^3Aucun joueur en GDT')
        return
    end
    
    
    -- ==========================================
    -- �TAPE 1 : ANNULER LA PARTIE SI ACTIVE
    -- ==========================================
    if GameManager and GameManager.gameActive then
        local success, msg = CancelGame()
        if success then
        end
        Wait(1000)
    end
    
    -- ==========================================
    -- �TAPE 2 : KICK TOUS LES JOUEURS
    -- ==========================================
    
    local kickedCount = 0
    local failedKicks = {}
    
    for _, playerInfo in ipairs(playersToKick) do
        local playerId = playerInfo.id
        local playerName = playerInfo.name
        

        
        local success = pcall(function()
            RemovePlayerFromGDT(playerId, false)
        end)
        
        if success then
            TriggerClientEvent('esx:showNotification', playerId, '? Tous les joueurs ont �t� �ject�s par un admin')
            kickedCount = kickedCount + 1
        else
            table.insert(failedKicks, {id = playerId, name = playerName})
        end
        
        Wait(100)
    end
    
    -- ==========================================
    -- �TAPE 3 : RESET COMPLET DU SYST�ME
    -- ==========================================
    
    ResetAllBuckets()
    GDT.Players = {}
    
    if GameManager then
        GameManager.state = Constants.GameState.WAITING
        GameManager.gameActive = false
        GameManager.currentRound = 0
        GameManager.currentMapId = nil
        GameManager.scores = { red = 0, blue = 0 }
        GameManager.alivePlayers = { red = {}, blue = {} }
    end
    
    
    if #failedKicks > 0 then
        for _, failed in ipairs(failedKicks) do
        end
    end
    
    -- ==========================================
    -- FEEDBACK � L'ADMIN
    -- ==========================================
    local message = '^5=== KICK MASSIF TERMIN� ===^7\n'
    message = message .. string.format('^2? %d joueurs �ject�s^7\n', kickedCount)
    message = message .. '\n^3D�tails:^7\n'
    message = message .. string.format('   Lobby: %d\n', stats.lobby)
    message = message .. string.format('   �quipe Rouge: %d\n', stats.red)
    message = message .. string.format('   �quipe Bleue: %d\n', stats.blue)
    message = message .. string.format('   En partie: %d\n', stats.inGame)
    message = message .. string.format('   Spectateurs: %d\n', stats.spectators)
    
    if #failedKicks > 0 then
        message = message .. '\n? �checs: '..#failedKicks..'^7\n'
        for _, failed in ipairs(failedKicks) do
            message = message .. string.format('   ? %s (ID %d)\n', failed.name, failed.id)
        end
    end
    
    message = message .. '\n^2? Syst�me GDT compl�tement reset^7'
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
        args = { message }
    })
    
    TriggerClientEvent('esx:showNotification', source, '^2? '..kickedCount..' joueurs �ject�s de la GDT')
    
    LogAction(source, 'ADMIN_KICKALL', 'Total: '..kickedCount..' | Lobby: '..stats.lobby..' | Rouge: '..stats.red..' | Bleu: '..stats.blue)
end, false)

-- ==========================================
-- COMMANDE : /gtlist (Liste des joueurs)
-- ==========================================

RegisterCommand('gtlist', function(source)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    local count = 0
    local message = '^5=== JOUEURS EN GDT ===^7\n'
    
    for playerId, data in pairs(GDT.Players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            local teamName = Utils.GetTeamName(data.team)
            local teamColor = Utils.GetTeamColor(data.team)
            local stateIcon = ''
            
            if data.state == Constants.PlayerState.IN_LOBBY then
                stateIcon = '??'
            elseif data.state == Constants.PlayerState.IN_GAME then
                stateIcon = '??'
            elseif data.state == Constants.PlayerState.DEAD_IN_GAME then
                stateIcon = '??'
            end
            
            message = message .. string.format('%s%s [%d] %s - �quipe: %s%s^7 - Bucket: %d\n', 
                stateIcon, teamColor, playerId, xPlayer.getName(), teamColor, teamName, data.bucket)
            count = count + 1
        end
    end
    
    if GameManager and GameManager.gameActive then
        local mapName = GameManager.currentMapId and Config.Maps[GameManager.currentMapId].name or 'N/A'
        message = message .. '\n^2?? PARTIE EN COURS^7\n'
        message = message .. string.format('   Map: %s (ID %s)\n', mapName, tostring(GameManager.currentMapId))
        message = message .. string.format('   Round: %d/%d\n', GameManager.currentRound, Config.GameSettings.maxRounds)
        message = message .. string.format('   Score: Rouge %d - %d Bleu\n', GameManager.scores.red, GameManager.scores.blue)
        message = message .. string.format('   Vivants: Rouge %d - %d Bleu\n', #GameManager.alivePlayers.red, #GameManager.alivePlayers.blue)
    end
    
    message = message .. string.format('\n^5Total: %d joueurs^7', count)
    message = message .. '\n^3Commandes: /gdtkick [id] | /gdtkickall | /openpedgdt [true/false]^7'
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
        args = { message }
    })
    
    LogAction(source, 'ADMIN_LIST', 'Total: '..count)
end, false)

-- ==========================================
-- COMMANDE : /gtreset (Reset complet)
-- ==========================================

RegisterCommand('gtreset', function(source)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    local count = 0
    
    if GameManager and GameManager.gameActive then
        local success, msg = CancelGame()
    end
    
    for playerId, _ in pairs(GDT.Players) do
        RemovePlayerFromGDT(playerId, false)
        TriggerClientEvent('esx:showNotification', playerId, 'La GDT a été réinitialisée')
        count = count + 1
    end
    
    ResetAllBuckets()
    
    TriggerClientEvent('esx:showNotification', source, '^2GDT réinitialisée ('..count..' joueurs éjectés)')
    
    
end, false)

-- ==========================================
-- COMMANDE : /gtstart [mapId] (AVEC MAPS)
-- ==========================================

RegisterCommand('gtstart', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    local mapId = tonumber(args[1]) or Config.DefaultMapId
    
    if not GameManager then
        return TriggerClientEvent('esx:showNotification', source, 'Erreur: GameManager non initialis�')
    end
    
    if not Config.Maps[mapId] then
        TriggerClientEvent('esx:showNotification', source, Config.Notifications.mapNotFound)
        
        local availableMaps = '\n^5=== MAPS DISPONIBLES ===^7\n'
        for id, mapData in pairs(Config.Maps) do
            if mapData.enabled then
                availableMaps = availableMaps .. string.format('^2[%d]^7 %s - %s\n', id, mapData.name, mapData.description)
            else
                availableMaps = availableMaps .. string.format('^8[%d]^7 %s - (Désactivée)^7\n', id, mapData.name)
            end
        end
        availableMaps = availableMaps .. '^7\nUsage: ^3/gtstart [mapId]^7'
        
        TriggerClientEvent('chat:addMessage', source, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
            args = { availableMaps }
        })
        
        return
    end
    
    if not Config.Maps[mapId].enabled then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.mapDisabled)
    end
    
    local success, message = StartGame(mapId)
    
    if success then
        local mapName = Config.Maps[mapId].name
        TriggerClientEvent('esx:showNotification', source, '^2'..message..' | Map: '..mapName)
        
        for playerId, _ in pairs(GDT.Players) do
            TriggerClientEvent('esx:showNotification', playerId, '^3Map sélectionnée : ^2'..mapName)
        end
        
    else
        TriggerClientEvent('esx:showNotification', source, '? '..message)
    end
end, false)

-- ==========================================
-- COMMANDE : /gtmaps (Liste des maps)
-- ==========================================

RegisterCommand('gtmaps', function(source)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    local message = '^5=== MAPS DISPONIBLES ===^7\n'
    local enabledCount = 0
    local totalCount = 0
    
    for id, mapData in pairs(Config.Maps) do
        totalCount = totalCount + 1
        
        if mapData.enabled then
            enabledCount = enabledCount + 1
            message = message .. string.format('^2[%d] %s^7\n', id, mapData.name)
            message = message .. string.format('    + %s\n', mapData.description)
            message = message .. string.format('    + Zone: Rayon %.0fm | Centre: %.0f, %.0f\n', 
                mapData.combatZone.radius,
                mapData.combatZone.center.x,
                mapData.combatZone.center.y
            )
        else
            message = message .. string.format('^8[%d] %s (Désactivée)^7\n', id, mapData.name)
        end
    end
    
    message = message .. string.format('\n^5Total: %d maps (%d activées)^7', totalCount, enabledCount)
    message = message .. '\n^3Usage: /gtstart [mapId]^7'
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
        args = { message }
    })
    
end, false)

-- ==========================================
-- COMMANDE : /gtann [texte] (CORRIG�E BUCKET)
-- ==========================================

RegisterCommand('gtann', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    if #args < 1 then
        return TriggerClientEvent('esx:showNotification', source, 'Usage: /gtann [texte]')
    end
    
    local message = table.concat(args, ' ')

    
    local count = 0
    for playerId, playerData in pairs(GDT.Players) do
        local playerBucket = GetPlayerRoutingBucket(playerId)
        TriggerClientEvent('gdt:client:showAnnounce', playerId, message, Config.GameSettings.announceDuration)
        count = count + 1
    end
    

    
    TriggerClientEvent('esx:showNotification', source, '^2Annonce envoyée à '..count..' joueur(s)')
    
    LogAction(source, 'ANNOUNCE', 'Message: '..message..' | Recipients: '..count)
end, false)

-- ==========================================
-- COMMANDE : /gtstop (Arr�ter partie)
-- ==========================================

RegisterCommand('gtstop', function(source)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    if not GameManager then
        return TriggerClientEvent('esx:showNotification', source, 'GameManager non initialis�')
    end
    
    local success, message = CancelGame()
    
    if success then
        TriggerClientEvent('esx:showNotification', source, '^2'..message)
    else
        TriggerClientEvent('esx:showNotification', source, '? '..message)
    end
end, false)

-- ==========================================
-- COMMANDE TEST : /gttest (DEBUG)
-- ==========================================

RegisterCommand('gttest', function(source, args)
    -- V�rification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    local testMessage = args[1] and table.concat(args, ' ') or 'TEST ANNONCE GDT'
    
    TriggerClientEvent('gdt:client:showAnnounce', source, testMessage, 5000)
    
    Wait(100)
    
    for playerId, playerData in pairs(GDT.Players) do
    
        TriggerClientEvent('gdt:client:showAnnounce', playerId, testMessage, 5000)
    end
    
    TriggerClientEvent('gdt:client:showAnnounce', -1, testMessage, 5000)
    
    
    TriggerClientEvent('esx:showNotification', source, '^2Test d\'annonce envoy� !')
end, false)

-- ==========================================
-- COMMANDE : /gtdebug (Info debug)
-- ==========================================

RegisterCommand('gtdebug', function(source)
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end
    
    local myBucket = GetPlayerRoutingBucket(source)
    local inGDT = GDT.Players[source] and 'OUI' or 'NON'
    
    local info = '^5=== DEBUG GDT ===^7\n'
    info = info .. '^3Ton ID: ^7'..source..'\n'
    info = info .. '^3Ton bucket: ^7'..myBucket..'\n'
    info = info .. '^3Dans GDT: ^7'..inGDT..'\n'
    
    if GDT.Players[source] then
        info = info .. '^3équipe: ^7'..GDT.Players[source].team..'\n'
        info = info .. '^3état: ^7'..GDT.Players[source].state..'\n'
    end
    
    if GameManager and GameManager.gameActive then
        local currentMapId = GameManager.currentMapId or 'Inconnue'
        local currentMapName = GameManager.currentMapId and Config.Maps[GameManager.currentMapId].name or 'N/A'
        info = info .. '^3Partie active: ^2OUI^7\n'
        info = info .. '^3Map actuelle: ^7['..currentMapId..'] '..currentMapName..'\n'
        info = info .. '^3Round: ^7'..GameManager.currentRound..'\n'
    else
        info = info .. '^3Partie active: ? NON^7\n'
    end
    
    info = info .. '^5Total joueurs GDT: ^7'..Utils.TableSize(GDT.Players)
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
        args = { info }
    })
end, false)

-- ==========================================
-- NOUVELLE COMMANDE : /gtquit (POUR TOUS LES JOUEURS)
-- ==========================================
-- Permet aux joueurs normaux de quitter la GDT
-- Commande serveur de secours si la commande client bug

RegisterCommand('gtquit', function(source)
    -- V�rifier que c'est un joueur (pas la console)
    if source == 0 then
        return
    end

    -- V�rifier si le joueur est en GDT
    if not GDT.Players[source] then
        TriggerClientEvent('esx:showNotification', source, 'Tu n\'es pas en GDT')
        return
    end

    -- Notification
    TriggerClientEvent('esx:showNotification', source, 'Sortie de la GDT en cours...')

    Wait(500)

    -- D�clencher l'�v�nement de quit (qui utilisera RemovePlayerFromGDT)
    TriggerEvent('gdt:server:quitGDT', source)
end, false)

-- ==========================================
-- COMMANDE : /gteqlist (Toggle liste équipes persistante)
-- ==========================================

RegisterCommand('gteqlist', function(source)
    -- Vérification admin
    if not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end

    -- Envoyer le toggle au client (le client gère l'état on/off)
    TriggerClientEvent('gdt:client:toggleTeamList', source)
end, false)

-- ==========================================
-- ÉVÉNEMENT : Demande de données pour la liste d'équipes
-- ==========================================

RegisterNetEvent('gdt:server:requestTeamList', function()
    local source = source

    -- Collecter les données de chaque équipe
    local redPlayers = {}
    local bluePlayers = {}
    local lobbyPlayers = {}

    for playerId, data in pairs(GDT.Players) do
        local name = GetPlayerName(playerId) or 'Inconnu'
        local stateLabel = ''

        if data.state == Constants.PlayerState.IN_GAME then
            stateLabel = 'EN JEU'
        elseif data.state == Constants.PlayerState.DEAD_IN_GAME then
            stateLabel = 'MORT'
        elseif data.state == Constants.PlayerState.SPECTATING then
            stateLabel = 'SPEC'
        elseif data.state == Constants.PlayerState.IN_LOBBY then
            stateLabel = 'LOBBY'
        elseif data.state == Constants.PlayerState.IN_TEAM_RED or data.state == Constants.PlayerState.IN_TEAM_BLUE then
            stateLabel = 'PRET'
        end

        local entry = { id = playerId, name = name, state = stateLabel }

        if data.team == Constants.Teams.RED then
            table.insert(redPlayers, entry)
        elseif data.team == Constants.Teams.BLUE then
            table.insert(bluePlayers, entry)
        else
            table.insert(lobbyPlayers, entry)
        end
    end

    -- Infos partie
    local gameInfo = nil
    if GameManager and GameManager.gameActive then
        local mapName = GameManager.currentMapId and Config.Maps[GameManager.currentMapId] and Config.Maps[GameManager.currentMapId].name or 'N/A'
        gameInfo = {
            round = GameManager.currentRound,
            maxRounds = Config.GameSettings.maxRounds,
            scoreRed = GameManager.scores.red,
            scoreBlue = GameManager.scores.blue,
            mapName = mapName
        }
    end

    TriggerClientEvent('gdt:client:updateTeamList', source, {
        red = redPlayers,
        blue = bluePlayers,
        lobby = lobbyPlayers,
        gameInfo = gameInfo
    })
end)