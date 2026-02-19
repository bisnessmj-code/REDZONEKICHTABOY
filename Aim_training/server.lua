ESX = exports['es_extended']:getSharedObject()

-- Table pour gérer les instances (routing buckets)
local nextRoutingBucket = 1000 -- Commence à 1000 pour éviter les conflits
local playersInInstance = {} -- Table pour tracker les joueurs en instance

-- Événement pour demander une instance
RegisterNetEvent('aim_training:requestInstance')
AddEventHandler('aim_training:requestInstance', function()
    local _source = source

    -- Vérifier si le joueur est déjà en instance
    if playersInInstance[_source] then
        TriggerClientEvent('esx:showNotification', _source, '~r~Vous êtes déjà en partie!')
        return
    end

    -- Créer une instance unique pour ce joueur
    local routingBucket = nextRoutingBucket
    nextRoutingBucket = nextRoutingBucket + 1

    -- Mettre le joueur dans le routing bucket
    SetPlayerRoutingBucket(_source, routingBucket)
    playersInInstance[_source] = routingBucket

    print('^2[Aim Training]^0 Joueur ' .. GetPlayerName(_source) .. ' mis dans l\'instance ' .. routingBucket)

    -- Notifier le client pour démarrer la partie
    TriggerClientEvent('aim_training:startGameInInstance', _source)
end)

-- Événement pour sortir de l'instance
RegisterNetEvent('aim_training:exitInstance')
AddEventHandler('aim_training:exitInstance', function()
    local _source = source

    if playersInInstance[_source] then
        -- Remettre le joueur dans le monde normal (bucket 0)
        SetPlayerRoutingBucket(_source, 0)
        print('^2[Aim Training]^0 Joueur ' .. GetPlayerName(_source) .. ' sorti de l\'instance ' .. playersInInstance[_source])
        playersInInstance[_source] = nil
    end
end)

-- Événement quand un joueur complète la partie
RegisterNetEvent('aim_training:completeGame')
AddEventHandler('aim_training:completeGame', function(kills)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        -- Donner la récompense
        xPlayer.addAccountMoney('bank', Config.Reward)

        -- Mettre à jour le classement dans la base de données
        local identifier = xPlayer.identifier
        local name = GetPlayerName(_source)

        MySQL.query('SELECT kills FROM aim_training_leaderboard WHERE identifier = ?', {identifier}, function(result)
            result = result or {}
            local currentKills = result[1] and result[1].kills or nil

            if not currentKills or kills > currentKills then
                MySQL.execute('INSERT INTO aim_training_leaderboard (identifier, name, kills) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE kills = ?, name = ?', {
                    identifier, name, kills, kills, name
                })
            end
        end)

        TriggerClientEvent('esx:showNotification', _source, '~g~Vous avez reçu $' .. Config.Reward .. ' dans votre banque!')

        -- Sortir de l'instance
        if playersInInstance[_source] then
            SetPlayerRoutingBucket(_source, 0)
            print('^2[Aim Training]^0 Joueur ' .. GetPlayerName(_source) .. ' sorti de l\'instance ' .. playersInInstance[_source])
            playersInInstance[_source] = nil
        end
    end
end)

-- Callback pour obtenir le classement
ESX.RegisterServerCallback('aim_training:getLeaderboard', function(source, cb)
    MySQL.query('SELECT name, kills FROM aim_training_leaderboard ORDER BY kills DESC LIMIT 10', {}, function(result)
        cb(result)
    end)
end)

-- Nettoyer les instances quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local _source = source

    if playersInInstance[_source] then
        print('^2[Aim Training]^0 Joueur déconnecté en instance, nettoyage du bucket ' .. playersInInstance[_source])
        playersInInstance[_source] = nil
    end
end)
