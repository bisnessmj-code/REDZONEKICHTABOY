--[[
    Module Auth - Panel Admin Fight League
    Authentification et vérification des permissions
]]

local Auth = {}

-- Cache des sessions actives
local activeSessions = {}

-- Rate limiting
local rateLimits = {}
local RATE_LIMIT_WINDOW = 60000 -- 1 minute
local RATE_LIMIT_MAX = Config.Security.RateLimitPerMinute

-- ══════════════════════════════════════════════════════════════
-- GESTION DES SESSIONS
-- ══════════════════════════════════════════════════════════════

-- Initialiser une session staff
function Auth.InitSession(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local identifier = xPlayer.getIdentifier()
    local group = xPlayer.getGroup()

    -- Vérifier si le groupe a accès au panel
    if not Permissions.Grades[group] then
        return nil
    end

    local session = {
        source = source,
        identifier = identifier,
        name = GetPlayerName(source),
        group = group,
        level = Permissions.GetLevel(group),
        abilities = Permissions.GetAllAbilities(group),
        createdAt = os.time(),
        lastActivity = os.time()
    }

    activeSessions[source] = session

    -- Logger l'ouverture du panel
    Database.AddLog(
        Enums.LogCategory.AUTH,
        Enums.LogAction.PANEL_OPEN,
        identifier,
        session.name,
        nil, nil,
        {group = group, level = session.level}
    )

    -- Discord webhook
    if Discord and Discord.LogAuth then
        Discord.LogAuth('open', session.name, group, nil)
    end

    -- Mettre à jour la dernière connexion panel
    Database.Execute([[
        INSERT INTO panel_staff (identifier, staff_name, staff_group, last_panel_access)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE last_panel_access = NOW(), staff_name = ?, staff_group = ?
    ]], {identifier, session.name, group, session.name, group})

    return session
end

-- Terminer une session
function Auth.EndSession(source)
    local session = activeSessions[source]
    if session then
        local duration = os.time() - session.createdAt

        Database.AddLog(
            Enums.LogCategory.AUTH,
            Enums.LogAction.PANEL_CLOSE,
            session.identifier,
            session.name,
            nil, nil,
            {duration = duration}
        )

        -- Discord webhook
        if Discord and Discord.LogAuth then
            Discord.LogAuth('close', session.name, session.group, {duration = duration})
        end

        activeSessions[source] = nil
    end
end

-- Obtenir une session
function Auth.GetSession(source)
    local session = activeSessions[source]
    if not session then return nil end

    -- Vérifier le timeout
    if os.time() - session.lastActivity > Config.Security.SessionTimeout then
        Auth.EndSession(source)
        return nil
    end

    session.lastActivity = os.time()
    return session
end

-- Rafraîchir la session (après changement de groupe)
function Auth.RefreshSession(source)
    if activeSessions[source] then
        Auth.EndSession(source)
        return Auth.InitSession(source)
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
-- VÉRIFICATION DES PERMISSIONS
-- ══════════════════════════════════════════════════════════════

-- Vérifier si un joueur a accès au panel
function Auth.CanAccessPanel(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local group = xPlayer.getGroup()
    return Permissions.Grades[group] ~= nil
end

-- Vérifier une permission
function Auth.HasPermission(source, permission)
    local session = Auth.GetSession(source)
    if not session then
        -- Essayer de créer une session
        if Config.Debug then print('^3[AUTH DEBUG]^0 Pas de session pour ' .. source .. ', tentative de création...') end
        session = Auth.InitSession(source)
        if not session then
            if Config.Debug then print('^1[AUTH DEBUG]^0 Impossible de créer une session pour ' .. source) end
            return false
        end
    end

    if Config.Debug then print('^3[AUTH DEBUG]^0 Vérification permission: ' .. permission .. ' pour ' .. session.name .. ' (' .. session.group .. ')') end

    -- Wildcard
    if session.abilities['*'] then
        if Config.Debug then print('^2[AUTH DEBUG]^0 Permission accordée (wildcard)') end
        return true
    end

    local hasIt = session.abilities[permission] == true
    if Config.Debug then print('^3[AUTH DEBUG]^0 Permission ' .. permission .. ': ' .. tostring(hasIt)) end
    return hasIt
end

-- Vérifier si peut agir sur une cible
-- allowSelf: permet les actions sur soi-même (pour certaines actions inoffensives uniquement)
function Auth.CanActOn(source, targetSource, allowSelf)
    local session = Auth.GetSession(source)
    if not session then
        if Config.Debug then print('^1[AUTH]^0 CanActOn: Pas de session pour source ' .. tostring(source)) end
        return false
    end

    -- CORRECTION SÉCURITÉ: Empêcher les actions critiques sur soi-même
    if source == targetSource then
        if allowSelf then
            if Config.Debug then print('^3[AUTH]^0 CanActOn: Meme joueur, autorise (allowSelf=true)') end
            return true
        else
            if Config.Debug then print('^1[AUTH]^0 CanActOn: Action sur soi-même REFUSÉE pour raisons de sécurité') end
            return false
        end
    end

    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then
        if Config.Debug then print('^1[AUTH]^0 CanActOn: Target non trouve ' .. tostring(targetSource)) end
        return false
    end

    local targetGroup = xTarget.getGroup()
    local targetLevel = Permissions.GetLevel(targetGroup)

    if Config.Debug then print('^3[AUTH]^0 CanActOn: Staff=' .. session.name .. ' (level ' .. session.level .. ') vs Target=' .. xTarget.getName() .. ' group=' .. targetGroup .. ' (level ' .. targetLevel .. ')') end

    -- Si la cible n'est pas staff (level 0), on peut toujours agir
    if targetLevel == 0 then
        if Config.Debug then print('^2[AUTH]^0 CanActOn: Target est un joueur normal, autorise') end
        return true
    end

    -- Sinon, il faut un niveau superieur
    local canAct = session.level > targetLevel
    if Config.Debug then print('^3[AUTH]^0 CanActOn: Resultat = ' .. tostring(canAct)) end
    return canAct
end

-- Vérifier le niveau minimum requis
function Auth.HasMinLevel(source, minLevel)
    local session = Auth.GetSession(source)
    if not session then return false end
    return session.level >= minLevel
end

-- ══════════════════════════════════════════════════════════════
-- RATE LIMITING
-- ══════════════════════════════════════════════════════════════

-- Vérifier le rate limit
function Auth.CheckRateLimit(source)
    local now = GetGameTimer()
    local identifier = Helpers.GetMainIdentifier(source)

    if not rateLimits[identifier] then
        rateLimits[identifier] = {count = 0, windowStart = now}
    end

    local limit = rateLimits[identifier]

    -- Reset si nouvelle fenêtre
    if now - limit.windowStart > RATE_LIMIT_WINDOW then
        limit.count = 0
        limit.windowStart = now
    end

    limit.count = limit.count + 1

    if limit.count > RATE_LIMIT_MAX then
        if Config.Security.LogSuspiciousActivity then
            Database.AddLog(
                Enums.LogCategory.SYSTEM,
                'rate_limit_exceeded',
                identifier,
                GetPlayerName(source),
                nil, nil,
                {count = limit.count}
            )
        end
        return false
    end

    return true
end

-- ══════════════════════════════════════════════════════════════
-- EXPORTS
-- ══════════════════════════════════════════════════════════════

-- Export: Vérifier si un joueur a une permission
exports('hasPermission', function(source, permission)
    return Auth.HasPermission(source, permission)
end)

-- Export: Obtenir les infos staff
exports('getStaffInfo', function(source)
    local session = Auth.GetSession(source)
    if not session then return nil end

    return {
        identifier = session.identifier,
        name = session.name,
        group = session.group,
        level = session.level
    }
end)

-- ══════════════════════════════════════════════════════════════
-- NETTOYAGE
-- ══════════════════════════════════════════════════════════════

-- Nettoyage à la déconnexion
AddEventHandler('playerDropped', function()
    local source = source
    Auth.EndSession(source)
end)

-- Nettoyage périodique des rate limits
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        local now = GetGameTimer()
        for id, limit in pairs(rateLimits) do
            if now - limit.windowStart > RATE_LIMIT_WINDOW * 2 then
                rateLimits[id] = nil
            end
        end
    end
end)

-- Export global
_G.Auth = Auth
