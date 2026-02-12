--[[
    ═══════════════════════════════════════════════════════════
    🏆 SERVEUR - ÉVÉNEMENTS LEADERBOARD
    ═══════════════════════════════════════════════════════════
    
    Gère les requêtes de classement ELO.
]]

local SOURCE_FILE = 'server/leaderboard.lua'

-- ═══════════════════════════════════════════════════════════
-- 📊 CACHE DU LEADERBOARD
-- ═══════════════════════════════════════════════════════════

local leaderboardCache = {}
local lastCacheUpdate = 0
local CACHE_DURATION = 30000 -- 30 secondes de cache

-- ═══════════════════════════════════════════════════════════
-- 🔍 RÉCUPÉRATION DU TOP 3
-- ═══════════════════════════════════════════════════════════

--- Récupère le Top 3 depuis la base de données
---@param callback function
local function GetTop3(callback)
    local currentTime = GetGameTimer()
    
    -- Utiliser le cache si valide
    if #leaderboardCache > 0 and (currentTime - lastCacheUpdate) < CACHE_DURATION then
        Utils.Debug('Leaderboard depuis cache', { count = #leaderboardCache }, SOURCE_FILE)
        callback(leaderboardCache)
        return
    end
    
    -- Requête à la BDD (récupère le nom stocké)
    MySQL.Async.fetchAll(
        [[SELECT identifier, name, elo, wins, losses, total_matches 
          FROM catmouse_elo 
          WHERE total_matches > 0 
          ORDER BY elo DESC 
          LIMIT 3]],
        {},
        function(results)
            if results then
                leaderboardCache = {}
                
                for _, row in ipairs(results) do
                    -- Utiliser le nom stocké en BDD (persistant même si déconnecté)
                    local playerName = row.name or 'Joueur'
                    
                    -- Si le joueur est connecté, mettre à jour avec son nom actuel
                    local connectedName = GetPlayerNameFromIdentifier(row.identifier)
                    if connectedName then
                        playerName = connectedName
                    end
                    
                    table.insert(leaderboardCache, {
                        identifier = row.identifier,
                        name = playerName,
                        elo = row.elo,
                        wins = row.wins,
                        losses = row.losses,
                        matches = row.total_matches
                    })
                end
                
                lastCacheUpdate = currentTime
                
                Utils.Debug('Leaderboard mis à jour depuis BDD', { count = #leaderboardCache }, SOURCE_FILE)
                callback(leaderboardCache)
            else
                Utils.Error('Échec récupération leaderboard', nil, SOURCE_FILE)
                callback({})
            end
        end
    )
end

--- Récupère le nom d'un joueur connecté par son identifier
---@param identifier string
---@return string|nil
function GetPlayerNameFromIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifiers = GetPlayerIdentifiers(playerId)
        
        for _, id in ipairs(playerIdentifiers) do
            if id == identifier then
                return GetPlayerName(playerId)
            end
        end
    end
    return nil
end

--- Extrait un nom lisible depuis l'identifier
---@param identifier string
---@return string
function ExtractNameFromIdentifier(identifier)
    -- Essayer de trouver un nom stocké dans la BDD (si tu as une table users)
    -- Sinon, afficher une version courte de l'identifier
    
    if string.find(identifier, 'steam:') then
        return 'Steam_' .. string.sub(identifier, -6)
    elseif string.find(identifier, 'license:') then
        return 'Player_' .. string.sub(identifier, -6)
    elseif string.find(identifier, 'discord:') then
        return 'Discord_' .. string.sub(identifier, -6)
    else
        return 'Player_' .. string.sub(identifier, -6)
    end
end

-- ═══════════════════════════════════════════════════════════
-- 📡 ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

--- Demande du leaderboard par un client
RegisterNetEvent('catmouse:requestLeaderboard', function()
    local source = source
    
    Utils.Debug('Demande leaderboard', { source = source }, SOURCE_FILE)
    
    GetTop3(function(data)
        TriggerClientEvent('catmouse:receiveLeaderboard', source, data)
    end)
end)

--- Invalider le cache (appelé après chaque match)
function InvalidateLeaderboardCache()
    leaderboardCache = {}
    lastCacheUpdate = 0
    Utils.Debug('Cache leaderboard invalidé', nil, SOURCE_FILE)
end

-- Exposer la fonction pour le système ELO
_G.InvalidateLeaderboardCache = InvalidateLeaderboardCache

