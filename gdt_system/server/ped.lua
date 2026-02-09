-- ==========================================
-- SERVER PED - GESTION DE L'ÉTAT DU PED (SYNCHRONISÉ)
-- ==========================================
-- ✅ État centralisé sur le serveur
-- ✅ Synchronisation automatique pour les nouveaux joueurs
-- ✅ Commandes admin pour activer/désactiver
-- ==========================================

-- État global du PED (désactivé par défaut)
local PedState = {
    enabled = false,
    lastChangedBy = nil,
    lastChangedAt = nil
}

-- ==========================================
-- INITIALISATION
-- ==========================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- PED désactivé par défaut au démarrage
    PedState.enabled = false
  
end)

-- ==========================================
-- ÉVÉNEMENT : JOUEUR DEMANDE L'ÉTAT DU PED
-- ==========================================

RegisterNetEvent('gdt:server:requestPedState', function()
    local source = source
    
    -- Envoyer l'état actuel au joueur qui demande
    TriggerClientEvent('gdt:client:syncPedState', source, PedState.enabled)
    
    local playerName = GetPlayerName(source) or 'Inconnu'
    
end)

-- ==========================================
-- SYNCHRONISER LE PED POUR TOUS LES JOUEURS
-- ==========================================

function SyncPedStateToAll()
    -- Envoyer à tous les joueurs connectés
    TriggerClientEvent('gdt:client:syncPedState', -1, PedState.enabled)
   
end

-- ==========================================
-- ACTIVER LE PED
-- ==========================================

function EnablePed(adminSource)
    if PedState.enabled then
        return false, "Le PED est déjà activé"
    end
    
    PedState.enabled = true
    PedState.lastChangedBy = adminSource
    PedState.lastChangedAt = os.time()
    
    -- Synchroniser pour tous
    SyncPedStateToAll()
    
    local adminName = adminSource and GetPlayerName(adminSource) or 'Console'
   
    return true, "PED activé avec succès"
end

-- ==========================================
-- DÉSACTIVER LE PED
-- ==========================================

function DisablePed(adminSource)
    if not PedState.enabled then
        return false, "Le PED est déjà désactivé"
    end
    
    PedState.enabled = false
    PedState.lastChangedBy = adminSource
    PedState.lastChangedAt = os.time()
    
    -- Synchroniser pour tous
    SyncPedStateToAll()
    
    local adminName = adminSource and GetPlayerName(adminSource) or 'Console'
 
    
    return true, "PED désactivé avec succès"
end

-- ==========================================
-- BASCULER L'ÉTAT DU PED
-- ==========================================

function TogglePed(adminSource)
    if PedState.enabled then
        return DisablePed(adminSource)
    else
        return EnablePed(adminSource)
    end
end

-- ==========================================
-- OBTENIR L'ÉTAT DU PED
-- ==========================================

function GetPedState()
    return PedState
end

function IsPedEnabled()
    return PedState.enabled
end

-- ==========================================
-- COMMANDE ADMIN : /gtped
-- ==========================================

RegisterCommand('gtped', function(source, args, rawCommand)
    -- Vérification console
    if source == 0 then
        local action = args[1] or 'toggle'
        
        if action == 'on' or action == 'enable' or action == '1' then
            local success, message = EnablePed(0)

        elseif action == 'off' or action == 'disable' or action == '0' then
            local success, message = DisablePed(0)

        elseif action == 'status' then

        else
            local success, message = TogglePed(0)

        end
        return
    end
    
    -- Vérification admin pour les joueurs
    if not Permissions.IsAdmin(source) then
        TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
        return
    end
    
    local action = args[1] or 'toggle'
    local success, message
    
    if action == 'on' or action == 'enable' or action == '1' then
        success, message = EnablePed(source)
    elseif action == 'off' or action == 'disable' or action == '0' then
        success, message = DisablePed(source)
    elseif action == 'status' then
        local status = PedState.enabled and '~g~ACTIVÉ' or '~r~DÉSACTIVÉ'
        TriggerClientEvent('esx:showNotification', source, 'PED GDT : '..status)
        return
    else
        success, message = TogglePed(source)
    end
    
    if success then
        TriggerClientEvent('esx:showNotification', source, '~g~'..message)
    else
        TriggerClientEvent('esx:showNotification', source, '~o~'..message)
    end
end, false)

-- ==========================================
-- SYNCHRONISATION AUTOMATIQUE POUR NOUVEAUX JOUEURS
-- ==========================================

-- Quand un joueur spawn/charge
RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    -- Petit délai pour s'assurer que le client est prêt
    Citizen.SetTimeout(2000, function()
        if playerId then
            TriggerClientEvent('gdt:client:syncPedState', playerId, PedState.enabled)

        end
    end)
end)

-- ==========================================
-- EXPORTS GLOBAUX
-- ==========================================

_G.EnablePed = EnablePed
_G.DisablePed = DisablePed
_G.TogglePed = TogglePed
_G.GetPedState = GetPedState
_G.IsPedEnabled = IsPedEnabled

exports('EnablePed', EnablePed)
exports('DisablePed', DisablePed)
exports('TogglePed', TogglePed)
exports('IsPedEnabled', IsPedEnabled)