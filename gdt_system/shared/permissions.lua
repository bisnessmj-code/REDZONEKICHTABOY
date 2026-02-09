-- ==========================================
-- GESTION DES PERMISSIONS (VERSION CORRIGÉE)
-- ==========================================

Permissions = {}

-- ==========================================
-- FONCTION PRINCIPALE : VÉRIFIER SI ADMIN
-- ==========================================

function Permissions.IsAdmin(source)
    if not source or source == 0 then 
        return false 
    end
    
    -- ==========================================
    -- MÉTHODE 1 : Vérification ACE Permission
    -- ==========================================
    if IsPlayerAceAllowed(source, Config.AdminPermissions.command) then
        return true
    end
    
    -- ==========================================
    -- MÉTHODE 2 : Vérification Groupe ESX
    -- ==========================================
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return false
    end
    
    local playerGroup = xPlayer.getGroup()
    
    -- ==========================================
    -- ⭐ VÉRIFICATION DANS allowedGroups
    -- ==========================================
    for _, allowedGroup in ipairs(Config.AdminPermissions.allowedGroups) do
        if playerGroup == allowedGroup then
            return true
        end
    end
    
    -- ==========================================
    -- MÉTHODE 3 : Vérification BDD Directe (BACKUP)
    -- ==========================================
    local identifier = xPlayer.getIdentifier()
    
    if identifier then
        MySQL.Async.fetchScalar('SELECT `group` FROM users WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(dbGroup)
            if dbGroup then
                
                for _, allowedGroup in ipairs(Config.AdminPermissions.allowedGroups) do
                    if dbGroup == allowedGroup then
                    end
                end
            end
        end)
    end
    
    return false
end

-- ==========================================
-- FONCTION : VÉRIFIER SI PEUT REJOINDRE GDT
-- ==========================================

function Permissions.CanJoinGDT(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Ici tu peux ajouter des conditions supplémentaires
    -- Exemple : niveau minimum, argent, ban list, etc.
    
    return true
end

-- ==========================================
-- FONCTION : AFFICHER LES GROUPES AUTORISÉS
-- ==========================================

function Permissions.GetAllowedGroups()
    return Config.AdminPermissions.allowedGroups
end

-- ==========================================
-- FONCTION : AJOUTER UN GROUPE AUTORISÉ
-- ==========================================

function Permissions.AddAllowedGroup(groupName)
    if not Utils.TableContains(Config.AdminPermissions.allowedGroups, groupName) then
        table.insert(Config.AdminPermissions.allowedGroups, groupName)
        return true
    end
    return false
end

-- ==========================================
-- FONCTION : RETIRER UN GROUPE AUTORISÉ
-- ==========================================

function Permissions.RemoveAllowedGroup(groupName)
    for i, group in ipairs(Config.AdminPermissions.allowedGroups) do
        if group == groupName then
            table.remove(Config.AdminPermissions.allowedGroups, i)
            return true
        end
    end
    return false
end

-- ==========================================
-- COMMANDE DEBUG : /gtperms
-- ==========================================

RegisterCommand('gtperms', function(source, args)
    if source == 0 then
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local isAdmin = Permissions.IsAdmin(source)
    local playerGroup = xPlayer.getGroup()
    
    local message = '^5=== GDT PERMISSIONS ===^7\n'
    message = message .. '^3Ton ID: ^7'..source..'\n'
    message = message .. '^3Ton Groupe: ^7'..playerGroup..'\n'
    message = message .. '^3Admin GDT: '..(isAdmin and 'OUI' or 'NON')..'^7\n'
    message = message .. '\n^3Groupes autorisés:^7\n'
    
    for _, group in ipairs(Config.AdminPermissions.allowedGroups) do
        local isYourGroup = (group == playerGroup)
        message = message .. '  '..(isYourGroup and '^2✓ ' or '^8  ')..group..(isYourGroup and ' (TOI)' or '')..'^7\n'
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.75); border-radius: 5px;">{0}</div>',
        args = { message }
    })
    
   end, false)

return Permissions