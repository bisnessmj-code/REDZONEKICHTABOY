--[[
    =====================================================
    REDZONE LEAGUE - Systeme de Banque (Serveur)
    =====================================================
    Gestion des depots et retraits bancaires.
]]

Redzone = Redzone or {}
Redzone.Server = Redzone.Server or {}

-- =====================================================
-- FRAMEWORK ESX
-- =====================================================

local ESX = nil

CreateThread(function()
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    while ESX == nil do Wait(100) end
end)

-- =====================================================
-- DEPOT D'ARGENT
-- =====================================================

RegisterNetEvent('redzone:bank:deposit')
AddEventHandler('redzone:bank:deposit', function(amount)
    local source = source
    amount = tonumber(amount)

    if not amount or amount <= 0 then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local cash = xPlayer.getMoney()

    if cash < amount then
        Redzone.Server.Utils.NotifyError(source, 'Vous n\'avez pas assez d\'argent liquide ($' .. Redzone.Shared.FormatNumber(cash) .. ')')
        return
    end

    xPlayer.removeMoney(amount)
    xPlayer.addAccountMoney('bank', amount)

    Redzone.Server.Utils.NotifySuccess(source, 'Depot de $' .. Redzone.Shared.FormatNumber(amount) .. ' effectue')
    Redzone.Shared.Debug('[BANK] Depot - Joueur: ', source, ' | Montant: ', amount)
end)

RegisterNetEvent('redzone:bank:depositAll')
AddEventHandler('redzone:bank:depositAll', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local cash = xPlayer.getMoney()

    if cash <= 0 then
        Redzone.Server.Utils.NotifyError(source, 'Vous n\'avez pas d\'argent liquide')
        return
    end

    xPlayer.removeMoney(cash)
    xPlayer.addAccountMoney('bank', cash)

    Redzone.Server.Utils.NotifySuccess(source, 'Depot de $' .. Redzone.Shared.FormatNumber(cash) .. ' effectue')
    Redzone.Shared.Debug('[BANK] Depot total - Joueur: ', source, ' | Montant: ', cash)
end)

-- =====================================================
-- RETRAIT D'ARGENT
-- =====================================================

RegisterNetEvent('redzone:bank:withdraw')
AddEventHandler('redzone:bank:withdraw', function(amount)
    local source = source
    amount = tonumber(amount)

    if not amount or amount <= 0 then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local bank = xPlayer.getAccount('bank').money

    if bank < amount then
        Redzone.Server.Utils.NotifyError(source, 'Vous n\'avez pas assez en banque ($' .. Redzone.Shared.FormatNumber(bank) .. ')')
        return
    end

    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(amount)

    Redzone.Server.Utils.NotifySuccess(source, 'Retrait de $' .. Redzone.Shared.FormatNumber(amount) .. ' effectue')
    Redzone.Shared.Debug('[BANK] Retrait - Joueur: ', source, ' | Montant: ', amount)
end)

RegisterNetEvent('redzone:bank:withdrawAll')
AddEventHandler('redzone:bank:withdrawAll', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local bank = xPlayer.getAccount('bank').money

    if bank <= 0 then
        Redzone.Server.Utils.NotifyError(source, 'Votre compte en banque est vide')
        return
    end

    xPlayer.removeAccountMoney('bank', bank)
    xPlayer.addMoney(bank)

    Redzone.Server.Utils.NotifySuccess(source, 'Retrait de $' .. Redzone.Shared.FormatNumber(bank) .. ' effectue')
    Redzone.Shared.Debug('[BANK] Retrait total - Joueur: ', source, ' | Montant: ', bank)
end)

-- =====================================================
-- INITIALISATION
-- =====================================================

Redzone.Shared.Debug('[SERVER/BANK] Module Banque charge')
