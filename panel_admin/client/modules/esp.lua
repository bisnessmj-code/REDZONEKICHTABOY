--[[
    ESP - Panel Admin Fight League
    Affichage des noms, IDs, vie et armure au-dessus des joueurs
]]

local ESP = {}

-- Etat de l'ESP
local isEspActive = false

-- Cache des grades joueurs (mis a jour periodiquement)
local playerGrades = {}

-- Couleurs par grade
local gradeColors = {
    owner = {r = 255, g = 0, b = 0},         -- Rouge
    admin = {r = 255, g = 100, b = 0},       -- Orange
    responsable = {r = 255, g = 0, b = 255}, -- Violet/Magenta
    organisateur = {r = 0, g = 200, b = 255},-- Cyan/Bleu clair
    staff = {r = 0, g = 255, b = 100},       -- Vert clair
    default = {r = 255, g = 255, b = 255}    -- Blanc
}

-- --------------------------------------------------------------
-- FONCTIONS PRINCIPALES
-- --------------------------------------------------------------

function ESP.Enable()
    isEspActive = true
    -- Demander les grades au serveur
    TriggerServerEvent('panel:requestPlayerGrades')
end

function ESP.Disable()
    isEspActive = false
end

function ESP.Toggle()
    if isEspActive then
        ESP.Disable()
    else
        ESP.Enable()
    end
end

function ESP.IsActive()
    return isEspActive
end

-- --------------------------------------------------------------
-- FONCTIONS DE DESSIN
-- --------------------------------------------------------------

-- Calculer le facteur de taille en fonction de la distance
-- Taille reduite pour un affichage plus discret
function GetScaleFactor(distance)
    local baseDistance = 8.0 -- Distance de reference augmentee
    local factor = baseDistance / distance
    -- Limiter entre 0.25 et 0.55 (beaucoup plus petit qu'avant)
    if factor > 0.55 then factor = 0.55 end
    if factor < 0.25 then factor = 0.25 end
    return factor
end

-- Couleur jaune warning pour quand le joueur parle
local talkingColor = {r = 255, g = 200, b = 0}

-- Dessiner les barres de son animees
function DrawSoundBars(screenX, screenY, scale)
    local time = GetGameTimer() / 150
    local barWidth = 0.003 * scale
    local maxHeight = 0.012 * scale
    local spacing = 0.004 * scale

    -- 3 barres avec animations differentes
    for i = 1, 3 do
        local offset = (i - 2) * spacing
        local phase = time + (i * 1.5)
        local height = (math.abs(math.sin(phase)) * 0.7 + 0.3) * maxHeight

        DrawRect(screenX + offset, screenY, barWidth, height, talkingColor.r, talkingColor.g, talkingColor.b, 255)
    end
end

-- Dessiner l'ESP complet pour un joueur
function DrawPlayerESP(screenX, screenY, serverId, playerName, health, maxHealth, armor, isTalking, color, scale)
    -- Taille du texte - plus petit quand proche, un peu plus grand quand loin
    local baseTextSize = 0.32 -- Taille de base encore plus reduite
    local textSize = baseTextSize + (scale * 0.25) -- Variation legere

    -- Espacement vertical entre nom et barres
    local lineHeight = 0.015 * (scale + 0.6) -- Plus d'espace entre les elements
    local currentY = screenY

    -- === LIGNE 1: [ID] Nom (+ barres son si parle) ===
    local displayText = '[' .. serverId .. '] ' .. playerName

    SetTextScale(0.0, textSize)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)

    -- Couleur selon si parle ou non
    if isTalking then
        SetTextColour(talkingColor.r, talkingColor.g, talkingColor.b, 255)
    else
        SetTextColour(color.r, color.g, color.b, 255)
    end

    SetTextEntry('STRING')
    AddTextComponentString(displayText)
    DrawText(screenX, currentY)

    -- Dessiner les barres de son si le joueur parle
    if isTalking then
        -- Calculer la largeur du texte pour positionner les barres
        local textWidth = 0.045 * scale + (#playerName * 0.004 * scale)
        DrawSoundBars(screenX + textWidth, currentY + (0.008 * scale), scale)
    end

    currentY = currentY + lineHeight + (0.018 * (scale + 0.5)) -- Plus d'espace avant les barres

    -- === LIGNE 2: Barres de vie/armure ===
    -- Barres plus grandes et plus visibles
    local barWidth = 0.055 * (scale + 0.25)
    local barHeight = 0.007 * (scale + 0.25)
    local barSpacing = 0.004 * scale

    -- Calculer la progression de vie
    local healthProgress = health / maxHealth
    if healthProgress > 1.0 then healthProgress = 1.0 end
    if healthProgress < 0.0 then healthProgress = 0.0 end

    -- Couleur de vie selon le niveau
    local healthColor = {r = 100, g = 255, b = 100}
    if healthProgress < 0.5 then
        healthColor = {r = 255, g = 180, b = 0}
    end
    if healthProgress < 0.25 then
        healthColor = {r = 255, g = 50, b = 50}
    end

    -- Epaisseur de la bordure noire
    local borderSize = 0.002 * (scale + 0.2)

    if armor > 0 then
        -- Deux barres cote a cote
        local halfWidth = (barWidth - barSpacing) / 2
        local healthX = screenX - halfWidth/2 - barSpacing/2
        local armorX = screenX + halfWidth/2 + barSpacing/2

        -- Bordure noire barre de vie (gauche)
        DrawRect(healthX, currentY, halfWidth + borderSize * 2, barHeight + borderSize * 2, 0, 0, 0, 255)
        -- Fond barre de vie
        DrawRect(healthX, currentY, halfWidth, barHeight, 30, 30, 30, 200)
        -- Remplissage barre de vie
        local healthFillWidth = halfWidth * healthProgress
        if healthFillWidth > 0 then
            DrawRect(healthX - (halfWidth/2) + (healthFillWidth/2), currentY, healthFillWidth, barHeight - 0.001, healthColor.r, healthColor.g, healthColor.b, 255)
        end

        -- Bordure noire barre d'armure (droite)
        local armorProgress = armor / 100
        if armorProgress > 1.0 then armorProgress = 1.0 end
        DrawRect(armorX, currentY, halfWidth + borderSize * 2, barHeight + borderSize * 2, 0, 0, 0, 255)
        -- Fond barre d'armure
        DrawRect(armorX, currentY, halfWidth, barHeight, 30, 30, 30, 200)
        -- Remplissage barre d'armure
        local armorFillWidth = halfWidth * armorProgress
        if armorFillWidth > 0 then
            DrawRect(armorX - (halfWidth/2) + (armorFillWidth/2), currentY, armorFillWidth, barHeight - 0.001, 80, 150, 255, 255)
        end
    else
        -- Une seule barre centree
        -- Bordure noire
        DrawRect(screenX, currentY, barWidth + borderSize * 2, barHeight + borderSize * 2, 0, 0, 0, 255)
        -- Fond barre
        DrawRect(screenX, currentY, barWidth, barHeight, 30, 30, 30, 200)
        -- Remplissage barre de vie
        local healthFillWidth = barWidth * healthProgress
        if healthFillWidth > 0 then
            DrawRect(screenX - (barWidth/2) + (healthFillWidth/2), currentY, healthFillWidth, barHeight - 0.001, healthColor.r, healthColor.g, healthColor.b, 255)
        end
    end
end

-- Obtenir la couleur selon le grade
function GetGradeColor(grade)
    if grade and gradeColors[grade] then
        return gradeColors[grade]
    end
    return gradeColors.default
end

-- --------------------------------------------------------------
-- THREAD PRINCIPAL
-- --------------------------------------------------------------

CreateThread(function()
    while true do
        if isEspActive then
            Wait(0)

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- Parcourir tous les joueurs
            for _, playerId in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(playerId)

                -- Ne pas afficher pour soi-meme
                if targetPed ~= playerPed and DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)

                    -- Afficher jusqu'a 150m
                    if distance < 150.0 then
                        local serverId = GetPlayerServerId(playerId)
                        local playerName = GetPlayerName(playerId)
                        local health = GetEntityHealth(targetPed)
                        local maxHealth = GetEntityMaxHealth(targetPed)
                        local armor = GetPedArmour(targetPed)

                        -- Ajuster la sante (enlever les 100 de base)
                        local displayHealth = health - 100
                        local displayMaxHealth = maxHealth - 100
                        if displayHealth < 0 then displayHealth = 0 end
                        if displayMaxHealth < 100 then displayMaxHealth = 100 end

                        -- Position au-dessus de la tete
                        -- Plus loin = monte beaucoup plus haut pour rester visible
                        local headPos = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
                        local heightOffset = 0.65 + (distance * 0.06) -- 0.75m de base + 6cm par metre de distance
                        if heightOffset > 5.0 then heightOffset = 5.0 end -- Max 5m au dessus
                        local displayZ = headPos.z + heightOffset

                        -- Obtenir le grade et la couleur
                        local grade = playerGrades[serverId] or 'default'
                        local color = GetGradeColor(grade)

                        -- Detecter si le joueur parle
                        local isTalking = NetworkIsPlayerTalking(playerId)

                        -- Calculer le scale en fonction de la distance
                        local scale = GetScaleFactor(distance)

                        -- Convertir position 3D en 2D
                        local onScreen, screenX, screenY = World3dToScreen2d(headPos.x, headPos.y, displayZ)

                        if onScreen then
                            -- Afficher tout l'ESP avec le scale
                            DrawPlayerESP(screenX, screenY, serverId, playerName, displayHealth, displayMaxHealth, armor, isTalking, color, scale)
                        end
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Mise a jour periodique des grades
CreateThread(function()
    while true do
        if isEspActive then
            TriggerServerEvent('panel:requestPlayerGrades')
        end
        Wait(5000) -- Mise a jour toutes les 5 secondes
    end
end)

-- --------------------------------------------------------------
-- EVENTS
-- --------------------------------------------------------------

-- Recevoir les grades des joueurs
RegisterNetEvent('panel:receivePlayerGrades', function(grades)
    playerGrades = grades or {}
end)

-- --------------------------------------------------------------
-- COMMANDES ET KEYBIND
-- --------------------------------------------------------------

-- Commande pour toggle ESP (keybind)
RegisterCommand('+panel_esp', function()
    -- Verifier les permissions via le serveur
    TriggerServerEvent('panel:checkEspPermission')
end, false)

RegisterCommand('-panel_esp', function() end, false)

-- Enregistrer la touche (configurable dans Parametres > Raccourcis clavier)
RegisterKeyMapping('+panel_esp', 'Panel Admin - Afficher joueurs (ESP)', 'keyboard', 'F3')

-- Commande /id pour le staff
RegisterCommand('id', function()
    -- Verifier les permissions via le serveur (meme verification que le keybind)
    TriggerServerEvent('panel:checkEspPermission')
end, false)

-- Suggestion de la commande
TriggerEvent('chat:addSuggestion', '/id', 'Afficher/Masquer les IDs des joueurs (Staff)')

-- Event de reponse du serveur pour la permission
RegisterNetEvent('panel:espAllowed', function()
    ESP.Toggle()
end)

RegisterNetEvent('panel:espDenied', function()
    TriggerEvent('panel:notification', {
        type = 'error',
        title = 'ESP',
        message = 'Vous n\'avez pas la permission d\'utiliser l\'ESP'
    })
end)

-- --------------------------------------------------------------
-- CLEANUP
-- --------------------------------------------------------------

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        isEspActive = false
    end
end)

-- Export global
_G.ESP = ESP
