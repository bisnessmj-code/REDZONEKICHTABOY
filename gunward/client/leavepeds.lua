Gunward.Client.LeavePeds = {}

local leavePed = nil

function Gunward.Client.LeavePeds.CreatePed(teamName)
    Gunward.Client.LeavePeds.DeletePed()

    local coords = Config.LeavePeds[teamName]
    if not coords then return end

    local model = 's_m_y_cop_01'
    Gunward.Client.Utils.LoadModel(model)
    local hash = GetHashKey(model)

    leavePed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(leavePed, true)
    SetEntityInvincible(leavePed, true)
    SetBlockingOfNonTemporaryEvents(leavePed, true)
    TaskStartScenarioInPlace(leavePed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetEntityAsMissionEntity(leavePed, true, true)

    SetModelAsNoLongerNeeded(hash)
    Gunward.Debug('Leave PED created for team', teamName)
end

function Gunward.Client.LeavePeds.DeletePed()
    if leavePed and DoesEntityExist(leavePed) then
        DeleteEntity(leavePed)
    end
    leavePed = nil
end

-- Interaction thread for leave PED
CreateThread(function()
    while true do
        local sleep = 1000
        local team = Gunward.Client.Teams.GetCurrent()

        if team and Config.LeavePeds[team] then
            local pedCoords = Config.LeavePeds[team]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

            if dist < 15.0 then
                sleep = 0
                Gunward.Client.Utils.DrawText3D(
                    vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0),
                    '~w~Appuyez sur ~r~[E]~w~ - Quitter le Gunward'
                )

                if dist < 2.5 then
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('gunward:server:leaveGunward')
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Gunward.Client.LeavePeds.DeletePed()
    end
end)
