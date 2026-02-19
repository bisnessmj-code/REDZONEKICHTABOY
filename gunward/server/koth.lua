Gunward.Server.KOTH = {}

local currentZoneIndex = 1
local zoneStartTime = 0
local teamPoints = {}
local currentHolder = nil
local kothActive = false

-- Initialize team points
local function ResetPoints()
    teamPoints = {}
    for teamName, _ in pairs(Config.Teams) do
        teamPoints[teamName] = 0
    end
    currentHolder = nil
end

ResetPoints()

-- Get players in the active zone per team
local function GetPlayersInZone()
    local zone = Config.KOTH.Zones[currentZoneIndex]
    if not zone then return {} end

    local teamCounts = {}
    for teamName, _ in pairs(Config.Teams) do
        teamCounts[teamName] = 0
    end

    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        local team = Gunward.Server.Teams.GetPlayerTeam(src)
        if team then
            local ped = GetPlayerPed(src)
            if ped and DoesEntityExist(ped) then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(pedCoords - zone.coords)
                if dist <= Config.KOTH.ZoneRadius then
                    teamCounts[team] = teamCounts[team] + 1
                end
            end
        end
    end

    return teamCounts
end

-- Find the team with the most players in zone
local function GetDominantTeam(teamCounts)
    local maxCount = 0
    local dominant = nil

    for teamName, count in pairs(teamCounts) do
        if count > maxCount then
            maxCount = count
            dominant = teamName
        elseif count == maxCount and count > 0 then
            dominant = nil
        end
    end

    return dominant
end

-- Build scores data for NUI
local function BuildScoresData()
    local scores = {}
    for _, teamName in ipairs(Config.TeamOrder) do
        local teamData = Config.Teams[teamName]
        scores[#scores + 1] = {
            name = teamName,
            label = teamData.label,
            points = teamPoints[teamName] or 0,
            color = teamData.color,
            isHolder = (teamName == currentHolder),
        }
    end
    return scores
end

-- Reward the winning team
local function RewardTeam(winnerTeam)
    if not winnerTeam then return end

    local players = Gunward.Server.Teams.GetTeamPlayers(winnerTeam)
    for src, _ in pairs(players) do
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addAccountMoney('bank', Config.KOTH.Reward)
        end
    end
end

-- Advance to next zone
local function RotateZone()
    -- Find winner (team with most points)
    local winnerTeam = nil
    local maxPoints = 0
    for teamName, pts in pairs(teamPoints) do
        if pts > maxPoints then
            maxPoints = pts
            winnerTeam = teamName
        elseif pts == maxPoints and pts > 0 then
            winnerTeam = nil -- tie = no winner
        end
    end

    -- Reward winner
    if winnerTeam then
        RewardTeam(winnerTeam)
    end

    -- Advance zone index
    currentZoneIndex = currentZoneIndex + 1
    if currentZoneIndex > #Config.KOTH.Zones then
        currentZoneIndex = 1
    end

    -- Reset state
    ResetPoints()
    zoneStartTime = os.time()

    -- Broadcast to all clients
    local newZone = Config.KOTH.Zones[currentZoneIndex]
    TriggerClientEvent('gunward:client:kothZoneChanged', -1, {
        winnerTeam = winnerTeam,
        winnerLabel = winnerTeam and Config.Teams[winnerTeam].label or nil,
        reward = Config.KOTH.Reward,
        newZoneIndex = currentZoneIndex,
        newZoneCoords = newZone.coords,
        newZoneLabel = newZone.label,
        timeRemaining = Config.KOTH.RotationTime,
        scores = BuildScoresData(),
    })

    Gunward.Debug('KOTH zone rotated to', currentZoneIndex, newZone.label, '| Winner:', winnerTeam or 'none')
end

-- Start KOTH system
local function StartKOTH()
    if kothActive then return end
    kothActive = true
    zoneStartTime = os.time()
    ResetPoints()

    Gunward.Debug('KOTH system started, zone:', currentZoneIndex)

    -- Capture check loop (every 3s)
    CreateThread(function()
        while kothActive do
            Wait(Config.KOTH.CheckInterval)

            if Gunward.Server.Teams.GetTotalPlayers() == 0 then
                goto continue
            end

            local teamCounts = GetPlayersInZone()
            local dominant = GetDominantTeam(teamCounts)

            -- Add points: 1 point per player in zone for each team
            for teamName, count in pairs(teamCounts) do
                if count > 0 then
                    teamPoints[teamName] = teamPoints[teamName] + count
                end
            end

            -- Update holder
            if dominant ~= currentHolder then
                currentHolder = dominant
            end

            -- Broadcast scores + holder to all clients
            local elapsed = os.time() - zoneStartTime
            local remaining = math.max(0, Config.KOTH.RotationTime - elapsed)

            TriggerClientEvent('gunward:client:kothScoreUpdate', -1, {
                holder = currentHolder,
                holderColor = currentHolder and Config.Teams[currentHolder].blipColor or nil,
                scores = BuildScoresData(),
                timeRemaining = remaining,
                serverPlayers = #GetPlayers(),
            })

            ::continue::
        end
    end)

    -- Rotation check loop
    CreateThread(function()
        while kothActive do
            Wait(1000)

            if Gunward.Server.Teams.GetTotalPlayers() == 0 then
                -- Pause timer when no players
                zoneStartTime = zoneStartTime + 1
                goto continue
            end

            if os.time() - zoneStartTime >= Config.KOTH.RotationTime then
                RotateZone()
            end

            ::continue::
        end
    end)
end

-- Sync callback for players joining mid-game
ESX.RegisterServerCallback('gunward:server:kothSync', function(source, cb)
    local zone = Config.KOTH.Zones[currentZoneIndex]
    local elapsed = os.time() - zoneStartTime
    local remaining = math.max(0, Config.KOTH.RotationTime - elapsed)

    cb({
        zoneIndex = currentZoneIndex,
        zoneCoords = zone.coords,
        zoneLabel = zone.label,
        holder = currentHolder,
        holderColor = currentHolder and Config.Teams[currentHolder].blipColor or nil,
        timeRemaining = remaining,
        scores = BuildScoresData(),
    })
end)

-- Auto-start when resource starts
CreateThread(function()
    Wait(1000)
    StartKOTH()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    kothActive = false
end)

-- ── TIMER INFO (called by getStatsUI callback) ──────────────────────────────
-- Returns current zone timer state from in-memory data — no DB hit.
function Gunward.Server.KOTH.GetTimerInfo()
    if zoneStartTime == 0 then
        return {
            timeRemaining = Config.KOTH.RotationTime,
            zoneLabel     = Config.KOTH.Zones[currentZoneIndex] and Config.KOTH.Zones[currentZoneIndex].label or '',
            zoneIndex     = currentZoneIndex,
        }
    end
    local zone      = Config.KOTH.Zones[currentZoneIndex]
    local elapsed   = os.time() - zoneStartTime
    local remaining = math.max(0, Config.KOTH.RotationTime - elapsed)
    return {
        timeRemaining = remaining,
        zoneLabel     = zone and zone.label or '',
        zoneIndex     = currentZoneIndex,
    }
end
