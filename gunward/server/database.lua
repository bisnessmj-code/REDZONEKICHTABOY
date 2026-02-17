Gunward.Server.Database = {}

function Gunward.Server.Database.EnsurePlayer(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.insert('INSERT IGNORE INTO gunward_stats (identifier) VALUES (?)', {identifier})
end

function Gunward.Server.Database.GetStats(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local identifier = xPlayer.getIdentifier()
    MySQL.single('SELECT * FROM gunward_stats WHERE identifier = ?', {identifier}, function(result)
        cb(result)
    end)
end

function Gunward.Server.Database.AddKill(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET kills = kills + 1 WHERE identifier = ?', {identifier})
end

function Gunward.Server.Database.AddDeath(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET deaths = deaths + 1 WHERE identifier = ?', {identifier})
end

function Gunward.Server.Database.AddWin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET wins = wins + 1 WHERE identifier = ?', {identifier})
end

function Gunward.Server.Database.IncrementGamesPlayed(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET games_played = games_played + 1, last_played = NOW() WHERE identifier = ?', {identifier})
end

function Gunward.Server.Database.GetLeaderboard(limit, cb)
    limit = limit or 10
    MySQL.query('SELECT * FROM gunward_stats ORDER BY kills DESC LIMIT ?', {limit}, function(results)
        cb(results or {})
    end)
end
