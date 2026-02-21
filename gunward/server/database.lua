Gunward.Server.Database = {}

-- ── ENSURE PLAYER ──────────────────────────────────────────────────────────
-- Creates the row if it doesn't exist and keeps the FiveM name in sync.
function Gunward.Server.Database.EnsurePlayer(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local name       = GetPlayerName(source) or 'Unknown'

    MySQL.insert(
        'INSERT INTO gunward_stats (identifier, name) VALUES (?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name)',
        { identifier, name }
    )
end

-- ── GET STATS (single player) ───────────────────────────────────────────────
function Gunward.Server.Database.GetStats(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local identifier = xPlayer.getIdentifier()
    MySQL.single(
        'SELECT *, ROUND(kills / GREATEST(deaths, 1), 2) AS kd FROM gunward_stats WHERE identifier = ?',
        { identifier },
        function(result) cb(result) end
    )
end

-- ── ADD KILL ────────────────────────────────────────────────────────────────
function Gunward.Server.Database.AddKill(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    -- Update kills + add $100 kill reward in a single query
    MySQL.update(
        'UPDATE gunward_stats SET kills = kills + 1, bank = bank + 100 WHERE identifier = ?',
        { identifier }
    )
end

-- ── ADD DEATH ───────────────────────────────────────────────────────────────
function Gunward.Server.Database.AddDeath(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET deaths = deaths + 1 WHERE identifier = ?', { identifier })
end

-- ── ADD WIN ─────────────────────────────────────────────────────────────────
function Gunward.Server.Database.AddWin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET wins = wins + 1 WHERE identifier = ?', { identifier })
end

-- ── GAMES PLAYED ────────────────────────────────────────────────────────────
function Gunward.Server.Database.IncrementGamesPlayed(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update(
        'UPDATE gunward_stats SET games_played = games_played + 1, last_played = NOW() WHERE identifier = ?',
        { identifier }
    )
end

-- ── BANK ────────────────────────────────────────────────────────────────────
function Gunward.Server.Database.GetBank(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(0) end

    local identifier = xPlayer.getIdentifier()
    MySQL.single(
        'SELECT bank FROM gunward_stats WHERE identifier = ?',
        { identifier },
        function(result) cb(result and result.bank or 0) end
    )
end

function Gunward.Server.Database.AddBank(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE gunward_stats SET bank = bank + ? WHERE identifier = ?', { amount, identifier })
end

function Gunward.Server.Database.RemoveBank(source, amount, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    local identifier = xPlayer.getIdentifier()
    MySQL.single(
        'SELECT bank FROM gunward_stats WHERE identifier = ?',
        { identifier },
        function(result)
            if not result or result.bank < amount then cb(false) return end
            MySQL.update(
                'UPDATE gunward_stats SET bank = bank - ? WHERE identifier = ?',
                { amount, identifier }
            )
            cb(true)
        end
    )
end

-- ── SERVER CALLBACK: getBank ─────────────────────────────────────────────────
ESX.RegisterServerCallback('gunward:server:getBank', function(source, cb)
    Gunward.Server.Database.GetBank(source, cb)
end)

-- ── SERVER CALLBACK: getShopInfo ─────────────────────────────────────────────
-- Returns balance + isPrivileged so the client can display effective prices.
ESX.RegisterServerCallback('gunward:server:getShopInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local isPrivileged = xPlayer and Config.PrivilegedGroups[xPlayer.getGroup() or ''] and true or false
    Gunward.Server.Database.GetBank(source, function(balance)
        cb({ balance = balance, isPrivileged = isPrivileged })
    end)
end)

-- ── SERVER CALLBACK: getStatsUI ──────────────────────────────────────────────
-- Returns everything the NUI needs in a single async call:
--   leaderboard (top 20 by K/D), myStats, myPosition, teamCounts,
--   serverPlayers, myIdentifier, timerInfo
ESX.RegisterServerCallback('gunward:server:getStatsUI', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    local identifier    = xPlayer.getIdentifier()
    local fivemName     = GetPlayerName(source) or 'Unknown'
    local teamCounts    = Gunward.Server.Teams.GetAllCounts()
    local serverPlayers = #GetPlayers()

    -- KOTH timer info (non-blocking, in-memory)
    local timerInfo = {}
    if Gunward.Server.KOTH and Gunward.Server.KOTH.GetTimerInfo then
        timerInfo = Gunward.Server.KOTH.GetTimerInfo()
    end

    -- Step 1: Sync the FiveM name to DB FIRST, then chain the SELECT.
    -- This fixes the case where the name column was empty for existing rows.
    MySQL.insert(
        'INSERT INTO gunward_stats (identifier, name) VALUES (?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name)',
        { identifier, fivemName },
        function()
            -- Step 2: Now that name is committed, fetch leaderboard sorted by K/D DESC
            MySQL.query([[
                SELECT identifier, name, kills, deaths, bank,
                       ROUND(kills / GREATEST(deaths, 1), 2) AS kd
                FROM gunward_stats
                WHERE kills > 0 OR deaths > 0 OR bank > 0
                ORDER BY kills DESC, kd DESC
                LIMIT 20
            ]], {}, function(leaderboard)
                leaderboard = leaderboard or {}

                -- Find my position and row in the leaderboard
                local myPosition = #leaderboard + 1
                local myRow      = nil
                for i, row in ipairs(leaderboard) do
                    if row.identifier == identifier then
                        -- Guarantee the name is correct even if DB row lagged
                        row.name = fivemName
                        myPosition = i
                        myRow      = row
                        break
                    end
                end

                if myRow then
                    cb({
                        leaderboard   = leaderboard,
                        myStats       = myRow,
                        myPosition    = myPosition,
                        myIdent       = identifier,
                        teamCounts    = teamCounts,
                        serverPlayers = serverPlayers,
                        timerInfo     = timerInfo,
                    })
                else
                    -- Player has no kills/deaths yet — fetch their row separately
                    MySQL.single(
                        [[SELECT identifier, name, kills, deaths, bank,
                                 ROUND(kills / GREATEST(deaths, 1), 2) AS kd
                          FROM gunward_stats WHERE identifier = ?]],
                        { identifier },
                        function(result)
                            if result then result.name = fivemName end
                            cb({
                                leaderboard   = leaderboard,
                                myStats       = result,
                                myPosition    = myPosition,
                                myIdent       = identifier,
                                teamCounts    = teamCounts,
                                serverPlayers = serverPlayers,
                                timerInfo     = timerInfo,
                            })
                        end
                    )
                end
            end)
        end
    )
end)

-- ── PUSH STATS UPDATE AFTER A KILL ───────────────────────────────────────────
-- Called 300 ms after AddKill/AddDeath to let the DB commits settle.
-- Fetches updated rows for both players and broadcasts to all Gunward players.
function Gunward.Server.Database.PushKillStatsUpdate(killerId, victimId)
    local killerPlayer = ESX.GetPlayerFromId(killerId)
    local victimPlayer = ESX.GetPlayerFromId(victimId)
    if not killerPlayer or not victimPlayer then return end

    local killerIdent = killerPlayer.getIdentifier()
    local victimIdent = victimPlayer.getIdentifier()
    -- Keep FiveM names in memory so we can patch them onto the DB result
    local killerName  = GetPlayerName(killerId) or 'Unknown'
    local victimName  = GetPlayerName(victimId) or 'Unknown'

    MySQL.query([[
        SELECT identifier, name, kills, deaths, bank,
               ROUND(kills / GREATEST(deaths, 1), 2) AS kd
        FROM gunward_stats
        WHERE identifier IN (?, ?)
    ]], { killerIdent, victimIdent }, function(results)
        if not results or #results == 0 then return end

        -- Guarantee names are correct (in case DB name column is stale)
        for _, row in ipairs(results) do
            if row.identifier == killerIdent then row.name = killerName end
            if row.identifier == victimIdent  then row.name = victimName  end
        end

        -- Only push to players currently in Gunward
        for _, src in ipairs(GetPlayers()) do
            src = tonumber(src)
            if Gunward.Server.Teams.IsPlayerInGunward(src) then
                TriggerClientEvent('gunward:client:statsUpdate', src, { updatedPlayers = results })
            end
        end
    end)
end

-- ── LEGACY: GetLeaderboard ───────────────────────────────────────────────────
function Gunward.Server.Database.GetLeaderboard(limit, cb)
    limit = limit or 10
    MySQL.query(
        'SELECT * FROM gunward_stats ORDER BY kills DESC LIMIT ?',
        { limit },
        function(results) cb(results or {}) end
    )
end
