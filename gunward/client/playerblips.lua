Gunward.Client.PlayerBlips = {}

local playerBlips = {}
local blipLoopActive = false

local function RemoveAllBlips()
    for serverId, blip in pairs(playerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    playerBlips = {}
end

local function RemoveBlipForPlayer(serverId)
    if playerBlips[serverId] and DoesBlipExist(playerBlips[serverId]) then
        RemoveBlip(playerBlips[serverId])
    end
    playerBlips[serverId] = nil
end

local function StartBlipLoop()
    if blipLoopActive then return end
    blipLoopActive = true

    CreateThread(function()
        while blipLoopActive do
            local myId = PlayerId()
            local myServerId = GetPlayerServerId(myId)

            -- Track active players this tick
            local activePlayers = {}

            for _, playerId in ipairs(GetActivePlayers()) do
                local serverId = GetPlayerServerId(playerId)
                if serverId ~= myServerId then
                    local team = Player(serverId).state.gunwardTeam
                    if team and Config.Teams[team] then
                        activePlayers[serverId] = true
                        local ped = GetPlayerPed(playerId)

                        if ped and DoesEntityExist(ped) then
                            if not playerBlips[serverId] or not DoesBlipExist(playerBlips[serverId]) then
                                -- Create blip attached to ped
                                local blip = AddBlipForEntity(ped)
                                SetBlipSprite(blip, 1) -- standard dot
                                SetBlipScale(blip, 0.75)
                                SetBlipColour(blip, Config.Teams[team].blipColor)
                                SetBlipDisplay(blip, 4)
                                SetBlipAsShortRange(blip, false)
                                ShowHeadingIndicatorOnBlip(blip, true)

                                -- Show player name
                                BeginTextCommandSetBlipName('STRING')
                                AddTextComponentSubstringPlayerName(GetPlayerName(playerId))
                                EndTextCommandSetBlipName(blip)

                                playerBlips[serverId] = blip
                            else
                                -- Update color if team changed
                                local blip = playerBlips[serverId]
                                local currentColor = GetBlipColour(blip)
                                if currentColor ~= Config.Teams[team].blipColor then
                                    SetBlipColour(blip, Config.Teams[team].blipColor)
                                end
                            end
                        end
                    end
                end
            end

            -- Remove blips for players who left
            for serverId, blip in pairs(playerBlips) do
                if not activePlayers[serverId] then
                    if DoesBlipExist(blip) then
                        RemoveBlip(blip)
                    end
                    playerBlips[serverId] = nil
                end
            end

            Wait(1000)
        end
    end)
end

local function StopBlipLoop()
    blipLoopActive = false
    RemoveAllBlips()
end

-- Start when joining gunward
RegisterNetEvent('gunward:client:teamJoined', function(teamName)
    Wait(1500)
    StartBlipLoop()
end)

-- Stop when leaving gunward
RegisterNetEvent('gunward:client:removedFromGunward', function()
    StopBlipLoop()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    StopBlipLoop()
end)
