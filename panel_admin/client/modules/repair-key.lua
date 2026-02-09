--[[
    Module Repair Key - Panel Admin Fight League
    Touche de reparation vehicule configurable
]]

local ESX = exports['es_extended']:getSharedObject()

-- Variables locales
local lastRepairTime = 0
local playerGroup = 'user'

-- ══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ══════════════════════════════════════════════════════════════

-- Recuperer le groupe du joueur
CreateThread(function()
    while not ESX do
        Wait(100)
        ESX = exports['es_extended']:getSharedObject()
    end

    -- Attendre que le joueur soit charge
    while not ESX.IsPlayerLoaded() do
        Wait(100)
    end

    -- Recuperer le groupe initial
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.group then
        playerGroup = playerData.group
    end
end)

-- Mettre a jour le groupe quand il change
RegisterNetEvent('esx:setJob', function(job)
    -- Le groupe ESX n'est pas le job, on garde le groupe actuel
end)

-- Ecouter les changements de groupe
AddEventHandler('esx:setPlayerData', function(key, val)
    if key == 'group' then
        playerGroup = val
    end
end)

-- Callback pour recuperer le groupe depuis le serveur
RegisterNetEvent('panel:updatePlayerGroup', function(group)
    playerGroup = group
end)

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS
-- ══════════════════════════════════════════════════════════════

-- Verifier si le groupe est autorise
local function isGroupAllowed()
    if not Config.RepairKey or not Config.RepairKey.AllowedGroups then
        return false
    end

    for _, allowedGroup in ipairs(Config.RepairKey.AllowedGroups) do
        if string.lower(playerGroup) == string.lower(allowedGroup) then
            return true
        end
    end

    return false
end

-- Reparer le vehicule
local function repairVehicle()
    -- Verifier si la fonctionnalite est activee
    if not Config.RepairKey or not Config.RepairKey.Enabled then
        return
    end

    -- Verifier le groupe
    if not isGroupAllowed() then
        if Config.RepairKey.NotifyOnRepair then
            TriggerEvent('panel:notification', {
                type = 'error',
                title = 'Reparation',
                message = 'Vous n\'avez pas la permission'
            })
        end
        return
    end

    -- Verifier le cooldown
    local currentTime = GetGameTimer()
    local cooldownMs = (Config.RepairKey.Cooldown or 5) * 1000

    if currentTime - lastRepairTime < cooldownMs then
        local remaining = math.ceil((cooldownMs - (currentTime - lastRepairTime)) / 1000)
        if Config.RepairKey.NotifyOnRepair then
            TriggerEvent('panel:notification', {
                type = 'warning',
                title = 'Reparation',
                message = 'Attendez ' .. remaining .. ' seconde(s)'
            })
        end
        return
    end

    -- Verifier si le joueur est dans un vehicule
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        if Config.RepairKey.NotifyOnRepair then
            TriggerEvent('panel:notification', {
                type = 'error',
                title = 'Reparation',
                message = 'Vous devez etre dans un vehicule'
            })
        end
        return
    end

    -- Reparer le vehicule
    SetVehicleFixed(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)

    -- Reparer les pneus
    for i = 0, 7 do
        if IsVehicleTyreBurst(vehicle, i, false) then
            SetVehicleTyreFixed(vehicle, i)
        end
    end

    -- Reparer les fenetres
    for i = 0, 7 do
        FixVehicleWindow(vehicle, i)
    end

    -- Reparer les portes
    for i = 0, 5 do
        SetVehicleDoorShut(vehicle, i, false)
    end

    -- Mettre a jour le cooldown
    lastRepairTime = currentTime

    -- Notification
    if Config.RepairKey.NotifyOnRepair then
        TriggerEvent('panel:notification', {
            type = 'success',
            title = 'Reparation',
            message = 'Vehicule repare!'
        })
    end

    -- Log serveur (optionnel)
    TriggerServerEvent('panel:logRepairKey')
end

-- ══════════════════════════════════════════════════════════════
-- KEYBIND
-- ══════════════════════════════════════════════════════════════

-- Enregistrer la commande
RegisterCommand('repairkey', function()
    repairVehicle()
end, false)

-- Enregistrer le keybind (modifiable dans les parametres FiveM)
CreateThread(function()
    Wait(1000) -- Attendre que le config soit charge

    if Config.RepairKey and Config.RepairKey.Enabled then
        local defaultKey = Config.RepairKey.DefaultKey or 'F9'
        RegisterKeyMapping('repairkey', 'Reparer le vehicule', 'keyboard', defaultKey)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- DEMANDER LE GROUPE AU SERVEUR
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(5000) -- Attendre le chargement complet
    TriggerServerEvent('panel:requestPlayerGroup')
end)

if Config.Debug then print('^2[PANEL ADMIN]^0 Module Repair Key charge') end
