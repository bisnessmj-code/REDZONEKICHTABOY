-- ==========================================
-- CLIENT SPECTATOR - SYSTÈME DE SPECTATEUR
-- ==========================================

local SpectatorMode = {
    active = false,
    targetPlayerId = nil,
    availableTargets = {},
    currentIndex = 1,
    myTeam = nil,
    hudVisible = false
}

-- ==========================================
-- ACTIVER LE MODE SPECTATEUR
-- ==========================================

function StartSpectatorMode(team)
    if SpectatorMode.active then return end

    SpectatorMode.active = true
    SpectatorMode.myTeam = team
    SpectatorMode.availableTargets = {}
    SpectatorMode.currentIndex = 1
    SpectatorMode.targetPlayerId = nil

    -- ✅ P1 #6 : Notifier le serveur de l'entrée en spectateur
    TriggerServerEvent('gdt:server:enterSpectator')

    -- Demander la liste des coéquipiers vivants
    TriggerServerEvent('gdt:server:requestAliveTeammates', team)

    -- Notification
    ESX.ShowNotification('Mode Spectateur activé\nUtilise ← → pour changer de joueur')

    -- ✅ P2 #11 : Démarrer les threads dynamiquement (au lieu de while true permanent)
    StartSpectatorThreads()
end

-- ==========================================
-- DÉSACTIVER LE MODE SPECTATEUR
-- ==========================================

function StopSpectatorMode()
    -- ✅ P1 #6 : Toujours notifier le serveur même si déjà inactif client-side
    TriggerServerEvent('gdt:server:exitSpectator')

    if not SpectatorMode.active then return end
    
    -- Arrêter de spectater
    if SpectatorMode.targetPlayerId then
        local playerPed = PlayerPedId()
        NetworkSetInSpectatorMode(false, playerPed)
    end
    
    -- Reset des variables
    SpectatorMode.active = false
    SpectatorMode.targetPlayerId = nil
    SpectatorMode.availableTargets = {}
    SpectatorMode.currentIndex = 1
    SpectatorMode.myTeam = nil
    SpectatorMode.hudVisible = false
    
    -- Masquer le HUD
    SendNUIMessage({
        action = 'hideSpectatorHUD'
    })
    
end

-- ==========================================
-- RECEVOIR LA LISTE DES COÉQUIPIERS VIVANTS
-- ==========================================

RegisterNetEvent('gdt:client:updateAliveTeammates', function(teammates)
    if not SpectatorMode.active then return end
    
    
    SpectatorMode.availableTargets = teammates
    
    if #teammates == 0 then
        -- Plus personne à spectater
        ESX.ShowNotification('Plus aucun coéquipier en vie')
        SpectatorMode.hudVisible = false
        SendNUIMessage({
            action = 'hideSpectatorHUD'
        })
        return
    end
    
    -- Si pas de cible actuelle ou cible morte, prendre la première
    if not SpectatorMode.targetPlayerId or not IsTargetStillAlive(SpectatorMode.targetPlayerId) then
        SpectatorMode.currentIndex = 1
        SpectatePlayer(teammates[1].id)
    end
end)

-- ==========================================
-- SPECTATER UN JOUEUR
-- ==========================================

function SpectatePlayer(targetId)
    if not targetId or targetId == 0 then return end
    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    
    if not targetPed or targetPed == 0 then
        return
    end
    
    
    SpectatorMode.targetPlayerId = targetId
    
    -- Activer le mode spectateur natif
    NetworkSetInSpectatorMode(true, targetPed)
    
    -- Afficher le HUD avec les infos du joueur
    local targetName = GetPlayerName(GetPlayerFromServerId(targetId)) or 'Inconnu'
    SpectatorMode.hudVisible = true
    
    SendNUIMessage({
        action = 'showSpectatorHUD',
        targetName = targetName,
        targetId = targetId,
        currentIndex = SpectatorMode.currentIndex,
        totalTargets = #SpectatorMode.availableTargets
    })
end

-- ==========================================
-- VÉRIFIER SI LA CIBLE EST TOUJOURS VIVANTE
-- ==========================================

function IsTargetStillAlive(targetId)
    for _, teammate in ipairs(SpectatorMode.availableTargets) do
        if teammate.id == targetId then
            return true
        end
    end
    return false
end

-- ==========================================
-- CHANGER DE CIBLE (SUIVANT)
-- ==========================================

function SpectateNext()
    if #SpectatorMode.availableTargets == 0 then return end
    
    SpectatorMode.currentIndex = SpectatorMode.currentIndex + 1
    
    if SpectatorMode.currentIndex > #SpectatorMode.availableTargets then
        SpectatorMode.currentIndex = 1
    end
    
    local nextTarget = SpectatorMode.availableTargets[SpectatorMode.currentIndex]
    SpectatePlayer(nextTarget.id)
end

-- ==========================================
-- CHANGER DE CIBLE (PRÉCÉDENT)
-- ==========================================

function SpectatePrevious()
    if #SpectatorMode.availableTargets == 0 then return end
    
    SpectatorMode.currentIndex = SpectatorMode.currentIndex - 1
    
    if SpectatorMode.currentIndex < 1 then
        SpectatorMode.currentIndex = #SpectatorMode.availableTargets
    end
    
    local prevTarget = SpectatorMode.availableTargets[SpectatorMode.currentIndex]
    SpectatePlayer(prevTarget.id)
end

-- ==========================================
-- ÉVÉNEMENT : DÉSACTIVER LE SPECTATEUR
-- ==========================================

RegisterNetEvent('gdt:client:stopSpectator', function()
    StopSpectatorMode()
end)

-- ==========================================
-- ✅ P3 #12 : FORCER LE MODE SPECTATEUR (reconnexion)
-- ==========================================

RegisterNetEvent('gdt:client:forceSpectator', function(team)
    StartSpectatorMode(team)
end)

-- ==========================================
-- ✅ P2 #11 : THREADS DYNAMIQUES (démarrent/s'arrêtent avec le mode spectateur)
-- ==========================================

function StartSpectatorThreads()
    -- Thread 1 : Gestion des contrôles (tourne uniquement quand spectateur actif)
    Citizen.CreateThread(function()
        while SpectatorMode.active do
            -- Désactiver certains contrôles en mode spectateur
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon wheel
            DisableControlAction(0, 263, true) -- Melee Attack Input
            DisableControlAction(0, 264, true) -- Melee Attack Alternate

            -- Flèche droite (→) pour joueur suivant
            if IsControlJustPressed(0, 175) then -- RIGHT
                SpectateNext()
            end

            -- Flèche gauche (←) pour joueur précédent
            if IsControlJustPressed(0, 174) then -- LEFT
                SpectatePrevious()
            end

            Wait(0)
        end
    end)

    -- Thread 2 : Surveillance des cibles (tourne uniquement quand spectateur actif)
    Citizen.CreateThread(function()
        while SpectatorMode.active do
            Wait(2000)
            if SpectatorMode.active and SpectatorMode.targetPlayerId then
                if not IsTargetStillAlive(SpectatorMode.targetPlayerId) then
                    TriggerServerEvent('gdt:server:requestAliveTeammates', SpectatorMode.myTeam)
                end
            end
        end
    end)
end

-- ==========================================
-- EXPORTS
-- ==========================================

exports('StartSpectatorMode', StartSpectatorMode)
exports('StopSpectatorMode', StopSpectatorMode)
exports('IsInSpectatorMode', function() return SpectatorMode.active end)