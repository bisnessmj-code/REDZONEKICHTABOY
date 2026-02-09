--[[
    Module Commands - Panel Admin Fight League
    Commandes administratives avec gestion des permissions et buckets
]]

local Commands = {}

-- Position du Lobby
local LobbyPosition = {
    x = -5804.123047,
    y = -920.531860,
    z = 505.320801,
    heading = 274.960632
}

-- Instance par defaut
local DefaultBucket = 0

-- Rayon max pour repair
local MaxRepairRadius = 100.0

-- Stockage des positions precedentes (pour /return)
local savedPositions = {}

-- ══════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════

-- Verifier si un joueur est staff
local function IsStaff(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    return Permissions.Grades[group] ~= nil
end

-- Verifier si un joueur est admin/owner
local function IsAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    return group == 'admin' or group == 'owner'
end

-- Envoyer une notification au joueur (avec couleurs GTA)
local function Notify(source, message)
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 255, 255},
        multiline = true,
        args = {'', message}
    })
end

-- Sauvegarder la position d'un joueur
local function SavePlayerPosition(playerId)
    local coords = Helpers.GetPlayerCoords(playerId)
    local bucket = GetPlayerRoutingBucket(playerId)

    if coords then
        savedPositions[playerId] = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            bucket = bucket,
            timestamp = os.time()
        }
        return true
    end
    return false
end

-- Obtenir le nom du joueur
local function GetName(source)
    return GetPlayerName(source) or 'Inconnu'
end

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DE TELEPORTATION
-- ══════════════════════════════════════════════════════════════

-- /tp [id] - Teleporter un joueur vers soi
RegisterCommand('tp', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        Notify(source, 'Usage: /tp [id]')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local staffCoords = Helpers.GetPlayerCoords(source)
    if not staffCoords then
        Notify(source, 'Impossible de recuperer vos coordonnees')
        return
    end

    local targetName = GetName(targetId)
    local staffBucket = GetPlayerRoutingBucket(source)
    local targetBucket = GetPlayerRoutingBucket(targetId)

    -- Sauvegarder la position du joueur cible
    SavePlayerPosition(targetId)

    -- Changer le bucket du joueur pour le mettre dans le meme que l'admin
    if targetBucket ~= staffBucket then
        SetPlayerRoutingBucket(targetId, staffBucket)
        Wait(150) -- Attendre que le changement soit effectif
    end

    -- Teleporter le joueur
    TriggerClientEvent('admin:teleportToCoords', targetId, staffCoords.x, staffCoords.y, staffCoords.z, 0.0)

    Notify(source, '' .. targetName .. ' teleporte vers vous')
    Notify(targetId, 'Vous avez ete teleporte par un admin')

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.TELEPORT, 'tp_bring', session.identifier, session.name, xTarget.getIdentifier(), targetName, {from_bucket = targetBucket, to_bucket = staffBucket})

        -- Discord webhook
        if Discord and Discord.LogTeleport then
            Discord.LogTeleport('tp_bring', session.name, targetName, nil)
        end
    end
end, false)

-- /tpa [id] - Se teleporter vers un joueur
RegisterCommand('tpa', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        Notify(source, 'Usage: /tpa [id]')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local targetCoords = Helpers.GetPlayerCoords(targetId)
    if not targetCoords then
        Notify(source, 'Impossible de recuperer les coordonnees du joueur')
        return
    end

    local targetName = GetName(targetId)
    local staffBucket = GetPlayerRoutingBucket(source)
    local targetBucket = GetPlayerRoutingBucket(targetId)

    -- Sauvegarder la position de l'admin avant teleportation
    SavePlayerPosition(source)

    -- Changer le bucket de l'admin pour le mettre dans le meme que la cible
    if staffBucket ~= targetBucket then
        SetPlayerRoutingBucket(source, targetBucket)
        Wait(200) -- Attendre que le changement soit effectif
    end

    -- Teleporter l'admin
    TriggerClientEvent('admin:teleportToCoords', source, targetCoords.x, targetCoords.y, targetCoords.z, 0.0)

    Notify(source, 'Teleporte vers ' .. targetName)

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.TELEPORT, 'tp_goto', session.identifier, session.name, xTarget.getIdentifier(), targetName, {to_bucket = targetBucket})

        -- Discord webhook
        if Discord and Discord.LogTeleport then
            Discord.LogTeleport('tp_goto', session.name, targetName, nil)
        end
    end
end, false)

-- /return [id] - Retourner un joueur a sa position precedente
RegisterCommand('return', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1]) or source
    local savedPos = savedPositions[targetId]

    if not savedPos then
        Notify(source, 'Aucune position precedente sauvegardee pour ce joueur')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local targetName = GetName(targetId)
    local currentBucket = GetPlayerRoutingBucket(targetId)

    -- Remettre dans le bucket precedent
    if currentBucket ~= savedPos.bucket then
        SetPlayerRoutingBucket(targetId, savedPos.bucket)
        Wait(150)
    end

    -- Teleporter aux anciennes coordonnees
    TriggerClientEvent('admin:teleportToCoords', targetId, savedPos.x, savedPos.y, savedPos.z, 0.0)

    -- Supprimer la position sauvegardee
    savedPositions[targetId] = nil

    if targetId == source then
        Notify(source, 'Retourne a votre position et bucket precedent')
    else
        Notify(source, '' .. targetName .. ' retourne a sa position et bucket precedent')
        Notify(targetId, 'Vous avez ete retourne a votre position precedente')
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.TELEPORT, 'tp_return', session.identifier, session.name, xTarget.getIdentifier(), targetName, {to_bucket = savedPos.bucket})

        -- Discord webhook
        if Discord and Discord.LogTeleport then
            Discord.LogTeleport('tp_return', session.name, targetName, nil)
        end
    end
end, false)

-- /tpall - Teleporter tous les joueurs vers soi (Admin Only)
RegisterCommand('tpall', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        Notify(source, 'Commande reservee aux admins')
        return
    end

    local staffCoords = Helpers.GetPlayerCoords(source)
    if not staffCoords then
        Notify(source, 'Impossible de recuperer vos coordonnees')
        return
    end

    local staffBucket = GetPlayerRoutingBucket(source)
    local count = 0

    for _, playerId in ipairs(ESX.GetPlayers()) do
        if playerId ~= source then
            -- Sauvegarder la position de chaque joueur
            SavePlayerPosition(playerId)

            -- Changer l'instance si necessaire
            local playerBucket = GetPlayerRoutingBucket(playerId)
            if playerBucket ~= staffBucket then
                SetPlayerRoutingBucket(playerId, staffBucket)
            end

            TriggerClientEvent('admin:teleportToCoords', playerId, staffCoords.x, staffCoords.y, staffCoords.z, 0.0)
            Notify(playerId, 'Vous avez ete teleporte par un admin')
            count = count + 1
        end
    end

    Notify(source, '' .. count .. ' joueur(s) teleporte(s) vers vous')

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.TELEPORT, 'tp_all', session.identifier, session.name, nil, nil, {count = count})

        -- Discord webhook
        if Discord and Discord.LogTeleport then
            Discord.LogTeleport('tp_all', session.name, nil, {count = count})
        end
    end
end, false)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES LOBBY/INSTANCE
-- ══════════════════════════════════════════════════════════════

-- /instancebyid [id] - Recuperer un joueur bloque dans une instance
RegisterCommand('instancebyid', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        Notify(source, 'Usage: /instancebyid [id]')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local targetName = GetName(targetId)
    local adminName = GetName(source)
    local currentBucket = GetPlayerRoutingBucket(targetId)

    -- Sauvegarder la position actuelle (pour /return)
    SavePlayerPosition(targetId)

    -- Remettre dans l'instance 0
    SetPlayerRoutingBucket(targetId, DefaultBucket)
    Wait(200)

    -- Teleporter au lobby
    TriggerClientEvent('admin:teleportToCoords', targetId, LobbyPosition.x, LobbyPosition.y, LobbyPosition.z, LobbyPosition.heading)

    -- Log console
    if Config.Debug then print('[ADMIN] ' .. adminName .. ' a ramene ' .. targetName .. ' (ID: ' .. targetId .. ') de l\'instance ' .. currentBucket .. ' vers l\'instance 0 (Lobby)') end

    Notify(source, '' .. targetName .. ' ramene au lobby (Instance: ' .. currentBucket .. ' -> 0)')
    Notify(targetId, 'Vous avez ete ramene au lobby par un admin (Vous etiez bloque dans l\'instance ' .. currentBucket .. ')')

    -- Log DB
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.TELEPORT, 'instance_reset', session.identifier, session.name, xTarget.getIdentifier(), targetName, {from_bucket = currentBucket, to_bucket = 0})
    end
end, false)

-- /lobbyforce [id] - Se ramener soi-meme ou un joueur au lobby
RegisterCommand('lobbyforce', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1])
    local adminName = GetName(source)

    -- Si un ID est fourni, ramener ce joueur
    if targetId then
        local xTarget = ESX.GetPlayerFromId(targetId)
        if not xTarget then
            Notify(source, 'Joueur introuvable')
            return
        end

        local targetName = GetName(targetId)
        local currentBucket = GetPlayerRoutingBucket(targetId)

        -- Sauvegarder la position actuelle (pour /return)
        SavePlayerPosition(targetId)

        -- Remettre dans l'instance 0
        SetPlayerRoutingBucket(targetId, DefaultBucket)
        Wait(200)

        -- Teleporter au lobby
        TriggerClientEvent('admin:teleportToCoords', targetId, LobbyPosition.x, LobbyPosition.y, LobbyPosition.z, LobbyPosition.heading)

        if Config.Debug then print('[ADMIN] ' .. adminName .. ' a ramene ' .. targetName .. ' (ID: ' .. targetId .. ') au lobby (Instance: ' .. currentBucket .. ' -> 0)') end

        Notify(source, '' .. targetName .. ' ramene au lobby (Instance: ' .. currentBucket .. ' -> 0)')
        Notify(targetId, 'Vous avez ete ramene au lobby par un admin')

        -- Log DB
        local session = Auth.GetSession(source)
        if session then
            Database.AddLog(Enums.LogCategory.TELEPORT, 'lobby_force', session.identifier, session.name, xTarget.getIdentifier(), targetName, {from_bucket = currentBucket})
        end
    else
        -- Se ramener soi-meme
        local currentBucket = GetPlayerRoutingBucket(source)

        -- Remettre dans l'instance 0
        SetPlayerRoutingBucket(source, DefaultBucket)
        Wait(200)

        -- Teleporter au lobby
        TriggerClientEvent('admin:teleportToCoords', source, LobbyPosition.x, LobbyPosition.y, LobbyPosition.z, LobbyPosition.heading)

        if Config.Debug then print('[ADMIN] ' .. adminName .. ' s\'est ramene au lobby (Instance: ' .. currentBucket .. ' -> 0)') end

        if currentBucket ~= DefaultBucket then
            Notify(source, 'Vous avez ete ramene au lobby (Instance: ' .. currentBucket .. ' -> 0)')
        else
            Notify(source, 'Vous avez ete teleporte au lobby')
        end

        -- Log DB
        local session = Auth.GetSession(source)
        if session then
            Database.AddLog(Enums.LogCategory.TELEPORT, 'lobby_self', session.identifier, session.name, session.identifier, session.name, {from_bucket = currentBucket})
        end
    end
end, false)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DE SOIN
-- ══════════════════════════════════════════════════════════════

-- /heal [id] - Soigner un joueur
RegisterCommand('heal', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1]) or source
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local targetName = GetName(targetId)

    TriggerClientEvent('admin:healPlayer', targetId)

    if targetId == source then
        Notify(source, 'Vous avez ete soigne')
    else
        Notify(source, '' .. targetName .. ' a ete soigne')
        Notify(targetId, 'Vous avez ete soigne par un admin')
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.PLAYER, 'player_heal', session.identifier, session.name, xTarget.getIdentifier(), targetName, {})

        -- Discord webhook
        if Discord and Discord.LogPlayer then
            Discord.LogPlayer('player_heal', session.name, targetName, nil)
        end
    end
end, false)

-- /revive [id] - Reanimer un joueur
RegisterCommand('revive', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1]) or source
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local targetName = GetName(targetId)

    TriggerClientEvent('admin:revivePlayer', targetId)

    if targetId == source then
        Notify(source, 'Vous avez ete reanime')
    else
        Notify(source, '' .. targetName .. ' a ete reanime')
        Notify(targetId, 'Vous avez ete reanime par un admin')
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.PLAYER, 'player_revive', session.identifier, session.name, xTarget.getIdentifier(), targetName, {})

        -- Discord webhook
        if Discord and Discord.LogPlayer then
            Discord.LogPlayer('player_revive', session.name, targetName, nil)
        end
    end
end, false)

-- /healall - Soigner tous les joueurs (Admin Only)
RegisterCommand('healall', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        Notify(source, 'Commande reservee aux admins')
        return
    end

    local count = 0
    for _, playerId in ipairs(ESX.GetPlayers()) do
        TriggerClientEvent('admin:healPlayer', playerId)
        count = count + 1
    end

    Notify(source, '' .. count .. ' joueur(s) soigne(s)')

    -- Notification globale
    for _, playerId in ipairs(ESX.GetPlayers()) do
        if playerId ~= source then
            Notify(playerId, 'Tous les joueurs ont ete soignes par un admin')
        end
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.PLAYER, 'heal_all', session.identifier, session.name, nil, nil, {count = count})

        -- Discord webhook
        if Discord and Discord.LogPlayer then
            Discord.LogPlayer('heal_all', session.name, nil, {count = count})
        end
    end
end, false)

-- /reviveall - Reanimer tous les joueurs (Admin Only)
RegisterCommand('reviveall', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        Notify(source, 'Commande reservee aux admins')
        return
    end

    local count = 0
    for _, playerId in ipairs(ESX.GetPlayers()) do
        TriggerClientEvent('admin:revivePlayer', playerId)
        count = count + 1
    end

    Notify(source, '' .. count .. ' joueur(s) reanime(s)')

    -- Notification globale
    for _, playerId in ipairs(ESX.GetPlayers()) do
        if playerId ~= source then
            Notify(playerId, 'Tous les joueurs ont ete reanimes par un admin')
        end
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.PLAYER, 'revive_all', session.identifier, session.name, nil, nil, {count = count})

        -- Discord webhook
        if Discord and Discord.LogPlayer then
            Discord.LogPlayer('revive_all', session.name, nil, {count = count})
        end
    end
end, false)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DE VEHICULE
-- ══════════════════════════════════════════════════════════════

-- /repairveh [id] ou /repairveh radius [rayon]
RegisterCommand('repairveh', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local adminName = GetName(source)

    -- Mode radius
    if args[1] == 'radius' then
        local radius = tonumber(args[2]) or 10.0

        -- Limiter le rayon
        if radius < 1 then radius = 1 end
        if radius > MaxRepairRadius then
            radius = MaxRepairRadius
            Notify(source, '~o~Rayon limite a ' .. MaxRepairRadius .. ' metres')
        end

        TriggerClientEvent('admin:repairVehiclesInRadius', source, radius)

        if Config.Debug then print('[ADMIN] ' .. adminName .. ' a repare tous les vehicules dans un rayon de ' .. radius .. ' metres') end

        -- Log
        local session = Auth.GetSession(source)
        if session then
            Database.AddLog(Enums.LogCategory.VEHICLE, 'vehicle_repair_radius', session.identifier, session.name, nil, nil, {radius = radius})
        end
        return
    end

    -- Mode joueur
    local targetId = tonumber(args[1]) or source
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xTarget then
        Notify(source, 'Joueur introuvable')
        return
    end

    local targetName = GetName(targetId)

    TriggerClientEvent('admin:repairVehicle', targetId, source)

    if Config.Debug then print('[ADMIN] ' .. adminName .. ' a repare le vehicule de ' .. targetName .. ' (ID: ' .. targetId .. ')') end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.VEHICLE, 'vehicle_repair', session.identifier, session.name, xTarget.getIdentifier(), targetName, {})
    end
end, false)

-- /repairall - Reparer TOUS les vehicules du serveur (Admin Only)
RegisterCommand('repairall', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        Notify(source, 'Commande reservee aux admins')
        return
    end

    local adminName = GetName(source)

    -- Envoyer a TOUS les joueurs pour reparer tous les vehicules
    for _, playerId in ipairs(ESX.GetPlayers()) do
        TriggerClientEvent('admin:repairAllVehicles', playerId)
    end

    if Config.Debug then print('[ADMIN] ' .. adminName .. ' a repare les vehicules de tous les joueurs') end

    Notify(source, 'Tous les vehicules ont ete repares')

    -- Notification globale
    for _, playerId in ipairs(ESX.GetPlayers()) do
        if playerId ~= source then
            Notify(playerId, 'Tous les vehicules ont ete repares par un admin')
        end
    end

    -- Log
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.VEHICLE, 'repair_all', session.identifier, session.name, nil, nil, {})
    end
end, false)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DE MODERATION
-- ══════════════════════════════════════════════════════════════

-- /kick [id] [raison]
RegisterCommand('kick', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, '~r~Vous n\'avez pas la permission')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        Notify(source, '~r~Usage: /kick [id] [raison]')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        Notify(source, '~r~Joueur introuvable')
        return
    end

    -- Verifier qu'on ne kick pas un grade superieur
    local sourcePlayer = ESX.GetPlayerFromId(source)
    local sourceLevel = Permissions.GetLevel(sourcePlayer.getGroup())
    local targetLevel = Permissions.GetLevel(xTarget.getGroup())

    if targetLevel >= sourceLevel and source ~= targetId then
        Notify(source, '~r~Vous ne pouvez pas kick un membre de grade egal ou superieur')
        return
    end

    -- Construire la raison
    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == '' then
        reason = 'Aucune raison specifiee'
    end

    local targetName = GetName(targetId)
    local targetIdentifier = xTarget.getIdentifier()
    local adminName = GetName(source)

    -- Log avant le kick
    local session = Auth.GetSession(source)
    if session then
        Database.AddLog(Enums.LogCategory.SANCTION, 'kick_player', session.identifier, session.name, targetIdentifier, targetName, {reason = reason})
    end

    -- Kick le joueur
    DropPlayer(targetId, 'Vous avez ete expulse par ' .. adminName .. '\nRaison: ' .. reason)

    Notify(source, '' .. targetName .. ' a ete expulse')
end, false)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DE BAN
-- ══════════════════════════════════════════════════════════════

-- /ban [ID ou license] [temps] [raison]
-- temps = nombre d'heures OU "perm" pour permanent
RegisterCommand('ban', function(source, args)
    if source == 0 then return end

    -- Verifier permissions via le groupe ESX directement
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        Notify(source, '~r~Erreur: impossible de recuperer vos infos')
        return
    end

    local staffGroup = xPlayer.getGroup()
    local hasTempBan = Permissions.HasAbility(staffGroup, 'sanction.ban.temp')
    local hasPermBan = Permissions.HasAbility(staffGroup, 'sanction.ban.perm')

    if not hasTempBan and not hasPermBan then
        Notify(source, '~r~Vous n\'avez pas la permission de bannir')
        return
    end

    -- Creer/recuperer la session pour les logs
    local session = Auth.GetSession(source)
    if not session then
        session = Auth.InitSession(source)
    end

    -- Verification des arguments
    if #args < 3 then
        Notify(source, '~y~Usage: /ban [ID ou license] [temps/perm] [raison]')
        Notify(source, '~y~Exemple: /ban 5 24 Cheat')
        Notify(source, '~y~Exemple: /ban license:abc123 perm Cheat')
        return
    end

    local targetArg = args[1]
    local durationArg = args[2]
    local reason = table.concat(args, ' ', 3)

    if reason == '' then
        reason = 'Aucune raison specifiee'
    end

    -- Determiner la duree (0 = permanent)
    local durationHours = tonumber(durationArg)
    local isPermanent = (durationArg:lower() == 'perm' or durationArg:lower() == 'permanent' or durationHours == 0)

    if not isPermanent then
        if not durationHours or durationHours < 0 then
            Notify(source, '~r~Duree invalide. Utilisez un nombre d\'heures ou 0/perm pour permanent')
            return
        end
    else
        durationHours = nil -- Reset pour les bans permanents
    end

    -- Verifier la permission selon le type de ban
    if isPermanent and not hasPermBan then
        Notify(source, '~r~Vous n\'avez pas la permission de bannir de maniere permanente')
        return
    end

    local targetId = tonumber(targetArg)
    local targetIdentifier = nil
    local targetName = nil
    local identifiers = nil
    local connectedPlayerId = nil -- Pour stocker l'ID du joueur connecté (si trouvé)

    -- Si c'est un ID numerique, chercher le joueur connecte
    if targetId then
        local xTarget = ESX.GetPlayerFromId(targetId)
        if not xTarget then
            Notify(source, '~r~Joueur avec l\'ID ' .. targetId .. ' introuvable')
            return
        end

        -- Verifier qu'on ne ban pas un grade superieur ou egal
        local sourceLevel = Permissions.GetLevel(staffGroup)
        local targetLevel = Permissions.GetLevel(xTarget.getGroup())

        if targetLevel >= sourceLevel then
            Notify(source, '~r~Vous ne pouvez pas bannir un membre de grade egal ou superieur')
            return
        end

        targetIdentifier = xTarget.getIdentifier()
        targetName = GetName(targetId)
        identifiers = Helpers.GetPlayerIdentifiers(targetId)
        connectedPlayerId = targetId
    else
        -- C'est une license/identifier - chercher d'abord si le joueur est connecté
        targetIdentifier = targetArg
        targetName = 'Inconnu (ban manuel)'

        -- Chercher si le joueur avec cette license est connecté
        local xPlayers = ESX.GetExtendedPlayers()
        for _, xTargetPlayer in pairs(xPlayers) do
            if xTargetPlayer.getIdentifier() == targetIdentifier then
                -- Joueur trouvé connecté!
                connectedPlayerId = xTargetPlayer.source

                -- Verifier qu'on ne ban pas un grade superieur ou egal
                local sourceLevel = Permissions.GetLevel(staffGroup)
                local targetLevel = Permissions.GetLevel(xTargetPlayer.getGroup())

                if targetLevel >= sourceLevel then
                    Notify(source, '~r~Vous ne pouvez pas bannir un membre de grade egal ou superieur')
                    return
                end

                targetName = GetName(connectedPlayerId)
                identifiers = Helpers.GetPlayerIdentifiers(connectedPlayerId)
                break
            end
        end

        -- Si pas connecté, essayer de trouver le nom dans la BDD
        if not connectedPlayerId then
            local userData = Database.SingleAsync([[
                SELECT firstname, lastname FROM users WHERE identifier = ?
            ]], {targetIdentifier})

            if userData then
                targetName = (userData.firstname or '') .. ' ' .. (userData.lastname or '')
            end
        end
    end

    -- Verifier si deja banni
    local existingBan = Database.SingleAsync([[
        SELECT * FROM panel_bans WHERE identifier = ? AND (expires_at IS NULL OR expires_at > NOW())
    ]], {targetIdentifier})

    if existingBan then
        Notify(source, '~r~Ce joueur est deja banni')
        return
    end

    -- Calculer la date d'expiration
    local expiresAt = nil
    if not isPermanent and durationHours then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (durationHours * 3600))
    end

    -- Generer un ID de deban unique
    local unbanId = Database.GenerateUnbanId()

    -- Ajouter le ban dans panel_sanctions
    Database.AddSanction({
        type = isPermanent and Enums.SanctionType.BAN_PERM or Enums.SanctionType.BAN_TEMP,
        targetIdentifier = targetIdentifier,
        targetName = targetName,
        staffIdentifier = session.identifier,
        staffName = session.name,
        reason = reason,
        duration = durationHours,
        unbanId = unbanId
    })

    -- Ajouter dans panel_bans
    Database.AddBan({
        identifier = targetIdentifier,
        playerName = targetName,
        steamId = identifiers and identifiers.steam or nil,
        discordId = identifiers and identifiers.discord or nil,
        license = identifiers and identifiers.license or targetIdentifier,
        ip = identifiers and identifiers.ip or nil,
        reason = reason,
        staffIdentifier = session.identifier,
        staffName = session.name,
        duration = isPermanent and -1 or durationHours,
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
        {reason = reason, duration = durationHours, permanent = isPermanent, command = true, unbanId = unbanId}
    )

    -- Discord webhook
    if Discord and Discord.LogSanction then
        local sanctionType = isPermanent and 'ban_perm' or 'ban_temp'
        local targetData = {
            serverId = connectedPlayerId,
            discord = identifiers and identifiers.discord or nil,
            license = identifiers and identifiers.license or targetIdentifier,
            steam = identifiers and identifiers.steam or nil,
            fivem = identifiers and identifiers.fivem or nil,
            unbanId = unbanId
        }
        Discord.LogSanction(sanctionType, session.name, targetName, reason, durationHours, targetData)
    end

    -- Kick le joueur s'il est connecté
    if connectedPlayerId then
        local durationText = isPermanent and 'Permanent' or Helpers.FormatDuration(durationHours)
        local kickMessage = 'Vous avez ete banni.\n\n' ..
            'Raison: ' .. reason .. '\n' ..
            'Duree: ' .. durationText .. '\n' ..
            'ID de deban: ' .. unbanId .. '\n\n' ..
            'Contestation: discord.gg/fightleague'

        DropPlayer(connectedPlayerId, kickMessage)
    end

    -- Notification avec ID de deban
    local durationDisplay = isPermanent and '~r~PERMANENT' or ('~y~' .. durationHours .. ' heure(s)')
    Notify(source, '~g~' .. targetName .. ' a ete banni - Duree: ' .. durationDisplay .. ' - ID: ' .. unbanId)

    -- Stats
    Database.UpdateDailyStat('bans_count', 1)
end, false)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES DE COMMUNICATION
-- ══════════════════════════════════════════════════════════════

-- /annonce [message] - Annonce urgente rapide
RegisterCommand('annonce', function(source, args)
    if source == 0 then return end

    -- Verifier permissions via le groupe ESX directement
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        Notify(source, '~r~Erreur: impossible de recuperer vos infos')
        return
    end

    local staffGroup = xPlayer.getGroup()
    if not Permissions.HasAbility(staffGroup, 'announce.send') then
        Notify(source, '~r~Vous n\'avez pas la permission d\'envoyer des annonces')
        return
    end

    local message = table.concat(args, ' ')
    if message == '' then
        Notify(source, '~y~Usage: /annonce [message]')
        return
    end

    -- Envoyer une annonce urgente via le module Announcements
    local success, announceId = Announcements.Send(source, message, 'chat', 'urgent', 'ANNONCE URGENTE')

    if success then
        Notify(source, '~g~Annonce urgente envoyee a tous les joueurs')
    else
        Notify(source, '~r~Erreur lors de l\'envoi de l\'annonce')
    end
end, false)

-- /mstaff [message] - Message staff
RegisterCommand('mstaff', function(source, args)
    if source == 0 then return end
    if not IsStaff(source) then
        Notify(source, 'Vous n\'avez pas la permission')
        return
    end

    local message = table.concat(args, ' ')
    if message == '' then
        Notify(source, 'Usage: /mstaff [message]')
        return
    end

    local senderName = GetName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()

    -- Couleurs et prefixes par grade
    local colors = {
        owner = {255, 0, 0},        -- Rouge
        admin = {128, 0, 128},      -- Violet
        responsable = {0, 100, 255}, -- Bleu
        organisateur = {0, 255, 0}, -- Vert
        staff = {255, 165, 0}       -- Orange
    }

    local prefixes = {
        owner = '[OWNER]',
        admin = '[ADMIN]',
        responsable = '[RESPONSABLE]',
        organisateur = '[ORGANISATEUR]',
        staff = '[STAFF]'
    }

    local color = colors[group] or {255, 165, 0}
    local prefix = prefixes[group] or '[STAFF]'

    local count = 0
    for _, playerId in ipairs(ESX.GetPlayers()) do
        if IsStaff(playerId) then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = color,
                multiline = true,
                args = {prefix .. ' ' .. senderName, message}
            })
            -- Son de notification
            TriggerClientEvent('InteractSound_CL:PlayOnOne', playerId, 'demo', 0.4)
            count = count + 1
        end
    end

    Notify(source, 'Message envoye a ' .. count .. ' membre(s) du staff')
end, false)

-- ══════════════════════════════════════════════════════════════
-- SUGGESTIONS DE COMMANDES
-- ══════════════════════════════════════════════════════════════

TriggerEvent('chat:addSuggestion', '/tp', 'Teleporter un joueur vers vous', {{name = 'id', help = 'ID du joueur'}})
TriggerEvent('chat:addSuggestion', '/tpa', 'Se teleporter vers un joueur', {{name = 'id', help = 'ID du joueur'}})
TriggerEvent('chat:addSuggestion', '/return', 'Retourner a la position precedente', {{name = 'id', help = 'ID du joueur (optionnel)'}})
TriggerEvent('chat:addSuggestion', '/tpall', 'Teleporter tous les joueurs vers vous (Admin)', {})
TriggerEvent('chat:addSuggestion', '/instancebyid', 'Ramener un joueur bloque au lobby', {{name = 'id', help = 'ID du joueur'}})
TriggerEvent('chat:addSuggestion', '/lobbyforce', 'Retourner au lobby', {{name = 'id', help = 'ID du joueur (optionnel, sinon vous-meme)'}})
TriggerEvent('chat:addSuggestion', '/heal', 'Soigner un joueur', {{name = 'id', help = 'ID du joueur (optionnel)'}})
TriggerEvent('chat:addSuggestion', '/revive', 'Reanimer un joueur', {{name = 'id', help = 'ID du joueur (optionnel)'}})
TriggerEvent('chat:addSuggestion', '/healall', 'Soigner tous les joueurs (Admin)', {})
TriggerEvent('chat:addSuggestion', '/reviveall', 'Reanimer tous les joueurs (Admin)', {})
TriggerEvent('chat:addSuggestion', '/repairveh', 'Reparer un vehicule', {{name = 'id/radius', help = 'ID joueur ou "radius [rayon]"'}})
TriggerEvent('chat:addSuggestion', '/repairall', 'Reparer tous les vehicules (Admin)', {})
TriggerEvent('chat:addSuggestion', '/kick', 'Expulser un joueur', {{name = 'id', help = 'ID du joueur'}, {name = 'raison', help = 'Raison du kick'}})
TriggerEvent('chat:addSuggestion', '/ban', 'Bannir un joueur', {{name = 'id/license', help = 'ID du joueur ou license'}, {name = 'temps', help = 'Heures (0 = permanent)'}, {name = 'raison', help = 'Raison du ban'}})
TriggerEvent('chat:addSuggestion', '/annonce', 'Envoyer une annonce urgente', {{name = 'message', help = 'Message de l\'annonce'}})
TriggerEvent('chat:addSuggestion', '/mstaff', 'Envoyer un message au staff', {{name = 'message', help = 'Votre message'}})

-- Nettoyage des positions expirees (30 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        local now = os.time()
        for playerId, pos in pairs(savedPositions) do
            if now - pos.timestamp > 1800 then
                savedPositions[playerId] = nil
            end
        end
    end
end)

-- Export global
_G.Commands = Commands

if Config.Debug then print('^2[PANEL ADMIN]^0 Module Commands charge') end
