-- ==========================================
-- CLIENT UI - GESTION DE L'INTERFACE NUI
-- ==========================================

local UIOpen = false

-- ==========================================
-- OUVRIR L'INTERFACE
-- ==========================================

function OpenUI()
    if UIOpen then return end
    
    UIOpen = true
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI'
    })
    
    Utils.Debug('Interface ouverte')
end

-- ==========================================
-- FERMER L'INTERFACE
-- ==========================================

function CloseUI()
    if not UIOpen then return end
    
    UIOpen = false
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })
    
end

-- ==========================================
-- CALLBACK NUI : REJOINDRE LE LOBBY
-- ==========================================

RegisterNUICallback('joinLobby', function(data, cb)
    CloseUI()
    
    ESX.TriggerServerCallback('gdt:canJoin', function(canJoin)
        if canJoin then
            TriggerServerEvent('gdt:server:joinLobby')
        else
            ESX.ShowNotification('Tu ne peux pas rejoindre la GDT')
        end
    end)
    
    cb('ok')
end)

-- ==========================================
-- CALLBACK NUI : FERMER L'UI
-- ==========================================

RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

-- ==========================================
-- CALLBACK NUI : CLASSEMENT TOP 20
-- ==========================================

RegisterNUICallback('getLeaderboard', function(data, cb)
    ESX.TriggerServerCallback('gdt:getLeaderboard', function(results)
        SendNUIMessage({
            action = 'showLeaderboard',
            players = results
        })
    end)
    cb('ok')
end)

-- ==========================================
-- TOUCHE ESC POUR FERMER
-- ==========================================

Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if UIOpen then
            -- Désactiver les contrôles
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            -- ESC pour fermer
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) then
                CloseUI()
            end
        else
            Wait(500)
        end
    end
end)

-- ==========================================
-- EXPORTS
-- ==========================================

exports('OpenUI', OpenUI)
exports('CloseUI', CloseUI)
exports('IsUIOpen', function() return UIOpen end)
