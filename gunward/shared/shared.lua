Gunward = Gunward or {}
Gunward.Client = Gunward.Client or {}
Gunward.Server = Gunward.Server or {}

function Gunward.Debug(...)
    if Config.Debug then
        print('[GUNWARD:DEBUG]', ...)
    end
end

function Gunward.GetTeamData(teamName)
    return Config.Teams[teamName]
end

function Gunward.IsValidTeam(teamName)
    return Config.Teams[teamName] ~= nil
end

function Gunward.GetTeamColor(teamName)
    local team = Config.Teams[teamName]
    if not team then return {r = 255, g = 255, b = 255} end
    return team.color
end
