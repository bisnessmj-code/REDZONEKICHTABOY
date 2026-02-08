--[[
    =====================================================
    REDZONE LEAGUE - Systeme Kit de Bienvenue (Serveur)
    =====================================================
    Ce fichier gere la verification en base de donnees
    et l'attribution du kit de bienvenue (une seule fois).
]]

Redzone = Redzone or {}
Redzone.Server = Redzone.Server or {}

-- =====================================================
-- VARIABLES LOCALES
-- =====================================================

local ESX = nil

-- =====================================================
-- INITIALISATION
-- =====================================================

local function InitWelcomeKitESX()
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    while ESX == nil do
        Wait(100)
    end
end

-- =====================================================
-- EVENEMENT: Reclamer le kit de bienvenue
-- =====================================================

RegisterNetEvent('redzone:welcomekit:claim')
AddEventHandler('redzone:welcomekit:claim', function()
    local source = source

    -- Verification de securite
    if not Redzone.Server.Utils.IsPlayerConnected(source) then return end

    -- Obtenir le joueur ESX
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        Redzone.Shared.Debug('[WELCOMEKIT/ERROR] Joueur ESX introuvable: ', source)
        Redzone.Server.Utils.NotifyError(source, 'Erreur: joueur introuvable.')
        return
    end

    local identifier = xPlayer.getIdentifier()
    local playerName = Redzone.Server.Utils.GetPlayerName(source)

    -- Verifier si le joueur a deja recupere le kit
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM redzone_welcome_kit WHERE identifier = ?', {identifier}, function(count)
        if count and count > 0 then
            -- Le joueur a deja recupere le kit
            Redzone.Server.Utils.NotifyError(source, 'Vous avez deja recupere votre Kit de Bienvenue !')
            Redzone.Shared.Debug('[WELCOMEKIT] Joueur ', source, ' a deja recupere le kit')
            return
        end

        -- Donner les items du kit
        local kitConfig = Config.WelcomeKit

        -- Donner les armes (weapon_pistol50 x10)
        for _, item in ipairs(kitConfig.Items) do
            local success = pcall(function()
                exports['qs-inventory']:AddItem(source, item.name, item.amount)
            end)
            if not success then
                Redzone.Shared.Debug('[WELCOMEKIT/ERROR] Erreur lors de l\'ajout de ', item.name, ' x', item.amount)
            end
        end

        -- Inserer dans la base de donnees
        MySQL.Async.execute('INSERT INTO redzone_welcome_kit (identifier, name) VALUES (?, ?)', {identifier, playerName}, function(rowsChanged)
            if rowsChanged and rowsChanged > 0 then
                Redzone.Server.Utils.NotifySuccess(source, 'Kit de Bienvenue recupere ! Verifiez votre inventaire.')
                Redzone.Shared.Debug('[WELCOMEKIT] Kit donne au joueur ', source, ' (', identifier, ')')
            else
                Redzone.Server.Utils.NotifyError(source, 'Erreur lors de la recuperation du kit.')
                Redzone.Shared.Debug('[WELCOMEKIT/ERROR] Erreur insertion DB pour joueur ', source)
            end
        end)
    end)
end)

-- =====================================================
-- EVENEMENT: Verifier si le joueur a deja le kit
-- =====================================================

RegisterNetEvent('redzone:welcomekit:checkStatus')
AddEventHandler('redzone:welcomekit:checkStatus', function()
    local source = source

    if not Redzone.Server.Utils.IsPlayerConnected(source) then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM redzone_welcome_kit WHERE identifier = ?', {identifier}, function(count)
        local alreadyClaimed = count and count > 0
        TriggerClientEvent('redzone:welcomekit:statusResult', source, alreadyClaimed)
    end)
end)

-- =====================================================
-- DEMARRAGE
-- =====================================================

CreateThread(function()
    InitWelcomeKitESX()
    Redzone.Shared.Debug('[SERVER/WELCOMEKIT] Module Kit de Bienvenue charge')
end)
