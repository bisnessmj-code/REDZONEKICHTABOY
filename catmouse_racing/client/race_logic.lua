--[[
    ═══════════════════════════════════════════════════════════
    🎮 CLIENT - LOGIQUE DE COURSE (VERSION OPTIMISÉE)
    ═══════════════════════════════════════════════════════════
    
    ✅ Game loop optimisée avec Wait adaptatif
    ✅ Pooling des entités et coordonnées
    ✅ Calculs de distance seulement quand nécessaire
]]

local SOURCE_FILE = 'client/race_logic.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 ÉTAT DE LA COURSE
-- ═══════════════════════════════════════════════════════════

local RaceState = {
    isInRace = false,
    status = Constants.RaceStatus.NONE,
    
    currentRound = 0,
    maxRounds = 3,
    
    role = Constants.Role.NONE,
    
    opponentId = nil,
    opponentName = nil,
    
    roundDuration = 0,
    roundStartTimeServer = 0,
    remainingTime = 0,
    
    captureProgress = 0,
    isCapturing = false,
    captureStartTime = 0,
    
    distanceToOpponent = 0,
    
    myScore = 0,
    opponentScore = 0,
    
    bucketId = nil,
    
    isFrozen = false,
    
    vehicleModel = nil,
    spawnPosition = nil
}

-- ✅ NOUVEAU: Cache optimisé avec intervalle de mise à jour
local Cache = {
    playerPed = 0,
    playerCoords = vector3(0, 0, 0),
    opponentCoords = vector3(0, 0, 0),
    vehicleSpeed = 0,
    lastUpdate = 0
}

local CACHE_UPDATE_INTERVAL = 250 -- Mettre à jour toutes les 250ms au lieu de chaque frame

local TRANSITION_DURATION = 6000
local FINAL_RESULT_DURATION = 5000

-- ═══════════════════════════════════════════════════════════
-- 📊 ACCESSEURS
-- ═══════════════════════════════════════════════════════════

function IsInRace()
    return RaceState.isInRace
end

function GetRaceStatus()
    return RaceState.status
end

function GetPlayerRole()
    return RaceState.role
end

function GetRaceState()
    return RaceState
end

--- Reset complet de l'état (pour kick admin)
function ResetRaceState()
    Utils.Debug('Reset complet de l\'état de course', nil, SOURCE_FILE)
    
    RaceState.isInRace = false
    RaceState.status = Constants.RaceStatus.NONE
    RaceState.currentRound = 0
    RaceState.role = Constants.Role.NONE
    RaceState.opponentId = nil
    RaceState.opponentName = nil
    RaceState.roundDuration = 0
    RaceState.roundStartTimeServer = 0
    RaceState.remainingTime = 0
    RaceState.captureProgress = 0
    RaceState.isCapturing = false
    RaceState.captureStartTime = 0
    RaceState.distanceToOpponent = 0
    RaceState.myScore = 0
    RaceState.opponentScore = 0
    RaceState.bucketId = nil
    RaceState.isFrozen = false
    RaceState.vehicleModel = nil
    RaceState.spawnPosition = nil
    
    Cache.playerPed = 0
    Cache.playerCoords = vector3(0, 0, 0)
    Cache.opponentCoords = vector3(0, 0, 0)
    Cache.vehicleSpeed = 0
    Cache.lastUpdate = 0
end

-- ═══════════════════════════════════════════════════════════
-- 🔄 MISE À JOUR DU CACHE (OPTIMISÉE)
-- ═══════════════════════════════════════════════════════════

local function UpdateCache()
    local currentTime = GetGameTimer()
    
    -- ✅ OPTIMISATION: Ne mettre à jour que si l'intervalle est écoulé
    if currentTime - Cache.lastUpdate < CACHE_UPDATE_INTERVAL then
        return false -- Pas de mise à jour effectuée
    end
    
    Cache.playerPed = PlayerPedId()
    Cache.playerCoords = GetEntityCoords(Cache.playerPed)
    
    local vehicle = GetVehiclePedIsIn(Cache.playerPed, false)
    if vehicle ~= 0 then
        Cache.vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    else
        Cache.vehicleSpeed = 0
    end
    
    if RaceState.opponentId then
        local opponentPed = GetPlayerPed(GetPlayerFromServerId(RaceState.opponentId))
        if DoesEntityExist(opponentPed) then
            Cache.opponentCoords = GetEntityCoords(opponentPed)
        end
    end
    
    Cache.lastUpdate = currentTime
    return true -- Mise à jour effectuée
end

-- ═══════════════════════════════════════════════════════════
-- 📏 CALCUL DE DISTANCE
-- ═══════════════════════════════════════════════════════════

local function CalculateDistance()
    if not RaceState.opponentId then return 999999.0 end
    
    RaceState.distanceToOpponent = #(Cache.playerCoords - Cache.opponentCoords)
    
    return RaceState.distanceToOpponent
end

local function CheckEscape()
    if RaceState.role ~= Constants.Role.RUNNER then return false end
    
    local distance = CalculateDistance()
    
    if distance >= Config.Race.escapeDistance then
        Utils.Info('ÉVASION RÉUSSIE !', {
            distance = distance,
            required = Config.Race.escapeDistance
        })
        return true
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 🎯 SYSTÈME DE CAPTURE
-- ═══════════════════════════════════════════════════════════

local function CanCapture()
    if RaceState.role ~= Constants.Role.HUNTER then return false end
    
    local distance = CalculateDistance()
    
    if distance > Config.Race.captureDistance then
        return false
    end
    
    local opponentPed = GetPlayerPed(GetPlayerFromServerId(RaceState.opponentId))
    if DoesEntityExist(opponentPed) then
        local opponentVehicle = GetVehiclePedIsIn(opponentPed, false)
        if opponentVehicle ~= 0 then
            local opponentSpeed = GetEntitySpeed(opponentVehicle) * 3.6
            if opponentSpeed > Config.Race.captureSpeedLimit then
                return false
            end
        end
    end
    
    return true
end

local function UpdateCapture()
    if RaceState.role ~= Constants.Role.HUNTER then return end

    local canCapture = CanCapture()

    -- ✅ NOUVEAU: Si la capture est en cours, on vérifie la zone de tolérance
    local isInToleranceZone = false
    if RaceState.isCapturing then
        local distance = CalculateDistance()

        -- Vérifier la vitesse du fuyard avec la limite de tolérance
        local opponentPed = GetPlayerPed(GetPlayerFromServerId(RaceState.opponentId))
        local speedOk = true
        if DoesEntityExist(opponentPed) then
            local opponentVehicle = GetVehiclePedIsIn(opponentPed, false)
            if opponentVehicle ~= 0 then
                local opponentSpeed = GetEntitySpeed(opponentVehicle) * 3.6
                -- Utilise la vitesse de tolérance pour continuer la capture
                speedOk = opponentSpeed <= Config.Race.captureToleranceSpeedLimit
            end
        end

        -- La capture continue si le fuyard reste proche (distance initiale + tolérance) ET respecte la vitesse de tolérance
        local maxToleranceDistance = Config.Race.captureDistance + Config.Race.captureToleranceDistance
        isInToleranceZone = distance <= maxToleranceDistance and speedOk
    end

    if canCapture or isInToleranceZone then
        if not RaceState.isCapturing then
            RaceState.isCapturing = true
            RaceState.captureStartTime = GetGameTimer()

            Utils.Debug('Capture démarrée', nil, SOURCE_FILE)

            PlaySoundFrontend(-1, Config.Sounds.capture_start.name, Config.Sounds.capture_start.set, true)

            SendNUIMessage({
                action = 'showCaptureBar',
                data = { show = true }
            })
        end

        local elapsed = GetGameTimer() - RaceState.captureStartTime
        RaceState.captureProgress = math.min(100, (elapsed / Config.Race.captureDuration) * 100)

        SendNUIMessage({
            action = 'updateCaptureProgress',
            data = { progress = RaceState.captureProgress }
        })

        if RaceState.captureProgress >= 100 then
            Utils.Info('CAPTURE RÉUSSIE !', nil)

            PlaySoundFrontend(-1, Config.Sounds.capture_complete.name, Config.Sounds.capture_complete.set, true)

            TriggerServerEvent('catmouse:captureComplete')

            RaceState.isCapturing = false
            RaceState.captureProgress = 0
        end

    else
        if RaceState.isCapturing then
            Utils.Debug('Capture interrompue - Fuyard échappé de la zone de tolérance', nil, SOURCE_FILE)

            if Config.Race.captureResetOnEscape then
                RaceState.captureProgress = 0
            end

            RaceState.isCapturing = false

            SendNUIMessage({
                action = 'showCaptureBar',
                data = { show = false }
            })
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ⏱️ GESTION DU TIMER
-- ═══════════════════════════════════════════════════════════

local function UpdateTimer()
    if RaceState.status ~= Constants.RaceStatus.ACTIVE then return end
    
    local currentTimeClient = GetGameTimer()
    local elapsedTime = currentTimeClient - RaceState.roundStartTimeServer
    
    RaceState.remainingTime = math.max(0, RaceState.roundDuration - elapsedTime)
    
    SendNUIMessage({
        action = 'updateTimer',
        data = { 
            remainingTime = RaceState.remainingTime,
            formattedTime = Utils.FormatTime(RaceState.remainingTime)
        }
    })
    
    if RaceState.remainingTime <= 0 then
        Utils.Info('TIMER EXPIRÉ !', nil)
        
        if RaceState.role == Constants.Role.RUNNER then
            TriggerServerEvent('catmouse:timerExpired')
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- 🧊 SYSTÈME DE FREEZE
-- ═══════════════════════════════════════════════════════════

local function FreezePlayer()
    if RaceState.isFrozen then return end
    
    RaceState.isFrozen = true
    Utils.Debug('Joueur freezé', nil, SOURCE_FILE)
    
    CreateThread(function()
        while RaceState.isFrozen do
            local playerPed = PlayerPedId()
            
            FreezeEntityPosition(playerPed, true)
            
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= 0 then
                FreezeEntityPosition(vehicle, true)
                SetVehicleEngineOn(vehicle, false, true, true)
            end
            
            DisableAllControlActions(0)
            
            Wait(0)
        end
    end)
end

local function UnfreezePlayer()
    if not RaceState.isFrozen then return end
    
    RaceState.isFrozen = false
    Utils.Debug('Joueur défreezé', nil, SOURCE_FILE)
    
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        FreezeEntityPosition(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
    end
end

-- ═══════════════════════════════════════════════════════════
-- 🎬 ANIMATIONS
-- ═══════════════════════════════════════════════════════════

function PlayVictoryAnimation()
    Utils.Trace('PlayVictoryAnimation')
    
    local playerPed = PlayerPedId()
    local animDict = Config.Animations.victory.dict
    local animName = Config.Animations.victory.name
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, Config.Animations.victory.duration, 0, 0, false, false, false)
    
    PlaySoundFrontend(-1, Config.Sounds.victory.name, Config.Sounds.victory.set, true)
    
    Utils.Debug('Animation victoire jouée', nil, SOURCE_FILE)
end

function PlayDefeatAnimation()
    Utils.Trace('PlayDefeatAnimation')
    
    local playerPed = PlayerPedId()
    local animDict = Config.Animations.defeat.dict
    local animName = Config.Animations.defeat.name
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, Config.Animations.defeat.duration, 0, 0, false, false, false)
    
    PlaySoundFrontend(-1, Config.Sounds.defeat.name, Config.Sounds.defeat.set, true)
    
    Utils.Debug('Animation défaite jouée', nil, SOURCE_FILE)
end

-- ═══════════════════════════════════════════════════════════
-- 🔄 BOUCLE PRINCIPALE DE JEU (ULTRA-OPTIMISÉE)
-- ═══════════════════════════════════════════════════════════

local gameLoopActive = false

local function StartGameLoop()
    if gameLoopActive then return end
    
    gameLoopActive = true
    Utils.Debug('Game loop démarrée', nil, SOURCE_FILE)
    
    CreateThread(function()
        while gameLoopActive and RaceState.isInRace do
            -- ✅ OPTIMISATION: Mettre à jour le cache (retourne true si mis à jour)
            local cacheUpdated = UpdateCache()
            
            if RaceState.status == Constants.RaceStatus.ACTIVE then
                -- Seulement si le cache a été mis à jour
                if cacheUpdated then
                    CalculateDistance()
                    
                    if RaceState.role == Constants.Role.RUNNER then
                        SendNUIMessage({
                            action = 'updateDistance',
                            data = { distance = RaceState.distanceToOpponent }
                        })
                        
                        if CheckEscape() then
                            TriggerServerEvent('catmouse:escapeComplete')
                        end
                    end
                    
                    if RaceState.role == Constants.Role.HUNTER then
                        UpdateCapture()
                    end
                    
                    UpdateTimer()
                end
            end
            
            -- ✅ OPTIMISATION: Wait adaptatif
            -- Au lieu de Wait(250) constant, on adapte selon le statut
            if RaceState.status == Constants.RaceStatus.ACTIVE then
                Wait(250) -- Course active : 4 fois par seconde
            else
                Wait(500) -- Autre statut : 2 fois par seconde
            end
        end
        
        Utils.Debug('Game loop terminée', nil, SOURCE_FILE)
    end)
end

function StopGameLoop()
    gameLoopActive = false
end

-- ═══════════════════════════════════════════════════════════
-- 📡 ÉVÉNEMENTS (SUITE DANS LE PROCHAIN MESSAGE)
-- ═══════════════════════════════════════════════════════════

RegisterNetEvent(Constants.Events.PREPARE_RACE, function(data)
    Utils.Debug('Event PREPARE_RACE reçu', data, SOURCE_FILE)
    
    SendNUIMessage({
        action = 'hideRoundTransition'
    })
    
    if GetCurrentRaceVehicle() then
        Utils.Debug('Suppression véhicule précédent avant préparation nouveau round', nil, SOURCE_FILE)
        DeleteRaceVehicle()
    end
    
    RaceState.isInRace = true
    RaceState.status = Constants.RaceStatus.PREPARING
    RaceState.currentRound = data.round
    RaceState.maxRounds = data.maxRounds
    RaceState.role = data.role
    RaceState.opponentId = data.opponentId
    RaceState.opponentName = data.opponentName
    RaceState.bucketId = data.bucketId
    RaceState.captureProgress = 0
    RaceState.isCapturing = false
    RaceState.vehicleModel = data.vehicleModel
    RaceState.spawnPosition = data.spawnPosition
    
    Utils.Info('Préparation course', {
        round = RaceState.currentRound,
        role = Utils.GetRoleName(RaceState.role),
        opponent = RaceState.opponentName,
        vehicleModel = RaceState.vehicleModel,
        spawnLocation = data.spawnLocationName or 'N/A',
        spawnCoords = string.format('vec4(%.2f, %.2f, %.2f, %.2f)', 
            RaceState.spawnPosition.x, 
            RaceState.spawnPosition.y, 
            RaceState.spawnPosition.z, 
            RaceState.spawnPosition.w
        )
    })
    
    ShowNotification({
        type = Constants.NotificationType.INFO,
        message = Utils.FormatText(Config.Texts.race_round, RaceState.currentRound, RaceState.maxRounds)
    })
    
    ShowNotification({
        type = Constants.NotificationType.INFO,
        message = 'Votre rôle : ' .. Utils.GetRoleName(RaceState.role)
    })
    
    DoScreenFadeOut(500)
    Wait(500)
    
    local vehicleNetId = SpawnRaceVehicle(RaceState.role, RaceState.vehicleModel, RaceState.spawnPosition)
    
    if not vehicleNetId then
        Utils.Error('Échec spawn véhicule', nil, SOURCE_FILE)
        DoScreenFadeIn(500)
        return
    end
    
    EnableRestrictions()
    
    SendNUIMessage({
        action = 'showRaceHUD',
        data = {
            round = RaceState.currentRound,
            maxRounds = RaceState.maxRounds,
            role = RaceState.role,
            roleName = Utils.GetRoleName(RaceState.role),
            opponentName = RaceState.opponentName,
            myScore = RaceState.myScore,
            opponentScore = RaceState.opponentScore
        }
    })
    
    Wait(500)
    DoScreenFadeIn(500)
    
    TriggerServerEvent('catmouse:clientReady', vehicleNetId)
    
    Utils.Debug('Client prêt - Véhicule spawné', { vehicleNetId = vehicleNetId }, SOURCE_FILE)
end)

RegisterNetEvent(Constants.Events.START_COUNTDOWN, function(data)
    Utils.Debug('Event START_COUNTDOWN reçu', data, SOURCE_FILE)

    RaceState.status = Constants.RaceStatus.COUNTDOWN

    -- Pas de freeze ni de countdown - démarrage immédiat
    SendNUIMessage({
        action = 'showCountdown',
        data = { number = 0, text = 'GO!' }
    })

    PlaySoundFrontend(-1, Config.Sounds.go.name, Config.Sounds.go.set, true)

    Utils.Info('GO !', nil)
end)

RegisterNetEvent(Constants.Events.START_RACE, function(data)
    Utils.Debug('Event START_RACE reçu', data, SOURCE_FILE)
    
    RaceState.status = Constants.RaceStatus.ACTIVE
    RaceState.roundDuration = data.roundDuration
    RaceState.roundStartTimeServer = GetGameTimer()
    
    Utils.Info('Course démarrée !', {
        duration = data.roundDuration / 1000 .. 's'
    })
    
    StartGameLoop()
    
    if StartSecurityMonitoring then
        StartSecurityMonitoring()
        Utils.Debug('Surveillance véhicule activée', nil, SOURCE_FILE)
    end
    
    Wait(1000)
    SendNUIMessage({
        action = 'hideCountdown'
    })
end)

RegisterNetEvent(Constants.Events.ROUND_RESULT, function(data)
    Utils.Debug('Event ROUND_RESULT reçu', data, SOURCE_FILE)
    
    if StopSecurityMonitoring then
        StopSecurityMonitoring()
        Utils.Debug('Surveillance véhicule désactivée', nil, SOURCE_FILE)
    end
    
    RaceState.status = Constants.RaceStatus.ENDING
    
    StopGameLoop()
    
    SendNUIMessage({
        action = 'showCaptureBar',
        data = { show = false }
    })
    
    local myId = GetPlayerServerId(PlayerId())
    RaceState.myScore = data.scores[myId] or 0
    RaceState.opponentScore = data.scores[RaceState.opponentId] or 0
    
    Utils.Debug('Scores mis à jour', {
        myScore = RaceState.myScore,
        opponentScore = RaceState.opponentScore
    }, SOURCE_FILE)
    
    local resultText
    if data.result == Constants.RoundResult.RUNNER_ESCAPED then
        resultText = Config.Texts.result_runner_escaped
    elseif data.result == Constants.RoundResult.RUNNER_CAPTURED then
        resultText = Config.Texts.result_runner_captured
    elseif data.result == Constants.RoundResult.VEHICLE_VIOLATION then
        resultText = 'Infraction véhicule détectée !'
    else
        resultText = Config.Texts.result_time_up
    end
    
    SendNUIMessage({
        action = 'showRoundTransition',
        data = {
            isWinner = data.isWinner,
            message = resultText,
            duration = TRANSITION_DURATION
        }
    })
    
    SendNUIMessage({
        action = 'updateScores',
        data = { 
            myScore = RaceState.myScore,
            opponentScore = RaceState.opponentScore
        }
    })
    
    CreateThread(function()
        if data.isWinner then
            PlayVictoryAnimation()
        else
            PlayDefeatAnimation()
        end
        
        Wait(Config.Animations.victory.duration)
        
        if GetCurrentRaceVehicle() then
            DeleteRaceVehicle()
            Utils.Debug('Véhicule supprimé après animation', nil, SOURCE_FILE)
        else
            Utils.Debug('Véhicule déjà supprimé', nil, SOURCE_FILE)
        end
    end)
end)

RegisterNetEvent(Constants.Events.END_RACE, function(data)
    Utils.Debug('Event END_RACE reçu', data, SOURCE_FILE)
    
    if StopSecurityMonitoring then
        StopSecurityMonitoring()
    end
    
    RaceState.status = Constants.RaceStatus.FINISHED
    
    SendNUIMessage({
        action = 'hideRoundTransition'
    })
    
    local myId = GetPlayerServerId(PlayerId())
    RaceState.myScore = data.finalScores[myId] or 0
    RaceState.opponentScore = data.finalScores[data.winnerId == myId and RaceState.opponentId or data.winnerId] or 0
    
    local isForfeit = data.disconnection or data.forfeit or data.adminKick
    local forfeitReason = ''
    
    if data.adminKick then
        forfeitReason = '⚠️ Adversaire expulsé par un admin'
    elseif data.disconnection then
        forfeitReason = Utils.FormatText(Config.Texts.player_disconnected, data.disconnectedPlayerName or RaceState.opponentName)
    elseif data.forfeit then
        forfeitReason = Utils.FormatText(Config.Texts.player_quit, data.quitterName or RaceState.opponentName)
    end
    
    Utils.Info('Match terminé', {
        isWinner = data.isWinner,
        winnerName = data.winnerName,
        myScore = RaceState.myScore,
        opponentScore = RaceState.opponentScore,
        forfeit = isForfeit,
        reason = forfeitReason
    })
    
    if isForfeit then
        ShowNotification({
            type = data.isWinner and Constants.NotificationType.SUCCESS or Constants.NotificationType.WARNING,
            message = forfeitReason .. ' - ' .. (data.isWinner and Config.Texts.win_by_forfeit or Config.Texts.lose_by_forfeit)
        })
    else
        ShowNotification({
            type = data.isWinner and Constants.NotificationType.SUCCESS or Constants.NotificationType.ERROR,
            message = Utils.FormatText(Config.Texts.result_final_winner, data.winnerName)
        })
    end
    
    SendNUIMessage({
        action = 'showFinalResult',
        data = {
            isWinner = data.isWinner,
            winnerName = data.winnerName,
            myScore = RaceState.myScore,
            opponentScore = RaceState.opponentScore,
            myName = GetPlayerName(PlayerId()),
            opponentName = RaceState.opponentName,
            forfeit = isForfeit,
            forfeitReason = forfeitReason
        }
    })
    
    Utils.Debug('Attente affichage résultat final (' .. FINAL_RESULT_DURATION .. 'ms)...', nil, SOURCE_FILE)
    Wait(FINAL_RESULT_DURATION)
    
    Utils.Debug('Début du nettoyage post-match', nil, SOURCE_FILE)
    CleanupRace()
    
    ResetRaceState()
    
    SendNUIMessage({
        action = 'hideRaceHUD'
    })
    
    Utils.Debug('Nettoyage complet terminé', nil, SOURCE_FILE)
end)

RegisterNetEvent(Constants.Events.MATCH_FOUND, function()
    PlaySoundFrontend(-1, Config.Sounds.match_found.name, Config.Sounds.match_found.set, true)
end)

-- ═══════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if RaceState.isInRace then
        UnfreezePlayer()
        StopGameLoop()
        CleanupRace()
        TriggerServerEvent(Constants.Events.LEAVE_RACE)
    end
    
    SendNUIMessage({ action = 'hideRoundTransition' })
end)

