--[[
    =====================================================
    REDZONE LEAGUE - Système de Rachat d'Armes
    =====================================================
    Ce fichier gère les PEDs de rachat d'armes et le menu
    de vente. Les armes sont rachetées à 50% du prix du shop.
]]

Redzone = Redzone or {}
Redzone.Client = Redzone.Client or {}
Redzone.Client.SellWeapon = {}

-- =====================================================
-- VARIABLES LOCALES
-- =====================================================

-- Stockage des PEDs sell weapon créés
local sellWeaponPeds = {}

-- État d'interaction
local isNearSellPed = false
local currentSellPed = nil

-- État du menu de vente
local isMenuOpen = false

-- Index de sélection actuel
local selectedIndex = 1

-- =====================================================
-- CONFIGURATION DES PEDS VENDRE ARME
-- =====================================================

local SellWeaponLocations = {
    {
        id = 1,
        name = 'Rachat Zone traitement',
        Model = 's_m_y_ammucity_01',
        Coords = vector4(1158.830810, -1490.268188, 34.688598, 130.393708),
        Scenario = 'WORLD_HUMAN_CLIPBOARD',
        Invincible = true,
        Frozen = true,
        BlockEvents = true,
    },
    {
        id = 2,
        name = 'Rachat Zone Pole emploi',
        Model = 's_m_y_ammucity_01',
        Coords = vector4(-289.481324, -891.316468, 31.065918, 335.905518),
        Scenario = 'WORLD_HUMAN_CLIPBOARD',
        Invincible = true,
        Frozen = true,
        BlockEvents = true,
    },
    {
        id = 3,
        name = 'Rachat Zone Casino',
        Model = 's_m_y_ammucity_01',
        Coords = vector4(885.553834, -50.035164, 78.750976, 197.007874),
        Scenario = 'WORLD_HUMAN_CLIPBOARD',
        Invincible = true,
        Frozen = true,
        BlockEvents = true,
    },
    {
        id = 4,
        name = 'Rachat Zone Aeroport',
        Model = 's_m_y_ammucity_01',
        Coords = vector4(-996.307678, -2526.824219, 13.828613, 58.110229),
        Scenario = 'WORLD_HUMAN_CLIPBOARD',
        Invincible = true,
        Frozen = true,
        BlockEvents = true,
    },
    {
        id = 5,
        name = 'Rachat Zone Ouest',
        Model = 's_m_y_ammucity_01',
        Coords = vector4(-1571.492310, -288.993408, 48.269654, 145.984252),
        Scenario = 'WORLD_HUMAN_CLIPBOARD',
        Invincible = true,
        Frozen = true,
        BlockEvents = true,
    },
}

-- =====================================================
-- CRÉATION DES PEDS
-- =====================================================

---Crée un PED de rachat d'armes
---@param pedConfig table Configuration du PED
---@return number|nil pedHandle Le handle du PED créé ou nil si erreur
local function CreateSellWeaponPed(pedConfig)
    if not pedConfig or not pedConfig.Model or not pedConfig.Coords then
        Redzone.Shared.Debug('[SELLWEAPON/ERROR] Configuration invalide pour la création du PED')
        return nil
    end

    local modelHash = GetHashKey(pedConfig.Model)
    if not Redzone.Client.Utils.LoadModel(modelHash) then
        Redzone.Shared.Debug('[SELLWEAPON/ERROR] Impossible de charger le modèle: ', pedConfig.Model)
        return nil
    end

    local coords = Redzone.Shared.Vec4ToVec3(pedConfig.Coords)
    local heading = Redzone.Shared.GetHeadingFromVec4(pedConfig.Coords)

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, heading, false, true)

    if DoesEntityExist(ped) then
        if pedConfig.Invincible then
            SetEntityInvincible(ped, true)
        end

        if pedConfig.Frozen then
            FreezeEntityPosition(ped, true)
        end

        if pedConfig.BlockEvents then
            SetBlockingOfNonTemporaryEvents(ped, true)
        end

        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true)
        SetPedDiesWhenInjured(ped, false)

        if pedConfig.Scenario then
            TaskStartScenarioInPlace(ped, pedConfig.Scenario, 0, true)
        end

        Redzone.Client.Utils.UnloadModel(modelHash)
        Redzone.Shared.Debug('[SELLWEAPON] PED créé: ', pedConfig.name)

        return ped
    end

    Redzone.Shared.Debug('[SELLWEAPON/ERROR] Échec de la création du PED')
    return nil
end

---Supprime un PED de rachat
---@param ped number Le handle du PED à supprimer
local function DeleteSellWeaponPed(ped)
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
        Redzone.Shared.Debug('[SELLWEAPON] PED supprimé')
    end
end

-- =====================================================
-- INITIALISATION DES PEDS
-- =====================================================

---Crée tous les PEDs de rachat d'armes
function Redzone.Client.SellWeapon.CreateAllPeds()
    Redzone.Client.SellWeapon.DeleteAllPeds()

    for _, location in ipairs(SellWeaponLocations) do
        local ped = CreateSellWeaponPed(location)
        if ped then
            sellWeaponPeds[location.id] = {
                ped = ped,
                config = location
            }
        end
    end

    Redzone.Shared.Debug('[SELLWEAPON] Tous les PEDs ont été créés')
end

---Supprime tous les PEDs de rachat d'armes
function Redzone.Client.SellWeapon.DeleteAllPeds()
    for id, data in pairs(sellWeaponPeds) do
        DeleteSellWeaponPed(data.ped)
        sellWeaponPeds[id] = nil
    end
    Redzone.Shared.Debug('[SELLWEAPON] Tous les PEDs ont été supprimés')
end

-- =====================================================
-- DÉTECTION DES ARMES DU JOUEUR
-- =====================================================

---Obtient la liste des armes que le joueur possède avec leur prix de rachat
---@return table weapons Liste des armes {model, name, sellPrice}
local function GetPlayerWeaponsForSale()
    local weapons = {}
    local playerPed = PlayerPedId()

    for category, products in pairs(Config.ShopPeds.Products) do
        for _, product in ipairs(products) do
            if product.type == 'weapon' then
                local weaponHash = GetHashKey(product.model)
                if HasPedGotWeapon(playerPed, weaponHash, false) then
                    local sellPrice = math.floor(product.price * 0.4)
                    table.insert(weapons, {
                        model = product.model,
                        name = product.name,
                        sellPrice = sellPrice,
                    })
                end
            end
        end
    end

    return weapons
end

-- =====================================================
-- INTERACTION
-- =====================================================

---Vérifie si le joueur est proche d'un PED de rachat
---@return boolean isNear True si proche
---@return table|nil pedData Les données du PED le plus proche
function Redzone.Client.SellWeapon.IsPlayerNearSellPed()
    local playerCoords = Redzone.Client.Utils.GetPlayerCoords()
    local closestDistance = Config.Interaction.InteractDistance
    local closestPed = nil

    for id, data in pairs(sellWeaponPeds) do
        if DoesEntityExist(data.ped) then
            local pedCoords = Redzone.Shared.Vec4ToVec3(data.config.Coords)
            local distance = #(playerCoords - pedCoords)

            if distance <= closestDistance then
                closestDistance = distance
                closestPed = data
            end
        end
    end

    return closestPed ~= nil, closestPed
end

-- =====================================================
-- MENU DE VENTE (Style RageUI)
-- =====================================================

-- Dimensions et position du menu
local MENU = {
    x = 0.118,
    y = 0.070,
    width = 0.235,
    headerHeight = 0.038,
    itemHeight = 0.034,
    spacing = 0.0,
}

---Dessine un rectangle à l'écran
local function DrawMenuRect(x, y, w, h, r, g, b, a)
    DrawRect(x, y, w, h, r, g, b, a)
end

---Dessine un texte aligné à gauche dans le menu
local function DrawMenuText(x, y, text, scale, r, g, b, a)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow()
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

---Dessine un texte centré dans le menu
local function DrawMenuTextCentered(x, y, text, scale, r, g, b, a)
    SetTextFont(1)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(true)
    SetTextDropShadow()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

---Dessine un texte aligné à droite dans le menu
local function DrawMenuTextRight(x, y, text, scale, r, g, b, a)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow()
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextWrap(0.0, x)
    SetTextRightJustify(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0, y)
end

---Formate un prix en texte lisible
---@param price number Le prix
---@return string Le prix formaté
local function FormatPrice(price)
    local formatted = tostring(price)
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1.%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

---Affiche le menu de vente d'armes (style RageUI)
local function ShowSellMenu()
    isMenuOpen = true
    selectedIndex = 1

    local weapons = GetPlayerWeaponsForSale()
    local itemCount = #weapons

    if itemCount == 0 then
        Redzone.Client.Utils.NotifyError('Vous n\'avez aucune arme a vendre.')
        isMenuOpen = false
        return
    end

    CreateThread(function()
        while isMenuOpen do
            Wait(0)

            -- Rafraîchir la liste des armes (au cas où)
            weapons = GetPlayerWeaponsForSale()
            itemCount = #weapons

            if itemCount == 0 then
                isMenuOpen = false
                Redzone.Client.Utils.NotifyInfo('Plus aucune arme a vendre.')
                break
            end

            -- Ajuster l'index si nécessaire
            if selectedIndex > itemCount then
                selectedIndex = itemCount
            end

            local currentY = MENU.y + 0.015

            -- === HEADER (bandeau ROUGE) ===
            local headerY = currentY + MENU.headerHeight / 2
            DrawMenuRect(MENU.x, headerY, MENU.width, MENU.headerHeight, 200, 0, 0, 240)
            DrawMenuTextCentered(MENU.x, currentY + 0.005, 'VENDRE ARME', 0.45, 255, 255, 255, 255)
            currentY = currentY + MENU.headerHeight

            -- === ITEMS ===
            for i, weapon in ipairs(weapons) do
                local itemY = currentY + MENU.itemHeight / 2
                local priceText = FormatPrice(weapon.sellPrice)

                if i == selectedIndex then
                    -- Item sélectionné (fond blanc)
                    DrawMenuRect(MENU.x, itemY, MENU.width, MENU.itemHeight, 255, 255, 255, 240)
                    DrawMenuText(MENU.x - MENU.width / 2 + 0.008, currentY + 0.005, weapon.name, 0.33, 0, 0, 0, 255)
                    DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, priceText, 0.33, 0, 100, 0, 255)
                else
                    -- Item normal (fond noir semi-transparent)
                    DrawMenuRect(MENU.x, itemY, MENU.width, MENU.itemHeight, 0, 0, 0, 180)
                    DrawMenuText(MENU.x - MENU.width / 2 + 0.008, currentY + 0.005, weapon.name, 0.33, 255, 255, 255, 255)
                    DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, priceText, 0.33, 100, 255, 100, 255)
                end

                currentY = currentY + MENU.itemHeight + MENU.spacing
            end

            -- === FOOTER (compteur) ===
            local footerY = currentY + 0.012
            DrawMenuRect(MENU.x, footerY, MENU.width, 0.024, 0, 0, 0, 200)
            DrawMenuTextCentered(MENU.x, currentY + 0.002, tostring(selectedIndex) .. ' / ' .. tostring(itemCount), 0.30, 255, 255, 255, 200)

            -- === CONTRÔLES ===
            DisableControlAction(0, 27, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)

            -- Flèche Haut
            if IsDisabledControlJustPressed(0, 172) then
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then
                    selectedIndex = itemCount
                end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            -- Flèche Bas
            if IsDisabledControlJustPressed(0, 173) then
                selectedIndex = selectedIndex + 1
                if selectedIndex > itemCount then
                    selectedIndex = 1
                end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            -- Entrée pour vendre
            if IsControlJustPressed(0, 191) then
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                local selectedWeapon = weapons[selectedIndex]
                if selectedWeapon then
                    TriggerServerEvent('redzone:sellweapon:sell', selectedWeapon.model)
                end
            end

            -- Backspace pour fermer
            if IsControlJustPressed(0, 177) then
                PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                isMenuOpen = false
                Redzone.Shared.Debug('[SELLWEAPON] Menu fermé par le joueur')
            end
        end
    end)
end

-- =====================================================
-- THREAD D'INTERACTION
-- =====================================================

---Démarre le thread d'interaction avec les PEDs de rachat
function Redzone.Client.SellWeapon.StartInteractionThread()
    Redzone.Shared.Debug('[SELLWEAPON] Démarrage du thread d\'interaction')

    CreateThread(function()
        while true do
            local sleep = 1000

            if Redzone.Client.Teleport.IsInRedzone() then
                sleep = 200

                -- Afficher le texte 3D [VENDRE ARME] au-dessus des PEDs à moins de 15m
                local playerCoords = Redzone.Client.Utils.GetPlayerCoords()
                for _, data in pairs(sellWeaponPeds) do
                    if DoesEntityExist(data.ped) then
                        local pedCoords = GetEntityCoords(data.ped)
                        local dist = #(playerCoords - pedCoords)
                        if dist <= 15.0 then
                            sleep = 0
                            Redzone.Client.Utils.DrawText3D(vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.3), '[VENDRE ARME]', 0.45)
                        end
                    end
                end

                if not isMenuOpen then
                    local near, pedData = Redzone.Client.SellWeapon.IsPlayerNearSellPed()

                    if near then
                        sleep = 0
                        isNearSellPed = true
                        currentSellPed = pedData

                        Redzone.Client.Utils.ShowHelpText('Appuyez sur ~INPUT_CONTEXT~ pour vendre une arme')

                        if Redzone.Client.Utils.IsKeyJustPressed(Config.Interaction.InteractKey) then
                            ShowSellMenu()
                        end
                    else
                        isNearSellPed = false
                        currentSellPed = nil
                    end
                end
            else
                isNearSellPed = false
                currentSellPed = nil
            end

            Wait(sleep)
        end
    end)
end

-- =====================================================
-- ÉVÉNEMENTS D'ENTRÉE/SORTIE DU REDZONE
-- =====================================================

---Appelé quand le joueur entre dans le redzone
function Redzone.Client.SellWeapon.OnEnterRedzone()
    Redzone.Shared.Debug('[SELLWEAPON] Joueur entré dans le redzone - Création des PEDs')
    Redzone.Client.SellWeapon.CreateAllPeds()
end

---Appelé quand le joueur quitte le redzone
function Redzone.Client.SellWeapon.OnLeaveRedzone()
    Redzone.Shared.Debug('[SELLWEAPON] Joueur sorti du redzone - Suppression des PEDs')
    Redzone.Client.SellWeapon.DeleteAllPeds()
    isMenuOpen = false
end

-- =====================================================
-- ÉVÉNEMENTS SERVEUR
-- =====================================================

---Réception de la confirmation de retrait d'arme
RegisterNetEvent('redzone:sellweapon:removeWeapon')
AddEventHandler('redzone:sellweapon:removeWeapon', function(weaponModel)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponModel)
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        RemoveWeaponFromPed(playerPed, weaponHash)
    end
end)

-- =====================================================
-- NETTOYAGE
-- =====================================================

---Événement: Arrêt de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    Redzone.Client.SellWeapon.DeleteAllPeds()
    isMenuOpen = false

    Redzone.Shared.Debug('[SELLWEAPON] Nettoyage des PEDs effectué')
end)

-- =====================================================
-- INITIALISATION
-- =====================================================

Redzone.Shared.Debug('[CLIENT/SELLWEAPON] Module Vente Armes chargé')
