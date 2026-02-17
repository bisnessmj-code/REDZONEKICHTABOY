Gunward.Client.Ped = {}

local pedEntity = nil

function Gunward.Client.Ped.Create()
    local cfg = Config.Ped
    local model = cfg.model

    if not Gunward.Client.Utils.LoadModel(model) then
        Gunward.Debug('Failed to load ped model:', model)
        return
    end

    local hash = type(model) == 'string' and GetHashKey(model) or model
    pedEntity = CreatePed(4, hash, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.coords.w, false, true)

    if cfg.frozen then
        FreezeEntityPosition(pedEntity, true)
    end
    if cfg.invincible then
        SetEntityInvincible(pedEntity, true)
    end
    if cfg.blockEvents then
        SetBlockingOfNonTemporaryEvents(pedEntity, true)
    end
    if cfg.scenario then
        TaskStartScenarioInPlace(pedEntity, cfg.scenario, 0, true)
    end

    SetEntityAsMissionEntity(pedEntity, true, true)
    SetModelAsNoLongerNeeded(hash)

    Gunward.Debug('Ped created at', cfg.coords)
end

function Gunward.Client.Ped.Delete()
    if pedEntity and DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
        pedEntity = nil
        Gunward.Debug('Ped deleted')
    end
end

function Gunward.Client.Ped.GetEntity()
    return pedEntity
end

function Gunward.Client.Ped.StartInteractionThread()
    CreateThread(function()
        local pedCoords = Config.Ped.coords
        local interactDist = Config.Ped.interactDistance

        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

            if dist < 10.0 then
                sleep = 200
                if dist < interactDist then
                    sleep = 0
                    Gunward.Client.Utils.DrawText3D(vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0), Lang('ped_interact'))

                    if IsControlJustPressed(0, 38) then -- E key
                        Gunward.Client.Teams.OpenSelection()
                    end
                end
            end

            Wait(sleep)
        end
    end)
end
