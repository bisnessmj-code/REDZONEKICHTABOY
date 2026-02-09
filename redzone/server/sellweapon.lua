--[[
    =====================================================
    REDZONE LEAGUE - Système de Rachat d'Armes (Serveur)
    =====================================================
    Ce fichier gère la validation et le paiement du rachat
    d'armes. Les armes sont rachetées à 50% du prix du shop.
]]

Redzone = Redzone or {}
Redzone.Server = Redzone.Server or {}

-- =====================================================
-- VARIABLES LOCALES
-- =====================================================

-- Framework ESX
local ESX = nil

-- Liste des armes valides avec leurs prix (construite à partir de la config)
local validWeapons = {}

-- =====================================================
-- INITIALISATION
-- =====================================================

---Initialise ESX
local function InitSellWeaponESX()
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    while ESX == nil do
        Wait(100)
    end
end

---Construit la liste des armes valides à partir de la config
local function BuildValidWeaponsList()
    for category, products in pairs(Config.ShopPeds.Products) do
        for _, product in ipairs(products) do
            if product.type == 'weapon' then
                validWeapons[product.model] = {
                    name = product.name,
                    price = product.price,
                }
            end
        end
    end
    Redzone.Shared.Debug('[SERVER/SELLWEAPON] Liste des armes valides construite')
end

-- =====================================================
-- ÉVÉNEMENTS
-- =====================================================

---Événement: Vente d'une arme par un joueur
---@param weaponModel string Le modèle de l'arme à vendre
RegisterNetEvent('redzone:sellweapon:sell')
AddEventHandler('redzone:sellweapon:sell', function(weaponModel)
    local source = source

    -- Vérification de sécurité
    if not Redzone.Server.Utils.IsPlayerConnected(source) then return end

    -- Vérifier que le joueur est dans le redzone
    if not exports[GetCurrentResourceName()]:IsPlayerInRedzone(source) then
        Redzone.Shared.Debug('[SELLWEAPON/ERROR] Joueur ', source, ' tente de vendre hors redzone')
        Redzone.Server.Utils.NotifyError(source, 'Vous devez etre dans la Redzone.')
        return
    end

    -- Valider que l'arme existe dans la config
    if not validWeapons[weaponModel] then
        Redzone.Shared.Debug('[SELLWEAPON/ERROR] Arme invalide: ', weaponModel, ' par joueur ', source)
        Redzone.Server.Utils.NotifyError(source, 'Arme invalide.')
        return
    end

    -- Obtenir le joueur ESX
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        Redzone.Shared.Debug('[SELLWEAPON/ERROR] Joueur ESX introuvable: ', source)
        Redzone.Server.Utils.NotifyError(source, 'Erreur: joueur introuvable.')
        return
    end

    -- Calculer le prix de rachat (50%)
    local weaponData = validWeapons[weaponModel]
    local sellPrice = math.floor(weaponData.price * 0.4)

    -- Retirer l'arme du joueur (ESX + qs-inventory + client)
    xPlayer.removeWeapon(weaponModel)

    -- Retirer aussi l'arme de qs-inventory (item en minuscule)
    local itemName = string.lower(weaponModel)
    pcall(function()
        exports['qs-inventory']:RemoveItem(source, itemName, 1)
    end)

    -- Retirer l'arme côté client (du ped GTA)
    TriggerClientEvent('redzone:sellweapon:removeWeapon', source, weaponModel)

    -- Donner le cash (item money via qs-inventory)
    local success = pcall(function()
        exports['qs-inventory']:AddItem(source, 'money', sellPrice)
    end)

    if not success then
        Redzone.Shared.Debug('[SELLWEAPON/ERROR] Erreur AddItem money pour joueur ', source)
        Redzone.Server.Utils.NotifyError(source, 'Erreur lors du paiement.')
        return
    end

    -- Notification de succès
    Redzone.Server.Utils.NotifySuccess(source, weaponData.name .. ' vendu pour $' .. sellPrice)

    Redzone.Shared.Debug('[SELLWEAPON] Vente par joueur ', source, ': ', weaponModel, ' pour $', sellPrice)
end)

-- =====================================================
-- DÉMARRAGE
-- =====================================================

CreateThread(function()
    InitSellWeaponESX()
    BuildValidWeaponsList()
    Redzone.Shared.Debug('[SERVER/SELLWEAPON] Module Rachat Armes serveur chargé')
end)
