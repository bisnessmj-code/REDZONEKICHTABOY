--[[
    =====================================================
    REDZONE LEAGUE - Systeme de Banque
    =====================================================
    PEDs banque avec menu style RageUI pour deposer/retirer
    de l'argent du compte en banque.
]]

Redzone = Redzone or {}
Redzone.Client = Redzone.Client or {}
Redzone.Client.Bank = {}

-- =====================================================
-- VARIABLES LOCALES
-- =====================================================

local bankPeds = {}
local isBankMenuOpen = false
local selectedIndex = 1

-- Menu actuel: 'main', 'deposit', 'withdraw'
local currentMenu = 'main'

-- Montants disponibles pour depot/retrait
local amounts = {1000, 5000, 10000, 50000, 100000, 500000, 1000000}

-- Items du menu principal
local mainMenuItems = {
    { label = 'Deposer', action = 'deposit' },
    { label = 'Retirer', action = 'withdraw' },
}

-- =====================================================
-- CREATION DES PEDS BANQUE
-- =====================================================

local function CreateBankPed(location)
    local settings = Config.BankPeds.Settings
    local modelHash = GetHashKey(settings.Model)

    if not Redzone.Client.Utils.LoadModel(modelHash) then
        Redzone.Shared.Debug('[BANK/ERROR] Impossible de charger le modele: ', settings.Model)
        return nil
    end

    local coords = Redzone.Shared.Vec4ToVec3(location.Coords)
    local heading = Redzone.Shared.GetHeadingFromVec4(location.Coords)

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, heading, false, true)

    if DoesEntityExist(ped) then
        if settings.Invincible then SetEntityInvincible(ped, true) end
        if settings.Frozen then FreezeEntityPosition(ped, true) end
        if settings.BlockEvents then SetBlockingOfNonTemporaryEvents(ped, true) end

        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true)
        SetPedDiesWhenInjured(ped, false)

        if settings.Scenario then
            TaskStartScenarioInPlace(ped, settings.Scenario, 0, true)
        end

        Redzone.Client.Utils.UnloadModel(modelHash)
        Redzone.Shared.Debug('[BANK] PED banque cree: ', location.name)
        return ped
    end

    return nil
end

-- =====================================================
-- GESTION DES PEDS
-- =====================================================

function Redzone.Client.Bank.CreateAllPeds()
    Redzone.Client.Bank.DeleteAllPeds()

    for _, location in ipairs(Config.BankPeds.Locations) do
        local ped = CreateBankPed(location)
        if ped then
            bankPeds[location.id] = {
                ped = ped,
                config = location,
            }
        end
    end

    Redzone.Shared.Debug('[BANK] Tous les PEDs banque ont ete crees')
end

function Redzone.Client.Bank.DeleteAllPeds()
    for id, data in pairs(bankPeds) do
        if DoesEntityExist(data.ped) then
            DeleteEntity(data.ped)
        end
        bankPeds[id] = nil
    end
end

-- =====================================================
-- VERIFICATION PROXIMITE
-- =====================================================

local function IsPlayerNearBankPed()
    local playerCoords = Redzone.Client.Utils.GetPlayerCoords()
    local closestDist = Config.Interaction.InteractDistance
    local closestBank = nil

    for _, data in pairs(bankPeds) do
        if DoesEntityExist(data.ped) then
            local pedCoords = Redzone.Shared.Vec4ToVec3(data.config.Coords)
            local dist = #(playerCoords - pedCoords)
            if dist <= closestDist then
                closestDist = dist
                closestBank = data
            end
        end
    end

    return closestBank ~= nil, closestBank
end

-- =====================================================
-- MENU STYLE RAGEUI (DrawRect / DrawText)
-- =====================================================

-- Dimensions et position du menu (meme style que vehicle.lua)
local MENU = {
    x = 0.118,
    y = 0.070,
    width = 0.210,
    headerHeight = 0.038,
    itemHeight = 0.034,
    spacing = 0.0,
}

local function DrawMenuRect(x, y, w, h, r, g, b, a)
    DrawRect(x, y, w, h, r, g, b, a)
end

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

local function DrawMenuTextRight(x, y, text, scale, r, g, b, a)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextRightJustify(true)
    SetTextWrap(0.0, x)
    SetTextDropShadow()
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

-- =====================================================
-- CONSTRUCTION DES ITEMS SELON LE MENU
-- =====================================================

local function GetCurrentItems()
    if currentMenu == 'main' then
        return mainMenuItems
    elseif currentMenu == 'deposit' then
        local items = {}
        for _, amount in ipairs(amounts) do
            table.insert(items, { label = '$' .. Redzone.Shared.FormatNumber(amount), amount = amount })
        end
        table.insert(items, { label = 'Tout deposer', amount = 'all' })
        return items
    elseif currentMenu == 'withdraw' then
        local items = {}
        for _, amount in ipairs(amounts) do
            table.insert(items, { label = '$' .. Redzone.Shared.FormatNumber(amount), amount = amount })
        end
        table.insert(items, { label = 'Tout retirer', amount = 'all' })
        return items
    end
    return {}
end

local function GetMenuTitle()
    if currentMenu == 'main' then
        return 'BANK'
    elseif currentMenu == 'deposit' then
        return 'DEPOSER'
    elseif currentMenu == 'withdraw' then
        return 'RETIRER'
    end
    return 'BANK'
end

-- =====================================================
-- OUVERTURE DU MENU
-- =====================================================

local function OpenBankMenu()
    if isBankMenuOpen then return end
    isBankMenuOpen = true
    currentMenu = 'main'
    selectedIndex = 1

    CreateThread(function()
        while isBankMenuOpen do
            Wait(0)

            local items = GetCurrentItems()
            local itemCount = #items
            local title = GetMenuTitle()

            if itemCount == 0 then
                isBankMenuOpen = false
                break
            end

            -- Clamper l'index
            if selectedIndex > itemCount then selectedIndex = itemCount end
            if selectedIndex < 1 then selectedIndex = 1 end

            local currentY = MENU.y + 0.015

            -- === HEADER (bandeau vert pour banque) ===
            local headerY = currentY + MENU.headerHeight / 2
            DrawMenuRect(MENU.x, headerY, MENU.width, MENU.headerHeight, 0, 150, 0, 240)
            DrawMenuTextCentered(MENU.x, currentY + 0.005, title, 0.45, 255, 255, 255, 255)
            currentY = currentY + MENU.headerHeight

            -- === ITEMS ===
            for i, item in ipairs(items) do
                local itemY = currentY + MENU.itemHeight / 2

                if i == selectedIndex then
                    -- Item selectionne (fond blanc)
                    DrawMenuRect(MENU.x, itemY, MENU.width, MENU.itemHeight, 255, 255, 255, 240)
                    DrawMenuText(MENU.x - MENU.width / 2 + 0.008, currentY + 0.005, item.label, 0.33, 0, 0, 0, 255)

                    -- Fleche droite pour les sous-menus
                    if currentMenu == 'main' then
                        if item.action == 'deposit' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, '>>>', 0.33, 0, 120, 0, 255)
                        elseif item.action == 'withdraw' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, '>>>', 0.33, 200, 0, 0, 255)
                        end
                    end

                    -- Label "TOUT" pour les options tout deposer/retirer
                    if item.amount == 'all' then
                        if currentMenu == 'deposit' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, 'TOUT', 0.33, 0, 120, 0, 255)
                        elseif currentMenu == 'withdraw' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, 'TOUT', 0.33, 200, 0, 0, 255)
                        end
                    end
                else
                    -- Item normal (fond noir semi-transparent)
                    DrawMenuRect(MENU.x, itemY, MENU.width, MENU.itemHeight, 0, 0, 0, 180)
                    DrawMenuText(MENU.x - MENU.width / 2 + 0.008, currentY + 0.005, item.label, 0.33, 255, 255, 255, 255)

                    if currentMenu == 'main' then
                        if item.action == 'deposit' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, '>>>', 0.33, 0, 180, 0, 200)
                        elseif item.action == 'withdraw' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, '>>>', 0.33, 200, 0, 0, 200)
                        end
                    end

                    if item.amount == 'all' then
                        if currentMenu == 'deposit' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, 'TOUT', 0.33, 0, 180, 0, 200)
                        elseif currentMenu == 'withdraw' then
                            DrawMenuTextRight(MENU.x + MENU.width / 2 - 0.008, currentY + 0.005, 'TOUT', 0.33, 200, 0, 0, 200)
                        end
                    end
                end

                currentY = currentY + MENU.itemHeight + MENU.spacing
            end

            -- === FOOTER (compteur) ===
            local footerY = currentY + 0.012
            DrawMenuRect(MENU.x, footerY, MENU.width, 0.024, 0, 0, 0, 200)
            DrawMenuTextCentered(MENU.x, currentY + 0.002, tostring(selectedIndex) .. ' / ' .. tostring(itemCount), 0.30, 255, 255, 255, 200)

            -- === CONTROLES ===
            DisableControlAction(0, 27, true)   -- Phone
            DisableControlAction(0, 172, true)  -- Arrow Up
            DisableControlAction(0, 173, true)  -- Arrow Down

            -- Fleche Haut
            if IsDisabledControlJustPressed(0, 172) then
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then
                    selectedIndex = itemCount
                end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            -- Fleche Bas
            if IsDisabledControlJustPressed(0, 173) then
                selectedIndex = selectedIndex + 1
                if selectedIndex > itemCount then
                    selectedIndex = 1
                end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            -- Entree pour valider
            if IsControlJustPressed(0, 191) then
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                local item = items[selectedIndex]

                if currentMenu == 'main' then
                    -- Ouvrir sous-menu
                    currentMenu = item.action
                    selectedIndex = 1
                elseif currentMenu == 'deposit' then
                    if item.amount == 'all' then
                        TriggerServerEvent('redzone:bank:depositAll')
                    else
                        TriggerServerEvent('redzone:bank:deposit', item.amount)
                    end
                    isBankMenuOpen = false
                elseif currentMenu == 'withdraw' then
                    if item.amount == 'all' then
                        TriggerServerEvent('redzone:bank:withdrawAll')
                    else
                        TriggerServerEvent('redzone:bank:withdraw', item.amount)
                    end
                    isBankMenuOpen = false
                end
            end

            -- Backspace pour retour / fermer
            if IsControlJustPressed(0, 177) then
                PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

                if currentMenu == 'main' then
                    -- Fermer le menu
                    isBankMenuOpen = false
                else
                    -- Retour au menu principal
                    currentMenu = 'main'
                    selectedIndex = 1
                end
            end
        end
    end)
end

-- =====================================================
-- THREAD D'INTERACTION
-- =====================================================

function Redzone.Client.Bank.StartInteractionThread()
    Redzone.Shared.Debug('[BANK] Demarrage du thread d\'interaction banque')

    CreateThread(function()
        while true do
            local sleep = 1000

            if Redzone.Client.Teleport and Redzone.Client.Teleport.IsInRedzone() then
                sleep = 200

                -- Afficher [BANK] au-dessus des PEDs a moins de 15m
                local playerCoords = Redzone.Client.Utils.GetPlayerCoords()
                for _, data in pairs(bankPeds) do
                    if DoesEntityExist(data.ped) then
                        local pedCoords = GetEntityCoords(data.ped)
                        local dist = #(playerCoords - pedCoords)
                        if dist <= 15.0 then
                            sleep = 0
                            Redzone.Client.Utils.DrawText3D(vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.3), '[BANK]', 0.45)
                        end
                    end
                end

                if not isBankMenuOpen then
                    local near, bankData = IsPlayerNearBankPed()
                    if near then
                        sleep = 0
                        Redzone.Client.Utils.ShowHelpText(Config.BankPeds.Settings.HelpText)

                        if Redzone.Client.Utils.IsKeyJustPressed(Config.Interaction.InteractKey) then
                            OpenBankMenu()
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

-- =====================================================
-- EVENEMENTS ENTREE/SORTIE REDZONE
-- =====================================================

function Redzone.Client.Bank.OnEnterRedzone()
    Redzone.Shared.Debug('[BANK] Joueur entre dans le redzone - Creation des PEDs banque')
    Redzone.Client.Bank.CreateAllPeds()
end

function Redzone.Client.Bank.OnLeaveRedzone()
    Redzone.Shared.Debug('[BANK] Joueur sorti du redzone - Suppression des PEDs banque')
    Redzone.Client.Bank.DeleteAllPeds()
    isBankMenuOpen = false
end

-- =====================================================
-- NETTOYAGE
-- =====================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Redzone.Client.Bank.DeleteAllPeds()
end)

-- =====================================================
-- INITIALISATION
-- =====================================================

Redzone.Shared.Debug('[CLIENT/BANK] Module Banque charge')
