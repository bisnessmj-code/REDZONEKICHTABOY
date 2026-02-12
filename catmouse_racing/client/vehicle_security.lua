--[[
    ═══════════════════════════════════════════════════════════
    🛡️ CLIENT - SYSTÈME DE SÉCURITÉ VÉHICULE (ULTRA-OPTIMISÉ)
    ═══════════════════════════════════════════════════════════
    
    ✅ Vérifications espacées (1000ms au lieu de 500ms)
    ✅ Pooling des entités
    ✅ Système anti-spam d'événements
]]

local SOURCE_FILE = 'client/vehicle_security.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES
-- ═══════════════════════════════════════════════════════════

local SecurityState = {
    isMonitoring = false,
    violationReported = false,
    
    isFlipped = false,
    flippedStartTime = 0,
    hasWarned = false,
    
    isAirborne = false,
    airborneStartTime = 0,
    lastGroundZ = 0,
    
    -- ✅ NOUVEAU: Cache pour éviter les recalculs
    cachedVehicle = 0,
    cachedCoords = vector3(0, 0, 0),
    lastCacheUpdate = 0
}

-- ✅ OPTIMISATION: Intervalle de cache augmenté
local CACHE_INTERVAL = 500

-- ✅ OPTIMISATION: Intervalle de vérification augmenté
local CHECK_INTERVAL = 1000 -- 1 seconde au lieu de 500ms

-- ═══════════════════════════════════════════════════════════
-- 🔄 MISE À JOUR DU CACHE
-- ═══════════════════════════════════════════════════════════

local function UpdateSecurityCache()
    local now = GetGameTimer()
    
    if now - SecurityState.lastCacheUpdate < CACHE_INTERVAL then
        return false -- Pas de mise à jour effectuée
    end
    
    local playerPed = PlayerPedId()
    SecurityState.cachedVehicle = GetVehiclePedIsIn(playerPed, false)
    
    if SecurityState.cachedVehicle ~= 0 then
        SecurityState.cachedCoords = GetEntityCoords(SecurityState.cachedVehicle)
    end
    
    SecurityState.lastCacheUpdate = now
    return true -- Mise à jour effectuée
end

-- ═══════════════════════════════════════════════════════════
-- 🔍 DÉTECTION VÉHICULE RETOURNÉ
-- ═══════════════════════════════════════════════════════════

local function CheckFlipped()
    if not Config.VehicleSecurity.flipped.enabled then return false end
    
    UpdateSecurityCache()
    
    if SecurityState.cachedVehicle == 0 then
        SecurityState.isFlipped = false
        SecurityState.hasWarned = false
        return false
    end
    
    local rotation = GetEntityRotation(SecurityState.cachedVehicle, 2)
    local roll = rotation.y
    
    local isCurrentlyFlipped = (roll > 120.0 or roll < -120.0)
    local now = GetGameTimer()
    
    if isCurrentlyFlipped then
        if not SecurityState.isFlipped then
            SecurityState.isFlipped = true
            SecurityState.flippedStartTime = now
            SecurityState.hasWarned = false
        end
        
        local elapsedTime = now - SecurityState.flippedStartTime
        
        if not SecurityState.hasWarned and elapsedTime >= (Config.VehicleSecurity.flipped.gracePeriod / 2) then
            SecurityState.hasWarned = true
            
            ShowNotification({
                type = Constants.NotificationType.WARNING,
                message = Config.Texts.violation_warning_flipped
            })
        end
        
        if elapsedTime >= Config.VehicleSecurity.flipped.gracePeriod then
            return true, 'flipped'
        end
        
    else
        if SecurityState.isFlipped then
            ShowNotification({
                type = Constants.NotificationType.SUCCESS,
                message = '✅ Véhicule redressé !'
            })
        end
        
        SecurityState.isFlipped = false
        SecurityState.hasWarned = false
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════
-- ✈️ DÉTECTION SAUT ABUSIF
-- ═══════════════════════════════════════════════════════════

local function CheckAirborne()
    if not Config.VehicleSecurity.airborne.enabled then return false end
    
    UpdateSecurityCache()
    
    if SecurityState.cachedVehicle == 0 then
        SecurityState.isAirborne = false
        return false
    end
    
    local isOnGround = IsVehicleOnAllWheels(SecurityState.cachedVehicle)
    local now = GetGameTimer()
    
    if not isOnGround and Config.VehicleSecurity.airborne.checkGroundDistance then
        local vehZ = SecurityState.cachedCoords.z
        local groundZ = GetGroundZFor_3dCoord(SecurityState.cachedCoords.x, SecurityState.cachedCoords.y, vehZ, false)
        local heightAboveGround = vehZ - groundZ
        
        if heightAboveGround > Config.VehicleSecurity.airborne.maxAltitude then
            if not SecurityState.isAirborne then
                SecurityState.isAirborne = true
                SecurityState.airborneStartTime = now
                

            end
            
            local airborneTime = now - SecurityState.airborneStartTime
            
            if airborneTime >= Config.VehicleSecurity.airborne.maxDuration then
           return true, 'airborne'
            end
        else
            SecurityState.isAirborne = false
        end
    else
        SecurityState.isAirborne = false
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 💥 DÉTECTION VÉHICULE DÉTRUIT
-- ═══════════════════════════════════════════════════════════

local function CheckDestroyed()
    if not Config.VehicleSecurity.destroyed.enabled then return false end
    
    UpdateSecurityCache()
    
    if SecurityState.cachedVehicle == 0 then return false end
    
    if IsEntityDead(SecurityState.cachedVehicle) or GetVehicleEngineHealth(SecurityState.cachedVehicle) <= 0 then

        return true, 'destroyed'
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 🌊 DÉTECTION VÉHICULE DANS L'EAU
-- ═══════════════════════════════════════════════════════════

local function CheckInWater()
    UpdateSecurityCache()
    
    if SecurityState.cachedVehicle == 0 then return false end
    
    if IsEntityInWater(SecurityState.cachedVehicle) then
        local submergedLevel = GetEntitySubmergedLevel(SecurityState.cachedVehicle)
        
        if submergedLevel > 0.8 then
      return true, 'destroyed'
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 🚨 SIGNALEMENT D'INFRACTION AU SERVEUR
-- ═══════════════════════════════════════════════════════════

local function ReportViolation(violationType)
    if SecurityState.violationReported then
       return
    end
    
    SecurityState.violationReported = true
    

    -- Son d'alerte
    PlaySoundFrontend(-1, Config.Sounds.violation.name, Config.Sounds.violation.set, true)
    
    -- Notification
    local message = Config.Texts['violation_' .. violationType] or 'Infraction détectée !'
    ShowNotification({
        type = Constants.NotificationType.ERROR,
        message = message
    })
    
    -- Envoyer l'événement au serveur
    TriggerServerEvent('catmouse:vehicleViolation', violationType)
    
    
    -- Arrêter la surveillance
    StopSecurityMonitoring()
end

-- ═══════════════════════════════════════════════════════════
-- 🔁 BOUCLE DE SURVEILLANCE (OPTIMISÉE)
-- ═══════════════════════════════════════════════════════════

local function StartSecurityLoop()

    
    CreateThread(function()
        while SecurityState.isMonitoring do
            local hasViolation = false
            local violationType = nil
            
            -- ✅ OPTIMISATION: Mettre à jour le cache avant les vérifications
            UpdateSecurityCache()
            
            -- 1. Véhicule détruit
            hasViolation, violationType = CheckDestroyed()
            if hasViolation then
                ReportViolation(violationType)
                break
            end
            
            -- 2. Véhicule dans l'eau
            hasViolation, violationType = CheckInWater()
            if hasViolation then
                ReportViolation(violationType)
                break
            end
            
            -- 3. Véhicule retourné
            hasViolation, violationType = CheckFlipped()
            if hasViolation then
                ReportViolation(violationType)
                break
            end
            
            -- 4. Saut abusif
            hasViolation, violationType = CheckAirborne()
            if hasViolation then
                ReportViolation(violationType)
                break
            end
            
            -- ✅ OPTIMISATION: Wait augmenté à 1000ms
            Wait(CHECK_INTERVAL)
        end
        
    end)
end

-- ═══════════════════════════════════════════════════════════
-- 🎮 CONTRÔLE DU SYSTÈME
-- ═══════════════════════════════════════════════════════════

function StartSecurityMonitoring()
    if not Config.VehicleSecurity.enabled then
        return
    end
    
    if SecurityState.isMonitoring then
        return
    end
    
    
    SecurityState.isMonitoring = true
    SecurityState.violationReported = false
    SecurityState.isFlipped = false
    SecurityState.flippedStartTime = 0
    SecurityState.hasWarned = false
    SecurityState.isAirborne = false
    SecurityState.airborneStartTime = 0
    SecurityState.lastGroundZ = 0
    SecurityState.cachedVehicle = 0
    SecurityState.cachedCoords = vector3(0, 0, 0)
    SecurityState.lastCacheUpdate = 0
    
    StartSecurityLoop()
end

function StopSecurityMonitoring()
    if not SecurityState.isMonitoring then return end
    

    
    SecurityState.isMonitoring = false
    SecurityState.isFlipped = false
    SecurityState.hasWarned = false
    SecurityState.isAirborne = false
    SecurityState.violationReported = false
    SecurityState.cachedVehicle = 0
    SecurityState.cachedCoords = vector3(0, 0, 0)
end

function IsSecurityMonitoring()
    return SecurityState.isMonitoring
end

-- ═══════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    StopSecurityMonitoring()
end)


