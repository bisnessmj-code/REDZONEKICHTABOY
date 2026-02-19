Gunward.Client.KOTH = {}

local kothBlipRadius   = nil
local kothBlipCenter   = nil
local currentZoneIndex = nil
local currentZoneLabel = ''   -- used to forward zone label to NUI timer

-- Remove all KOTH blips
local function RemoveBlips()
    if kothBlipRadius and DoesBlipExist(kothBlipRadius) then
        RemoveBlip(kothBlipRadius)
        kothBlipRadius = nil
    end
    if kothBlipCenter and DoesBlipExist(kothBlipCenter) then
        RemoveBlip(kothBlipCenter)
        kothBlipCenter = nil
    end
    currentZoneIndex = nil
end

-- Create blips for a zone
local function CreateBlips(zoneCoords, zoneLabel, holderColor)
    RemoveBlips()

    -- Radius blip (zone area)
    kothBlipRadius = AddBlipForRadius(zoneCoords.x, zoneCoords.y, zoneCoords.z, Config.KOTH.ZoneRadius)
    SetBlipColour(kothBlipRadius, holderColor or 4) -- 4 = white by default
    SetBlipAlpha(kothBlipRadius, 100)

    -- Center point blip
    kothBlipCenter = AddBlipForCoord(zoneCoords.x, zoneCoords.y, zoneCoords.z)
    SetBlipSprite(kothBlipCenter, 439) -- flag sprite
    SetBlipDisplay(kothBlipCenter, 4)
    SetBlipScale(kothBlipCenter, 1.0)
    SetBlipColour(kothBlipCenter, holderColor or 4)
    SetBlipAsShortRange(kothBlipCenter, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('KOTH: ' .. zoneLabel)
    EndTextCommandSetBlipName(kothBlipCenter)
end

-- Update blip color based on holder
local function UpdateBlipColor(holderColor)
    local color = holderColor or 4

    if kothBlipRadius and DoesBlipExist(kothBlipRadius) then
        SetBlipColour(kothBlipRadius, color)
    end
    if kothBlipCenter and DoesBlipExist(kothBlipCenter) then
        SetBlipColour(kothBlipCenter, color)
    end
end

-- Show announce via NUI
local function ShowAnnounce(message, duration)
    SendNUIMessage({
        action = 'showAnnounce',
        message = message,
        duration = duration or 5000,
    })
end

-- Show/hide scoreboard
local function ShowScoreboard(scores, timeRemaining, zoneLabel)
    SendNUIMessage({
        action = 'kothShowScoreboard',
        scores = scores,
        timeRemaining = timeRemaining,
        zoneLabel = zoneLabel or '',
    })
end

local function HideScoreboard()
    SendNUIMessage({ action = 'kothHideScoreboard' })
end

local function UpdateScoreboard(scores, timeRemaining)
    SendNUIMessage({
        action = 'kothUpdateScores',
        scores = scores,
        timeRemaining = timeRemaining,
    })
end

-- Request sync from server and setup blips
local function RequestSync()
    ESX.TriggerServerCallback('gunward:server:kothSync', function(data)
        if not data then return end

        currentZoneIndex = data.zoneIndex
        currentZoneLabel = data.zoneLabel or ''
        CreateBlips(data.zoneCoords, data.zoneLabel, data.holderColor)

        -- Show scoreboard
        ShowScoreboard(data.scores, data.timeRemaining, data.zoneLabel)

        -- Forward timer to Gunward UI
        SendNUIMessage({
            action        = 'updateTimer',
            timeRemaining = data.timeRemaining,
            zoneLabel     = currentZoneLabel,
        })

        Gunward.Debug('KOTH synced: zone', data.zoneIndex, data.zoneLabel, '| holder:', data.holder or 'none')
    end)
end

-- When player joins gunward, request KOTH sync
RegisterNetEvent('gunward:client:teamJoined', function(teamName)
    Wait(1000) -- Let everything settle
    RequestSync()
end)

-- Score + holder update every 3s
RegisterNetEvent('gunward:client:kothScoreUpdate', function(data)
    if not Gunward.Client.Teams.IsInGunward() then return end

    -- Update blip color
    UpdateBlipColor(data.holderColor)

    -- Update KOTH scoreboard NUI
    UpdateScoreboard(data.scores, data.timeRemaining)

    -- Forward timer + player count to Gunward main UI (event-driven, no extra timer)
    SendNUIMessage({
        action        = 'updateTimer',
        timeRemaining = data.timeRemaining,
        zoneLabel     = currentZoneLabel,
    })
    if data.serverPlayers then
        SendNUIMessage({ action = 'updatePlayerCount', count = data.serverPlayers })
    end
end)

-- When zone rotates
RegisterNetEvent('gunward:client:kothZoneChanged', function(data)
    if not Gunward.Client.Teams.IsInGunward() then return end

    -- Show winner announce
    if data.winnerTeam then
        ShowAnnounce(data.winnerLabel .. ' A DOMINE LA ZONE ! +$' .. data.reward, 5000)
    else
        ShowAnnounce('AUCUNE EQUIPE N\'A DOMINE LA ZONE', 4000)
    end

    -- Wait before showing new zone
    Wait(3000)

    -- Create new blips
    currentZoneIndex = data.newZoneIndex
    currentZoneLabel = data.newZoneLabel or ''
    CreateBlips(data.newZoneCoords, data.newZoneLabel, nil)

    -- Show new zone announce + reset scoreboard
    ShowAnnounce('NOUVELLE ZONE: ' .. data.newZoneLabel, 5000)
    ShowScoreboard(data.scores, data.timeRemaining, data.newZoneLabel)
end)

-- Cleanup when leaving gunward
RegisterNetEvent('gunward:client:removedFromGunward', function()
    RemoveBlips()
    HideScoreboard()
    currentZoneLabel = ''
end)

-- ── RELAY: post-kill stats update → Gunward UI ───────────────────────────────
-- Server pushes updated rows for killer + victim after each legitimate kill.
RegisterNetEvent('gunward:client:statsUpdate', function(data)
    SendNUIMessage({
        action         = 'updateStats',
        updatedPlayers = data.updatedPlayers,
    })
end)
