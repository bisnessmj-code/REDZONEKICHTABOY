--[[
    Module Teleport - Panel Admin Fight League
    Système de téléportation avec gestion des instances
]]

local Teleport = {}

-- Stockage des positions precedentes (pour le return)
local previousPositions = {}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Téléporter un joueur à des coordonnées
function Teleport.ToCoords(staffSource, targetSource, x, y, z)
    if not Auth.HasPermission(staffSource, 'teleport.player') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, coords = Validators.Coords(x, y, z)
    if not valid then return false, coords end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    TriggerClientEvent('panel:teleport', targetSource, coords.x, coords.y, coords.z)

    Database.AddLog(
        Enums.LogCategory.TELEPORT,
        Enums.LogAction.TP_COORDS,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(targetSource), -- Nom FiveM
        {coords = {x = coords.x, y = coords.y, z = coords.z}}
    )

    -- Discord webhook
    if Discord and Discord.LogTeleport then
        Discord.LogTeleport('tp_coords', session.name, GetPlayerName(targetSource), {coords = {x = coords.x, y = coords.y, z = coords.z}})
    end

    return true
end

-- Se téléporter soi-même
function Teleport.Self(staffSource, x, y, z)
    if not Auth.HasPermission(staffSource, 'teleport.self') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, coords = Validators.Coords(x, y, z)
    if not valid then return false, coords end

    local session = Auth.GetSession(staffSource)

    -- Sauvegarder la position actuelle du staff avant de teleporter
    local staffCoords = Helpers.GetPlayerCoords(staffSource)
    local staffBucket = GetPlayerRoutingBucket(staffSource)

    if staffCoords then
        previousPositions[staffSource] = {
            x = staffCoords.x,
            y = staffCoords.y,
            z = staffCoords.z,
            bucket = staffBucket,
            timestamp = os.time()
        }
        if Config.Debug then print('^3[TELEPORT]^0 Position sauvegardee pour staff ' .. staffSource .. ' avant TP self') end
    end

    TriggerClientEvent('panel:teleport', staffSource, coords.x, coords.y, coords.z)

    -- Remettre le joueur dans l'instance 0 (lobby) lors de la teleportation self
    SetPlayerRoutingBucket(staffSource, 0)

    Database.AddLog(
        Enums.LogCategory.TELEPORT,
        Enums.LogAction.TP_COORDS,
        session.identifier,
        session.name,
        session.identifier,
        session.name,
        {coords = {x = coords.x, y = coords.y, z = coords.z}, self = true}
    )

    -- Discord webhook
    if Discord and Discord.LogTeleport then
        Discord.LogTeleport('tp_self', session.name, nil, {coords = {x = coords.x, y = coords.y, z = coords.z}})
    end

    return true
end

-- Aller vers un joueur (goto) - avec gestion des instances
function Teleport.Goto(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'teleport.goto') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    if staffSource == targetSource then
        return false, Enums.ErrorCode.CANNOT_SELF_ACTION
    end

    local targetCoords = Helpers.GetPlayerCoords(targetSource)
    if not targetCoords then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)
    local xTarget = ESX.GetPlayerFromId(targetSource)

    -- Sauvegarder la position actuelle du staff avant de teleporter
    local staffCoords = Helpers.GetPlayerCoords(staffSource)
    local staffBucket = GetPlayerRoutingBucket(staffSource)

    if staffCoords then
        previousPositions[staffSource] = {
            x = staffCoords.x,
            y = staffCoords.y,
            z = staffCoords.z,
            bucket = staffBucket,
            timestamp = os.time()
        }
        if Config.Debug then print('^3[TELEPORT]^0 Position sauvegardee pour staff ' .. staffSource .. ' (bucket: ' .. staffBucket .. ')') end
    end

    -- Recuperer le routing bucket de la cible
    local targetBucket = GetPlayerRoutingBucket(targetSource)

    -- Changer le routing bucket du staff si different
    if targetBucket ~= staffBucket then
        SetPlayerRoutingBucket(staffSource, targetBucket)
        if Config.Debug then print('^3[TELEPORT]^0 Staff ' .. staffSource .. ' deplace dans instance ' .. targetBucket) end
    end

    -- Teleporter le staff
    TriggerClientEvent('panel:teleport', staffSource, targetCoords.x, targetCoords.y, targetCoords.z)

    Database.AddLog(
        Enums.LogCategory.TELEPORT,
        Enums.LogAction.TP_GOTO,
        session.identifier,
        session.name,
        xTarget and xTarget.getIdentifier() or nil,
        GetPlayerName(targetSource) or 'Inconnu', -- Nom FiveM
        {bucket = targetBucket}
    )

    -- Discord webhook
    if Discord and Discord.LogTeleport then
        Discord.LogTeleport('tp_goto', session.name, GetPlayerName(targetSource) or 'Inconnu', nil)
    end

    return true
end

-- Amener un joueur vers soi (bring) - avec gestion des instances
function Teleport.Bring(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'teleport.bring') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    if staffSource == targetSource then
        return false, Enums.ErrorCode.CANNOT_SELF_ACTION
    end

    local staffCoords = Helpers.GetPlayerCoords(staffSource)
    if not staffCoords then return false, 'Impossible de recuperer vos coordonnees' end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    -- Sauvegarder la position actuelle du joueur cible avant de teleporter
    local targetCoords = Helpers.GetPlayerCoords(targetSource)
    local targetBucket = GetPlayerRoutingBucket(targetSource)

    if targetCoords then
        previousPositions[targetSource] = {
            x = targetCoords.x,
            y = targetCoords.y,
            z = targetCoords.z,
            bucket = targetBucket,
            timestamp = os.time()
        }
        if Config.Debug then print('^3[TELEPORT]^0 Position sauvegardee pour joueur ' .. targetSource .. ' (bucket: ' .. targetBucket .. ')') end
    end

    -- Recuperer le routing bucket du staff
    local staffBucket = GetPlayerRoutingBucket(staffSource)

    -- Changer le routing bucket du joueur si different
    if staffBucket ~= targetBucket then
        SetPlayerRoutingBucket(targetSource, staffBucket)
        if Config.Debug then print('^3[TELEPORT]^0 Joueur ' .. targetSource .. ' deplace dans instance ' .. staffBucket) end
    end

    -- Teleporter le joueur
    TriggerClientEvent('panel:teleport', targetSource, staffCoords.x, staffCoords.y, staffCoords.z)

    TriggerClientEvent('panel:notification', targetSource, {
        type = 'info',
        title = 'Teleportation',
        message = 'Vous avez ete teleporte par ' .. session.name
    })

    Database.AddLog(
        Enums.LogCategory.TELEPORT,
        Enums.LogAction.TP_BRING,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(targetSource), -- Nom FiveM
        {fromBucket = targetBucket, toBucket = staffBucket}
    )

    -- Discord webhook
    if Discord and Discord.LogTeleport then
        Discord.LogTeleport('tp_bring', session.name, GetPlayerName(targetSource), nil)
    end

    return true
end

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS RETURN
-- ══════════════════════════════════════════════════════════════

-- Retourner a sa position precedente (pour le staff)
function Teleport.Return(staffSource)
    if not Auth.HasPermission(staffSource, 'teleport.self') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local prevPos = previousPositions[staffSource]
    if not prevPos then
        return false, 'Aucune position precedente sauvegardee'
    end

    -- Verifier que la position n'est pas trop vieille (30 minutes max)
    if os.time() - prevPos.timestamp > 1800 then
        previousPositions[staffSource] = nil
        return false, 'Position precedente expiree (plus de 30 minutes)'
    end

    local session = Auth.GetSession(staffSource)
    local currentBucket = GetPlayerRoutingBucket(staffSource)

    -- Changer le routing bucket si necessaire
    if prevPos.bucket ~= currentBucket then
        SetPlayerRoutingBucket(staffSource, prevPos.bucket)
        if Config.Debug then print('^3[TELEPORT]^0 Staff ' .. staffSource .. ' retourne dans instance ' .. prevPos.bucket) end
    end

    -- Teleporter
    TriggerClientEvent('panel:teleport', staffSource, prevPos.x, prevPos.y, prevPos.z)

    -- Supprimer la position sauvegardee
    previousPositions[staffSource] = nil

    Database.AddLog(
        Enums.LogCategory.TELEPORT,
        'tp_return',
        session.identifier,
        session.name,
        session.identifier,
        session.name,
        {coords = {x = prevPos.x, y = prevPos.y, z = prevPos.z}, bucket = prevPos.bucket}
    )

    -- Discord webhook
    if Discord and Discord.LogTeleport then
        Discord.LogTeleport('tp_return', session.name, nil, {coords = {x = prevPos.x, y = prevPos.y, z = prevPos.z}})
    end

    return true
end

-- Retourner un joueur a sa position precedente
function Teleport.ReturnPlayer(staffSource, targetSource)
    if not Auth.HasPermission(staffSource, 'teleport.bring') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local prevPos = previousPositions[targetSource]
    if not prevPos then
        return false, 'Aucune position precedente pour ce joueur'
    end

    -- Verifier que la position n'est pas trop vieille (30 minutes max)
    if os.time() - prevPos.timestamp > 1800 then
        previousPositions[targetSource] = nil
        return false, 'Position precedente expiree (plus de 30 minutes)'
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)
    local currentBucket = GetPlayerRoutingBucket(targetSource)

    -- Changer le routing bucket si necessaire
    if prevPos.bucket ~= currentBucket then
        SetPlayerRoutingBucket(targetSource, prevPos.bucket)
        if Config.Debug then print('^3[TELEPORT]^0 Joueur ' .. targetSource .. ' retourne dans instance ' .. prevPos.bucket) end
    end

    -- Teleporter
    TriggerClientEvent('panel:teleport', targetSource, prevPos.x, prevPos.y, prevPos.z)

    TriggerClientEvent('panel:notification', targetSource, {
        type = 'info',
        title = 'Teleportation',
        message = 'Vous avez ete retourne a votre position precedente'
    })

    -- Supprimer la position sauvegardee
    previousPositions[targetSource] = nil

    Database.AddLog(
        Enums.LogCategory.TELEPORT,
        'tp_return_player',
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(targetSource), -- Nom FiveM
        {coords = {x = prevPos.x, y = prevPos.y, z = prevPos.z}, bucket = prevPos.bucket}
    )

    return true
end

-- Verifier si un joueur a une position de retour
function Teleport.HasReturnPosition(source)
    local prevPos = previousPositions[source]
    if not prevPos then return false end
    if os.time() - prevPos.timestamp > 1800 then
        previousPositions[source] = nil
        return false
    end
    return true
end

-- Nettoyer les positions expirees (appele periodiquement)
function Teleport.CleanupExpiredPositions()
    local currentTime = os.time()
    for source, pos in pairs(previousPositions) do
        if currentTime - pos.timestamp > 1800 then
            previousPositions[source] = nil
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- EMPLACEMENTS SAUVEGARDÉS
-- ══════════════════════════════════════════════════════════════

-- Obtenir les emplacements sauvegardés
function Teleport.GetLocations(category)
    local query = [[
        SELECT * FROM panel_saved_locations
        WHERE is_public = 1
    ]]
    local params = {}

    if category then
        query = query .. ' AND category = ?'
        table.insert(params, category)
    end

    query = query .. ' ORDER BY category, name'

    return Database.QueryAsync(query, params)
end

-- Ajouter un emplacement
function Teleport.AddLocation(staffSource, name, category, x, y, z, heading)
    local session = Auth.GetSession(staffSource)
    if not session then return false, Enums.ErrorCode.NO_PERMISSION end

    local valid, coords = Validators.Coords(x, y, z)
    if not valid then return false, coords end

    return Database.InsertAsync([[
        INSERT INTO panel_saved_locations (name, category, x, y, z, heading, created_by, is_public)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    ]], {name, category or 'custom', coords.x, coords.y, coords.z, heading or 0.0, session.identifier})
end

-- Supprimer un emplacement
function Teleport.RemoveLocation(id)
    return Database.ExecuteAsync([[
        DELETE FROM panel_saved_locations WHERE id = ?
    ]], {id})
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS
-- ══════════════════════════════════════════════════════════════

-- Callback pour obtenir les emplacements de teleportation depuis le config
ESX.RegisterServerCallback('panel:getTeleportLocations', function(source, cb)
    if not Auth.CanAccessPanel(source) then
        cb({success = false, error = Enums.ErrorCode.NO_PERMISSION})
        return
    end

    -- Convertir les emplacements du config en format pour le NUI
    local locations = {}
    if Config.Teleport and Config.Teleport.DefaultLocations then
        for _, loc in ipairs(Config.Teleport.DefaultLocations) do
            table.insert(locations, {
                name = loc.name,
                category = loc.category,
                x = loc.coords.x,
                y = loc.coords.y,
                z = loc.coords.z,
                heading = loc.heading or 0.0
            })
        end
    end

    cb({success = true, locations = locations})
end)

-- Export global
_G.Teleport = Teleport
