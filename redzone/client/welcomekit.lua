--[[
    =====================================================
    REDZONE LEAGUE - Systeme Kit de Bienvenue (Client)
    =====================================================
    Ce fichier gere le PED du kit de bienvenue
    dans l'instance 0 (lobby).
]]

Redzone = Redzone or {}
Redzone.Client = Redzone.Client or {}
Redzone.Client.WelcomeKit = {}

-- =====================================================
-- VARIABLES LOCALES
-- =====================================================

-- Le PED du kit de bienvenue
local welcomeKitPed = nil

-- Statut: le joueur a-t-il deja recupere le kit
local hasClaimedKit = false

-- Cooldown pour eviter le spam d'interaction
local canInteract = true

-- =====================================================
-- CREATION DU PED
-- =====================================================

---Cree le PED du kit de bienvenue
local function CreateWelcomeKitPed()
    local config = Config.WelcomeKit.Ped
    if not config then return end

    local modelHash = GetHashKey(config.Model)
    if not Redzone.Client.Utils.LoadModel(modelHash) then
        Redzone.Shared.Debug('[WELCOMEKIT/ERROR] Impossible de charger le modele: ', config.Model)
        return
    end

    local coords = Redzone.Shared.Vec4ToVec3(config.Coords)
    local heading = Redzone.Shared.GetHeadingFromVec4(config.Coords)

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, heading, false, true)

    if DoesEntityExist(ped) then
        if config.Invincible then
            SetEntityInvincible(ped, true)
        end

        if config.Frozen then
            FreezeEntityPosition(ped, true)
        end

        if config.BlockEvents then
            SetBlockingOfNonTemporaryEvents(ped, true)
        end

        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true)
        SetPedDiesWhenInjured(ped, false)

        if config.Scenario then
            TaskStartScenarioInPlace(ped, config.Scenario, 0, true)
        end

        Redzone.Client.Utils.UnloadModel(modelHash)
        Redzone.Shared.Debug('[WELCOMEKIT] PED Kit de Bienvenue cree')

        welcomeKitPed = ped
    end
end

---Supprime le PED du kit de bienvenue
local function DeleteWelcomeKitPed()
    if welcomeKitPed and DoesEntityExist(welcomeKitPed) then
        DeleteEntity(welcomeKitPed)
        welcomeKitPed = nil
        Redzone.Shared.Debug('[WELCOMEKIT] PED Kit de Bienvenue supprime')
    end
end

-- =====================================================
-- EVENEMENTS SERVEUR
-- =====================================================

---Reception du statut du kit depuis le serveur
RegisterNetEvent('redzone:welcomekit:statusResult')
AddEventHandler('redzone:welcomekit:statusResult', function(alreadyClaimed)
    hasClaimedKit = alreadyClaimed
    Redzone.Shared.Debug('[WELCOMEKIT] Statut kit: ', tostring(alreadyClaimed))
end)

-- =====================================================
-- THREAD D'INTERACTION
-- =====================================================

---Demarre le thread d'interaction avec le PED kit de bienvenue
local function StartWelcomeKitThread()
    Redzone.Shared.Debug('[WELCOMEKIT] Demarrage du thread d\'interaction')

    -- Demander le statut au serveur
    TriggerServerEvent('redzone:welcomekit:checkStatus')

    CreateThread(function()
        while true do
            local sleep = 1000

            -- Seulement en dehors du redzone (instance 0)
            if not Redzone.Client.Teleport.IsInRedzone() then
                local config = Config.WelcomeKit.Ped
                if config and welcomeKitPed and DoesEntityExist(welcomeKitPed) then
                    local playerCoords = Redzone.Client.Utils.GetPlayerCoords()
                    local pedCoords = Redzone.Shared.Vec4ToVec3(config.Coords)
                    local distance = #(playerCoords - pedCoords)

                    -- Afficher le texte 3D au-dessus du PED a moins de 15m
                    if distance <= 15.0 then
                        sleep = 0

                        -- Afficher le label au-dessus du PED
                        local labelText = '[ KIT DE BIENVENUE ]'
                        if hasClaimedKit then
                            labelText = '[ KIT DE BIENVENUE - DEJA RECUPERE ]'
                        end
                        Redzone.Client.Utils.DrawText3D(vector3(pedCoords.x, pedCoords.y, pedCoords.z + 1.3), labelText, 0.45)

                        -- Interaction a portee
                        if distance <= Config.Interaction.InteractDistance then
                            if hasClaimedKit then
                                Redzone.Client.Utils.ShowHelpText('Vous avez deja recupere votre ~r~Kit de Bienvenue')
                            else
                                Redzone.Client.Utils.ShowHelpText('Appuyez sur ~INPUT_CONTEXT~ pour recuperer le ~g~Kit de Bienvenue')
                            end

                            if Redzone.Client.Utils.IsKeyJustPressed(Config.Interaction.InteractKey) and canInteract then
                                if hasClaimedKit then
                                    Redzone.Client.Utils.NotifyError('Vous avez deja recupere votre Kit de Bienvenue !')
                                else
                                    canInteract = false
                                    TriggerServerEvent('redzone:welcomekit:claim')

                                    -- Mettre a jour le statut localement
                                    hasClaimedKit = true

                                    -- Cooldown de 5 secondes
                                    SetTimeout(5000, function()
                                        canInteract = true
                                    end)
                                end
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

-- =====================================================
-- NETTOYAGE
-- =====================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DeleteWelcomeKitPed()
    Redzone.Shared.Debug('[WELCOMEKIT] Nettoyage effectue')
end)

-- =====================================================
-- INITIALISATION
-- =====================================================

CreateThread(function()
    Wait(5000)
    CreateWelcomeKitPed()
    StartWelcomeKitThread()
end)

Redzone.Shared.Debug('[CLIENT/WELCOMEKIT] Module Kit de Bienvenue charge')
