-- ==========================================
-- CLIENT PED - GESTION DU PED GDT (SYNCHRONISÉ)
-- ==========================================
-- ✅ PED invisible par défaut au démarrage du script
-- ✅ Synchronisation serveur pour tous les joueurs
-- ✅ Les nouveaux connectés reçoivent l'état actuel
-- ==========================================

local PedEntity = nil
local PedBlip = nil
local PedEnabled = false -- État local du PED (désactivé par défaut)

-- ==========================================
-- INITIALISATION DU PED
-- ==========================================

function InitializePed()
    -- Ne pas créer le PED immédiatement
    -- Demander l'état au serveur
    TriggerServerEvent('gdt:server:requestPedState')
    Utils.Debug('Demande de l\'état du PED au serveur')
end

-- ==========================================
-- CRÉER LE PED
-- ==========================================

function CreateGDTPed()
    -- Vérifier si le PED existe déjà
    if PedEntity and DoesEntityExist(PedEntity) then
        Utils.Debug('PED déjà existant')
        return
    end
    
    local pedConfig = Config.PedLocation
    local modelHash = GetHashKey(pedConfig.model)
    
    -- Charger le modèle
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            Utils.Debug('ERREUR: Impossible de charger le modèle du PED')
            return
        end
    end
    
    -- Créer le PED
    PedEntity = CreatePed(4, modelHash, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z - 1.0, pedConfig.coords.w, false, true)
    
    if not PedEntity or PedEntity == 0 then
        Utils.Debug('ERREUR: Création du PED échouée')
        return
    end
    
    -- Configuration du PED
    SetEntityInvincible(PedEntity, pedConfig.invincible)
    SetBlockingOfNonTemporaryEvents(PedEntity, pedConfig.blockevents)
    FreezeEntityPosition(PedEntity, pedConfig.frozen)
    SetPedCanRagdoll(PedEntity, false)
    SetPedDiesWhenInjured(PedEntity, false)
    SetPedCanBeTargetted(PedEntity, false)
    
    -- Libérer le modèle
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Créer le blip
    CreatePedBlip()
    
    PedEnabled = true
    Utils.Debug('PED GDT créé avec succès')
end

-- ==========================================
-- SUPPRIMER LE PED
-- ==========================================

function DeleteGDTPed()
    -- Supprimer le blip
    if PedBlip and DoesBlipExist(PedBlip) then
        RemoveBlip(PedBlip)
        PedBlip = nil
    end
    
    -- Supprimer le PED
    if PedEntity and DoesEntityExist(PedEntity) then
        DeleteEntity(PedEntity)
        PedEntity = nil
    end
    
    PedEnabled = false
    Utils.Debug('PED GDT supprimé')
end

-- ==========================================
-- CRÉER LE BLIP DU PED
-- ==========================================

function CreatePedBlip()
    if PedBlip and DoesBlipExist(PedBlip) then return end
    if not PedEntity or not DoesEntityExist(PedEntity) then return end
    
    PedBlip = AddBlipForEntity(PedEntity)
    SetBlipSprite(PedBlip, 310) -- Icône de combat
    SetBlipDisplay(PedBlip, 4)
    SetBlipScale(PedBlip, 0.8)
    SetBlipColour(PedBlip, 1) -- Rouge
    SetBlipAsShortRange(PedBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Guerre de Territoire')
    EndTextCommandSetBlipName(PedBlip)
end

-- ==========================================
-- NETTOYAGE DU PED
-- ==========================================

function CleanupPed()
    DeleteGDTPed()
end

-- ==========================================
-- ÉVÉNEMENT : RECEVOIR L'ÉTAT DU PED DEPUIS LE SERVEUR
-- ==========================================

RegisterNetEvent('gdt:client:syncPedState', function(isEnabled)
    Utils.Debug('État du PED reçu du serveur: '..tostring(isEnabled))
    
    if isEnabled then
        -- PED activé : le créer s'il n'existe pas
        if not PedEntity or not DoesEntityExist(PedEntity) then
            CreateGDTPed()
        end
    else
        -- PED désactivé : le supprimer s'il existe
        if PedEntity and DoesEntityExist(PedEntity) then
            DeleteGDTPed()
        end
    end
    
    PedEnabled = isEnabled
end)

-- ==========================================
-- THREAD : INTERACTION AVEC LE PED
-- ==========================================

Citizen.CreateThread(function()
    while true do
        local sleep = 1000 -- Par défaut, vérification lente
        
        -- Vérifier uniquement si le PED est activé et existe
        if PedEnabled and PedEntity and DoesEntityExist(PedEntity) then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local pedCoords = GetEntityCoords(PedEntity)
            local distance = #(playerCoords - pedCoords)
            
            -- Si proche du PED
            if distance < Constants.Limits.MARKER_DRAW_DISTANCE then
                sleep = 0 -- Passer en mode rapide pour l'affichage

                -- Texte [GDT] au dessus de la tete
                local headPos = GetEntityCoords(PedEntity)
                DrawText3D(headPos.x, headPos.y, headPos.z + 1.5, '[GDT]')

                -- Afficher le marker
                DrawMarker(
                    1, -- Type
                    pedCoords.x, pedCoords.y, pedCoords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    255, 165, 0, 100, -- Orange
                    false, true, 2, nil, nil, false
                )
                
                -- Si très proche
                if distance < Constants.Limits.MAX_DISTANCE_CHECK then
                    -- Afficher le texte d'aide
                    ESX.ShowHelpNotification('Appuie sur ~INPUT_CONTEXT~ pour ouvrir le menu GDT')
                    
                    -- Vérifier l'input
                    if IsControlJustPressed(0, 38) then -- E
                        OpenUI()
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ==========================================
-- GETTERS
-- ==========================================

function IsPedEnabled()
    return PedEnabled
end

function GetPedEntity()
    return PedEntity
end

-- ==========================================
-- EXPORTS
-- ==========================================

exports('IsPedEnabled', IsPedEnabled)
exports('GetPedEntity', GetPedEntity)
exports('CreateGDTPed', CreateGDTPed)
exports('DeleteGDTPed', DeleteGDTPed)

-- ==========================================
-- TEXTE 3D AU DESSUS DU PED
-- ==========================================

function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry('STRING')
        AddTextComponentString(text)
        DrawText(screenX, screenY)
    end
end