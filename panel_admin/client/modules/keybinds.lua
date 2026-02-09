--[[
    Keybinds - Panel Admin Fight League
    Gestion des raccourcis clavier via FiveM Key Mapping
    Configurable dans Paramètres > Raccourcis > FiveM
]]

local Keybinds = {}

-- ══════════════════════════════════════════════════════════════
-- ENREGISTREMENT DES KEYBINDS (Configurable dans le menu FiveM)
-- ══════════════════════════════════════════════════════════════

-- Commande pour toggle le panel
RegisterCommand('+panel_open', function()
    if NUIBridge and NUIBridge.IsOpen() then
        NUIBridge.Close()
    else
        TriggerServerEvent('panel:open')
    end
end, false)

RegisterCommand('-panel_open', function()
    -- Relâchement de la touche (optionnel)
end, false)

-- Enregistrer le keybind configurable
-- Sera visible dans : Paramètres > Raccourcis > FiveM > "Panel Admin"
RegisterKeyMapping('+panel_open', 'Ouvrir/Fermer le Panel Admin', 'keyboard', Config.OpenKey or 'F7')

-- ══════════════════════════════════════════════════════════════
-- KEYBIND POUR OUVRIR DIRECTEMENT LES REPORTS
-- ══════════════════════════════════════════════════════════════

-- Commande pour ouvrir les reports
RegisterCommand('+panel_reports', function()
    TriggerServerEvent('panel:openReports')
end, false)

RegisterCommand('-panel_reports', function()
    -- Relâchement de la touche (optionnel)
end, false)

-- Enregistrer le keybind configurable
-- Sera visible dans : Paramètres > Raccourcis > FiveM > "Panel Admin Reports"
RegisterKeyMapping('+panel_reports', 'Ouvrir les Tickets/Reports', 'keyboard', Config.ReportsKey or 'F8')

-- ══════════════════════════════════════════════════════════════
-- FERMETURE AVEC ESCAPE (si activé dans config)
-- ══════════════════════════════════════════════════════════════

if Config.CloseOnEscape then
    CreateThread(function()
        while true do
            Wait(0)

            if NUIBridge and NUIBridge.IsOpen() then
                -- Désactiver le menu pause quand le panel est ouvert
                DisableControlAction(0, 199, true) -- P (pause menu)

                -- Fermer avec Escape (Backspace dans le jeu)
                if IsControlJustPressed(0, 177) then -- Backspace/Escape
                    NUIBridge.Close()
                end
            else
                Wait(500) -- Moins de charge CPU quand panel fermé
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PUBLIQUES
-- ══════════════════════════════════════════════════════════════

-- Obtenir la touche actuelle (pour affichage)
function Keybinds.GetCurrentKey()
    return GetControlInstructionalButton(0, 0x156F7119, true) -- Hash de +panel_open
end

-- Export global
_G.Keybinds = Keybinds
