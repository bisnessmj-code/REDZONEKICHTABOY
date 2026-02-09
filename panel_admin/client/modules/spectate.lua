--[[
    Spectate - Panel Admin Fight League
    Mode spectateur
]]

local Spectate = {}

-- État du spectate
local isSpectating = false
local spectateTarget = nil
local originalCoords = nil
local originalBucket = 0
local spectateCamera = nil

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Démarrer le spectate
function Spectate.Start(targetId)
    if isSpectating then
        Spectate.Stop()
    end

    local playerPed = PlayerPedId()

    -- Sauvegarder la position originale
    originalCoords = GetEntityCoords(playerPed)

    -- Demander au serveur de changer notre instance et obtenir les coords de la cible
    ESX.TriggerServerCallback('panel:spectateStart', function(result)
        if not result.success then
            TriggerEvent('panel:notification', {
                type = 'error',
                title = 'Erreur',
                message = result.error or 'Impossible de spectate ce joueur'
            })
            return
        end

        -- Sauvegarder le bucket original
        originalBucket = result.originalBucket

        -- Rendre invisible et invincible AVANT de teleporter
        SetEntityVisible(playerPed, false, false)
        SetEntityInvincible(playerPed, true)
        SetEntityCollision(playerPed, false, false)

        -- Teleporter aux coordonnees de la cible (recues du serveur)
        -- Cela permet de charger la zone et le joueur dans la nouvelle instance
        if result.targetCoords then
            SetEntityCoords(playerPed, result.targetCoords.x, result.targetCoords.y, result.targetCoords.z, false, false, false, false)
        end

        -- Attendre que l'instance se charge et que le joueur soit visible
        local attempts = 0
        local maxAttempts = 50 -- 5 secondes max
        local targetPed = nil

        while attempts < maxAttempts do
            Wait(100)
            attempts = attempts + 1

            targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))

            if DoesEntityExist(targetPed) then
                break
            end

            -- Afficher un message de chargement
            if attempts % 10 == 0 and Config.Debug then
                print('[SPECTATE] Attente du chargement de l\'instance... (' .. attempts .. '/' .. maxAttempts .. ')')
            end
        end

        if not DoesEntityExist(targetPed) then
            -- Restaurer les etats et l'instance originale si echec
            SetEntityVisible(playerPed, true, false)
            SetEntityInvincible(playerPed, false)
            SetEntityCollision(playerPed, true, true)
            TriggerServerEvent('panel:spectateRestore', originalBucket)

            -- Retourner a la position originale
            if originalCoords then
                SetEntityCoords(playerPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
            end

            TriggerEvent('panel:notification', {
                type = 'error',
                title = 'Erreur',
                message = 'Impossible de charger le joueur dans l\'instance (timeout)'
            })
            return
        end

        isSpectating = true
        spectateTarget = targetId

        -- Teleporter 15 metres sous le joueur pour eviter de tomber dans le vide
        local targetCoords = GetEntityCoords(targetPed)
        SetEntityCoords(playerPed, targetCoords.x, targetCoords.y, targetCoords.z - 15.0, false, false, false, false)

        -- Figer le ped pour qu'il ne tombe pas
        FreezeEntityPosition(playerPed, true)

        -- Petit delai avant d'activer le mode spectateur
        Wait(100)

        -- Attacher au joueur en mode spectateur
        NetworkSetInSpectatorMode(true, targetPed)

        -- Notifier
        local instanceInfo = result.targetBucket ~= 0 and ' (Instance: ' .. result.targetBucket .. ')' or ''
        TriggerEvent('panel:notification', {
            type = 'info',
            title = 'Spectate',
            message = 'Mode spectateur active' .. instanceInfo .. '. Appuyez sur SUPPR, RETOUR ou ECHAP pour quitter.'
        })

        -- Log serveur
        TriggerServerEvent('panel:log', 'spectate_start', targetId)
    end, targetId)

    return true
end

-- Arrêter le spectate
function Spectate.Stop()
    if not isSpectating then return false end

    local playerPed = PlayerPedId()

    -- Désactiver le mode spectateur
    NetworkSetInSpectatorMode(false, playerPed)

    -- Nettoyer les états AVANT de remettre les flags (ordre important)
    isSpectating = false
    local savedTarget = spectateTarget
    local savedCoords = originalCoords
    local savedBucket = originalBucket
    spectateTarget = nil
    originalCoords = nil
    originalBucket = 0

    -- Petit délai pour laisser le moteur nettoyer
    Wait(100)

    -- Degeler le ped
    FreezeEntityPosition(playerPed, false)

    -- Restaurer la visibilité
    SetEntityVisible(playerPed, true, false)
    SetEntityInvincible(playerPed, false)
    SetEntityCollision(playerPed, true, true)

    -- Restaurer l'instance originale via le serveur
    TriggerServerEvent('panel:spectateRestore', savedBucket)

    -- Petit delai pour le changement d'instance
    Wait(100)

    -- Retourner à la position originale
    if savedCoords then
        SetEntityCoords(playerPed, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
        Wait(50) -- Attendre que le TP soit effectif
    end

    -- Log serveur
    if savedTarget then
        TriggerServerEvent('panel:log', 'spectate_end', savedTarget)
    end

    TriggerEvent('panel:notification', {
        type = 'info',
        title = 'Spectate',
        message = 'Mode spectateur desactive'
    })

    return true
end

-- Toggle spectate
function Spectate.Toggle(targetId)
    if isSpectating then
        return Spectate.Stop()
    else
        return Spectate.Start(targetId)
    end
end

-- Vérifier si en spectate
function Spectate.IsSpectating()
    return isSpectating
end

-- Obtenir la cible actuelle
function Spectate.GetTarget()
    return spectateTarget
end

-- ══════════════════════════════════════════════════════════════
-- COMMANDE POUR QUITTER LE SPECTATE
-- ══════════════════════════════════════════════════════════════

-- Commande +/- pour RegisterKeyMapping
RegisterCommand('+spectate_stop', function()
    if isSpectating then
        Spectate.Stop()
    end
end, false)

RegisterCommand('-spectate_stop', function() end, false)

-- Enregistrer la touche DELETE pour quitter le spectate (configurable dans Paramètres > Raccourcis clavier)
RegisterKeyMapping('+spectate_stop', 'Quitter le mode Spectate', 'keyboard', 'DELETE')

-- ══════════════════════════════════════════════════════════════
-- THREAD DE SUIVI
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        if isSpectating and spectateTarget then
            -- CORRECTION: Sauvegarder spectateTarget localement pour éviter race condition
            local currentTarget = spectateTarget

            -- Double vérification que la cible n'est pas devenue nil
            if not currentTarget then
                Wait(1000)
                goto continue
            end

            Wait(0) -- Mise à jour rapide quand en spectate
            local targetPed = GetPlayerPed(GetPlayerFromServerId(currentTarget))

            -- Vérifier si le joueur existe toujours
            if not DoesEntityExist(targetPed) then
                Spectate.Stop()
                TriggerEvent('panel:notification', {
                    type = 'warning',
                    title = 'Spectate',
                    message = 'Le joueur s\'est déconnecté'
                })
                goto continue
            end

            -- Maintenir le ped du staff 15 metres sous le joueur pour eviter qu'il tombe
            local playerPed = PlayerPedId()
            local targetCoords = GetEntityCoords(targetPed)
            SetEntityCoords(playerPed, targetCoords.x, targetCoords.y, targetCoords.z - 15.0, false, false, false, false)

            -- Détecter les touches supplémentaires (Backspace et Echap)
            -- 177 = INPUT_CELLPHONE_CANCEL (Backspace)
            -- 200 = INPUT_FRONTEND_PAUSE_ALTERNATE (Echap - quand le menu pause n'est pas ouvert)
            DisableControlAction(0, 200, true) -- Désactiver le menu pause temporairement

            if IsDisabledControlJustPressed(0, 200) then -- Echap
                Spectate.Stop()
                goto continue
            elseif IsControlJustPressed(0, 177) then -- Backspace
                Spectate.Stop()
                goto continue
            end

            -- Afficher les infos du joueur
            local health = GetEntityHealth(targetPed)
            local armor = GetPedArmour(targetPed)

            -- HUD simple avec instructions (CORRIGÉ: ajout de SetTextCentre + protection nil)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.0, 0.4)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(1)
            SetTextEntry('STRING')
            -- Protection contre nil avec tostring()
            AddTextComponentString('~b~SPECTATE~w~ | ID: ~y~' .. tostring(currentTarget) .. '~w~ | HP: ~g~' .. health .. '~w~ | Armure: ~b~' .. armor)
            DrawText(0.5, 0.93)

            -- Instructions pour quitter (CORRIGÉ: ajout de SetTextCentre)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.0, 0.35)
            SetTextColour(200, 200, 200, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(1)
            SetTextEntry('STRING')
            AddTextComponentString('~w~Appuyez sur ~r~SUPPR~w~, ~r~RETOUR~w~ ou ~r~ECHAP~w~ pour quitter')
            DrawText(0.5, 0.96)
        else
            Wait(1000) -- Attendre plus longtemps quand pas en spectate pour économiser les ressources
        end

        ::continue::
    end
end)

-- ══════════════════════════════════════════════════════════════
-- EVENTS
-- ══════════════════════════════════════════════════════════════

-- Démarrer spectate depuis NUI
RegisterNetEvent('panel:spectate', function(targetId)
    -- Désactiver le noclip si actif avant de spectater
    if _G.Noclip and _G.Noclip.IsActive() then
        _G.Noclip.Disable()
        Wait(500)
    end
    Spectate.Start(targetId)
end)

-- Arrêter spectate depuis NUI
RegisterNetEvent('panel:stopSpectate', function()
    Spectate.Stop()
end)

-- NUI Callback
RegisterNUICallback('spectate', function(data, cb)
    -- Désactiver le noclip si actif avant de spectater
    if _G.Noclip and _G.Noclip.IsActive() then
        _G.Noclip.Disable()
        Wait(500)
    end
    local success = Spectate.Start(data.targetId)
    cb({success = success})
end)

RegisterNUICallback('stopSpectate', function(data, cb)
    local success = Spectate.Stop()
    cb({success = success})
end)

-- Export global
_G.Spectate = Spectate
