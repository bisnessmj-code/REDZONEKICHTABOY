--[[
    ═══════════════════════════════════════════════════════════
    🛡️ SERVEUR - GESTIONNAIRE D'INFRACTIONS VÉHICULE (ULTIME)
    ═══════════════════════════════════════════════════════════
    
    ✅ VERSION FINALE avec logs maximaux
]]

local SOURCE_FILE = 'server/vehicle_violations.lua'

-- ═══════════════════════════════════════════════════════════
-- 📡 RÉCEPTION DES INFRACTIONS
-- ═══════════════════════════════════════════════════════════

RegisterNetEvent('catmouse:vehicleViolation', function(violationType)
    local source = source
    local playerName = GetPlayerName(source) or 'Joueur'

    
    -- Validation du type d'infraction
    local validTypes = { 'flipped', 'airborne', 'destroyed' }
    local isValid = false
    for _, validType in ipairs(validTypes) do
        if violationType == validType then
            isValid = true
            break
        end
    end
    
    if not isValid then
        return
    end

    
    -- Récupérer la session du joueur
    local bucketId = RaceManager.PlayerRaces[source]
    
    if not bucketId then
        return
    end
    
    
    local session = RaceManager.ActiveRaces[bucketId]
    
    if not session then
        return
    end
    
    -- Vérifier que la course est active
    if session.status ~= Constants.RaceStatus.ACTIVE then
        return
    end
    
    
    -- Récupérer les données des joueurs
    local violator = nil
    local opponent = nil
    
    for _, playerData in ipairs(session.players) do
        if playerData.id == source then
            violator = playerData
        else
            opponent = playerData
        end
    end
    
    if not violator or not opponent then
       return
    end
    
    
    -- Terminer le round avec victoire de l'adversaire
    RaceManager.EndRound(bucketId, Constants.RoundResult.VEHICLE_VIOLATION, opponent.id)
    
end)
