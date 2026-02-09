-- ==========================================
-- SERVER CALLBACKS - ESX CALLBACKS
-- ==========================================

-- ==========================================
-- VÉRIFIE SI UN JOUEUR PEUT REJOINDRE LA GDT (⭐ MODIFIÉ)
-- ==========================================

ESX.RegisterServerCallback('gdt:canJoin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    
    -- Si déjà en partie
    if GDT.Players[source] then
        return cb(false)
    end
    
    -- Vérifier la limite de joueurs (32 max pour 16v16)
    local totalPlayers = 0
    for _ in pairs(GDT.Players) do
        totalPlayers = totalPlayers + 1
    end
    
    if totalPlayers >= Config.MaxTotalPlayers then
        -- ==========================================
        -- ⭐ MODIFIÉ : MESSAGE DYNAMIQUE
        -- ==========================================
        -- Au lieu d'un message statique "(24/24)", on utilise string.format
        -- avec les valeurs réelles de totalPlayers et Config.MaxTotalPlayers
        local message = string.format(Config.Notifications.gdtFull, totalPlayers, Config.MaxTotalPlayers)
        TriggerClientEvent('esx:showNotification', source, message)
        return cb(false)
    end
    
    -- Vérification des permissions
    if not Permissions.CanJoinGDT(source) then
        return cb(false)
    end
    
    cb(true)
end)

-- ==========================================
-- RÉCUPÈRE L'ÉQUIPE ACTUELLE D'UN JOUEUR
-- ==========================================

ESX.RegisterServerCallback('gdt:getPlayerTeam', function(source, cb)
    local playerData = GDT.Players[source]
    
    if not playerData then
        return cb(nil)
    end
    
    cb({
        team = playerData.team,
        state = playerData.state,
        bucket = playerData.bucket
    })
end)

-- ==========================================
-- RÉCUPÈRE LA LISTE DES JOUEURS DANS LA GDT
-- ==========================================

ESX.RegisterServerCallback('gdt:getActivePlayers', function(source, cb)
    local players = {
        red = {},
        blue = {},
        lobby = {}
    }
    
    for playerId, data in pairs(GDT.Players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            local playerInfo = {
                id = playerId,
                name = xPlayer.getName(),
                team = data.team,
                state = data.state
            }
            
            if data.team == Constants.Teams.RED then
                table.insert(players.red, playerInfo)
            elseif data.team == Constants.Teams.BLUE then
                table.insert(players.blue, playerInfo)
            else
                table.insert(players.lobby, playerInfo)
            end
        end
    end
    
    cb(players)
end)

-- ==========================================
-- VÉRIFIE SI UN JOUEUR EST ADMIN
-- ==========================================

ESX.RegisterServerCallback('gdt:isAdmin', function(source, cb)
    cb(Permissions.IsAdmin(source))
end)

-- ==========================================
-- CLASSEMENT TOP 20 KILLERS
-- ==========================================

ESX.RegisterServerCallback('gdt:getLeaderboard', function(source, cb)
    Database.GetTop20Killers(function(results)
        cb(results)
    end)
end)