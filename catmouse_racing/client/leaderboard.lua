--[[
    ═══════════════════════════════════════════════════════════
    🏆 CLIENT - LEADERBOARD 3D FLOTTANT (VERSION STABLE)
    ═══════════════════════════════════════════════════════════
    
    ✅ Méthode BeginTextCommandDisplayText pour éviter le clignotement
    ✅ Rendu synchronisé pour stabilité maximale
    ✅ Position respectée de la config
]]

local SOURCE_FILE = 'client/leaderboard.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES
-- ═══════════════════════════════════════════════════════════

local leaderboardData = {}
local lastUpdate = 0
local isPlayerNearLeaderboard = false

-- ═══════════════════════════════════════════════════════════
-- 🎨 FONCTION DE RENDU 3D (VERSION STABLE)
-- ═══════════════════════════════════════════════════════════

--- Dessine du texte 3D dans le monde (méthode stable sans clignotement)
---@param x number
---@param y number
---@param z number
---@param text string
---@param scale number
---@param r number
---@param g number
---@param b number
local function DrawText3DStable(x, y, z, text, scale, r, g, b)
    -- Vérifier si le point est visible à l'écran
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if not onScreen then return end
    
    -- Configuration du texte
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(r, g, b, 255)
    
    -- Ombres et contours pour la lisibilité
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    
    -- Dessiner le texte
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end

--- Dessine le panneau du leaderboard complet
local function DrawLeaderboard()
    local pos = Config.Leaderboard.position
    local baseZ = pos.z
    
    -- ═══════════════════════════════════════════════════════
    -- TITRE
    -- ═══════════════════════════════════════════════════════
    DrawText3DStable(
        pos.x, 
        pos.y, 
        baseZ + Config.Leaderboard.titleOffset,
        Config.Leaderboard.title,
        Config.Leaderboard.titleScale,
        Config.Leaderboard.colors.title.r,
        Config.Leaderboard.colors.title.g,
        Config.Leaderboard.colors.title.b
    )
    
    -- ═══════════════════════════════════════════════════════
    -- TOP 3 JOUEURS
    -- ═══════════════════════════════════════════════════════
    if #leaderboardData > 0 then
        for i = 1, math.min(3, #leaderboardData) do
            local player = leaderboardData[i]
            local offsetZ = baseZ + Config.Leaderboard.startOffset - ((i - 1) * Config.Leaderboard.lineSpacing)
            
            -- Médaille/Rang
            local medal = Config.Leaderboard.medals[i] or tostring(i)
            local color = Config.Leaderboard.colors[i] or Config.Leaderboard.colors[3]
            
            -- Format: 🥇 PlayerName - 1500 ELO
            local displayText = string.format(
                "%s  %s  -  %d ELO",
                medal,
                player.name,
                player.elo
            )
            
            DrawText3DStable(
                pos.x, 
                pos.y, 
                offsetZ,
                displayText,
                Config.Leaderboard.textScale,
                color.r, 
                color.g, 
                color.b
            )
        end
    else
        -- Aucune donnée
        DrawText3DStable(
            pos.x, 
            pos.y, 
            baseZ + Config.Leaderboard.startOffset,
            "Aucun joueur classe",
            Config.Leaderboard.textScale,
            150, 150, 150
        )
    end
    
    -- ═══════════════════════════════════════════════════════
    -- FOOTER (optionnel)
    -- ═══════════════════════════════════════════════════════
    if Config.Leaderboard.showFooter then
        local footerZ = baseZ + Config.Leaderboard.startOffset - (3 * Config.Leaderboard.lineSpacing) - 0.1
        DrawText3DStable(
            pos.x, 
            pos.y, 
            footerZ,
            "Mise a jour toutes les " .. (Config.Leaderboard.refreshInterval / 1000) .. "s",
            0.25,
            100, 100, 100
        )
    end
end

-- ═══════════════════════════════════════════════════════════
-- 🔄 MISE À JOUR DES DONNÉES
-- ═══════════════════════════════════════════════════════════

--- Demande la mise à jour du leaderboard au serveur
local function RequestLeaderboardUpdate()
    Utils.Debug('Demande mise à jour leaderboard', nil, SOURCE_FILE)
    TriggerServerEvent('catmouse:requestLeaderboard')
end

--- Réception des données du leaderboard
RegisterNetEvent('catmouse:receiveLeaderboard', function(data)
    Utils.Debug('Leaderboard reçu', { count = #data }, SOURCE_FILE)
    leaderboardData = data
    lastUpdate = GetGameTimer()
end)

-- ═══════════════════════════════════════════════════════════
-- 🔁 BOUCLE PRINCIPALE (VERSION ULTRA-STABLE)
-- ═══════════════════════════════════════════════════════════

CreateThread(function()
    -- Attendre l'initialisation
    Wait(2000)
    
    -- Demander les données initiales
    RequestLeaderboardUpdate()
    
    -- Variables locales pour la boucle
    local checkInterval = 500 -- Vérifier la distance toutes les 500ms
    local lastDistanceCheck = 0
    
    while true do
        local currentTime = GetGameTimer()
        
        -- ✅ OPTIMISATION: Vérifier la distance seulement toutes les 500ms
        if currentTime - lastDistanceCheck > checkInterval then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local leaderboardPos = Config.Leaderboard.position
            
            local distance = #(playerCoords - vector3(leaderboardPos.x, leaderboardPos.y, leaderboardPos.z))
            
            if distance < Config.Leaderboard.renderDistance then
                -- Joueur proche
                if not isPlayerNearLeaderboard then
                    isPlayerNearLeaderboard = true
                    Utils.Debug('Joueur proche du leaderboard', { distance = distance }, SOURCE_FILE)
                end
                
                -- Rafraîchir les données si nécessaire
                if currentTime - lastUpdate > Config.Leaderboard.refreshInterval then
                    RequestLeaderboardUpdate()
                end
            else
                -- Joueur loin
                if isPlayerNearLeaderboard then
                    isPlayerNearLeaderboard = false
                    Utils.Debug('Joueur éloigné du leaderboard', nil, SOURCE_FILE)
                end
            end
            
            lastDistanceCheck = currentTime
        end
        
        -- ✅ RENDU: Dessiner SEULEMENT si proche
        if isPlayerNearLeaderboard then
            DrawLeaderboard()
            Wait(0) -- Rendu chaque frame quand proche
        else
            Wait(1000) -- Wait long quand loin
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 COMMANDE DEBUG
-- ═══════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('race_leaderboard', function()
        RequestLeaderboardUpdate()
        Utils.Info('Leaderboard rafraîchi manuellement', nil)
    end, false)
    
    RegisterCommand('race_leaderboard_pos', function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local leaderboardPos = Config.Leaderboard.position
        local distance = #(playerCoords - vector3(leaderboardPos.x, leaderboardPos.y, leaderboardPos.z))
        
        Utils.Info('Position leaderboard', {
            config = string.format('vec3(%.6f, %.6f, %.6f)', leaderboardPos.x, leaderboardPos.y, leaderboardPos.z),
            playerDist = string.format('%.2f mètres', distance)
        })
    end, false)
    
    TriggerEvent('chat:addSuggestion', '/race_leaderboard', 'Rafraîchir le classement')
    TriggerEvent('chat:addSuggestion', '/race_leaderboard_pos', 'Afficher la position du leaderboard')
end

