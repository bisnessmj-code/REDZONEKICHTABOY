ESX = exports['es_extended']:getSharedObject()

local inGame = false
local currentBot = nil
local killCount = 0
local gameThread = nil
local playerPed = PlayerPedId()
local originalWeapons = {}
local originalPosition = nil
local originalHeading = nil
-- Vérifie géométriquement si la visée pointe vers la tête du bot
local function IsAimingAtHead(bot)
    -- GetPedBoneCoords avec l'ID physique 31086 (SKEL_Head) - toujours valide
    local headPos = GetPedBoneCoords(bot, 31086, 0.0, 0.0, 0.0)

    local camPos = GetGameplayCamCoords()
    local camRot = GetGameplayCamRot(2)
    local rx = math.rad(camRot.x)
    local rz = math.rad(camRot.z)
    local aimDir = vector3(
        -math.sin(rz) * math.cos(rx),
         math.cos(rz) * math.cos(rx),
         math.sin(rx)
    )

    local toHead = headPos - camPos
    local dot = toHead.x * aimDir.x + toHead.y * aimDir.y + toHead.z * aimDir.z
    if dot <= 0 then return false end

    local closestPoint = camPos + aimDir * dot
    return #(closestPoint - headPos) < 0.13
end

-- Fonction pour afficher le menu principal
function OpenMainMenu()
    SendNUIMessage({
        action = 'openMainMenu'
    })
    SetNuiFocus(true, true)
end

-- Fonction pour afficher le classement
function OpenLeaderboardMenu(leaderboard)
    SendNUIMessage({
        action = 'openLeaderboard',
        leaderboard = leaderboard
    })
end

-- Callbacks NUI
RegisterNUICallback('startGame', function(data, cb)
    SetNuiFocus(false, false)
    StartGame()
    cb('ok')
end)

RegisterNUICallback('getLeaderboard', function(data, cb)
    ESX.TriggerServerCallback('aim_training:getLeaderboard', function(leaderboard)
        OpenLeaderboardMenu(leaderboard)
    end)
    cb('ok')
end)

RegisterNUICallback('backToMain', function(data, cb)
    OpenMainMenu()
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMenu' })
    cb('ok')
end)

-- Fermer le menu avec ESC
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 322) then -- ESC
            if IsPedSittingInAnyVehicle(PlayerPedId()) == false and not inGame then
                SendNUIMessage({ action = 'closeMenu' })
                SetNuiFocus(false, false)
            end
        end
    end
end)

-- Fonction pour démarrer la partie
function StartGame()
    if inGame then
        exports['brutal_notify']:SendAlert('Aim Training', 'Vous êtes déjà en partie!', 4000, 'error', true)
        return
    end

    -- Demander au serveur de créer une instance
    TriggerServerEvent('aim_training:requestInstance')
end

-- Event pour démarrer la partie après avoir reçu l'instance
RegisterNetEvent('aim_training:startGameInInstance')
AddEventHandler('aim_training:startGameInInstance', function()
    inGame = true
    killCount = 0
    playerPed = PlayerPedId()

    -- Fermer le menu NUI
    SendNUIMessage({ action = 'closeMenu' })
    SetNuiFocus(false, false)

    -- Sauvegarder la position actuelle
    local coords = GetEntityCoords(playerPed)
    originalPosition = {x = coords.x, y = coords.y, z = coords.z}
    originalHeading = GetEntityHeading(playerPed)

    -- Sauvegarder les armes actuelles
    RemoveAllPedWeapons(playerPed, true)

    -- Téléporter le joueur à la position de départ
    SetEntityCoords(playerPed, Config.PlayerStartPosition.x, Config.PlayerStartPosition.y, Config.PlayerStartPosition.z, false, false, false, true)
    SetEntityHeading(playerPed, Config.PlayerStartPosition.heading)

    -- Décompte de 3 secondes
    FreezeEntityPosition(playerPed, true)

    for i = 3, 1, -1 do
        exports['brutal_notify']:SendAlert('Aim Training', 'Début dans ' .. i .. '...', 1000, 'info', false)
        Wait(1000)
    end

    exports['brutal_notify']:SendAlert('Aim Training', 'C\'EST PARTI!', 3000, 'success', true)
    FreezeEntityPosition(playerPed, false)

    -- Donner le Pistol .50 avec munitions illimitées
    GiveWeaponToPed(playerPed, GetHashKey('WEAPON_PISTOL50'), 9999, false, true)
    SetPedInfiniteAmmo(playerPed, true, GetHashKey('WEAPON_PISTOL50'))
    SetPedInfiniteAmmoClip(playerPed, true) -- Pas de rechargement

    -- Désactiver l'aim assist pour un tir plus précis
    SetPlayerLockon(PlayerId(), false)
    SetPlayerTargetingMode(2) -- Mode libre sans assistance

    -- Afficher le HUD
    SendNUIMessage({ action = 'showHUD' })

    -- Lancer le jeu
    RunGame()
end)

-- Fonction principale du jeu
function RunGame()
    local startTime = GetGameTimer()
    local endTime = startTime + (Config.GameDuration * 1000)
    local botIndex = 1

    -- Thread pour vérifier la touche X et le timer
    gameThread = CreateThread(function()
        while inGame do
            Wait(0)

            -- Vérifier si X est pressé pour quitter
            if IsControlJustPressed(0, 73) then -- X key
                exports['brutal_notify']:SendAlert('Aim Training', 'Partie annulée!', 4000, 'error', true)
                EndGame(false)
                break
            end

            -- Mettre à jour le temps restant et les kills
            local currentTime = GetGameTimer()
            local timeLeft = math.ceil((endTime - currentTime) / 1000)

            if timeLeft <= 0 then
                EndGame(true)
                break
            end

            -- Mettre à jour le HUD NUI
            SendNUIMessage({
                action = 'updateHUD',
                time = timeLeft,
                kills = killCount
            })
        end
    end)

    -- Spawner le premier bot
    SpawnBot(botIndex)
    botIndex = botIndex + 1

    -- Thread principal
    CreateThread(function()
        while inGame do
            Wait(0)

            if currentBot ~= nil and DoesEntityExist(currentBot) then

                -- Tir : vérification géométrique immédiate, on tue le ped nous-mêmes
                if IsControlJustPressed(0, 24) then
                    if IsAimingAtHead(currentBot) then
                        killCount = killCount + 1
                        SendNUIMessage({
                            action = 'showKillNotif',
                            kills = killCount
                        })
                        local killed = currentBot
                        currentBot = nil
                        ApplyDamageToPed(killed, 5000, false) -- animation de mort
                        Wait(800)
                        if DoesEntityExist(killed) then DeleteEntity(killed) end
                        Wait(100)
                        if inGame then
                            SpawnBot(botIndex)
                            botIndex = botIndex + 1
                            if botIndex > #Config.BotSpawnPositions then botIndex = 1 end
                        end
                    end
                end

                -- Mort par auto-kill timer (SetEntityHealth 0)
                if currentBot ~= nil and IsPedDeadOrDying(currentBot, true) then
                    local dead = currentBot
                    currentBot = nil
                    if DoesEntityExist(dead) then DeleteEntity(dead) end
                    Wait(100)
                    if inGame then
                        SpawnBot(botIndex)
                        botIndex = botIndex + 1
                        if botIndex > #Config.BotSpawnPositions then botIndex = 1 end
                    end
                end

            elseif currentBot == nil and inGame then
                Wait(100)
                if inGame then
                    SpawnBot(botIndex)
                    botIndex = botIndex + 1
                    if botIndex > #Config.BotSpawnPositions then botIndex = 1 end
                end
            end
        end

        if currentBot ~= nil and DoesEntityExist(currentBot) then
            DeleteEntity(currentBot)
            currentBot = nil
        end
    end)
end

-- Fonction pour spawner un bot
function SpawnBot(index)
    local pos = Config.BotSpawnPositions[index]

    -- Charger le modèle
    local modelHash = GetHashKey(Config.BotModel)
    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 3000 then
            print("^1[Aim Training] ERROR: Model failed to load!^0")
            return
        end
    end

    -- Créer le ped
    currentBot = CreatePed(4, modelHash, pos.x, pos.y, pos.z, pos.heading, false, true)

    -- Attendre que l'entité soit créée
    while not DoesEntityExist(currentBot) do
        Wait(10)
    end

    -- Placer le ped exactement sur le sol
    SetEntityCoordsNoOffset(currentBot, pos.x, pos.y, pos.z, false, false, true)
    PlaceObjectOnGroundProperly(currentBot)

    -- Configuration du ped
    SetEntityAsMissionEntity(currentBot, true, true)
    SetPedCanRagdoll(currentBot, false)
    SetBlockingOfNonTemporaryEvents(currentBot, true)

    -- Figer le ped sur place
    FreezeEntityPosition(currentBot, true)

    -- Auto-kill après 1.5 secondes
    local botEntity = currentBot
    CreateThread(function()
        Wait(1500)
        if DoesEntityExist(botEntity) and botEntity == currentBot then
            SetEntityHealth(botEntity, 0)
        end
    end)
end

-- Fonction pour terminer la partie
function EndGame(completed)
    inGame = false

    -- Supprimer le bot actuel s'il existe
    if currentBot ~= nil and DoesEntityExist(currentBot) then
        DeleteEntity(currentBot)
        currentBot = nil
    end

    -- Retirer l'arme
    RemoveAllPedWeapons(playerPed, true)
    SetPedInfiniteAmmo(playerPed, false, GetHashKey('WEAPON_PISTOL50'))

    -- Cacher le HUD
    SendNUIMessage({ action = 'hideHUD' })

    -- Si la partie est complétée, donner la récompense
    if completed then
        exports['brutal_notify']:SendAlert('Aim Training', 'Partie terminée! ' .. killCount .. ' kills | +$2000', 6000, 'success', true)
        TriggerServerEvent('aim_training:completeGame', killCount)
    else
        exports['brutal_notify']:SendAlert('Aim Training', 'Partie abandonnée. ' .. killCount .. ' kills | Pas de récompense', 5000, 'warning', true)
        TriggerServerEvent('aim_training:exitInstance')
    end

    -- Attendre un peu avant de téléporter
    Wait(1000)

    -- Téléporter le joueur à sa position d'origine
    if originalPosition then
        SetEntityCoords(playerPed, originalPosition.x, originalPosition.y, originalPosition.z, false, false, false, true)
        SetEntityHeading(playerPed, originalHeading)
    end

    killCount = 0
end

-- Fonction pour afficher du texte 2D stylisé
function DrawAdvancedText(x, y, text, scale, font, r, g, b, a, center)
    SetTextFont(font or 4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(2, 2, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    if center then
        SetTextCentre(1)
    end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Variable pour le PED du menu
local menuPed = nil

-- Fonction pour créer le PED du menu
function CreateMenuPed()
    local modelHash = GetHashKey(Config.MenuPedModel)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    menuPed = CreatePed(4, modelHash, Config.MenuPedPosition.x, Config.MenuPedPosition.y, Config.MenuPedPosition.z, Config.MenuPedPosition.heading, false, true)

    PlaceObjectOnGroundProperly(menuPed)
    SetEntityAsMissionEntity(menuPed, true, true)
    SetPedFleeAttributes(menuPed, 0, false)
    SetBlockingOfNonTemporaryEvents(menuPed, true)
    SetEntityInvincible(menuPed, true)
    FreezeEntityPosition(menuPed, true)

    -- Animation idle
    TaskStartScenarioInPlace(menuPed, "WORLD_HUMAN_CLIPBOARD", 0, true)

    SetModelAsNoLongerNeeded(modelHash)
end

-- Thread pour créer le PED au démarrage
CreateThread(function()
    Wait(1000)
    CreateMenuPed()
end)

-- Thread pour gérer l'interaction avec le PED
CreateThread(function()
    while true do
        Wait(0)

        if not inGame then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = vector3(Config.MenuPedPosition.x, Config.MenuPedPosition.y, Config.MenuPedPosition.z)
            local distance = #(playerCoords - pedCoords)

            if distance < 30.0 then
                -- Afficher le label [AIM TRAINING] visible de loin
                DrawText3D(Config.MenuPedPosition.x, Config.MenuPedPosition.y, Config.MenuPedPosition.z + 2.2, '~w~[ AIM TRAINING ]')

                if distance < Config.InteractionDistance then
                    if IsControlJustPressed(0, 38) then -- E key
                        OpenMainMenu()
                    end
                end
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

-- Fonction pour afficher du texte 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
