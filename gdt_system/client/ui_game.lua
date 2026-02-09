-- ==========================================
-- CLIENT UI GAME - ANNONCES ET ANIMATIONS
-- ==========================================

-- ==========================================
-- AFFICHER UNE ANNONCE
-- ==========================================

RegisterNetEvent('gdt:client:showAnnounce', function(message, duration)

    
    -- Envoi au NUI
    SendNUIMessage({
        action = 'showAnnounce',
        message = message,
        duration = duration or 5000
    })
    
    -- Notification ESX visible pour confirmer la réception
    ESX.ShowNotification('ANNONCE: '..message)
    
    Utils.Debug('Annonce envoyée au NUI : '..message)
end)

-- ==========================================
-- AFFICHER VICTOIRE DU ROUND
-- ==========================================

RegisterNetEvent('gdt:client:showRoundWin', function(winner, scores, topRed, topBlue)
    local winnerTeam = winner == Constants.Teams.RED and 'ROUGE' or winner == Constants.Teams.BLUE and 'BLEUE' or 'ÉGALITÉ'
    local color = winner == Constants.Teams.RED and 'red' or winner == Constants.Teams.BLUE and 'blue' or 'white'

    SendNUIMessage({
        action = 'showRoundWin',
        winner = winnerTeam,
        color = color,
        scores = scores,
        topRed = topRed or {},
        topBlue = topBlue or {}
    })

end)

-- ==========================================
-- AFFICHER FIN DE PARTIE
-- ==========================================

RegisterNetEvent('gdt:client:showGameEnd', function(winner, scores, topRed, topBlue)
    local winnerTeam = winner == Constants.Teams.RED and 'ROUGE' or winner == Constants.Teams.BLUE and 'BLEUE' or 'ÉGALITÉ'
    local color = winner == Constants.Teams.RED and 'red' or winner == Constants.Teams.BLUE and 'blue' or 'white'

    SendNUIMessage({
        action = 'showGameEnd',
        winner = winnerTeam,
        color = color,
        scores = scores,
        topRed = topRed or {},
        topBlue = topBlue or {}
    })

end)

-- ==========================================
-- AFFICHER LE NOMBRE DE JOUEURS PAR ÉQUIPE
-- (Notification au-dessus de la minimap)
-- ==========================================

local showingTeamCount = false
local teamCountData = {}

RegisterNetEvent('gdt:client:showTeamCount', function(redCount, blueCount, lobbyCount)
    teamCountData = {
        red = redCount,
        blue = blueCount,
        lobby = lobbyCount,
        total = redCount + blueCount + lobbyCount
    }
    showingTeamCount = true

    -- Afficher pendant 8 secondes
    Citizen.SetTimeout(8000, function()
        showingTeamCount = false
    end)
end)

-- Thread pour afficher le texte au-dessus de la minimap
Citizen.CreateThread(function()
    while true do
        if showingTeamCount then
            -- Position au-dessus de la minimap (bas gauche)
            local x = 0.16
            local y = 0.78

            -- Titre
            SetTextFont(4)
            SetTextScale(0.45, 0.45)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~w~=== ~y~GDT EQUIPES ~w~===")
            DrawText(x, y)

            -- Équipe Rouge
            SetTextFont(4)
            SetTextScale(0.40, 0.40)
            SetTextColour(255, 80, 80, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~r~ROUGE: ~w~" .. teamCountData.red .. " joueur(s)")
            DrawText(x, y + 0.025)

            -- Équipe Bleue
            SetTextFont(4)
            SetTextScale(0.40, 0.40)
            SetTextColour(80, 150, 255, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~b~BLEU: ~w~" .. teamCountData.blue .. " joueur(s)")
            DrawText(x, y + 0.050)

            -- Lobby (en attente)
            SetTextFont(4)
            SetTextScale(0.40, 0.40)
            SetTextColour(200, 200, 200, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~c~LOBBY: ~w~" .. teamCountData.lobby .. " joueur(s)")
            DrawText(x, y + 0.075)

            -- Total
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 200, 0, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~y~TOTAL: ~w~" .. teamCountData.total .. " joueur(s)")
            DrawText(x, y + 0.100)

            Wait(0)
        else
            Wait(500)
        end
    end
end)