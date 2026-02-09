--[[
    Définition des Commandes - Panel Admin Fight League
    Commandes chat et raccourcis disponibles
]]

Commands = {}

-- ══════════════════════════════════════════════════════════════
-- COMMANDES PRINCIPALES
-- ══════════════════════════════════════════════════════════════

Commands.List = {
    -- Commande principale pour ouvrir le panel
    panel = {
        name = 'panel',
        aliases = {'admin', 'staffpanel'},
        description = 'Ouvrir le panel d\'administration',
        permission = 'panel.open',
        usage = '/panel',
        handler = 'openPanel'
    },

    -- Commandes de modération rapide
    warn = {
        name = 'warn',
        aliases = {},
        description = 'Avertir un joueur',
        permission = 'sanction.warn',
        usage = '/warn [id] [raison]',
        handler = 'warnPlayer',
        args = {
            {name = 'id', type = 'number', required = true},
            {name = 'reason', type = 'string', required = true}
        }
    },

    kick = {
        name = 'kick',
        aliases = {},
        description = 'Expulser un joueur',
        permission = 'sanction.kick',
        usage = '/kick [id] [raison]',
        handler = 'kickPlayer',
        args = {
            {name = 'id', type = 'number', required = true},
            {name = 'reason', type = 'string', required = true}
        }
    },

    ban = {
        name = 'ban',
        aliases = {},
        description = 'Bannir un joueur',
        permission = 'sanction.ban.temp',
        usage = '/ban [id] [durée en heures] [raison]',
        handler = 'banPlayer',
        args = {
            {name = 'id', type = 'number', required = true},
            {name = 'duration', type = 'number', required = true},
            {name = 'reason', type = 'string', required = true}
        }
    },

    unban = {
        name = 'unban',
        aliases = {},
        description = 'Débannir un joueur',
        permission = 'sanction.unban',
        usage = '/unban [identifier]',
        handler = 'unbanPlayer',
        args = {
            {name = 'identifier', type = 'string', required = true}
        }
    },

    -- Commandes de téléportation
    tp = {
        name = 'tp',
        aliases = {'teleport'},
        description = 'Se téléporter aux coordonnées',
        permission = 'teleport.self',
        usage = '/tp [x] [y] [z]',
        handler = 'teleportCoords',
        args = {
            {name = 'x', type = 'number', required = true},
            {name = 'y', type = 'number', required = true},
            {name = 'z', type = 'number', required = true}
        }
    },

    tpm = {
        name = 'tpm',
        aliases = {},
        description = 'Téléporter au marqueur sur la carte',
        permission = 'teleport.self',
        usage = '/tpm',
        handler = 'teleportMarker'
    },

    gotoPlayer = {
        name = 'goto',
        aliases = {'tpto'},
        description = 'Aller vers un joueur',
        permission = 'teleport.goto',
        usage = '/goto [id]',
        handler = 'gotoPlayer',
        args = {
            {name = 'id', type = 'number', required = true}
        }
    },

    bring = {
        name = 'bring',
        aliases = {'tphere'},
        description = 'Amener un joueur à soi',
        permission = 'teleport.bring',
        usage = '/bring [id]',
        handler = 'bringPlayer',
        args = {
            {name = 'id', type = 'number', required = true}
        }
    },

    -- Commandes de véhicules
    car = {
        name = 'car',
        aliases = {'vehicle', 'veh'},
        description = 'Spawn un véhicule',
        permission = 'vehicle.spawn',
        usage = '/car [modèle]',
        handler = 'spawnVehicle',
        args = {
            {name = 'model', type = 'string', required = true}
        }
    },

    dv = {
        name = 'dv',
        aliases = {'deletevehicle'},
        description = 'Supprimer le véhicule actuel',
        permission = 'vehicle.delete',
        usage = '/dv',
        handler = 'deleteVehicle'
    },

    repair = {
        name = 'repair',
        aliases = {'fix'},
        description = 'Réparer le véhicule actuel',
        permission = 'vehicle.repair',
        usage = '/repair',
        handler = 'repairVehicle'
    },

    -- Commandes joueur
    revive = {
        name = 'revive',
        aliases = {},
        description = 'Réanimer un joueur',
        permission = 'player.revive',
        usage = '/revive [id]',
        handler = 'revivePlayer',
        args = {
            {name = 'id', type = 'number', required = false}
        }
    },

    heal = {
        name = 'heal',
        aliases = {},
        description = 'Soigner un joueur',
        permission = 'player.heal',
        usage = '/heal [id]',
        handler = 'healPlayer',
        args = {
            {name = 'id', type = 'number', required = false}
        }
    },

    freeze = {
        name = 'freeze',
        aliases = {},
        description = 'Freeze/Unfreeze un joueur',
        permission = 'player.freeze',
        usage = '/freeze [id]',
        handler = 'freezePlayer',
        args = {
            {name = 'id', type = 'number', required = true}
        }
    },

    spectate = {
        name = 'spectate',
        aliases = {'spec'},
        description = 'Spectate un joueur',
        permission = 'player.spectate',
        usage = '/spectate [id]',
        handler = 'spectatePlayer',
        args = {
            {name = 'id', type = 'number', required = true}
        }
    },

    -- Commandes d'annonce
    announce = {
        name = 'announce',
        aliases = {'ann'},
        description = 'Envoyer une annonce',
        permission = 'announce.send',
        usage = '/announce [message]',
        handler = 'sendAnnouncement',
        args = {
            {name = 'message', type = 'string', required = true}
        }
    }
}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ══════════════════════════════════════════════════════════════

-- Obtenir une commande par son nom ou alias
function Commands.Get(name)
    name = string.lower(name)

    for cmdName, cmd in pairs(Commands.List) do
        if cmdName == name then
            return cmd
        end

        for _, alias in ipairs(cmd.aliases or {}) do
            if alias == name then
                return cmd
            end
        end
    end

    return nil
end

-- Obtenir toutes les commandes disponibles pour un grade
function Commands.GetAvailable(grade)
    local available = {}

    for cmdName, cmd in pairs(Commands.List) do
        if Permissions.HasAbility(grade, cmd.permission) then
            table.insert(available, cmd)
        end
    end

    return available
end

-- Parser les arguments d'une commande
function Commands.ParseArgs(cmd, rawArgs)
    if not cmd.args then return {} end

    local parsed = {}
    local argIndex = 1

    for i, argDef in ipairs(cmd.args) do
        local value = rawArgs[argIndex]

        if argDef.required and not value then
            return nil, 'Argument manquant: ' .. argDef.name
        end

        if value then
            if argDef.type == 'number' then
                value = tonumber(value)
                if not value then
                    return nil, 'Argument invalide: ' .. argDef.name .. ' doit être un nombre'
                end
            end

            parsed[argDef.name] = value
            argIndex = argIndex + 1
        end
    end

    -- Combiner les arguments restants pour le dernier argument string
    if cmd.args[#cmd.args] and cmd.args[#cmd.args].type == 'string' then
        local lastArgName = cmd.args[#cmd.args].name
        local remaining = {}

        for i = argIndex - 1 + #cmd.args, #rawArgs do
            if rawArgs[i] then
                table.insert(remaining, rawArgs[i])
            end
        end

        if #remaining > 0 then
            parsed[lastArgName] = table.concat(remaining, ' ')
        end
    end

    return parsed
end
