--[[
    ═══════════════════════════════════════════════════════════
    🖥️ SERVEUR - POINT D'ENTRÉE PRINCIPAL
    ═══════════════════════════════════════════════════════════
    
    Initialisation du serveur et commandes admin.
]]

local SOURCE_FILE = 'server/main.lua'

-- ═══════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════

CreateThread(function()
    -- Attendre que tout soit chargé
    Wait(1000)
    
    Utils.Info('=== CatMouse Racing - Serveur ===')
    Utils.Info('Version: 1.0.0')
    Utils.Info('Debug: ' .. (Config.Debug and 'ACTIVÉ' or 'DÉSACTIVÉ'))
    Utils.Info('Matchmaking: ' .. (Config.Matchmaking.enabled and 'ACTIVÉ' or 'DÉSACTIVÉ'))
    Utils.Info('Buckets disponibles: ' .. #RaceManager.AvailableBuckets)
    Utils.Info('===================================')
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 COMMANDES ADMIN (Debug)
-- ═══════════════════════════════════════════════════════════

if Config.Debug then
    -- Afficher l'état du système
    RegisterCommand('race_status', function(source)
        Utils.Info('=== ÉTAT DU SYSTÈME ===')
        Utils.Info('Buckets disponibles: ' .. #RaceManager.AvailableBuckets)
        Utils.Info('Courses actives: ' .. Utils.TableSize(RaceManager.ActiveRaces))
        Utils.Info('Joueurs en course: ' .. Utils.TableSize(RaceManager.PlayerRaces))
        Utils.Info('Invitations en attente: ' .. Utils.TableSize(RaceManager.PendingInvites))
        Utils.Info('Joueurs en queue: ' .. #Matchmaking.Queue)
        
        -- Détails des courses actives
        for bucketId, session in pairs(RaceManager.ActiveRaces) do
            Utils.Info('  Course #' .. bucketId .. ':')
            Utils.Info('    Status: ' .. Utils.GetStatusName(session.status))
            Utils.Info('    Round: ' .. session.currentRound .. '/' .. session.maxRounds)
            for _, player in ipairs(session.players) do
                Utils.Info('    - ' .. player.name .. ' (' .. Utils.GetRoleName(player.role) .. ') Score: ' .. player.score)
            end
        end
    end, true)
    
    -- Forcer le nettoyage
    RegisterCommand('race_cleanup', function(source)
        Utils.Info('Nettoyage forcé...')
        RaceManager.CleanupExpiredInvites()
        RaceManager.CleanupInactiveRaces()
        Matchmaking.CleanupQueue()
        Utils.Info('Nettoyage terminé')
    end, true)
    
    -- Annuler toutes les courses
    RegisterCommand('race_reset', function(source)
        Utils.Warn('RESET de toutes les courses...')
        
        for bucketId, _ in pairs(RaceManager.ActiveRaces) do
            RaceManager.ReleaseBucket(bucketId)
        end
        
        RaceManager.PendingInvites = {}
        Matchmaking.Queue = {}
        
        Utils.Info('Toutes les courses ont été annulées')
    end, true)
end

-- ═══════════════════════════════════════════════════════════
-- 🛠️ UTILITAIRES SUPPLÉMENTAIRES
-- ═══════════════════════════════════════════════════════════

--- Compte le nombre d'éléments dans une table (pour tables non-séquentielles)
---@param tbl table
---@return number
function Utils.TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end


