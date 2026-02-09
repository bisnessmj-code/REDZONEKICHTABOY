--[[
    Helpers Serveur - Panel Admin Fight League
    Fonctions utilitaires côté serveur
]]

Helpers = {}

-- ══════════════════════════════════════════════════════════════
-- IDENTIFIANTS JOUEUR
-- ══════════════════════════════════════════════════════════════

-- Obtenir tous les identifiants d'un joueur
function Helpers.GetPlayerIdentifiers(source)
    local identifiers = {
        steam = nil,
        license = nil,
        discord = nil,
        live = nil,
        xbl = nil,
        ip = nil,
        fivem = nil
    }

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            if string.find(id, 'steam:') then
                identifiers.steam = id
            elseif string.find(id, 'license:') then
                identifiers.license = id
            elseif string.find(id, 'discord:') then
                identifiers.discord = id
            elseif string.find(id, 'live:') then
                identifiers.live = id
            elseif string.find(id, 'xbl:') then
                identifiers.xbl = id
            elseif string.find(id, 'ip:') then
                identifiers.ip = id
            elseif string.find(id, 'fivem:') then
                identifiers.fivem = id
            end
        end
    end

    return identifiers
end

-- Obtenir un identifiant spécifique
function Helpers.GetIdentifier(source, idType)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.find(id, idType .. ':') then
            return id
        end
    end
    return nil
end

-- Obtenir l'identifiant principal (steam ou license)
function Helpers.GetMainIdentifier(source)
    local steam = Helpers.GetIdentifier(source, 'steam')
    if steam then return steam end

    local license = Helpers.GetIdentifier(source, 'license')
    if license then return license end

    return nil
end

-- ══════════════════════════════════════════════════════════════
-- FORMATAGE
-- ══════════════════════════════════════════════════════════════

-- Formater un nombre avec séparateurs
function Helpers.FormatNumber(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1 %2')
        if k == 0 then break end
    end
    return formatted
end

-- Formater une durée en texte lisible
function Helpers.FormatDuration(hours)
    if not hours or hours < 0 then
        return 'Permanent'
    end

    -- Convertir en minutes totales pour plus de precision
    local totalMinutes = math.floor(hours * 60)

    if totalMinutes < 60 then
        -- Moins d'une heure: afficher en minutes
        return totalMinutes .. ' minute' .. (totalMinutes > 1 and 's' or '')
    elseif totalMinutes < 1440 then -- Moins de 24 heures
        local h = math.floor(totalMinutes / 60)
        local m = totalMinutes % 60
        if m > 0 then
            return h .. 'h' .. string.format('%02d', m)
        else
            return h .. ' heure' .. (h > 1 and 's' or '')
        end
    elseif totalMinutes < 10080 then -- Moins de 7 jours
        local days = math.floor(totalMinutes / 1440)
        local remainingHours = math.floor((totalMinutes % 1440) / 60)
        if remainingHours > 0 then
            return days .. ' jour' .. (days > 1 and 's' or '') .. ' ' .. remainingHours .. 'h'
        else
            return days .. ' jour' .. (days > 1 and 's' or '')
        end
    else
        local weeks = math.floor(totalMinutes / 10080)
        local remainingDays = math.floor((totalMinutes % 10080) / 1440)
        if remainingDays > 0 then
            return weeks .. ' semaine' .. (weeks > 1 and 's' or '') .. ' ' .. remainingDays .. 'j'
        else
            return weeks .. ' semaine' .. (weeks > 1 and 's' or '')
        end
    end
end

-- Formater une date relative (il y a X)
function Helpers.FormatRelativeTime(timestamp)
    local diff = os.time() - timestamp

    if diff < 60 then
        return 'Il y a quelques secondes'
    elseif diff < 3600 then
        local minutes = math.floor(diff / 60)
        return 'Il y a ' .. minutes .. ' minute' .. (minutes > 1 and 's' or '')
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return 'Il y a ' .. hours .. ' heure' .. (hours > 1 and 's' or '')
    elseif diff < 604800 then
        local days = math.floor(diff / 86400)
        return 'Il y a ' .. days .. ' jour' .. (days > 1 and 's' or '')
    else
        return os.date('%d/%m/%Y', timestamp)
    end
end

-- Formater le temps de jeu
function Helpers.FormatPlaytime(minutes)
    if not minutes then return '0h' end

    local hours = math.floor(minutes / 60)
    local mins = minutes % 60

    if hours > 0 then
        return hours .. 'h ' .. mins .. 'm'
    else
        return mins .. 'm'
    end
end

-- ══════════════════════════════════════════════════════════════
-- VALIDATION
-- ══════════════════════════════════════════════════════════════

-- Vérifier si une valeur est vide
function Helpers.IsEmpty(value)
    return value == nil or value == '' or (type(value) == 'table' and next(value) == nil)
end

-- Nettoyer une chaîne (enlever les caractères spéciaux)
function Helpers.SanitizeString(str)
    if not str then return '' end
    return str:gsub('[<>\"\'&]', '')
end

-- Tronquer une chaîne
function Helpers.Truncate(str, maxLen)
    if not str then return '' end
    if #str <= maxLen then return str end
    return string.sub(str, 1, maxLen - 3) .. '...'
end

-- ══════════════════════════════════════════════════════════════
-- JOUEURS
-- ══════════════════════════════════════════════════════════════

-- Obtenir le nom d'un joueur
function Helpers.GetPlayerName(source)
    return GetPlayerName(source) or 'Inconnu'
end

-- Obtenir les coordonnées d'un joueur
function Helpers.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

-- Vérifier si un joueur est connecté
function Helpers.IsPlayerOnline(source)
    return GetPlayerName(source) ~= nil
end

-- Obtenir tous les joueurs connectés
function Helpers.GetAllPlayers()
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, tonumber(playerId))
    end
    return players
end

-- ══════════════════════════════════════════════════════════════
-- TABLES
-- ══════════════════════════════════════════════════════════════

-- Copier une table
function Helpers.DeepCopy(orig)
    local origType = type(orig)
    local copy
    if origType == 'table' then
        copy = {}
        for origKey, origValue in next, orig, nil do
            copy[Helpers.DeepCopy(origKey)] = Helpers.DeepCopy(origValue)
        end
        setmetatable(copy, Helpers.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Fusionner deux tables
function Helpers.MergeTables(t1, t2)
    local result = Helpers.DeepCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = Helpers.MergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Compter les éléments d'une table
function Helpers.TableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Vérifier si une valeur est dans une table
function Helpers.TableContains(t, value)
    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
-- MESSAGES & ERREURS
-- ══════════════════════════════════════════════════════════════

-- Formater un message d'erreur avec traduction
function Helpers.FormatError(errorCode)
    if not errorCode then
        return _L('error_unknown')
    end

    -- Essayer avec le code direct (ex: "NO_PERMISSION")
    local key = 'error_' .. tostring(errorCode)
    local translated = _L(key)

    -- Si la traduction retourne la clé elle-même, c'est qu'elle n'existe pas
    if translated == key then
        -- Essayer de nettoyer le code (enlever "error_" si présent)
        local cleanCode = errorCode:gsub('^error_', '')
        translated = _L('error_' .. cleanCode)

        -- Si toujours pas trouvé, retourner message par défaut
        if translated == ('error_' .. cleanCode) then
            return _L('error_unknown') .. ' (' .. tostring(errorCode) .. ')'
        end
    end

    return translated
end

-- Formater un message de succès avec traduction
function Helpers.FormatSuccess(successCode)
    if not successCode then
        return _L('success')
    end

    local key = 'success_' .. tostring(successCode)
    local translated = _L(key)

    if translated == key then
        return _L('success')
    end

    return translated
end

-- Créer une notification formatée
function Helpers.CreateNotification(type, titleKey, messageKey)
    return {
        type = type or 'info',
        title = _L(titleKey) or _L('info'),
        message = messageKey and _L(messageKey) or ''
    }
end

-- ══════════════════════════════════════════════════════════════
-- HIERARCHIE DES GRADES
-- ══════════════════════════════════════════════════════════════

-- Niveaux de grade (plus le nombre est eleve, plus le grade est haut)
local gradeLevels = {
    ['user'] = 0,
    ['staff'] = 1,
    ['organisateur'] = 2,
    ['responsable'] = 3,
    ['admin'] = 4,
    ['owner'] = 5
}

-- Obtenir le niveau d'un grade
function Helpers.GetGradeLevel(grade)
    return gradeLevels[string.lower(grade or '')] or 0
end

-- Verifier si un grade peut agir sur un autre (doit etre strictement superieur)
function Helpers.CanActOnGrade(staffGrade, targetGrade)
    local staffLevel = Helpers.GetGradeLevel(staffGrade)
    local targetLevel = Helpers.GetGradeLevel(targetGrade)
    return staffLevel > targetLevel
end

-- Obtenir le grade d'un joueur par son source
function Helpers.GetPlayerGrade(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.getGroup() or 'user'
    end
    return 'user'
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG
-- ══════════════════════════════════════════════════════════════

function Helpers.Debug(...)
    if Config.Debug then
        print('[PANEL DEBUG]', ...)
    end
end

function Helpers.DebugTable(t, indent)
    if not Config.Debug then return end
    indent = indent or ''
    for k, v in pairs(t) do
        if type(v) == 'table' then
            print(indent .. tostring(k) .. ':')
            Helpers.DebugTable(v, indent .. '  ')
        else
            print(indent .. tostring(k) .. ': ' .. tostring(v))
        end
    end
end
