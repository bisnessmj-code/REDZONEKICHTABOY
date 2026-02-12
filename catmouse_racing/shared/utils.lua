--[[
    ═══════════════════════════════════════════════════════════
    🛠️ FONCTIONS UTILITAIRES PARTAGÉES (VERSION AMÉLIORÉE)
    ═══════════════════════════════════════════════════════════
    
    ✅ NOUVEAU: Système de niveaux de log avec Config.LogLevel
]]

Utils = {}

-- ═══════════════════════════════════════════════════════════
-- 🐛 SYSTÈME DE LOG AVANCÉ AVEC NIVEAUX
-- ═══════════════════════════════════════════════════════════

-- Niveaux de log (du plus verbeux au plus important)
local LogLevel = {
    TRACE = 0,   -- Trace de l'exécution (très verbeux)
    DEBUG = 1,   -- Debug général
    INFO = 2,    -- Informations importantes
    WARN = 3,    -- Avertissements
    ERROR = 4,   -- Erreurs
    NONE = 5     -- Aucun log
}

-- Couleurs pour la console
local Colors = {
    RESET = '^7',
    RED = '^1',
    GREEN = '^2',
    YELLOW = '^3',
    BLUE = '^4',
    CYAN = '^5',
    MAGENTA = '^6',
    WHITE = '^0'
}

-- Préfixes par type de log
local LogPrefixes = {
    TRACE = Colors.MAGENTA .. '[TRACE]' .. Colors.RESET,
    DEBUG = Colors.CYAN .. '[DEBUG]' .. Colors.RESET,
    INFO = Colors.GREEN .. '[INFO]' .. Colors.RESET,
    WARN = Colors.YELLOW .. '[WARN]' .. Colors.RESET,
    ERROR = Colors.RED .. '[ERROR]' .. Colors.RESET
}

--- Obtenir le niveau de log configuré
---@return number
local function GetLogLevel()
    if not Config then return LogLevel.INFO end
    
    -- Si Config.Debug = false, on met le niveau à ERROR (seules les erreurs s'affichent)
    -- Si Config.Debug = true, on utilise Config.LogLevel ou on met TRACE par défaut
    if not Config.Debug then
        return LogLevel.ERROR
    end
    
    -- Si Debug = true, utiliser le niveau personnalisé ou TRACE par défaut
    return Config.LogLevel or LogLevel.TRACE
end

--- Fonction interne pour logger avec vérification du niveau
---@param level number Niveau du message
---@param prefix string Préfixe du log
---@param message string Message à logger
---@param data? table Données supplémentaires
---@param source? string Source du log (fichier/fonction)
local function Log(level, prefix, message, data, source)
    -- Vérifier si on doit afficher ce niveau de log
    if level < GetLogLevel() then return end
    
    local srcInfo = source and (Colors.BLUE .. '[' .. source .. ']' .. Colors.RESET .. ' ') or ''
    
    if data then

    else

    end
end

-- ═══════════════════════════════════════════════════════════
-- 📝 FONCTIONS DE LOG PUBLIQUES
-- ═══════════════════════════════════════════════════════════

--- Log de trace (très verbeux - exécution détaillée)
---@param functionName string Nom de la fonction
---@param args? table Arguments de la fonction
function Utils.Trace(functionName, args)
    if args then
        Log(LogLevel.TRACE, LogPrefixes.TRACE, '-> ' .. functionName .. '(' .. json.encode(args, { indent = false }) .. ')')
    else
        Log(LogLevel.TRACE, LogPrefixes.TRACE, '-> ' .. functionName .. '()')
    end
end

--- Log de debug conditionnel
---@param message string Message à logger
---@param data? table Données supplémentaires
---@param source? string Source du log (fichier/fonction)
function Utils.Debug(message, data, source)
    Log(LogLevel.DEBUG, LogPrefixes.DEBUG, message, data, source)
end

--- Log d'information
---@param message string
---@param data? table
function Utils.Info(message, data)
    Log(LogLevel.INFO, LogPrefixes.INFO, message, data)
end

--- Log d'avertissement
---@param message string
---@param data? table
function Utils.Warn(message, data)
    Log(LogLevel.WARN, LogPrefixes.WARN, message, data)
end

--- Log d'erreur
---@param message string
---@param data? table
---@param source? string
function Utils.Error(message, data, source)
    Log(LogLevel.ERROR, LogPrefixes.ERROR, message, data, source)
end

-- ═══════════════════════════════════════════════════════════
-- ✅ VALIDATION
-- ═══════════════════════════════════════════════════════════

--- Validation d'un ID serveur
---@param id any ID à valider
---@return boolean
function Utils.IsValidServerId(id)
    local numId = tonumber(id)
    return numId ~= nil and numId > 0
end

--- Vérification si une table est vide
---@param tbl table
---@return boolean
function Utils.IsTableEmpty(tbl)
    return next(tbl) == nil
end

--- Vérification si une valeur existe dans une table
---@param tbl table
---@param value any
---@return boolean
function Utils.TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 🔧 MANIPULATION
-- ═══════════════════════════════════════════════════════════

--- Formatage de texte avec paramètres
---@param text string Texte avec %s
---@param ... any Paramètres à injecter
---@return string
function Utils.FormatText(text, ...)
    local success, result = pcall(string.format, text, ...)
    if success then
        return result
    else
        Utils.Error('FormatText failed', { text = text, args = {...} }, 'Utils')
        return text
    end
end

--- Génération d'un ID unique (compatible client + serveur)
---@return string
function Utils.GenerateId()
    local timestamp = GetGameTimer()
    local random = math.random(10000, 99999)
    return string.format('%s_%s', timestamp, random)
end

--- Copie profonde d'une table
---@param orig table Table originale
---@return table
function Utils.DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in next, orig, nil do
            copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- Fusion de deux tables
---@param t1 table Table de base
---@param t2 table Table à fusionner
---@return table
function Utils.MergeTables(t1, t2)
    local result = Utils.DeepCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = Utils.MergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- ═══════════════════════════════════════════════════════════
-- ⏱️ TEMPS
-- ═══════════════════════════════════════════════════════════

--- Formatage d'un timestamp en MM:SS
---@param milliseconds number
---@return string
function Utils.FormatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format('%02d:%02d', minutes, seconds)
end

--- Formatage d'un timestamp en MM:SS.ms
---@param milliseconds number
---@return string
function Utils.FormatTimeMs(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local ms = milliseconds % 1000
    return string.format('%02d:%02d.%03d', minutes, seconds, ms)
end

--- Obtenir le timestamp actuel en millisecondes (compatible client + serveur)
---@return number
function Utils.GetTimestamp()
    if IsDuplicityVersion() then
        return os.time() * 1000
    else
        return GetGameTimer()
    end
end

-- ═══════════════════════════════════════════════════════════
-- 📏 CALCULS
-- ═══════════════════════════════════════════════════════════

--- Calcul de distance entre deux vecteurs
---@param v1 vector3
---@param v2 vector3
---@return number
function Utils.GetDistance(v1, v2)
    if not v1 or not v2 then return 999999.0 end
    return #(v1 - v2)
end

--- Calcul de distance 2D (ignore Z)
---@param v1 vector3
---@param v2 vector3
---@return number
function Utils.GetDistance2D(v1, v2)
    if not v1 or not v2 then return 999999.0 end
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Conversion km/h vers m/s
---@param kmh number
---@return number
function Utils.KmhToMs(kmh)
    return kmh / 3.6
end

--- Conversion m/s vers km/h
---@param ms number
---@return number
function Utils.MsToKmh(ms)
    return ms * 3.6
end

-- ═══════════════════════════════════════════════════════════
-- 🎲 ALÉATOIRE
-- ═══════════════════════════════════════════════════════════

--- Choix aléatoire d'un rôle (HUNTER ou RUNNER)
---@return number
function Utils.RandomRole()
    return math.random(1, 2)
end

--- Inversion d'un rôle
---@param role number
---@return number
function Utils.InvertRole(role)
    if role == Constants.Role.HUNTER then
        return Constants.Role.RUNNER
    elseif role == Constants.Role.RUNNER then
        return Constants.Role.HUNTER
    end
    return Constants.Role.NONE
end

--- Obtenir le nom d'un rôle
---@param role number
---@return string
function Utils.GetRoleName(role)
    return Constants.RoleName[role] or 'INCONNU'
end

--- Obtenir le nom d'un statut
---@param status number
---@return string
function Utils.GetStatusName(status)
    return Constants.RaceStatusName[status] or 'UNKNOWN'
end

--- Obtenir le nom d'un résultat
---@param result number
---@return string
function Utils.GetResultName(result)
    return Constants.RoundResultName[result] or 'UNKNOWN'
end

--- Compte le nombre d'éléments dans une table (pour tables non-séquentielles)
---@param tbl table
---@return number
function Utils.TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

