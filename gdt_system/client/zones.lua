-- ==========================================
-- CLIENT ZONES - GESTION DES ZONES D'ÉQUIPE
-- ==========================================

local ShowZones = false
local InRedZone = false
local InBlueZone = false

-- ==========================================
-- AFFICHER LES ZONES D'ÉQUIPE
-- ==========================================

function ShowTeamZones()
    if ShowZones then return end
    
    ShowZones = true
    Utils.Debug('Zones d\'équipe activées')
    
    -- Thread pour les markers et détection
    Citizen.CreateThread(function()
        while ShowZones do
            local sleep = 500
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Zone rouge
            local redZone = Config.TeamZones.red
            local distanceRed = #(playerCoords - redZone.coords)
            
            -- Zone bleue
            local blueZone = Config.TeamZones.blue
            local distanceBlue = #(playerCoords - blueZone.coords)
            
            -- Si proche d'une zone
            local minDistance = math.min(distanceRed, distanceBlue)
            if minDistance < Constants.Limits.MARKER_DRAW_DISTANCE then
                sleep = 0
                
                -- Marker rouge
                DrawMarker(
                    1, -- Type cylindre
                    redZone.coords.x, redZone.coords.y, redZone.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    redZone.radius * 2.0, redZone.radius * 2.0, 1.0,
                    redZone.color.r, redZone.color.g, redZone.color.b, redZone.color.a,
                    false, true, 2, nil, nil, false
                )
                
                -- Marker bleu
                DrawMarker(
                    1, -- Type cylindre
                    blueZone.coords.x, blueZone.coords.y, blueZone.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    blueZone.radius * 2.0, blueZone.radius * 2.0, 1.0,
                    blueZone.color.r, blueZone.color.g, blueZone.color.b, blueZone.color.a,
                    false, true, 2, nil, nil, false
                )
                
                -- Vérification entrée zone rouge
                if distanceRed < redZone.radius then
                    if not InRedZone and GetCurrentTeam() ~= Constants.Teams.RED then
                        InRedZone = true
                        ESX.ShowHelpNotification('Appuie sur ~INPUT_CONTEXT~ pour rejoindre l\'equipe Rouge')
                    end
                    
                    if InRedZone and IsControlJustPressed(0, 38) then -- E
                        TriggerServerEvent('gdt:server:selectTeam', Constants.Teams.RED)
                        InRedZone = false
                    end
                else
                    InRedZone = false
                end
                
                -- Vérification entrée zone bleue
                if distanceBlue < blueZone.radius then
                    if not InBlueZone and GetCurrentTeam() ~= Constants.Teams.BLUE then
                        InBlueZone = true
                        ESX.ShowHelpNotification('Appuie sur ~INPUT_CONTEXT~ pour rejoindre l\'equipe Bleue')
                    end
                    
                    if InBlueZone and IsControlJustPressed(0, 38) then -- E
                        TriggerServerEvent('gdt:server:selectTeam', Constants.Teams.BLUE)
                        InBlueZone = false
                    end
                else
                    InBlueZone = false
                end
            elseif minDistance < Constants.Limits.MARKER_DRAW_DISTANCE * 2 then
                sleep = 200 -- Palier intermediaire pour transition douce
            end

            Wait(sleep)
        end
    end)
end

-- ==========================================
-- MASQUER LES ZONES D'ÉQUIPE
-- ==========================================

function HideTeamZones()
    ShowZones = false
    InRedZone = false
    InBlueZone = false
    Utils.Debug('Zones d\'équipe désactivées')
end

-- ==========================================
-- EXPORTS
-- ==========================================

exports('ShowTeamZones', ShowTeamZones)
exports('HideTeamZones', HideTeamZones)
