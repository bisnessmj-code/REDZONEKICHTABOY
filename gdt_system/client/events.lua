-- ==========================================
-- CLIENT EVENTS - GESTION DES ÉVÉNEMENTS
-- ==========================================
-- ✅ CORRECTION : Toutes les sorties utilisent Config.ExitLocation
-- ✅ Plus de téléportation au PED
-- ==========================================

-- ==========================================
-- ÉVÉNEMENT : DEMANDE DE LA TENUE ACTUELLE
-- ==========================================

RegisterNetEvent('gdt:client:requestOutfit', function(bucket)
    local ped = PlayerPedId()
    local outfit = GetCurrentOutfit()
    
    if not outfit then
        ESX.ShowNotification('Erreur lors de la sauvegarde de la tenue')
        return
    end
    
    -- Envoi au serveur
    TriggerServerEvent('gdt:server:outfitSaved', outfit, bucket)
    
    Utils.Debug('Tenue sauvegardée et envoyée au serveur')
end)

-- ==========================================
-- ÉVÉNEMENT : TÉLÉPORTATION VERS LE LOBBY
-- ==========================================

RegisterNetEvent('gdt:client:teleportLobby', function()
    local ped = PlayerPedId()
    
    -- Désactivation des contrôles pendant le TP
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(500)
    
    Wait(500)
    
    -- Téléportation
    SetEntityCoords(ped, Config.LobbyLocation.x, Config.LobbyLocation.y, Config.LobbyLocation.z, false, false, false, true)
    
    Wait(500)
    
    -- Réactivation
    DoScreenFadeIn(500)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    
    SetInGDT(true)
    
    -- Affichage des zones d'équipe
    ShowTeamZones()
    
    Utils.Debug('Téléporté au lobby')
end)

-- ==========================================
-- ÉVÉNEMENT : APPLIQUER LA TENUE D'ÉQUIPE
-- ==========================================

RegisterNetEvent('gdt:client:applyTeamOutfit', function(team)
    if not Utils.IsValidTeam(team) then return end
    
    SetCurrentTeam(team)
    ApplyTeamOutfit(team)
    
    Utils.Debug('Tenue d\'équipe appliquée : '..team)
end)

-- ==========================================
-- ÉVÉNEMENT : RESTAURER LE JOUEUR (TÉLÉPORTE À ExitLocation)
-- ==========================================
-- ✅ MODIFIÉ : Téléporte à Config.ExitLocation au lieu du PED
-- Utilisé pour : /gdtquit, /gdtkick, etc.
-- ==========================================

RegisterNetEvent('gdt:client:restorePlayer', function(originalOutfit)
    local ped = PlayerPedId()
    
    
    -- Arrêter le spectateur si actif
    if exports['gdt_system']:IsInSpectatorMode() then
        StopSpectatorMode()
        Wait(200)
    end
    
    -- Fermeture de l'UI
    CloseUI()
    
    -- Désactivation des zones
    HideTeamZones()
    
    -- ==========================================
    -- ✅ TÉLÉPORTATION À Config.ExitLocation (PAS AU PED)
    -- ==========================================
    DoScreenFadeOut(500)
    Wait(500)
    
    local exitCoords = Config.ExitLocation
    SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, true)
    SetEntityHeading(ped, exitCoords.w)
    
    
    Wait(500)
    
    -- Restauration de la tenue
    if originalOutfit then
        RestoreOutfit(originalOutfit)
    end
    
    DoScreenFadeIn(500)
    
    SetInGDT(false)
    SetCurrentTeam(Constants.Teams.NONE)
    
    Utils.Debug('Joueur restauré (téléporté à ExitLocation)')
end)

-- ==========================================
-- ÉVÉNEMENT : RESTAURER UNIQUEMENT LA TENUE (SANS TÉLÉPORTATION)
-- ==========================================
-- Utilisé après EndGame quand le joueur est déjà téléporté à endLocation
-- ==========================================

RegisterNetEvent('gdt:client:restoreOutfitOnly', function(originalOutfit)
    local ped = PlayerPedId()
    
    
    -- Arrêter le spectateur si actif
    if exports['gdt_system']:IsInSpectatorMode() then
        StopSpectatorMode()
        Wait(200)
    end
    
    -- Fermeture de l'UI
    CloseUI()
    
    -- Désactivation des zones
    HideTeamZones()
    
    -- ✅ PAS DE TÉLÉPORTATION - Le joueur reste où il est (endLocation)
    
    -- Restauration de la tenue seulement
    if originalOutfit then
        RestoreOutfit(originalOutfit)
    end
    
    -- Reset des variables d'état
    SetInGDT(false)
    SetCurrentTeam(Constants.Teams.NONE)
    
    Utils.Debug('Tenue restaurée (sans téléportation)')
end)

-- ==========================================
-- ÉVÉNEMENT : PONG (RÉPONSE AU PING)
-- ==========================================

RegisterNetEvent('gdt:client:pong', function()
    Utils.Debug('Pong reçu du serveur')
end)

-- ==========================================
-- ✅ P3 #14 : SYNC ÉTAT SERVEUR → CLIENT
-- ==========================================
-- Corrige les variables locales si elles divergent du serveur (source de vérité)
-- ==========================================

RegisterNetEvent('gdt:client:syncState', function(serverState)
    if not serverState then return end

    -- Corriger InGDT
    local clientInGDT = IsInGDT()
    if serverState.inGDT ~= clientInGDT then
        SetInGDT(serverState.inGDT)
        Utils.Debug('Sync: InGDT corrigé ' .. tostring(clientInGDT) .. ' -> ' .. tostring(serverState.inGDT))
    end

    -- Corriger CurrentTeam
    local clientTeam = GetCurrentTeam()
    if serverState.team and serverState.team ~= clientTeam then
        SetCurrentTeam(serverState.team)
        Utils.Debug('Sync: Team corrigé ' .. tostring(clientTeam) .. ' -> ' .. tostring(serverState.team))
    end
end)

-- ==========================================
-- ✅ P3 #16 : NETTOYAGE FORCÉ AU RESTART RESOURCE
-- ==========================================

RegisterNetEvent('gdt:client:forceCleanup', function()
    -- Arrêter le spectateur
    if exports['gdt_system']:IsInSpectatorMode() then
        StopSpectatorMode()
    end

    -- Fermer l'UI
    CloseUI()

    -- Masquer les zones
    HideTeamZones()

    -- Masquer la team list
    SendNUIMessage({ action = 'hideTeamList' })

    -- Reset variables locales
    SetInGDT(false)
    SetCurrentTeam(Constants.Teams.NONE)
end)