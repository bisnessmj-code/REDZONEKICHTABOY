--[[
    Admin Commands Client - Panel Admin Fight League
    Gestion des events client pour les commandes admin
]]

-- ══════════════════════════════════════════════════════════════
-- TELEPORTATION
-- ══════════════════════════════════════════════════════════════

-- Teleporter aux coordonnees
RegisterNetEvent('admin:teleportToCoords', function(x, y, z, heading)
    local playerPed = PlayerPedId()

    -- Si en noclip, mettre a jour la position noclip directement
    if _G.Noclip and _G.Noclip.IsActive() then
        _G.Noclip.SetPosition(x, y, z)
        return
    end

    -- Si dans un vehicule, teleporter le vehicule
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        SetEntityCoords(vehicle, x, y, z, false, false, false, false)
        if heading and heading ~= 0 then
            SetEntityHeading(vehicle, heading)
        end
    else
        SetEntityCoords(playerPed, x, y, z, false, false, false, false)
        if heading and heading ~= 0 then
            SetEntityHeading(playerPed, heading)
        end
    end

    -- Fixer au sol apres un court delai
    SetTimeout(100, function()
        local ped = PlayerPedId()
        local currentCoords = GetEntityCoords(ped)
        local found, groundZ = GetGroundZFor_3dCoord(currentCoords.x, currentCoords.y, currentCoords.z + 5.0, false)

        if found then
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                SetEntityCoords(vehicle, currentCoords.x, currentCoords.y, groundZ + 0.5, false, false, false, false)
            else
                SetEntityCoords(ped, currentCoords.x, currentCoords.y, groundZ + 1.0, false, false, false, false)
            end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
-- SOIN / REANIMATION
-- ══════════════════════════════════════════════════════════════

-- Soigner le joueur
RegisterNetEvent('admin:healPlayer', function()
    local playerPed = PlayerPedId()

    -- Restaurer la vie au maximum
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))

    -- Restaurer l'armure a 100
    SetPedArmour(playerPed, 100)

    -- Nettoyer le sang
    ClearPedBloodDamage(playerPed)

    -- Reset les degats visibles
    ResetPedVisibleDamage(playerPed)

    -- Effacer les traces de degats d'arme
    ClearPedLastWeaponDamage(playerPed)

    -- Eteindre le feu si le joueur brule
    if IsEntityOnFire(playerPed) then
        StopEntityFire(playerPed)
    end

    -- Effet visuel
    AnimpostfxPlay('SuccessMichael', 500, false)
end)

-- Reanimer le joueur
RegisterNetEvent('admin:revivePlayer', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    -- Si mort, ressusciter
    if IsEntityDead(playerPed) or IsPlayerDead(PlayerId()) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        Wait(100)
        playerPed = PlayerPedId()
    end

    -- Restaurer la vie au maximum
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))

    -- Restaurer l'armure a 100
    SetPedArmour(playerPed, 100)

    -- Nettoyer le sang
    ClearPedBloodDamage(playerPed)

    -- Reset les degats visibles
    ResetPedVisibleDamage(playerPed)

    -- Effacer les traces de degats d'arme
    ClearPedLastWeaponDamage(playerPed)

    -- Arreter toutes les animations
    ClearPedTasksImmediately(playerPed)

    -- Eteindre le feu si le joueur brule
    if IsEntityOnFire(playerPed) then
        StopEntityFire(playerPed)
    end

    -- Effet visuel
    AnimpostfxPlay('SuccessMichael', 500, false)

    -- Trigger ESX revive pour compatibilite avec esx_ambulancejob
    TriggerEvent('esx_ambulancejob:revive')
    TriggerEvent('esx:onPlayerSpawn')
end)

-- ══════════════════════════════════════════════════════════════
-- VEHICULES
-- ══════════════════════════════════════════════════════════════

-- Fonction de reparation complete d'un vehicule
local function FullRepairVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end

    -- Reparation principale
    SetVehicleFixed(vehicle)

    -- Sante du moteur
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleEngineOn(vehicle, true, true, false)

    -- Sante de la carrosserie
    SetVehicleBodyHealth(vehicle, 1000.0)

    -- Sante du reservoir
    SetVehiclePetrolTankHealth(vehicle, 1000.0)

    -- Nettoyer la salete
    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)

    -- Reparer les 8 pneus (index 0-7)
    for i = 0, 7 do
        if IsVehicleTyreBurst(vehicle, i, true) or IsVehicleTyreBurst(vehicle, i, false) then
            SetVehicleTyreFixed(vehicle, i)
        end
    end

    -- Reparer les 8 fenetres (index 0-7)
    for i = 0, 7 do
        if not IsVehicleWindowIntact(vehicle, i) then
            FixVehicleWindow(vehicle, i)
        end
    end

    -- Fermer les 6 portes (index 0-5)
    for i = 0, 5 do
        if IsVehicleDoorDamaged(vehicle, i) then
            SetVehicleDoorShut(vehicle, i, false)
        end
    end

    -- Reset les deformations
    SetVehicleDeformationFixed(vehicle)

    -- Remettre le vehicule en etat de conduite
    SetVehicleUndriveable(vehicle, false)

    return true
end

-- Reparer le vehicule du joueur
RegisterNetEvent('admin:repairVehicle', function(adminSource)
    local playerPed = PlayerPedId()
    local repaired = false

    if IsPedInAnyVehicle(playerPed, false) then
        -- Reparer le vehicule dans lequel on est
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        repaired = FullRepairVehicle(vehicle)
    else
        -- Chercher un vehicule proche
        local coords = GetEntityCoords(playerPed)
        local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)

        if vehicle and DoesEntityExist(vehicle) then
            repaired = FullRepairVehicle(vehicle)
        end
    end

    -- Notifications
    local playerId = GetPlayerServerId(PlayerId())
    if adminSource and adminSource ~= playerId then
        -- Repare par un autre admin
        if repaired then
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 255},
                multiline = true,
                args = {'', 'Votre vehicule a ete repare par un admin'}
            })
        end
    else
        -- Repare soi-meme
        if repaired then
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 255},
                multiline = true,
                args = {'', 'Votre vehicule a ete repare'}
            })
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 255},
                multiline = true,
                args = {'', 'Aucun vehicule a reparer'}
            })
        end
    end
end)

-- Reparer tous les vehicules dans un rayon
RegisterNetEvent('admin:repairVehiclesInRadius', function(radius)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local count = 0

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehCoords)

            if distance <= radius then
                if FullRepairVehicle(vehicle) then
                    count = count + 1
                end
            end
        end
    end

    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {'', '' .. count .. ' vehicule(s) repare(s) dans un rayon de ' .. radius .. 'm'}
    })
end)

-- Reparer TOUS les vehicules du serveur (pour /repairall)
RegisterNetEvent('admin:repairAllVehicles', function()
    local vehicles = GetGamePool('CVehicle')
    local count = 0

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            if FullRepairVehicle(vehicle) then
                count = count + 1
            end
        end
    end

    -- Pas de notification ici car le serveur envoie deja une notification globale
end)

if Config.Debug then print('^2[PANEL ADMIN]^0 Admin Commands Client charge') end
