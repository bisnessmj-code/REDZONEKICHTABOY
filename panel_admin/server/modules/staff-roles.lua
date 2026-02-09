--[[
    Module Staff Roles - Panel Admin Fight League
    Gestion des rôles du staff
]]

local StaffRoles = {}

-- Hiérarchie des grades (niveau plus élevé = plus de pouvoir)
local gradeLevels = {
    ['user'] = 0,
    ['staff'] = 1,
    ['organisateur'] = 2,
    ['responsable'] = 3,
    ['admin'] = 4,
    ['owner'] = 5
}

-- Grades staff (tous sauf user)
local staffGrades = {'staff', 'organisateur', 'responsable', 'admin', 'owner'}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ══════════════════════════════════════════════════════════════

-- Obtenir le niveau d'un grade
local function getGradeLevel(grade)
    return gradeLevels[string.lower(grade or '')] or 0
end

-- Vérifier si un grade est un grade staff
local function isStaffGrade(grade)
    local g = string.lower(grade or '')
    for _, staffGrade in ipairs(staffGrades) do
        if g == staffGrade then
            return true
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Obtenir tous les membres du staff (en ligne et hors ligne)
function StaffRoles.GetAll()
    -- D'abord, récupérer tous les joueurs en ligne avec leur groupe ESX LIVE
    local onlinePlayers = {}
    local onlineStaff = {}
    local xPlayers = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(xPlayers) do
        local identifier = xPlayer.getIdentifier()
        local liveGroup = xPlayer.getGroup() -- Groupe ESX en temps réel

        onlinePlayers[identifier] = {
            serverId = xPlayer.source,
            name = GetPlayerName(xPlayer.source),
            group = liveGroup
        }

        -- Si c'est un staff en ligne, l'ajouter directement
        if isStaffGrade(liveGroup) then
            onlineStaff[identifier] = true
        end
    end

    -- Récupérer les joueurs staff HORS LIGNE depuis la base de données
    -- (ceux qui ne sont pas connectés mais ont un grade staff en BDD)
    local query = [[
        SELECT identifier,
               COALESCE(fivem_name, '') as fivem_name,
               COALESCE(firstname, '') as firstname,
               COALESCE(lastname, '') as lastname,
               `group`
        FROM users
        WHERE `group` IN ('staff', 'organisateur', 'responsable', 'admin', 'owner')
        ORDER BY
            CASE `group`
                WHEN 'owner' THEN 5
                WHEN 'admin' THEN 4
                WHEN 'responsable' THEN 3
                WHEN 'organisateur' THEN 2
                WHEN 'staff' THEN 1
                ELSE 0
            END DESC,
            fivem_name ASC
    ]]

    local results = Database.QueryAsync(query, {})

    if not results then
        results = {}
    end

    -- Formatter les résultats
    local members = {}
    local addedIdentifiers = {}

    -- D'abord ajouter tous les staff EN LIGNE avec leur groupe ESX LIVE
    for identifier, data in pairs(onlinePlayers) do
        if isStaffGrade(data.group) then
            local displayName = data.name or identifier

            table.insert(members, {
                identifier = identifier,
                name = displayName,
                group = data.group, -- Groupe ESX en temps réel
                isOnline = true,
                serverId = data.serverId
            })
            addedIdentifiers[identifier] = true
        end
    end

    -- Ensuite ajouter les staff HORS LIGNE depuis la BDD
    for _, row in ipairs(results) do
        if not addedIdentifiers[row.identifier] then
            -- Priorité: fivem_name > firstname + lastname > identifier
            local displayName = row.fivem_name

            -- Si fivem_name est vide, fallback sur le nom RP
            if not displayName or displayName == '' then
                displayName = row.firstname .. ' ' .. row.lastname
            end

            -- Si le nom est toujours vide, utiliser l'identifier
            if not displayName or displayName == ' ' or displayName == '' then
                displayName = row.identifier
            end

            table.insert(members, {
                identifier = row.identifier,
                name = displayName,
                group = row.group, -- Groupe depuis la BDD pour les hors ligne
                isOnline = false,
                serverId = nil
            })
            addedIdentifiers[row.identifier] = true
        end
    end

    return members
end

-- Modifier le grade d'un membre
function StaffRoles.UpdateGrade(staffSource, targetIdentifier, newGrade)
    -- Vérifier la session du staff
    local session = Auth.GetSession(staffSource)
    if not session then
        return false, 'NOT_AUTHENTICATED'
    end

    local staffLevel = getGradeLevel(session.group)

    -- Vérifier que le staff a au moins le niveau responsable
    if staffLevel < gradeLevels['responsable'] then
        return false, 'NO_PERMISSION'
    end

    -- Vérifier que le nouveau grade est valide
    newGrade = string.lower(newGrade or '')
    if gradeLevels[newGrade] == nil then
        return false, 'INVALID_GRADE'
    end

    -- Le staff ne peut assigner que des grades inférieurs à son propre niveau
    local newGradeLevel = getGradeLevel(newGrade)
    if newGradeLevel >= staffLevel then
        return false, 'CANNOT_ASSIGN_HIGHER_GRADE'
    end

    -- Récupérer le grade actuel de la cible
    local targetData = Database.SingleAsync([[
        SELECT `group`,
               COALESCE(fivem_name, '') as fivem_name,
               COALESCE(firstname, '') as firstname,
               COALESCE(lastname, '') as lastname
        FROM users
        WHERE identifier = ?
    ]], {targetIdentifier})

    if not targetData then
        return false, 'TARGET_NOT_FOUND'
    end

    local currentGradeLevel = getGradeLevel(targetData.group)

    -- Le staff ne peut modifier que des membres avec un grade inférieur
    if currentGradeLevel >= staffLevel then
        return false, 'CANNOT_MODIFY_HIGHER_GRADE'
    end

    -- Mettre à jour le grade dans la base de données
    Database.ExecuteAsync([[
        UPDATE users SET `group` = ? WHERE identifier = ?
    ]], {newGrade, targetIdentifier})

    -- Si le joueur est en ligne, mettre à jour son groupe ESX et récupérer son nom
    local onlineTargetName = nil
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.getIdentifier() == targetIdentifier then
            xPlayer.setGroup(newGrade)
            onlineTargetName = GetPlayerName(xPlayer.source)

            -- Notifier le joueur
            TriggerClientEvent('panel:notification', xPlayer.source, {
                type = 'info',
                title = 'Grade modifie',
                message = 'Votre grade a ete modifie en: ' .. newGrade
            })
            break
        end
    end

    -- Log l'action - utiliser le nom en ligne si disponible, sinon fivem_name, sinon le nom RP, sinon l'identifier
    local targetName = onlineTargetName
    if not targetName or targetName == '' then
        -- Priorité: fivem_name > firstname + lastname > identifier
        if targetData.fivem_name and targetData.fivem_name ~= '' then
            targetName = targetData.fivem_name
        else
            local dbName = (targetData.firstname or '') .. ' ' .. (targetData.lastname or '')
            dbName = dbName:gsub('^%s+', ''):gsub('%s+$', '') -- Trim
            targetName = dbName ~= '' and dbName or targetIdentifier
        end
    end
    Database.AddLog(
        Enums.LogCategory.PLAYER,
        Enums.LogAction.PLAYER_SETGROUP,
        session.identifier,
        session.name,
        targetIdentifier,
        targetName,
        {
            oldGrade = targetData.group,
            newGrade = newGrade
        }
    )

    -- Log Discord
    Discord.LogStaffRole(
        'change',
        session.name,
        targetName,
        targetIdentifier,
        targetData.group,
        newGrade
    )

    print('[STAFF ROLES] ' .. session.name .. ' a modifie le grade de ' .. targetIdentifier .. ': ' .. targetData.group .. ' -> ' .. newGrade)

    return true
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS SERVEUR
-- ══════════════════════════════════════════════════════════════

-- Obtenir la liste des membres du staff
ESX.RegisterServerCallback('panel:getStaffMembers', function(source, cb)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    -- Vérifier que le staff a au moins le niveau responsable
    local staffLevel = getGradeLevel(session.group)
    if staffLevel < gradeLevels['responsable'] then
        cb({success = false, error = 'NO_PERMISSION'})
        return
    end

    local members = StaffRoles.GetAll()

    cb({
        success = true,
        members = members
    })
end)

-- Modifier le grade d'un membre
ESX.RegisterServerCallback('panel:updateStaffGrade', function(source, cb, targetIdentifier, newGrade)
    local success, err = StaffRoles.UpdateGrade(source, targetIdentifier, newGrade)

    if success then
        cb({success = true})
    else
        cb({success = false, error = err})
    end
end)

-- Obtenir les joueurs connectés (pour promotion)
ESX.RegisterServerCallback('panel:getConnectedUsers', function(source, cb)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    -- Vérifier que le staff a au moins le niveau responsable
    local staffLevel = getGradeLevel(session.group)
    if staffLevel < gradeLevels['responsable'] then
        cb({success = false, error = 'NO_PERMISSION'})
        return
    end

    -- Récupérer tous les joueurs connectés
    local players = {}
    local xPlayers = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(xPlayers) do
        local playerGroup = xPlayer.getGroup() or 'user'
        local playerLevel = getGradeLevel(playerGroup)

        -- N'afficher que les joueurs avec un niveau inférieur au staff
        if playerLevel < staffLevel then
            table.insert(players, {
                serverId = xPlayer.source,
                identifier = xPlayer.getIdentifier(),
                name = GetPlayerName(xPlayer.source) or 'Inconnu',
                group = playerGroup
            })
        end
    end

    -- Trier par ID serveur
    table.sort(players, function(a, b)
        return a.serverId < b.serverId
    end)

    cb({
        success = true,
        players = players
    })
end)

-- Export global
_G.StaffRoles = StaffRoles

if Config.Debug then print('^2[PANEL ADMIN]^0 Module Staff Roles charge') end
