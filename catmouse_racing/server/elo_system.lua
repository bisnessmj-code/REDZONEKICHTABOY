--[[
    ═══════════════════════════════════════════════════════════
    🏆 SERVEUR - SYSTÈME ELO
    ═══════════════════════════════════════════════════════════
    
    Gestion du système de classement ELO.
    Calcul des points, mise à jour BDD, historique.
]]

local SOURCE_FILE = 'server/elo_system.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 MODULE ELO
-- ═══════════════════════════════════════════════════════════

EloSystem = EloSystem or {}

-- Cache local des ELO (évite les requêtes répétitives)
EloSystem.Cache = {}

-- ═══════════════════════════════════════════════════════════
-- 🔢 CALCUL ELO (Algorithme standard)
-- ═══════════════════════════════════════════════════════════

--- Calcul de la probabilité de victoire attendue
---@param eloA number ELO du joueur A
---@param eloB number ELO du joueur B
---@return number Probabilité entre 0 et 1
function EloSystem.ExpectedScore(eloA, eloB)
    return 1 / (1 + math.pow(10, (eloB - eloA) / 400))
end

--- Calcul du changement d'ELO après un match
---@param winnerElo number ELO du gagnant
---@param loserElo number ELO du perdant
---@return number Points à échanger
function EloSystem.CalculateEloChange(winnerElo, loserElo)
    local K = Config.Elo.kFactor
    
    -- K-Factor dynamique selon l'ELO (optionnel)
    if Config.Elo.dynamicKFactor then
        -- Nouveaux joueurs (< 10 matchs) ont un K plus élevé
        -- Joueurs hauts ELO ont un K plus bas
        if winnerElo < 1200 then
            K = Config.Elo.kFactorNew
        elseif winnerElo > 2000 then
            K = Config.Elo.kFactorHigh
        end
    end
    
    -- Probabilité de victoire attendue du gagnant
    local expectedWinner = EloSystem.ExpectedScore(winnerElo, loserElo)
    
    -- Changement d'ELO (arrondi)
    local change = math.floor(K * (1 - expectedWinner) + 0.5)
    
    -- Appliquer les limites min/max
    change = math.max(Config.Elo.minChange, math.min(Config.Elo.maxChange, change))
    
    Utils.Debug('Calcul ELO', {
        winnerElo = winnerElo,
        loserElo = loserElo,
        expectedWinner = string.format('%.2f', expectedWinner),
        kFactor = K,
        change = change
    }, SOURCE_FILE)
    
    return change
end

-- ═══════════════════════════════════════════════════════════
-- 🔍 RÉCUPÉRATION DE L'IDENTIFIANT
-- ═══════════════════════════════════════════════════════════

--- Récupère l'identifiant unique d'un joueur
---@param playerId number Server ID du joueur
---@return string|nil Identifiant ou nil si non trouvé
function EloSystem.GetPlayerIdentifier(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    
    if not identifiers then
        Utils.Error('Impossible de récupérer les identifiants', { playerId = playerId }, SOURCE_FILE)
        return nil
    end
    
    -- Priorité: license > steam > discord > fivem
    local priorityOrder = Config.Elo.identifierPriority or { 'license', 'steam', 'discord', 'fivem' }
    
    for _, prefix in ipairs(priorityOrder) do
        for _, identifier in ipairs(identifiers) do
            if string.find(identifier, prefix .. ':') then
                Utils.Debug('Identifiant trouvé', { 
                    playerId = playerId, 
                    type = prefix,
                    identifier = identifier 
                }, SOURCE_FILE)
                return identifier
            end
        end
    end
    
    -- Fallback: premier identifiant disponible
    if #identifiers > 0 then
        Utils.Warn('Utilisation du fallback identifier', { 
            playerId = playerId, 
            identifier = identifiers[1] 
        }, SOURCE_FILE)
        return identifiers[1]
    end
    
    Utils.Error('Aucun identifiant trouvé', { playerId = playerId }, SOURCE_FILE)
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- 💾 OPÉRATIONS BASE DE DONNÉES
-- ═══════════════════════════════════════════════════════════

--- Récupère ou crée l'ELO d'un joueur
---@param identifier string Identifiant du joueur
---@param playerName string|nil Nom du joueur (optionnel)
---@param callback function Callback avec les données
function EloSystem.GetOrCreatePlayer(identifier, playerName, callback)
    -- Support de l'ancienne signature (2 arguments)
    if type(playerName) == 'function' then
        callback = playerName
        playerName = nil
    end
    
    if not identifier then
        callback(nil)
        return
    end
    
    -- Vérifier le cache d'abord
    if EloSystem.Cache[identifier] then
        Utils.Debug('ELO depuis cache', { identifier = identifier, elo = EloSystem.Cache[identifier].elo }, SOURCE_FILE)
        callback(EloSystem.Cache[identifier])
        return
    end
    
    -- Requête SELECT
    MySQL.Async.fetchAll(
        'SELECT * FROM catmouse_elo WHERE identifier = ?',
        { identifier },
        function(results)
            if results and #results > 0 then
                -- Joueur existant
                local playerData = results[1]
                EloSystem.Cache[identifier] = playerData
                
                -- Mettre à jour le nom si fourni et différent
                if playerName and playerName ~= playerData.name then
                    MySQL.Async.execute(
                        'UPDATE catmouse_elo SET name = ? WHERE identifier = ?',
                        { playerName, identifier }
                    )
                    playerData.name = playerName
                    EloSystem.Cache[identifier].name = playerName
                    Utils.Debug('Nom joueur mis à jour', { identifier = identifier, name = playerName }, SOURCE_FILE)
                end
                
                Utils.Debug('ELO récupéré depuis BDD', { 
                    identifier = identifier, 
                    elo = playerData.elo,
                    name = playerData.name
                }, SOURCE_FILE)
                
                callback(playerData)
            else
                -- Nouveau joueur - Création
                local finalName = playerName or 'Joueur'
                
                MySQL.Async.insert(
                    'INSERT INTO catmouse_elo (identifier, name, elo) VALUES (?, ?, ?)',
                    { identifier, finalName, Config.Elo.defaultElo },
                    function(insertId)
                        if insertId then
                            local newPlayerData = {
                                id = insertId,
                                identifier = identifier,
                                name = finalName,
                                elo = Config.Elo.defaultElo,
                                wins = 0,
                                losses = 0,
                                total_matches = 0,
                                win_streak = 0,
                                best_streak = 0
                            }
                            
                            EloSystem.Cache[identifier] = newPlayerData
                            
                            Utils.Info('Nouveau joueur créé dans le système ELO', { 
                                identifier = identifier,
                                name = finalName,
                                elo = Config.Elo.defaultElo 
                            })
                            
                            callback(newPlayerData)
                        else
                            Utils.Error('Échec création joueur ELO', { identifier = identifier }, SOURCE_FILE)
                            callback(nil)
                        end
                    end
                )
            end
        end
    )
end

--- Met à jour l'ELO après un match
---@param winnerIdentifier string Identifiant du gagnant
---@param loserIdentifier string Identifiant du perdant
---@param winnerName string Nom du gagnant
---@param loserName string Nom du perdant
---@param winnerScore number Score du gagnant
---@param loserScore number Score du perdant
---@param callback? function Callback optionnel
function EloSystem.UpdateMatchResult(winnerIdentifier, loserIdentifier, winnerName, loserName, winnerScore, loserScore, callback)
    Utils.Debug('UpdateMatchResult appelé', {
        winner = winnerIdentifier,
        winnerName = winnerName,
        loser = loserIdentifier,
        loserName = loserName,
        score = winnerScore .. '-' .. loserScore
    }, SOURCE_FILE)
    
    -- Récupérer les données des deux joueurs (avec leur nom)
    EloSystem.GetOrCreatePlayer(winnerIdentifier, winnerName, function(winnerData)
        if not winnerData then
            Utils.Error('Données gagnant introuvables', { identifier = winnerIdentifier }, SOURCE_FILE)
            if callback then callback(false) end
            return
        end
        
        EloSystem.GetOrCreatePlayer(loserIdentifier, loserName, function(loserData)
            if not loserData then
                Utils.Error('Données perdant introuvables', { identifier = loserIdentifier }, SOURCE_FILE)
                if callback then callback(false) end
                return
            end
            
            -- Calculer le changement d'ELO
            local eloChange = EloSystem.CalculateEloChange(winnerData.elo, loserData.elo)
            
            -- Nouveaux ELO
            local winnerNewElo = winnerData.elo + eloChange
            local loserNewElo = math.max(0, loserData.elo - eloChange) -- Minimum 0
            
            -- Nouvelle série de victoires
            local winnerNewStreak = (winnerData.win_streak or 0) + 1
            local winnerBestStreak = math.max(winnerData.best_streak or 0, winnerNewStreak)
            
            Utils.Info('Mise à jour ELO', {
                winner = string.format('%s (%s): %d → %d (+%d)', winnerName, winnerIdentifier, winnerData.elo, winnerNewElo, eloChange),
                loser = string.format('%s (%s): %d → %d (-%d)', loserName, loserIdentifier, loserData.elo, loserNewElo, eloChange)
            })
            
            -- Mise à jour du gagnant (avec le nom)
            MySQL.Async.execute(
                [[UPDATE catmouse_elo SET 
                    name = ?,
                    elo = ?,
                    wins = wins + 1,
                    total_matches = total_matches + 1,
                    win_streak = ?,
                    best_streak = ?,
                    last_match = NOW()
                WHERE identifier = ?]],
                { winnerName, winnerNewElo, winnerNewStreak, winnerBestStreak, winnerIdentifier },
                function(rowsChanged)
                    if rowsChanged > 0 then
                        -- Mettre à jour le cache
                        if EloSystem.Cache[winnerIdentifier] then
                            EloSystem.Cache[winnerIdentifier].name = winnerName
                            EloSystem.Cache[winnerIdentifier].elo = winnerNewElo
                            EloSystem.Cache[winnerIdentifier].wins = (EloSystem.Cache[winnerIdentifier].wins or 0) + 1
                            EloSystem.Cache[winnerIdentifier].total_matches = (EloSystem.Cache[winnerIdentifier].total_matches or 0) + 1
                            EloSystem.Cache[winnerIdentifier].win_streak = winnerNewStreak
                            EloSystem.Cache[winnerIdentifier].best_streak = winnerBestStreak
                        end
                        
                        Utils.Debug('ELO gagnant mis à jour', { identifier = winnerIdentifier, name = winnerName }, SOURCE_FILE)
                    end
                end
            )
            
            -- Mise à jour du perdant (avec le nom)
            MySQL.Async.execute(
                [[UPDATE catmouse_elo SET 
                    name = ?,
                    elo = ?,
                    losses = losses + 1,
                    total_matches = total_matches + 1,
                    win_streak = 0,
                    last_match = NOW()
                WHERE identifier = ?]],
                { loserName, loserNewElo, loserIdentifier },
                function(rowsChanged)
                    if rowsChanged > 0 then
                        -- Mettre à jour le cache
                        if EloSystem.Cache[loserIdentifier] then
                            EloSystem.Cache[loserIdentifier].name = loserName
                            EloSystem.Cache[loserIdentifier].elo = loserNewElo
                            EloSystem.Cache[loserIdentifier].losses = (EloSystem.Cache[loserIdentifier].losses or 0) + 1
                            EloSystem.Cache[loserIdentifier].total_matches = (EloSystem.Cache[loserIdentifier].total_matches or 0) + 1
                            EloSystem.Cache[loserIdentifier].win_streak = 0
                        end
                        
                        Utils.Debug('ELO perdant mis à jour', { identifier = loserIdentifier, name = loserName }, SOURCE_FILE)
                    end
                end
            )
            
            -- Enregistrer l'historique du match
            if Config.Elo.saveHistory then
                MySQL.Async.insert(
                    [[INSERT INTO catmouse_match_history 
                        (winner_identifier, loser_identifier, winner_elo_before, winner_elo_after, 
                         loser_elo_before, loser_elo_after, elo_change, winner_score, loser_score)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]],
                    { 
                        winnerIdentifier, loserIdentifier, 
                        winnerData.elo, winnerNewElo,
                        loserData.elo, loserNewElo,
                        eloChange, winnerScore, loserScore 
                    },
                    function(insertId)
                        if insertId then
                            Utils.Debug('Historique match enregistré', { matchId = insertId }, SOURCE_FILE)
                        end
                    end
                )
            end
            
            if callback then callback(true, eloChange, winnerNewElo, loserNewElo) end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════
-- 📊 FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════

--- Récupère l'ELO d'un joueur par son Server ID
---@param playerId number Server ID
---@param callback function Callback avec l'ELO
function EloSystem.GetPlayerElo(playerId, callback)
    local identifier = EloSystem.GetPlayerIdentifier(playerId)
    
    if not identifier then
        callback(Config.Elo.defaultElo)
        return
    end
    
    EloSystem.GetOrCreatePlayer(identifier, function(playerData)
        if playerData then
            callback(playerData.elo)
        else
            callback(Config.Elo.defaultElo)
        end
    end)
end

--- Récupère les stats complètes d'un joueur
---@param playerId number Server ID
---@param callback function Callback avec les stats
function EloSystem.GetPlayerStats(playerId, callback)
    local identifier = EloSystem.GetPlayerIdentifier(playerId)
    
    if not identifier then
        callback(nil)
        return
    end
    
    EloSystem.GetOrCreatePlayer(identifier, callback)
end

--- Invalide le cache d'un joueur (forcer refresh)
---@param identifier string
function EloSystem.InvalidateCache(identifier)
    EloSystem.Cache[identifier] = nil
    Utils.Debug('Cache invalidé', { identifier = identifier }, SOURCE_FILE)
end

--- Nettoie tout le cache
function EloSystem.ClearCache()
    EloSystem.Cache = {}
    Utils.Debug('Cache ELO vidé', nil, SOURCE_FILE)
end

-- ═══════════════════════════════════════════════════════════
-- 🔌 ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

-- Nettoyer le cache quand un joueur se déconnecte
AddEventHandler('playerDropped', function()
    local playerId = source
    local identifier = EloSystem.GetPlayerIdentifier(playerId)
    
    if identifier then
        -- Optionnel: garder en cache pendant un moment pour les reconnexions
        SetTimeout(300000, function() -- 5 minutes
            EloSystem.InvalidateCache(identifier)
        end)
    end
end)

