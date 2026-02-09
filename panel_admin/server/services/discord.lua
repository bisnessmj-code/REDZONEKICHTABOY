--[[
    Service Discord - Panel Admin Fight League
    Intégration webhooks Discord

    SECURITE: Les webhooks sont stockes dans server.cfg via des convars
    pour eviter qu'ils soient dump par des cheaters
]]

local Discord = {}

-- ══════════════════════════════════════════════════════════════
-- CONFIGURATION - WEBHOOKS DEPUIS SERVER.CFG (SECURISE)
-- ══════════════════════════════════════════════════════════════

-- Cache des webhooks (charges une seule fois au demarrage)
local webhookCache = {}

-- Charger les webhooks depuis les convars (server.cfg)
local function loadWebhooks()
    webhookCache = {
        sanctions = GetConvar('discord_webhook_sanctions', ''),
        economy = GetConvar('discord_webhook_economy', ''),
        events = GetConvar('discord_webhook_events', ''),
        logs = GetConvar('discord_webhook_logs', ''),
        deaths = GetConvar('discord_webhook_deaths', ''),
        staffRoles = GetConvar('discord_webhook_staffRoles', ''),
        commands = GetConvar('discord_webhook_commands', ''),
        gdt = GetConvar('discord_webhook_gdt', ''),
        cvc = GetConvar('discord_webhook_cvc', ''),
        deco = GetConvar('panel_webhook_deco', '')
    }

    if Config.Debug then
        print('^2[DISCORD]^0 Webhooks charges depuis server.cfg')
        for k, v in pairs(webhookCache) do
            print('^3[DISCORD]^0 ' .. k .. ': ' .. (v ~= '' and 'OK' or 'NON CONFIGURE'))
        end
    end
end

-- Charger au demarrage
CreateThread(function()
    Wait(100)
    loadWebhooks()
end)

-- Obtenir un webhook
local function getWebhook(webhookType)
    return webhookCache[webhookType] or ''
end

local function isEnabled()
    return Config.Discord and Config.Discord.Enabled
end

-- Couleurs par type
local colors = {
    success = 3066993,   -- Vert
    error = 15158332,    -- Rouge
    warning = 15105570,  -- Orange
    info = 3447003,      -- Bleu
    sanction = 15158332, -- Rouge
    economy = 3066993,   -- Vert
    event = 10181046     -- Violet
}

-- ══════════════════════════════════════════════════════════════
-- ENVOI DE WEBHOOKS
-- ══════════════════════════════════════════════════════════════

-- Envoyer un message webhook
function Discord.Send(webhookType, data)
    if not isEnabled() then return end

    local webhookUrl = getWebhook(webhookType)
    if not webhookUrl or webhookUrl == '' then return end

    local embed = {
        title = data.title,
        description = data.description,
        color = data.color or colors.info,
        fields = data.fields or {},
        footer = {
            text = Config.ServerName .. ' • Panel Admin',
            icon_url = Config.Discord.BotAvatar or nil
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    local payload = {
        username = Config.Discord.BotName or 'Panel Fight League',
        avatar_url = Config.Discord.BotAvatar or nil,
        embeds = {embed}
    }

    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        if statusCode ~= 200 and statusCode ~= 204 then
            Helpers.Debug('Discord webhook error:', statusCode, response)
        end
    end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

-- ══════════════════════════════════════════════════════════════
-- MESSAGES PRÉ-FORMATÉS
-- ══════════════════════════════════════════════════════════════

-- Log de sanction
function Discord.LogSanction(sanctionType, staffName, targetName, reason, duration, targetData)
    local typeLabels = {
        warn = 'Avertissement',
        kick = 'Expulsion',
        ban_temp = 'Ban Temporaire',
        ban_perm = 'Ban Permanent'
    }

    local typeEmojis = {
        warn = ':warning:',
        kick = ':boot:',
        ban_temp = ':hammer:',
        ban_perm = ':no_entry:'
    }

    local typeColors = {
        warn = 15105570,   -- Orange
        kick = 15844367,   -- Or
        ban_temp = 15158332, -- Rouge
        ban_perm = 10038562  -- Rouge fonce
    }

    -- Formater les infos du joueur sanctionne
    local playerInfo = targetName or 'Inconnu'
    if targetData then
        if targetData.serverId then
            playerInfo = playerInfo .. '\n:id: **ID:** ' .. tostring(targetData.serverId)
        end
        if targetData.discord then
            local discordId = targetData.discord:gsub('discord:', '')
            playerInfo = playerInfo .. '\n:speech_balloon: **Discord:** <@' .. discordId .. '>'
        end
        if targetData.license then
            local license = targetData.license:gsub('license:', '')
            playerInfo = playerInfo .. '\n:page_facing_up: **License:** `' .. license .. '`'
        end
        if targetData.steam then
            local steam = targetData.steam:gsub('steam:', '')
            playerInfo = playerInfo .. '\n:joystick: **Steam:** `' .. steam .. '`'
        end
        if targetData.fivem then
            local fivem = targetData.fivem:gsub('fivem:', '')
            playerInfo = playerInfo .. '\n:video_game: **FiveM:** `' .. fivem .. '`'
        end
    end

    local fields = {
        {name = ':police_officer: Staff', value = staffName, inline = true},
        {name = ':bust_in_silhouette: Joueur', value = playerInfo, inline = true}
    }

    -- Type de sanction
    local typeText = (typeEmojis[sanctionType] or ':scales:') .. ' ' .. (typeLabels[sanctionType] or sanctionType)
    table.insert(fields, {name = ':bookmark_tabs: Type', value = typeText, inline = true})

    -- Duree (pour les bans temporaires)
    if sanctionType == 'ban_temp' and duration and duration > 0 then
        table.insert(fields, {name = ':hourglass: Duree', value = Helpers.FormatDuration(duration), inline = true})
    elseif sanctionType == 'ban_perm' then
        table.insert(fields, {name = ':hourglass: Duree', value = ':infinity: Permanent', inline = true})
    end

    -- Raison
    table.insert(fields, {name = ':scroll: Raison', value = reason or 'Non specifiee', inline = false})

    -- Heure
    table.insert(fields, {name = ':clock1: Heure', value = os.date('%d/%m/%Y a %H:%M:%S'), inline = true})

    local emoji = typeEmojis[sanctionType] or ':scales:'
    local title = emoji .. ' ' .. (typeLabels[sanctionType] or 'Sanction')

    Discord.Send('sanctions', {
        title = title,
        description = '**' .. targetName .. '** a recu une sanction',
        color = typeColors[sanctionType] or colors.sanction,
        fields = fields
    })
end

-- Log de débannissement
function Discord.LogUnban(staffName, targetName, targetIdentifier)
    Discord.Send('sanctions', {
        title = 'Débannissement',
        description = '**' .. targetName .. '** a été débanni',
        color = colors.success,
        fields = {
            {name = 'Staff', value = staffName, inline = true},
            {name = 'Joueur', value = targetName, inline = true},
            {name = 'Identifiant', value = targetIdentifier, inline = false}
        }
    })
end

-- Log économique
function Discord.LogEconomy(action, staffName, targetName, amount, moneyType, reason)
    local actionLabels = {
        add = 'Argent Ajouté',
        remove = 'Argent Retiré',
        set = 'Argent Défini'
    }

    local typeLabels = {
        money = 'Espèces',
        bank = 'Banque',
        black_money = 'Argent Sale'
    }

    Discord.Send('economy', {
        title = actionLabels[action] or action,
        description = 'Transaction économique effectuée',
        color = action == 'remove' and colors.warning or colors.economy,
        fields = {
            {name = 'Staff', value = staffName, inline = true},
            {name = 'Joueur', value = targetName, inline = true},
            {name = 'Montant', value = '$' .. Helpers.FormatNumber(amount), inline = true},
            {name = 'Type', value = typeLabels[moneyType] or moneyType, inline = true},
            {name = 'Raison', value = reason or 'Non spécifiée', inline = false}
        }
    })
end

-- Log d'événement
function Discord.LogEvent(action, staffName, eventName, eventType)
    local actionLabels = {
        create = 'Événement Créé',
        start = 'Événement Démarré',
        ['end'] = 'Événement Terminé',
        cancel = 'Événement Annulé'
    }

    local actionColors = {
        create = colors.info,
        start = colors.success,
        ['end'] = colors.warning,
        cancel = colors.error
    }

    Discord.Send('events', {
        title = actionLabels[action] or action,
        description = '**' .. eventName .. '**',
        color = actionColors[action] or colors.event,
        fields = {
            {name = 'Staff', value = staffName, inline = true},
            {name = 'Type', value = eventType or 'Non spécifié', inline = true}
        }
    })
end

-- Log général
function Discord.Log(title, description, fields, colorType)
    Discord.Send('logs', {
        title = title,
        description = description,
        color = colors[colorType] or colors.info,
        fields = fields or {}
    })
end

-- Log d'authentification (ouverture/fermeture panel)
function Discord.LogAuth(action, staffName, staffGroup, details)
    local title = action == 'open' and '🔓 Connexion Panel' or '🔒 Déconnexion Panel'
    local embedColor = action == 'open' and 3066993 or 15105570 -- Vert pour open, Orange pour close

    local fields = {
        {name = '👤 Staff', value = staffName, inline = true},
        {name = '🎖️ Grade', value = staffGroup or 'Inconnu', inline = true}
    }

    if action == 'close' and details and details.duration then
        local duration = details.duration
        local hours = math.floor(duration / 3600)
        local minutes = math.floor((duration % 3600) / 60)
        local seconds = duration % 60
        local durationText = string.format('%dh %dm %ds', hours, minutes, seconds)
        table.insert(fields, {name = '⏱️ Durée session', value = durationText, inline = true})
    end

    Discord.Send('logs', {
        title = title,
        description = action == 'open' and 'Un administrateur s\'est connecté au panel' or 'Un administrateur s\'est déconnecté du panel',
        color = embedColor,
        fields = fields
    })
end

-- Log de téléportation
function Discord.LogTeleport(action, staffName, targetName, details)
    local titles = {
        tp_coords = '📍 Téléportation Coordonnées',
        tp_self = '📍 Téléportation (Self)',
        tp_goto = '🚀 Goto Joueur',
        tp_bring = '📥 Bring Joueur',
        tp_return = '↩️ Retour Position',
        tp_marker = '🗺️ Téléportation Marqueur',
        tp_all = '🌐 Téléportation Tous'
    }

    local title = titles[action] or '📍 Téléportation'

    local fields = {
        {name = '👤 Staff', value = staffName, inline = true}
    }

    if targetName and targetName ~= staffName then
        table.insert(fields, {name = '🎯 Cible', value = targetName, inline = true})
    end

    if details then
        if details.coords then
            local coordsText = string.format('X: %.1f, Y: %.1f, Z: %.1f', details.coords.x, details.coords.y, details.coords.z)
            table.insert(fields, {name = '📍 Coordonnées', value = coordsText, inline = false})
        end
        if details.count then
            table.insert(fields, {name = '👥 Joueurs', value = tostring(details.count), inline = true})
        end
    end

    Discord.Send('logs', {
        title = title,
        description = 'Action de téléportation effectuée',
        color = 3447003, -- Bleu
        fields = fields
    })
end

-- Log d'action joueur (heal, revive, freeze, etc.)
function Discord.LogPlayer(action, staffName, targetName, details)
    local titles = {
        player_heal = '💚 Heal Joueur',
        player_revive = '💖 Revive Joueur',
        player_freeze = '🥶 Freeze Joueur',
        player_unfreeze = '🔥 Unfreeze Joueur',
        player_armor = '🛡️ Armure Joueur',
        heal_all = '💚 Heal Tous',
        revive_all = '💖 Revive Tous',
        player_kill = '💀 Kill Joueur',
        player_spectate = '👁️ Spectate Joueur'
    }

    local title = titles[action] or '👤 Action Joueur'

    local fields = {
        {name = '👤 Staff', value = staffName, inline = true}
    }

    if targetName then
        table.insert(fields, {name = '🎯 Cible', value = targetName, inline = true})
    end

    if details and details.count then
        table.insert(fields, {name = '👥 Joueurs affectés', value = tostring(details.count), inline = true})
    end

    Discord.Send('logs', {
        title = title,
        description = 'Action sur joueur effectuée',
        color = 10181046, -- Violet
        fields = fields
    })
end

-- Log de véhicule (spawn, delete, repair)
function Discord.LogVehicle(action, staffName, targetName, details)
    local titles = {
        vehicle_spawn = '🚗 Spawn Véhicule',
        vehicle_delete = '🗑️ Suppression Véhicule',
        vehicle_repair = '🔧 Réparation Véhicule'
    }

    local title = titles[action] or '🚗 Action Véhicule'

    local fields = {
        {name = '👤 Staff', value = staffName, inline = true}
    }

    if targetName then
        table.insert(fields, {name = '🎯 Cible', value = targetName, inline = true})
    end

    if details then
        if details.model then
            table.insert(fields, {name = '🚙 Modèle', value = details.model, inline = true})
        end
    end

    Discord.Send('logs', {
        title = title,
        description = 'Action véhicule effectuée',
        color = 15844367, -- Or
        fields = fields
    })
end

-- Log de noclip/ESP toggle
function Discord.LogAdminMode(action, staffName)
    local titles = {
        noclip_toggle = '👻 Noclip Toggle',
        esp_toggle = '👁️ ESP Toggle'
    }

    local title = titles[action] or '🛠️ Mode Admin'

    Discord.Send('logs', {
        title = title,
        description = 'Mode admin activé/désactivé',
        color = 9807270, -- Gris
        fields = {
            {name = '👤 Staff', value = staffName, inline = true}
        }
    })
end

-- Log d'annonce d'événement (GDT/CVC)
function Discord.LogEventAnnounce(staffName, eventType, time, message, minReactions, sentDiscord, sentIngame)
    local eventTitle = eventType == 'gdt' and '🎮 Annonce GDT' or '⚔️ Annonce CVC'
    local eventColor = eventType == 'gdt' and 3447003 or 15158332 -- Bleu pour GDT, Rouge pour CVC

    local channels = {}
    if sentDiscord then table.insert(channels, 'Discord') end
    if sentIngame then table.insert(channels, 'In-Game') end

    Discord.Send('events', {
        title = eventTitle,
        description = 'Nouvelle annonce d\'événement publiée',
        color = eventColor,
        fields = {
            {name = '👤 Staff', value = staffName, inline = true},
            {name = '📅 Horaire', value = time ~= '' and time or 'Non spécifié', inline = true},
            {name = '✅ Réactions min', value = tostring(minReactions), inline = true},
            {name = '📢 Canaux', value = table.concat(channels, ', '), inline = true},
            {name = '📝 Message', value = #message > 500 and (message:sub(1, 500) .. '...') or message, inline = false}
        }
    })
end

-- Log de mort (PVP, suicide, environnement)
function Discord.LogDeath(killerData, victimData, weapon, deathType)
    if not isEnabled() then return end

    local webhookUrl = getWebhook('deaths')
    if not webhookUrl or webhookUrl == '' then return end

    -- Définir le titre et la couleur selon le type de mort
    local title = '💀 Mort'
    local embedColor = 9807270 -- Gris par défaut
    local description = ''

    if deathType == 'death_pvp' and killerData then
        title = '💀 Mort en PVP'
        embedColor = 15158332 -- Rouge
        description = '**' .. (killerData.name or 'Inconnu') .. '** → **' .. (victimData.name or 'Inconnu') .. '**'
    elseif deathType == 'death_suicide' then
        title = '💀 Suicide'
        embedColor = 15105570 -- Orange
        description = '**' .. (victimData.name or 'Inconnu') .. '** s\'est suicidé'
    else
        title = '💀 Mort (' .. (weapon or 'Inconnue') .. ')'
        embedColor = 3447003 -- Bleu
        description = '**' .. (victimData.name or 'Inconnu') .. '** est mort'
    end

    -- Formater les identifiants du tueur (si PVP)
    local killerInfo = ''
    if killerData then
        killerInfo = killerData.name or 'Inconnu'
        killerInfo = killerInfo .. '\n🆔 ' .. tostring(killerData.serverId or '?')
        if killerData.discord then
            killerInfo = killerInfo .. ' • <@' .. killerData.discord .. '>'
        end
        if killerData.fivem then
            killerInfo = killerInfo .. '\n🎮 fivem:' .. killerData.fivem
        end
        if killerData.license then
            killerInfo = killerInfo .. '\n📝 license:' .. killerData.license
        end
        if killerData.steam then
            killerInfo = killerInfo .. '\n🎮 steam:' .. killerData.steam
        end
        if killerData.xbl then
            killerInfo = killerInfo .. '\n🎮 xbl:' .. killerData.xbl
        end
    end

    -- Formater les identifiants de la victime
    local victimInfo = victimData.name or 'Inconnu'
    victimInfo = victimInfo .. '\n🆔 ' .. tostring(victimData.serverId or '?')
    if victimData.discord then
        victimInfo = victimInfo .. ' • <@' .. victimData.discord .. '>'
    end
    if victimData.fivem then
        victimInfo = victimInfo .. '\n🎮 fivem:' .. victimData.fivem
    end
    if victimData.license then
        victimInfo = victimInfo .. '\n📝 license:' .. victimData.license
    end
    if victimData.steam then
        victimInfo = victimInfo .. '\n🎮 steam:' .. victimData.steam
    end
    if victimData.xbl then
        victimInfo = victimInfo .. '\n🎮 xbl:' .. victimData.xbl
    end

    local embed = {
        title = title,
        description = description,
        color = embedColor,
        fields = {},
        footer = {
            text = Config.ServerName .. ' • Death Log',
            icon_url = Config.Discord.BotAvatar or nil
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    -- Ajouter le champ tueur si PVP
    if killerData then
        table.insert(embed.fields, {
            name = '🔫 Tueur',
            value = killerInfo,
            inline = true
        })
    end

    -- Ajouter le champ victime
    table.insert(embed.fields, {
        name = '👤 Joueur',
        value = victimInfo,
        inline = true
    })

    -- Ajouter la cause de mort
    table.insert(embed.fields, {
        name = '⚔️ Cause',
        value = weapon or 'Inconnue',
        inline = true
    })

    -- Ajouter l'heure
    table.insert(embed.fields, {
        name = '🕐 Heure',
        value = os.date('%d/%m/%Y à %H:%M:%S'),
        inline = true
    })

    local payload = {
        username = Config.Discord.BotName or 'Panel Fight League',
        avatar_url = Config.Discord.BotAvatar or nil,
        embeds = {embed}
    }

    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        if Config.Debug then
            if statusCode ~= 200 and statusCode ~= 204 then
                print('^1[DISCORD]^0 Erreur envoi death log: ' .. tostring(statusCode))
            else
                print('^2[DISCORD]^0 Death log envoye avec succes')
            end
        end
    end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

-- Log de changement de grade staff
function Discord.LogStaffRole(action, staffName, targetName, targetIdentifier, oldGrade, newGrade)
    local oldLevel = ({user=0, staff=1, organisateur=2, responsable=3, admin=4, owner=5})[string.lower(oldGrade or 'user')] or 0
    local newLevel = ({user=0, staff=1, organisateur=2, responsable=3, admin=4, owner=5})[string.lower(newGrade or 'user')] or 0

    local title, embedColor, description

    if newLevel > oldLevel then
        -- Promotion
        title = '⬆️ Promotion Staff'
        embedColor = 3066993 -- Vert
        description = '**' .. targetName .. '** a été promu'
    elseif newLevel < oldLevel then
        -- Rétrogradation
        title = '⬇️ Rétrogradation Staff'
        embedColor = 15158332 -- Rouge
        description = '**' .. targetName .. '** a été rétrogradé'
    else
        -- Changement (même niveau, ne devrait pas arriver)
        title = '🔄 Modification Grade'
        embedColor = 15105570 -- Orange
        description = 'Le grade de **' .. targetName .. '** a été modifié'
    end

    local gradeLabels = {
        user = 'Utilisateur',
        staff = 'Staff',
        organisateur = 'Organisateur',
        responsable = 'Responsable',
        admin = 'Admin',
        owner = 'Owner'
    }

    Discord.Send('staffRoles', {
        title = title,
        description = description,
        color = embedColor,
        fields = {
            {name = '👮 Effectué par', value = staffName, inline = true},
            {name = '👤 Joueur', value = targetName, inline = true},
            {name = '🆔 Identifier', value = '`' .. (targetIdentifier or 'Inconnu') .. '`', inline = false},
            {name = '📉 Ancien grade', value = gradeLabels[string.lower(oldGrade or 'user')] or oldGrade, inline = true},
            {name = '📈 Nouveau grade', value = gradeLabels[string.lower(newGrade or 'user')] or newGrade, inline = true}
        }
    })
end

-- Log de deconnexion joueur
function Discord.LogDisconnect(playerData, reason, coords)
    if not isEnabled() then return end

    local webhookUrl = getWebhook('deco')
    if not webhookUrl or webhookUrl == '' then return end

    -- Formater les identifiants du joueur
    local playerInfo = playerData.name or 'Inconnu'
    playerInfo = playerInfo .. '\n:id: **ID Serveur:** ' .. tostring(playerData.serverId or '?')

    if playerData.discord then
        playerInfo = playerInfo .. '\n:speech_balloon: **Discord:** <@' .. playerData.discord .. '>'
    end
    if playerData.fivem then
        playerInfo = playerInfo .. '\n:video_game: **FiveM:** ' .. playerData.fivem
    end
    if playerData.license then
        playerInfo = playerInfo .. '\n:page_facing_up: **License:** `' .. playerData.license .. '`'
    end
    if playerData.steam then
        playerInfo = playerInfo .. '\n:joystick: **Steam:** `' .. playerData.steam .. '`'
    end

    -- Formater les coordonnees
    local coordsText = 'Inconnues'
    if coords then
        coordsText = string.format('X: %.1f, Y: %.1f, Z: %.1f', coords.x, coords.y, coords.z)
    end

    local embed = {
        title = ':door: Deconnexion Joueur',
        description = '**' .. (playerData.name or 'Inconnu') .. '** s\'est deconnecte du serveur',
        color = 15105570, -- Orange
        fields = {
            {
                name = ':bust_in_silhouette: Joueur',
                value = playerInfo,
                inline = false
            },
            {
                name = ':round_pushpin: Derniere Position',
                value = coordsText,
                inline = true
            },
            {
                name = ':scroll: Raison',
                value = reason or 'Deconnexion normale',
                inline = true
            },
            {
                name = ':clock1: Heure',
                value = os.date('%d/%m/%Y a %H:%M:%S'),
                inline = true
            }
        },
        footer = {
            text = Config.ServerName .. ' - Disconnect Log',
            icon_url = Config.Discord.BotAvatar or nil
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    local payload = {
        username = Config.Discord.BotName or 'Panel Fight League',
        avatar_url = Config.Discord.BotAvatar or nil,
        embeds = {embed}
    }

    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        if Config.Debug then
            if statusCode ~= 200 and statusCode ~= 204 then
                print('^1[DISCORD]^0 Erreur envoi disconnect log: ' .. tostring(statusCode))
            else
                print('^2[DISCORD]^0 Disconnect log envoye avec succes')
            end
        end
    end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

-- Export global
_G.Discord = Discord
