Gunward.Server.Commands = {}

local gameStarted = false

-- Helper to register commands from config
local function RegisterGunwardCommand(cmdData)
    if cmdData.side ~= 'server' then return end

    RegisterCommand(cmdData.command, function(source, args)
        if not Gunward.Server.Utils.HasPermission(source, cmdData.roles) then
            TriggerClientEvent('gunward:client:notify', source, Lang('cmd_no_permission'), 'error')
            return
        end

        local handler = Gunward.Server.Commands[cmdData.command]
        if handler then
            handler(source, args)
        end
    end, false)
end

-- Command handlers
Gunward.Server.Commands['gw_kick'] = function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then return end

    if not Gunward.Server.Teams.IsPlayerInGunward(targetId) then
        TriggerClientEvent('gunward:client:notify', source, Lang('cmd_kick_not_found'), 'error')
        return
    end

    Gunward.Server.Teams.RemovePlayer(targetId)
    Gunward.Server.Spawn.SetBucket(targetId, 0)
    TriggerClientEvent('gunward:client:removedFromGunward', targetId)
    TriggerClientEvent('gunward:client:returnToLobby', targetId)
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_kick', Gunward.Server.Utils.GetPlayerName(targetId)), 'success')
end

Gunward.Server.Commands['gw_kickall'] = function(source)
    Gunward.Server.Teams.ResetAll()
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_kickall'), 'success')
end

Gunward.Server.Commands['gw_start'] = function(source)
    if gameStarted then
        TriggerClientEvent('gunward:client:notify', source, Lang('game_already_started'), 'error')
        return
    end
    gameStarted = true
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_start'), 'success')
    Gunward.Debug('Game started by', source)
end

Gunward.Server.Commands['gw_stop'] = function(source)
    if not gameStarted then
        TriggerClientEvent('gunward:client:notify', source, Lang('game_not_started'), 'error')
        return
    end
    gameStarted = false
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_stop'), 'success')
    Gunward.Debug('Game stopped by', source)
end

Gunward.Server.Commands['gw_move'] = function(source, args)
    local targetId = tonumber(args[1])
    local teamName = args[2] and string.upper(args[2])
    if not targetId or not teamName then return end

    local success, err = Gunward.Server.Teams.MovePlayer(targetId, teamName)
    if not success then
        TriggerClientEvent('gunward:client:notify', source, Lang(err), 'error')
        return
    end

    TriggerClientEvent('gunward:client:teamJoined', targetId, teamName)
    TriggerClientEvent('gunward:client:spawnAtTeam', targetId, teamName)
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_move', Gunward.Server.Utils.GetPlayerName(targetId), teamName), 'success')
end

Gunward.Server.Commands['gw_reset'] = function(source)
    gameStarted = false
    Gunward.Server.Teams.ResetAll()
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_reset'), 'success')
end

Gunward.Server.Commands['gw_debug'] = function(source)
    Config.Debug = not Config.Debug
    local msg = Config.Debug and Lang('cmd_debug_on') or Lang('cmd_debug_off')
    TriggerClientEvent('gunward:client:notify', source, msg, 'info')
end

Gunward.Server.Commands['gw_tp'] = function(source, args)
    local teamName = args[1] and string.upper(args[1])
    if not teamName or not Gunward.IsValidTeam(teamName) then
        TriggerClientEvent('gunward:client:notify', source, Lang('team_invalid'), 'error')
        return
    end

    Gunward.Server.Spawn.SetBucket(source, Config.Bucket)
    TriggerClientEvent('gunward:client:spawnAtTeam', source, teamName)
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_tp', teamName), 'success')
end

Gunward.Server.Commands['gw_setteam'] = function(source, args)
    local targetId = tonumber(args[1])
    local teamName = args[2] and string.upper(args[2])
    if not targetId or not teamName then return end

    -- Remove from current team if in one
    if Gunward.Server.Teams.IsPlayerInGunward(targetId) then
        Gunward.Server.Teams.RemovePlayer(targetId)
        Gunward.Server.Spawn.SetBucket(targetId, 0)
    end

    local success, err = Gunward.Server.Teams.AddPlayer(targetId, teamName)
    if not success then
        TriggerClientEvent('gunward:client:notify', source, Lang(err), 'error')
        return
    end

    Gunward.Server.Spawn.SetBucket(targetId, Config.Bucket)
    TriggerClientEvent('gunward:client:teamJoined', targetId, teamName)
    TriggerClientEvent('gunward:client:spawnAtTeam', targetId, teamName)
    TriggerClientEvent('gunward:client:notify', source, Lang('cmd_setteam', Gunward.Server.Utils.GetPlayerName(targetId), teamName), 'success')
end

-- Register all server commands from config
CreateThread(function()
    for _, cmdData in ipairs(Config.Commands) do
        if cmdData.side == 'server' then
            RegisterGunwardCommand(cmdData)
        end
    end
    Gunward.Debug('Server commands registered')
end)

-- Exports
function Gunward.Server.Commands.IsGameStarted()
    return gameStarted
end
