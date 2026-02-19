Gunward.Client.VehicleShop = {}

local shopPed   = nil
local shopOpen  = false

-- ── BOOST ────────────────────────────────────────────────────────────────────

local boostedVehicle   = nil
local originalHandling = {}

local HANDLING_FIELDS = {
    'fInitialDriveForce', 'fClutchChangeRateScaleUpShift',
    'fTractionCurveMax', 'fTractionCurveMin', 'fTractionCurveLateral',
    'fLowSpeedTractionLossMult', 'fBrakeForce', 'fSuspensionForce',
    'fAntiRollBarForce', 'fCollisionDamageMult', 'fDeformationDamageMult',
    'fEngineDamageMult',
}

local function SaveOriginalHandling(vehicle)
    originalHandling = {}
    for _, field in ipairs(HANDLING_FIELDS) do
        originalHandling[field] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
    end
end

local function ApplyBoost(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local b = Config.VehicleBoost

    SaveOriginalHandling(vehicle)

    -- Appliquer les multiplicateurs sur les valeurs originales du véhicule
    for _, field in ipairs(HANDLING_FIELDS) do
        local mult = b[field]
        if mult and originalHandling[field] then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field,
                originalHandling[field] * mult)
        end
    end

    SetVehicleMaxSpeed(vehicle, b.topSpeedMs)
    SetVehicleCheatPowerIncrease(vehicle, b.powerMultiplier)

    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleCanBreak(vehicle, false)
    SetVehicleStrong(vehicle, true)
    SetVehicleHasStrongAxles(vehicle, true)
    SetVehicleOnGroundProperly(vehicle, true)
    ToggleVehicleMod(vehicle, 18, true) -- turbo

    boostedVehicle = vehicle
end

local function ClearBoost(vehicle)
    if not DoesEntityExist(vehicle) then return end
    -- Restaurer les valeurs originales
    for field, val in pairs(originalHandling) do
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, val)
    end
    SetVehicleMaxSpeed(vehicle, 0.0)  -- 0.0 = réinitialise la limite (pas de cap)
    SetVehicleCheatPowerIncrease(vehicle, 0.0)
    SetVehicleCanBeVisiblyDamaged(vehicle, true)
    SetVehicleTyresCanBurst(vehicle, true)
    SetVehicleCanBreak(vehicle, true)
    originalHandling = {}
    boostedVehicle   = nil
end

function Gunward.Client.VehicleShop.CreatePed(teamName)
    Gunward.Client.VehicleShop.DeletePed()

    local coords = Config.VehicleShopPeds[teamName]
    if not coords then return end

    local model = 's_m_y_marine_03'
    Gunward.Client.Utils.LoadModel(model)
    local hash = GetHashKey(model)

    shopPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(shopPed, true)
    SetEntityInvincible(shopPed, true)
    SetBlockingOfNonTemporaryEvents(shopPed, true)
    TaskStartScenarioInPlace(shopPed, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    SetEntityAsMissionEntity(shopPed, true, true)

    SetModelAsNoLongerNeeded(hash)
    Gunward.Debug('Vehicle shop PED created for team', teamName)
end

function Gunward.Client.VehicleShop.DeletePed()
    if shopPed and DoesEntityExist(shopPed) then
        DeleteEntity(shopPed)
    end
    shopPed = nil
end

function Gunward.Client.VehicleShop.OpenShop()
    if shopOpen then return end

    ESX.TriggerServerCallback('gunward:server:getShopInfo', function(data)
        local balance      = data.balance
        local isPrivileged = data.isPrivileged

        -- Build vehicle list with effective prices
        local vehicles = {}
        for _, veh in ipairs(Config.Vehicles) do
            vehicles[#vehicles + 1] = {
                model  = veh.model,
                label  = veh.label,
                price  = isPrivileged and 0 or veh.price,
            }
        end

        shopOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action   = 'openVehicleShop',
            vehicles = vehicles,
            balance  = balance,
        })
    end)
end

function Gunward.Client.VehicleShop.CloseShop()
    if not shopOpen then return end
    shopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeVehicleShop'})
end

-- NUI Callbacks
RegisterNUICallback('buyVehicle', function(data, cb)
    cb('ok')
    Gunward.Client.VehicleShop.CloseShop()
    TriggerServerEvent('gunward:server:buyVehicle', data.model)
end)

RegisterNUICallback('closeVehicleShop', function(_, cb)
    cb('ok')
    shopOpen = false
    SetNuiFocus(false, false)
end)

-- Receive vehicle from server
RegisterNetEvent('gunward:client:spawnVehicle', function(netId)
    -- Attendre que le netId existe
    local timeout = 0
    while not NetworkDoesNetworkIdExist(netId) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    if not NetworkDoesNetworkIdExist(netId) then
        Gunward.Client.Utils.Notify('Erreur: vehicule introuvable', 'error')
        return
    end

    -- Attendre que l'entité soit valide localement (NetToVeh peut retourner 0 même si le netId existe)
    local vehicle = 0
    timeout = 0
    while (vehicle == 0 or not DoesEntityExist(vehicle)) and timeout < 60 do
        vehicle = NetToVeh(netId)
        Wait(50)
        timeout = timeout + 1
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Gunward.Client.Utils.Notify('Erreur: entite vehicule introuvable', 'error')
        return
    end

    local ped = PlayerPedId()
    local team = Gunward.Client.Teams.GetCurrent()

    -- Apply team color
    if team and Config.TeamVehicleColors[team] then
        local colors = Config.TeamVehicleColors[team]
        SetVehicleColours(vehicle, colors.primary, colors.secondary)
    end

    -- Apply boost
    ApplyBoost(vehicle)

    -- Warp player into vehicle
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    Gunward.Client.Utils.Notify('Vehicule spawn!', 'success')
end)

-- ── BOOST THREAD — maintient le boost si le joueur change de véhicule ────────
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
                if boostedVehicle and boostedVehicle ~= vehicle then
                    ClearBoost(boostedVehicle)
                end
                if boostedVehicle == vehicle then
                    -- Réappliquer périodiquement (GTA peut réinitialiser certains flags)
                    SetVehicleCheatPowerIncrease(vehicle, Config.VehicleBoost.powerMultiplier)
                    SetVehicleMaxSpeed(vehicle, Config.VehicleBoost.topSpeedMs)
                    SetVehicleTyresCanBurst(vehicle, false)
                    SetVehicleCanBreak(vehicle, false)
                end
            end
        else
            if boostedVehicle and DoesEntityExist(boostedVehicle) then
                ClearBoost(boostedVehicle)
            end
        end
    end
end)

-- ── DROP INSTANTANÉ — appuie sur F pour sortir sans animation ────────────────
local lastExitTime = 0

CreateThread(function()
    while true do
        local sleep = 200
        local ped = PlayerPedId()

        if Gunward.Client.Teams.GetCurrent() and IsPedInAnyVehicle(ped, false) then
            sleep = 0
            -- Intercepte la touche F (control 75 = INPUT_VEH_EXIT)
            DisableControlAction(0, 75, true)

            if IsDisabledControlJustPressed(0, 75) then
                local vehicle = GetVehiclePedIsIn(ped, false)

                if DoesEntityExist(vehicle) then
                    -- Calculer le côté de sortie selon le siège du joueur
                    local seat = -2
                    for s = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                        if GetPedInVehicleSeat(vehicle, s) == ped then
                            seat = s
                            break
                        end
                    end

                    local side = (seat == -1 or seat == 1) and -2.5 or 2.5
                    local offset = GetOffsetFromEntityInWorldCoords(vehicle, side, 0.0, 0.0)

                    -- Trouver le sol
                    local groundZ = GetEntityCoords(vehicle).z
                    local found, z = GetGroundZFor_3dCoord(offset.x, offset.y, offset.z + 2.0, false)
                    if found then groundZ = z end

                    -- Éjecter et repositionner instantanément
                    SetPedIntoVehicle(ped, vehicle, -2)
                    SetEntityCoords(ped, offset.x, offset.y, groundZ + 0.5, false, false, false, false)
                    ClearPedTasksImmediately(ped)

                    lastExitTime = GetGameTimer()
                end
            end
        elseif lastExitTime > 0 and (GetGameTimer() - lastExitTime) < 800 then
            -- Bloquer la réentrée immédiate pendant 800ms
            sleep = 0
            DisableControlAction(0, 23, true)  -- INPUT_ENTER
            DisableControlAction(0, 75, true)  -- INPUT_VEH_EXIT
        else
            lastExitTime = 0
        end

        Wait(sleep)
    end
end)

-- Update balance after purchase
RegisterNetEvent('gunward:client:updateBank', function(newBalance)
    SendNUIMessage({
        action = 'updateBalance',
        balance = newBalance,
    })
end)

-- Interaction thread for vehicle shop PED
CreateThread(function()
    while true do
        local sleep = 1000
        local team = Gunward.Client.Teams.GetCurrent()

        if team and Config.VehicleShopPeds[team] then
            local pedCoords = Config.VehicleShopPeds[team]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

            if dist < 15.0 then
                sleep = 0
                Gunward.Client.Utils.DrawText3D(
                    vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.0),
                    '~w~Appuyez sur ~r~[E]~w~ - Boutique Vehicules'
                )

                if dist < 2.5 then
                    if IsControlJustPressed(0, 38) and not shopOpen then
                        Gunward.Client.VehicleShop.OpenShop()
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
        Gunward.Client.VehicleShop.DeletePed()
        if boostedVehicle and DoesEntityExist(boostedVehicle) then
            ClearBoost(boostedVehicle)
        end
    end
end)
