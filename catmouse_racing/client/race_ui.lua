--[[
    ═══════════════════════════════════════════════════════════
    🖥️ CLIENT - GESTION NUI (HUD DE COURSE)
    ═══════════════════════════════════════════════════════════
    
    Communication avec l'interface NUI pour le HUD en course.
]]

local SOURCE_FILE = 'client/race_ui.lua'

-- ═══════════════════════════════════════════════════════════
-- 📦 VARIABLES
-- ═══════════════════════════════════════════════════════════

local isMainUIOpen = false
local isRaceHUDVisible = false

-- ═══════════════════════════════════════════════════════════
-- 🎨 INTERFACE PRINCIPALE (Menu)
-- ═══════════════════════════════════════════════════════════

--- Ouverture de l'interface principale
function OpenRacingUI()
    Utils.Trace('OpenRacingUI')
    
    if isMainUIOpen then 
        Utils.Debug('UI déjà ouverte', nil, SOURCE_FILE)
        return 
    end
    
    if IsInRace() then
        ShowNotification({
            type = Constants.NotificationType.WARNING,
            message = Config.Texts.already_in_race
        })
        return
    end
    
    isMainUIOpen = true
    
    -- Envoi des données à la NUI
    SendNUIMessage({
        action = 'openUI',
        data = {
            title = Config.UI.title,
            subtitle = Config.UI.subtitle,
            rules = Config.Rules,
            texts = Config.Texts,
            matchmakingEnabled = Config.Matchmaking.enabled
        }
    })
    
    -- Activer le focus
    SetNuiFocus(true, true)
    
    Utils.Debug('Interface principale ouverte', nil, SOURCE_FILE)
end

--- Fermeture de l'interface principale
function CloseRacingUI()
    Utils.Trace('CloseRacingUI')
    
    if not isMainUIOpen then return end
    
    -- Retirer le focus EN PREMIER
    SetNuiFocus(false, false)
    
    isMainUIOpen = false
    
    SendNUIMessage({
        action = 'closeUI'
    })
    
    Utils.Debug('Interface principale fermée', nil, SOURCE_FILE)
end

--- État de l'UI principale
function IsMainUIOpen()
    return isMainUIOpen
end

-- ═══════════════════════════════════════════════════════════
-- 🏁 HUD DE COURSE
-- ═══════════════════════════════════════════════════════════

--- Affichage du HUD de course
function ShowRaceHUD(data)
    Utils.Trace('ShowRaceHUD', data)
    
    isRaceHUDVisible = true
    
    SendNUIMessage({
        action = 'showRaceHUD',
        data = data
    })
    
    Utils.Debug('HUD de course affiché', nil, SOURCE_FILE)
end

--- Masquage du HUD de course
function HideRaceHUD()
    Utils.Trace('HideRaceHUD')
    
    isRaceHUDVisible = false
    
    SendNUIMessage({
        action = 'hideRaceHUD'
    })
    
    Utils.Debug('HUD de course masqué', nil, SOURCE_FILE)
end

--- État du HUD
function IsRaceHUDVisible()
    return isRaceHUDVisible
end

-- ═══════════════════════════════════════════════════════════
-- 📡 CALLBACKS NUI
-- ═══════════════════════════════════════════════════════════

--- Fermeture UI (bouton FERMER)
RegisterNUICallback('catmouse:closeUI', function(data, cb)
    Utils.Debug('NUI Callback: closeUI', nil, SOURCE_FILE)
    CloseRacingUI()
    cb('ok')
end)

--- Envoi d'invitation
RegisterNUICallback('catmouse:sendInvite', function(data, cb)
    Utils.Debug('NUI Callback: sendInvite', data, SOURCE_FILE)
    
    local targetId = tonumber(data.targetId)
    
    if not targetId or targetId < 1 then
        ShowNotification({
            type = Constants.NotificationType.ERROR,
            message = Config.Texts.cmd_invalid_id
        })
        cb('error')
        return
    end
    
    TriggerServerEvent(Constants.Events.SEND_INVITATION, targetId)
    CloseRacingUI()
    cb('ok')
end)

--- Rejoindre la queue
RegisterNUICallback('catmouse:joinQueue', function(data, cb)
    Utils.Debug('NUI Callback: joinQueue', nil, SOURCE_FILE)
    
    TriggerServerEvent(Constants.Events.JOIN_QUEUE)
    CloseRacingUI()
    cb('ok')
end)

--- Quitter la queue
RegisterNUICallback('catmouse:leaveQueue', function(data, cb)
    Utils.Debug('NUI Callback: leaveQueue', nil, SOURCE_FILE)
    
    TriggerServerEvent(Constants.Events.LEAVE_QUEUE)
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 CONTRÔLES
-- ═══════════════════════════════════════════════════════════

--- Thread de gestion ESC pour l'UI principale
CreateThread(function()
    while true do
        if isMainUIOpen then
            -- Désactiver certains contrôles
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            
            -- ESC pour fermer
            if IsDisabledControlJustPressed(0, 322) then
                Utils.Debug('ESC pressé - Fermeture UI', nil, SOURCE_FILE)
                CloseRacingUI()
            end
            
            Wait(0)
        else
            Wait(500)
        end
    end
end)

