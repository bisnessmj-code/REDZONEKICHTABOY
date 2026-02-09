--[[
    Module Command Logger - Panel Admin Fight League
    Log toutes les commandes des joueurs sur Discord
]]

local ESX = exports['es_extended']:getSharedObject()

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ══════════════════════════════════════════════════════════════

-- Verifier si une commande est ignoree
local function isCommandIgnored(command)
    if not Config.CommandLogger or not Config.CommandLogger.IgnoredCommands then
        return false
    end

    local cmd = string.lower(command)
    for _, ignoredCmd in ipairs(Config.CommandLogger.IgnoredCommands) do
        if cmd == string.lower(ignoredCmd) then
            return true
        end
    end

    return false
end

-- Verifier si un groupe est ignore
local function isGroupIgnored(group)
    if not Config.CommandLogger then
        return false
    end

    local g = string.lower(group or 'user')

    -- Verifier OnlyGroups (si defini, seuls ces groupes sont logges)
    if Config.CommandLogger.OnlyGroups and #Config.CommandLogger.OnlyGroups > 0 then
        local found = false
        for _, onlyGroup in ipairs(Config.CommandLogger.OnlyGroups) do
            if g == string.lower(onlyGroup) then
                found = true
                break
            end
        end
        if not found then
            return true -- Groupe pas dans la liste OnlyGroups = ignore
        end
    end

    -- Verifier IgnoredGroups
    if Config.CommandLogger.IgnoredGroups then
        for _, ignoredGroup in ipairs(Config.CommandLogger.IgnoredGroups) do
            if g == string.lower(ignoredGroup) then
                return true
            end
        end
    end

    return false
end

-- Obtenir les identifiants du joueur
local function getPlayerIdentifiers(source)
    local identifiers = {
        license = nil,
        discord = nil,
        steam = nil,
        fivem = nil,
        ip = nil
    }

    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, 'license:') then
            identifiers.license = id
        elseif string.find(id, 'discord:') then
            identifiers.discord = string.gsub(id, 'discord:', '')
        elseif string.find(id, 'steam:') then
            identifiers.steam = id
        elseif string.find(id, 'fivem:') then
            identifiers.fivem = id
        elseif string.find(id, 'ip:') then
            identifiers.ip = string.gsub(id, 'ip:', '')
        end
    end

    return identifiers
end

-- Envoyer le log Discord
local function sendDiscordLog(playerName, playerId, playerGroup, command, identifiers)
    if not Config.Discord or not Config.Discord.Enabled then
        return
    end

    -- Utiliser le convar depuis server.cfg (securise)
    local webhook = GetConvar('discord_webhook_commands', '')
    if not webhook or webhook == '' then
        return
    end

    -- Discord mention si disponible
    local discordMention = identifiers.discord and ('<@' .. identifiers.discord .. '>') or 'N/A'

    -- Construire l'embed
    local embed = {
        {
            title = 'Commande Detectee',
            color = Config.CommandLogger.EmbedColor or 16744448,
            fields = {
                {
                    name = 'Joueur',
                    value = playerName,
                    inline = true
                },
                {
                    name = 'ID Serveur',
                    value = tostring(playerId),
                    inline = true
                },
                {
                    name = 'Groupe',
                    value = playerGroup or 'user',
                    inline = true
                },
                {
                    name = 'Commande',
                    value = '```/' .. command .. '```',
                    inline = false
                },
                {
                    name = 'License',
                    value = '```' .. (identifiers.license or 'N/A') .. '```',
                    inline = false
                },
                {
                    name = 'Discord',
                    value = discordMention,
                    inline = true
                },
                {
                    name = 'Steam',
                    value = '```' .. (identifiers.steam or 'N/A') .. '```',
                    inline = true
                }
            },
            footer = {
                text = 'Panel Admin Fight League'
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }

    -- Envoyer le webhook
    PerformHttpRequest(webhook, function(err, text, headers)
        if Config.Debug and err ~= 204 and err ~= 200 then
            print('^1[COMMAND LOGGER]^0 Erreur webhook Discord: ' .. tostring(err))
        end
    end, 'POST', json.encode({
        username = Config.Discord.BotName or 'Panel Fight League',
        avatar_url = Config.Discord.BotAvatar or '',
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end

-- Fonction principale de log
local function logCommand(source, commandString)
    -- Verifier si la fonctionnalite est activee
    if not Config.CommandLogger or not Config.CommandLogger.Enabled then
        return
    end

    if not source or source == 0 then return end -- Ignorer la console

    -- Extraire le nom de la commande (premier mot)
    local cmd = string.match(commandString, '^(%S+)')
    if not cmd then return end

    -- Verifier si la commande est ignoree
    if isCommandIgnored(cmd) then
        return
    end

    -- Obtenir les infos du joueur
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerName = GetPlayerName(source) or 'Inconnu'
    local playerGroup = xPlayer and xPlayer.getGroup() or 'user'

    -- Verifier si le groupe est ignore
    if isGroupIgnored(playerGroup) then
        return
    end

    -- Obtenir les identifiants
    local identifiers = getPlayerIdentifiers(source)

    -- Envoyer le log Discord
    sendDiscordLog(playerName, source, playerGroup, commandString, identifiers)

    -- Log console si debug
    if Config.Debug then
        print('^3[COMMAND LOGGER]^0 ' .. playerName .. ' (ID: ' .. source .. ', Group: ' .. playerGroup .. ') -> /' .. commandString)
    end
end

-- ══════════════════════════════════════════════════════════════
-- EVENTS - Capture des commandes
-- ══════════════════════════════════════════════════════════════

-- Methode 1: Event du chat (messages commencant par /)
AddEventHandler('chatMessage', function(source, author, message)
    if string.sub(message, 1, 1) == '/' then
        local commandString = string.sub(message, 2) -- Enlever le /
        logCommand(source, commandString)
    end
end)

-- Methode 2: Event interne FiveM pour les commandes inconnues
AddEventHandler('__cfx_internal:commandFallback', function(commandString)
    local source = source
    logCommand(source, commandString)
end)

-- Methode 3: Enregistrer un event client -> server pour capturer les commandes (PRINCIPALE)
RegisterNetEvent('panel:logPlayerCommand', function(commandString)
    local source = source

    -- Debug: Toujours afficher pour verifier que ca fonctionne
    print('^3[COMMAND LOGGER]^0 Commande recue de ID ' .. tostring(source) .. ': /' .. tostring(commandString))

    logCommand(source, commandString)
end)

print('^2[PANEL ADMIN]^0 Module Command Logger charge')
