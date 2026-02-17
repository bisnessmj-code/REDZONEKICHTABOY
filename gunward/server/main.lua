-- Client notification relay
RegisterNetEvent('gunward:client:notify')

-- Exports
exports('IsPlayerInGunward', function(playerId)
    return Gunward.Server.Teams.IsPlayerInGunward(playerId)
end)

exports('GetPlayerTeam', function(playerId)
    return Gunward.Server.Teams.GetPlayerTeam(playerId)
end)

exports('GetTeamPlayers', function(teamName)
    return Gunward.Server.Teams.GetTeamPlayers(teamName)
end)

exports('GetGunwardPlayerCount', function()
    return Gunward.Server.Teams.GetTotalPlayers()
end)

exports('RemovePlayerFromGunward', function(playerId)
    local removed = Gunward.Server.Teams.RemovePlayer(playerId)
    if removed then
        SetPlayerRoutingBucket(playerId, 0)
        TriggerClientEvent('gunward:client:removedFromGunward', playerId)
        TriggerClientEvent('gunward:client:returnToLobby', playerId)
    end
    return removed
end)

CreateThread(function()
    Gunward.Debug('Server initialized')
    Gunward.Debug('Teams:', json.encode(Config.TeamOrder))
    Gunward.Debug('Bucket:', Config.Bucket)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Gunward.Server.Teams.ResetAll()
    Gunward.Debug('Resource stopping, all players cleaned up')
end)
