Gunward.Client.Spawn = {}

function Gunward.Client.Spawn.ToTeam(teamName)
    local team = Config.Teams[teamName]
    if not team then return end

    local coords = team.spawn
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(500)

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)
    PlaceObjectOnGroundProperly(ped)

    Wait(200)
    DoScreenFadeIn(500)

    Gunward.Debug('Spawned at team:', teamName)
end

function Gunward.Client.Spawn.ReturnToLobby()
    local coords = Config.ReturnCoords
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(500)

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)

    Wait(200)
    DoScreenFadeIn(500)

    Gunward.Debug('Returned to lobby')
end

RegisterNetEvent('gunward:client:spawnAtTeam', function(teamName)
    Gunward.Client.Spawn.ToTeam(teamName)
end)

RegisterNetEvent('gunward:client:returnToLobby', function()
    Gunward.Client.Spawn.ReturnToLobby()
end)
