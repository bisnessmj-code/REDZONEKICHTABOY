Gunward.Server.Spawn = {}

function Gunward.Server.Spawn.SetBucket(source, bucket)
    SetPlayerRoutingBucket(source, bucket or Config.Bucket)
    Gunward.Debug('Player', source, 'set to bucket', bucket or Config.Bucket)
end

function Gunward.Server.Spawn.ReturnToLobby(source)
    SetPlayerRoutingBucket(source, 0)
    TriggerClientEvent('gunward:client:returnToLobby', source)
    Gunward.Debug('Player', source, 'returned to lobby bucket')
end

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    if Gunward.Server.Teams.IsPlayerInGunward(source) then
        Gunward.Server.Teams.RemovePlayer(source)
        Gunward.Debug('Player', source, 'disconnected, cleaned up from Gunward')
    end
end)
