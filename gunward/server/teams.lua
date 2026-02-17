Gunward.Server.Teams = {}

local teamPlayers = {}
local playerTeams = {}

-- Initialize team player lists
for teamName, _ in pairs(Config.Teams) do
    teamPlayers[teamName] = {}
end

function Gunward.Server.Teams.GetPlayerTeam(source)
    return playerTeams[source]
end

function Gunward.Server.Teams.GetTeamPlayers(teamName)
    return teamPlayers[teamName] or {}
end

function Gunward.Server.Teams.GetTeamCount(teamName)
    local count = 0
    if teamPlayers[teamName] then
        for _ in pairs(teamPlayers[teamName]) do
            count = count + 1
        end
    end
    return count
end

function Gunward.Server.Teams.GetAllCounts()
    local counts = {}
    for teamName, _ in pairs(Config.Teams) do
        counts[teamName] = Gunward.Server.Teams.GetTeamCount(teamName)
    end
    return counts
end

function Gunward.Server.Teams.GetTotalPlayers()
    local total = 0
    for teamName, _ in pairs(Config.Teams) do
        total = total + Gunward.Server.Teams.GetTeamCount(teamName)
    end
    return total
end

function Gunward.Server.Teams.IsPlayerInGunward(source)
    return playerTeams[source] ~= nil
end

function Gunward.Server.Teams.AddPlayer(source, teamName)
    if not Gunward.IsValidTeam(teamName) then return false, 'team_invalid' end
    if playerTeams[source] then return false, 'team_already_in' end

    local count = Gunward.Server.Teams.GetTeamCount(teamName)
    if count >= Config.Teams[teamName].maxPlayers then return false, 'team_full' end

    teamPlayers[teamName][source] = true
    playerTeams[source] = teamName

    Gunward.Debug('Player', source, 'joined team', teamName)
    return true
end

function Gunward.Server.Teams.RemovePlayer(source)
    local team = playerTeams[source]
    if not team then return false end

    if teamPlayers[team] then
        teamPlayers[team][source] = nil
    end
    playerTeams[source] = nil

    Gunward.Debug('Player', source, 'removed from team', team)
    return true, team
end

function Gunward.Server.Teams.MovePlayer(source, newTeam)
    if not Gunward.IsValidTeam(newTeam) then return false, 'team_invalid' end

    local count = Gunward.Server.Teams.GetTeamCount(newTeam)
    if count >= Config.Teams[newTeam].maxPlayers then return false, 'team_full' end

    Gunward.Server.Teams.RemovePlayer(source)
    return Gunward.Server.Teams.AddPlayer(source, newTeam)
end

function Gunward.Server.Teams.ResetAll()
    for teamName, _ in pairs(Config.Teams) do
        for src, _ in pairs(teamPlayers[teamName]) do
            TriggerClientEvent('gunward:client:removedFromGunward', src)
            TriggerClientEvent('gunward:client:returnToLobby', src)
            SetPlayerRoutingBucket(src, 0)
        end
        teamPlayers[teamName] = {}
    end
    playerTeams = {}
    Gunward.Debug('All teams reset')
end

-- Server callback for team counts
ESX.RegisterServerCallback('gunward:server:getTeamCounts', function(source, cb)
    cb(Gunward.Server.Teams.GetAllCounts())
end)

-- Join team event
RegisterNetEvent('gunward:server:joinTeam', function(teamName)
    local source = source
    local success, err = Gunward.Server.Teams.AddPlayer(source, teamName)

    if not success then
        TriggerClientEvent('gunward:client:notify', source, Lang(err), 'error')
        return
    end

    -- Set routing bucket
    SetPlayerRoutingBucket(source, Config.Bucket)

    -- Notify client
    TriggerClientEvent('gunward:client:teamJoined', source, teamName)
    TriggerClientEvent('gunward:client:spawnAtTeam', source, teamName)

    -- Update stats
    Gunward.Server.Database.EnsurePlayer(source)
end)

-- Leave gunward event
RegisterNetEvent('gunward:server:leaveGunward', function()
    local source = source
    local removed, oldTeam = Gunward.Server.Teams.RemovePlayer(source)

    if not removed then
        TriggerClientEvent('gunward:client:notify', source, Lang('cmd_leave_not_in'), 'error')
        return
    end

    SetPlayerRoutingBucket(source, 0)
    TriggerClientEvent('gunward:client:removedFromGunward', source)
    TriggerClientEvent('gunward:client:returnToLobby', source)
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_leave'), 'success')
end)
