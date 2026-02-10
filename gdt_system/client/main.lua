-- ==========================================
-- CLIENT MAIN - INITIALISATION
-- ==========================================

ESX = exports["es_extended"]:getSharedObject()

-- Variables locales
local PlayerData = {}
local InGDT = false
local CurrentTeam = Constants.Teams.NONE
local ShowingTeamZones = false

-- ==========================================
-- INITIALISATION DU CLIENT
-- ==========================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Utils.Debug('Client initialisé')
    
    -- Récupération des données joueur
    ESX.PlayerData = ESX.GetPlayerData()
    PlayerData = ESX.PlayerData
    
    -- Attendre que le joueur soit spawné
    while not ESX.IsPlayerLoaded() do
        Wait(100)
    end
    
    -- Initialisation des modules
    InitializePed()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Nettoyage
    if InGDT then
        TriggerServerEvent('gdt:server:quitGDT')
    end
    
    CleanupPed()
end)

-- ==========================================
-- MISE À JOUR DES DONNÉES JOUEUR
-- ==========================================

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    ESX.PlayerData = xPlayer
    
    InitializePed()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- ==========================================
-- COMMANDE CLIENT : /gtquit (VERSION AMÉLIORÉE)
-- ==========================================

RegisterCommand('gtquit', function()

    
    -- Vérification basique
    if not InGDT and CurrentTeam == Constants.Teams.NONE then

        ESX.ShowNotification('Tu n\'es pas en GDT')
        return
    end
    
    -- Message de confirmation
    ESX.ShowNotification('Sortie de la GDT en cours...')
    
    -- Envoi au serveur
    TriggerServerEvent('gdt:server:quitGDT')
    
    -- Nettoyage local immédiat de sécurité
    Citizen.CreateThread(function()
        Wait(2000) -- Attendre que le serveur réponde
        
        
        -- Double vérification : si toujours des effets actifs, forcer le nettoyage
        if InGDT or exports['gdt_system']:IsInSpectatorMode() then
            
            -- Arrêt spectateur
            if exports['gdt_system']:IsInSpectatorMode() then
                StopSpectatorMode()
            end
            
            -- Reset variables locales
            SetInGDT(false)
            SetCurrentTeam(Constants.Teams.NONE)
            
            -- Fermeture UI
            if exports['gdt_system']:IsUIOpen() then
                CloseUI()
            end
            
            -- Masquer les zones
            HideTeamZones()
            
            ESX.ShowNotification('Nettoyage forcé effectué')

        else

        end
        
    end)
end, false)

-- ==========================================
-- COMMANDE ALTERNATIVE : /gtleave
-- ==========================================

RegisterCommand('gtleave', function()
    ExecuteCommand('gtquit')
end, false)

-- ==========================================
-- COMMANDE ALTERNATIVE : /quitgdt (CLIENT) - Alias rétrocompatible
-- ==========================================

RegisterCommand('quitgdt', function()
    ExecuteCommand('gtquit')
end, false)

-- ==========================================
-- FONCTIONS UTILITAIRES
-- ==========================================

function SetInGDT(value)
    InGDT = value
end

function SetCurrentTeam(team)
    CurrentTeam = team
end

function IsInGDT()
    return InGDT
end

function GetCurrentTeam()
    return CurrentTeam
end

-- ==========================================
-- TEAM LIST PERSISTANTE (toggle /gteqlist)
-- ==========================================

local TeamListActive = false

RegisterNetEvent('gdt:client:toggleTeamList', function()
    TeamListActive = not TeamListActive

    if TeamListActive then
        -- Demander les données immédiatement
        TriggerServerEvent('gdt:server:requestTeamList')
        ESX.ShowNotification('Liste des équipes activée')

        -- Thread de refresh toutes les 5s
        Citizen.CreateThread(function()
            while TeamListActive do
                Wait(5000)
                if TeamListActive then
                    TriggerServerEvent('gdt:server:requestTeamList')
                end
            end
        end)
    else
        -- Masquer le panel NUI
        SendNUIMessage({ action = 'hideTeamList' })
        ESX.ShowNotification('Liste des équipes désactivée')
    end
end)

RegisterNetEvent('gdt:client:updateTeamList', function(data)
    if not TeamListActive then return end

    SendNUIMessage({
        action = 'showTeamList',
        red = data.red,
        blue = data.blue,
        lobby = data.lobby,
        gameInfo = data.gameInfo
    })
end)