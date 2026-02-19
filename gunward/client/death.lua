-- ============================================================
-- DEATH SYSTEM - Respawn + Kill Feed
-- ============================================================

-- Kill feed: relay to NUI
RegisterNetEvent('gunward:client:killfeed', function(data)
    SendNUIMessage({
        action = 'addKillFeed',
        killerName = data.killerName,
        killerId = data.killerId,
        victimName = data.victimName,
        victimId = data.victimId,
    })
end)

-- Death: instant respawn at team spawn
RegisterNetEvent('gunward:client:onDeath', function(attackerId, teamName)
    local ped = PlayerPedId()

    -- Get team spawn coords
    local teamData = Config.Teams[teamName]
    if not teamData then return end
    local spawn = teamData.spawn

    -- Quick fade out
    DoScreenFadeOut(300)
    Wait(300)

    -- Resurrect at team spawn
    local playerId = PlayerId()
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w, true, false)

    -- Re-get ped after resurrect
    ped = PlayerPedId()

    -- Remove all weapons client-side
    RemoveAllPedWeapons(ped, true)

    -- Restore full health + armor
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)

    -- Clear any ragdoll/tasks
    if not IsPedInAnyVehicle(ped, false) then
        ClearPedTasksImmediately(ped)
    end

    Wait(100)
    DoScreenFadeIn(300)

    Gunward.Debug('Respawned at team spawn:', teamName)
end)
