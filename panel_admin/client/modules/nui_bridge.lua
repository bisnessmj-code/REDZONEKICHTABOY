--[[
    NUI Bridge - Panel Admin Fight League
    Communication entre Lua client et interface NUI
]]

local NUIBridge = {}

-- État du panel
local isOpen = false
local currentSession = nil

-- ══════════════════════════════════════════════════════════════
-- GESTION DE L'INTERFACE
-- ══════════════════════════════════════════════════════════════

-- Ouvrir le panel
function NUIBridge.Open(session)
    if isOpen then return end

    currentSession = session
    isOpen = true

    SetNuiFocus(true, true)

    -- Envoyer au NUI
    SendNUIMessage({
        action = 'open',
        session = session
    })

    -- Demander les données initiales
    ESX.TriggerServerCallback('panel:init', function(result)
        if result.success then
            SendNUIMessage({
                action = 'init',
                data = result
            })
        end
    end)
end

-- Fermer le panel
function NUIBridge.Close()
    if not isOpen then return end

    isOpen = false
    currentSession = nil

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    TriggerServerEvent('panel:close')
end

-- Vérifier si ouvert
function NUIBridge.IsOpen()
    return isOpen
end

-- Obtenir la session
function NUIBridge.GetSession()
    return currentSession
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS NUI -> LUA
-- ══════════════════════════════════════════════════════════════

-- Fermeture depuis NUI
RegisterNUICallback('close', function(data, cb)
    NUIBridge.Close()
    cb('ok')
end)

-- Demande de données joueurs
RegisterNUICallback('getPlayers', function(data, cb)
    ESX.TriggerServerCallback('panel:getPlayers', function(result)
        cb(result)
    end)
end)

-- Demande détails joueur
RegisterNUICallback('getPlayerDetails', function(data, cb)
    ESX.TriggerServerCallback('panel:getPlayerDetails', function(result)
        cb(result)
    end, data.playerId)
end)

-- Recherche joueurs
RegisterNUICallback('searchPlayers', function(data, cb)
    ESX.TriggerServerCallback('panel:searchPlayers', function(result)
        cb(result)
    end, data.query, data.includeOffline)
end)

-- Action joueur
RegisterNUICallback('playerAction', function(data, cb)
    TriggerServerEvent('panel:playerAction', data.action, data.targetId, data)
    cb('ok')
end)

-- Envoyer un message a un joueur
RegisterNUICallback('sendMessageToPlayer', function(data, cb)
    TriggerServerEvent('panel:sendMessageToPlayer', data.playerId, data.message)
    cb('ok')
end)

-- Action sanction
RegisterNUICallback('sanctionAction', function(data, cb)
    TriggerServerEvent('panel:sanctionAction', data.action, data.targetId, data)
    cb('ok')
end)

-- Ban par identifier (joueur hors-ligne)
RegisterNUICallback('banByIdentifier', function(data, cb)
    ESX.TriggerServerCallback('panel:banByIdentifier', function(result)
        cb(result)
    end, data.identifier, data.reason, data.duration)
end)

-- Action économie
RegisterNUICallback('economyAction', function(data, cb)
    TriggerServerEvent('panel:economyAction', data.action, data.targetId, data)
    cb('ok')
end)

-- Action téléportation
RegisterNUICallback('teleportAction', function(data, cb)
    TriggerServerEvent('panel:teleportAction', data.action, data.targetId, data)
    cb('ok')
end)

-- Action véhicule
RegisterNUICallback('vehicleAction', function(data, cb)
    TriggerServerEvent('panel:vehicleAction', data.action, data.targetId, data)
    cb('ok')
end)

-- Action annonce
RegisterNUICallback('announceAction', function(data, cb)
    TriggerServerEvent('panel:announceAction', data)
    cb('ok')
end)

-- Demande logs
RegisterNUICallback('getLogs', function(data, cb)
    ESX.TriggerServerCallback('panel:getLogs', function(result)
        cb(result)
    end, data.filters, data.page, data.perPage)
end)

-- Demande historique des sanctions
RegisterNUICallback('getSanctions', function(data, cb)
    ESX.TriggerServerCallback('panel:getSanctions', function(result)
        cb(result)
    end, data.filters, data.page, data.perPage)
end)

-- Demande des comptes des joueurs en ligne (Owner/Admin)
RegisterNUICallback('getAccounts', function(data, cb)
    ESX.TriggerServerCallback('panel:getAccounts', function(result)
        cb(result)
    end)
end)

-- Demande de la liste des bans
RegisterNUICallback('getBans', function(data, cb)
    if Config.Debug then print('[NUI BRIDGE] getBans callback appele - envoi au serveur...') end
    ESX.TriggerServerCallback('panel:getBans', function(result)
        if Config.Debug then print('[NUI BRIDGE] getBans reponse: success=' .. tostring(result.success)) end
        cb(result)
    end)
end)

-- Debannir un joueur
RegisterNUICallback('unbanPlayer', function(data, cb)
    ESX.TriggerServerCallback('panel:unbanPlayer', function(result)
        cb(result)
    end, data.identifier)
end)

-- Obtenir les emplacements de teleportation depuis le config
RegisterNUICallback('getTeleportLocations', function(data, cb)
    ESX.TriggerServerCallback('panel:getTeleportLocations', function(result)
        cb(result)
    end)
end)

-- Obtenir les coordonnees actuelles du joueur
RegisterNUICallback('getPlayerCoords', function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    cb({
        success = true,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading
    })
end)

-- Demande de la liste des reports
RegisterNUICallback('getReports', function(data, cb)
    ESX.TriggerServerCallback('panel:getReports', function(result)
        cb(result)
    end)
end)

-- Action sur un report (claim, respond, resolve, delete)
RegisterNUICallback('reportAction', function(data, cb)
    if Config.Debug then print('[NUI BRIDGE] reportAction: action=' .. tostring(data.action) .. ', reportId=' .. tostring(data.reportId)) end
    ESX.TriggerServerCallback('panel:reportAction', function(result)
        if Config.Debug then print('[NUI BRIDGE] reportAction response: success=' .. tostring(result.success) .. ', error=' .. tostring(result.error)) end
        cb(result)
    end, data.action, data.reportId, data)
end)

-- Statistiques des reports
RegisterNUICallback('getReportStats', function(data, cb)
    ESX.TriggerServerCallback('panel:getReportStats', function(result)
        cb(result)
    end, data.timeFilter)
end)

-- Envoyer une annonce d'événement (GDT/CVC)
RegisterNUICallback('sendEventAnnouncement', function(data, cb)
    ESX.TriggerServerCallback('panel:sendEventAnnouncement', function(result)
        cb(result)
    end, data)
end)

-- Obtenir les statistiques des événements
RegisterNUICallback('getEventStats', function(data, cb)
    ESX.TriggerServerCallback('panel:getEventStats', function(result)
        cb(result)
    end, data.timeFilter)
end)

-- Réinitialiser les statistiques des événements
RegisterNUICallback('resetEventStats', function(data, cb)
    ESX.TriggerServerCallback('panel:resetEventStats', function(result)
        cb(result)
    end)
end)

-- Téléportation au marqueur
RegisterNUICallback('teleportToMarker', function(data, cb)
    local blip = GetFirstBlipInfoId(8) -- 8 = waypoint
    if DoesBlipExist(blip) then
        local coords = GetBlipInfoIdCoord(blip)
        -- Trouver la hauteur du sol
        local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
        if found then
            coords = vector3(coords.x, coords.y, z + 1.0)
        else
            coords = vector3(coords.x, coords.y, 100.0)
        end
        TriggerServerEvent('panel:teleportAction', 'self', nil, {x = coords.x, y = coords.y, z = coords.z})
        cb({success = true})
    else
        cb({success = false, error = 'Aucun marqueur placé'})
    end
end)

-- ══════════════════════════════════════════════════════════════
-- STAFF CHAT
-- ══════════════════════════════════════════════════════════════

-- Obtenir les messages du chat staff
RegisterNUICallback('getStaffChatMessages', function(data, cb)
    ESX.TriggerServerCallback('panel:getStaffChatMessages', function(result)
        cb(result)
    end)
end)

-- Envoyer un message dans le chat staff
RegisterNUICallback('sendStaffChatMessage', function(data, cb)
    ESX.TriggerServerCallback('panel:sendStaffChatMessage', function(result)
        cb(result)
    end, data.message)
end)

-- Supprimer un message du chat staff
RegisterNUICallback('deleteStaffChatMessage', function(data, cb)
    ESX.TriggerServerCallback('panel:deleteStaffChatMessage', function(result)
        cb(result)
    end, data.messageId)
end)

-- Supprimer tous les messages du chat staff (admin/owner)
RegisterNUICallback('clearStaffChat', function(data, cb)
    ESX.TriggerServerCallback('panel:clearStaffChat', function(result)
        cb(result)
    end)
end)

-- ══════════════════════════════════════════════════════════════
-- ACTIVITY TIMELINE
-- ══════════════════════════════════════════════════════════════

-- Obtenir les activités récentes
RegisterNUICallback('getRecentActivity', function(data, cb)
    ESX.TriggerServerCallback('panel:getRecentActivity', function(result)
        cb(result)
    end, data.limit or 20)
end)

-- ══════════════════════════════════════════════════════════════
-- STAFF ROLES MANAGEMENT
-- ══════════════════════════════════════════════════════════════

-- Obtenir la liste des membres du staff
RegisterNUICallback('getStaffMembers', function(data, cb)
    ESX.TriggerServerCallback('panel:getStaffMembers', function(result)
        cb(result)
    end)
end)

-- Modifier le grade d'un membre
RegisterNUICallback('updateStaffGrade', function(data, cb)
    ESX.TriggerServerCallback('panel:updateStaffGrade', function(result)
        cb(result)
    end, data.identifier, data.newGrade)
end)

-- Obtenir les joueurs connectés (pour promotion)
RegisterNUICallback('getConnectedUsers', function(data, cb)
    ESX.TriggerServerCallback('panel:getConnectedUsers', function(result)
        cb(result)
    end)
end)

-- ══════════════════════════════════════════════════════════════
-- EVENTS SERVEUR -> CLIENT
-- ══════════════════════════════════════════════════════════════

-- Ouvrir depuis le serveur
RegisterNetEvent('panel:openNUI', function(session)
    NUIBridge.Open(session)
end)

-- Ouvrir depuis le serveur directement sur l'onglet Reports
RegisterNetEvent('panel:openNUIReports', function(session)
    NUIBridge.Open(session)
    -- Attendre que le NUI soit ouvert puis changer d'onglet
    Wait(100)
    SendNUIMessage({
        action = 'switchToReports'
    })
end)

-- Note: panel:notification est gere dans client/main.lua pour eviter les doublons

-- Popup
RegisterNetEvent('panel:popup', function(data)
    SendNUIMessage({
        action = 'popup',
        data = data
    })
end)

-- Mise à jour données
RegisterNetEvent('panel:updateData', function(dataType, data)
    SendNUIMessage({
        action = 'updateData',
        dataType = dataType,
        data = data
    })
end)

-- Envoyer directement au NUI (pour reports, etc.)
RegisterNetEvent('panel:sendToNUI', function(message)
    SendNUIMessage(message)
end)

-- ══════════════════════════════════════════════════════════════
-- EXPORTS
-- ══════════════════════════════════════════════════════════════

exports('openPanel', function()
    TriggerServerEvent('panel:open')
end)

exports('closePanel', function()
    NUIBridge.Close()
end)

exports('isOpen', function()
    return NUIBridge.IsOpen()
end)

-- ══════════════════════════════════════════════════════════════
-- INTERACTIONS NOTIFICATIONS REPORT (ALT + Echap)
-- ══════════════════════════════════════════════════════════════

local hasActiveReportNotifications = false
local isReportInteractionMode = false

-- Le NUI nous informe quand il y a des notifications actives
RegisterNUICallback('reportNotificationsStatus', function(data, cb)
    hasActiveReportNotifications = data.hasNotifications
    cb({})
end)

-- Fermer le mode interaction (Echap depuis NUI)
RegisterNUICallback('closeReportInteraction', function(data, cb)
    if isReportInteractionMode then
        isReportInteractionMode = false
        SetNuiFocus(false, false)
    end
    cb({})
end)

-- Ouvrir directement l'onglet Reports
RegisterNUICallback('openReportsTab', function(data, cb)
    if not NUIBridge.IsOpen() then
        TriggerServerEvent('panel:open')
        -- Attendre que le panel s'ouvre puis changer d'onglet
        Wait(100)
    end
    SendNUIMessage({
        action = 'switchToReports'
    })
    cb({})
end)

-- Thread pour detecter la touche ALT gauche
CreateThread(function()
    while true do
        Wait(0)

        -- ALT gauche = 19 (LMENU)
        if hasActiveReportNotifications and not NUIBridge.IsOpen() and not isReportInteractionMode then
            if IsControlJustPressed(0, 19) then
                -- Activer le focus pour interagir avec les notifications
                isReportInteractionMode = true
                SetNuiFocus(true, true)
                SendNUIMessage({
                    action = 'enableReportInteraction'
                })
            end
        end

        -- Si on est en mode interaction et qu'on appuie sur Echap (hors du NUI)
        if isReportInteractionMode then
            if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 322) then -- Echap ou F10
                isReportInteractionMode = false
                SetNuiFocus(false, false)
                SendNUIMessage({
                    action = 'disableReportInteraction'
                })
            end
        end
    end
end)

-- Export global
_G.NUIBridge = NUIBridge
