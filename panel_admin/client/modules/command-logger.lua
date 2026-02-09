--[[
    Module Command Logger Client - Panel Admin Fight League
    Capture toutes les commandes et les envoie au serveur
    Utilise un hook sur ExecuteCommand pour capturer TOUTES les commandes
]]

-- ══════════════════════════════════════════════════════════════
-- VARIABLES
-- ══════════════════════════════════════════════════════════════

local commandsLogged = {} -- Anti-spam (eviter les doublons)
local COOLDOWN = 100 -- ms entre les logs de la meme commande

-- ══════════════════════════════════════════════════════════════
-- HOOK SUR EXECUTECOMMAND (METHODE LA PLUS FIABLE)
-- ══════════════════════════════════════════════════════════════

-- Sauvegarder la fonction originale
local OriginalExecuteCommand = ExecuteCommand

-- Remplacer ExecuteCommand par notre version
ExecuteCommand = function(commandString)
    -- Verifier si la fonctionnalite est activee
    if Config.CommandLogger and Config.CommandLogger.Enabled then
        -- Anti-spam: verifier si on a deja log cette commande recemment
        local now = GetGameTimer()
        local cmdKey = commandString

        if not commandsLogged[cmdKey] or (now - commandsLogged[cmdKey]) > COOLDOWN then
            commandsLogged[cmdKey] = now

            -- Envoyer au serveur pour log
            TriggerServerEvent('panel:logPlayerCommand', commandString)
        end
    end

    -- Appeler la fonction originale
    return OriginalExecuteCommand(commandString)
end

-- ══════════════════════════════════════════════════════════════
-- METHODE ALTERNATIVE: HOOK SUR LE CHAT
-- ══════════════════════════════════════════════════════════════

-- Certains serveurs n'utilisent pas ExecuteCommand directement
-- On ecoute aussi les events du chat

-- Event standard chat
AddEventHandler('chatMessage', function(source, name, message)
    if Config.CommandLogger and Config.CommandLogger.Enabled then
        if message and type(message) == 'string' and string.sub(message, 1, 1) == '/' then
            local commandString = string.sub(message, 2)
            local now = GetGameTimer()

            if not commandsLogged[commandString] or (now - commandsLogged[commandString]) > COOLDOWN then
                commandsLogged[commandString] = now
                TriggerServerEvent('panel:logPlayerCommand', commandString)
            end
        end
    end
end)

-- Event _chat:messageEntered (certaines versions du chat)
AddEventHandler('_chat:messageEntered', function(author, color, message)
    if Config.CommandLogger and Config.CommandLogger.Enabled then
        if message and type(message) == 'string' and string.sub(message, 1, 1) == '/' then
            local commandString = string.sub(message, 2)
            local now = GetGameTimer()

            if not commandsLogged[commandString] or (now - commandsLogged[commandString]) > COOLDOWN then
                commandsLogged[commandString] = now
                TriggerServerEvent('panel:logPlayerCommand', commandString)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- NETTOYAGE DU CACHE ANTI-SPAM
-- ══════════════════════════════════════════════════════════════

Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Toutes les minutes

        -- Nettoyer les vieilles entrees
        local now = GetGameTimer()
        for cmd, timestamp in pairs(commandsLogged) do
            if (now - timestamp) > 10000 then -- Plus de 10 secondes
                commandsLogged[cmd] = nil
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ══════════════════════════════════════════════════════════════

Citizen.CreateThread(function()
    Wait(1000)
    if Config.CommandLogger and Config.CommandLogger.Enabled and Config.Debug then
        print('^2[COMMAND LOGGER]^0 Client module charge - Hook ExecuteCommand actif')
    end
end)
