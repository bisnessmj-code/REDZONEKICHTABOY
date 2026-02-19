Gunward.Server.Spawn = {}

-- Central bucket change function - auto cleanup when leaving gunward bucket
function Gunward.Server.Spawn.SetBucket(source, bucket)
    local currentBucket = GetPlayerRoutingBucket(source)
    local newBucket = bucket or Config.Bucket

    -- If leaving gunward bucket -> cleanup weapons + vehicle
    if currentBucket == Config.Bucket and newBucket ~= Config.Bucket then
        Gunward.Server.VehicleShop.DeletePlayerVehicle(source)
        Gunward.Server.WeaponShop.CleanupPlayerWeapons(source)
        TriggerClientEvent('gunward:client:removeWeapons', source)
        Gunward.Debug('Player', source, 'leaving gunward bucket, cleanup done')
    end

    SetPlayerRoutingBucket(source, newBucket)
    Gunward.Debug('Player', source, 'set to bucket', newBucket)
end

function Gunward.Server.Spawn.ReturnToLobby(source)
    Gunward.Server.Spawn.SetBucket(source, 0)
    TriggerClientEvent('gunward:client:returnToLobby', source)
    Gunward.Debug('Player', source, 'returned to lobby bucket')
end

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    if Gunward.Server.Teams.IsPlayerInGunward(source) then
        Gunward.Server.VehicleShop.DeletePlayerVehicle(source)
        Gunward.Server.WeaponShop.CleanupPlayerWeapons(source)
        Gunward.Server.Teams.RemovePlayer(source)
        Gunward.Debug('Player', source, 'disconnected, cleaned up from Gunward')
    end
end)
