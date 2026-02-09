--[[
    Noclip - Panel Admin Fight League
    Mode noclip avec controles personnalises
]]

local Noclip = {}

-- Etat du noclip
local isNoclipActive = false
local noclipCam = nil
local originalCoords = nil
local originalHeading = nil
local currentNoclipPos = nil -- Position actuelle en noclip
local currentCamRot = nil -- Rotation actuelle de la camera
local isFirstPerson = true -- Mode premiere personne par defaut

-- Vitesses
local normalSpeed = 1.0
local fastSpeed = 3.0
local slowSpeed = 0.3
local currentSpeed = normalSpeed

-- Multiplicateur de vitesse (controlable avec la molette)
local speedMultiplier = 1.0
local minSpeedMultiplier = 0.1
local maxSpeedMultiplier = 10.0
local speedStep = 0.2 -- Increment par scroll

-- Distance camera troisieme personne
local thirdPersonDistance = 5.0

-- Clipset pour eviter la T-Pose
local noclipClipset = "move_m@confident"
local clipsetLoaded = false

-- Animation idle pour la troisieme personne
local idleAnimDict = "amb@world_human_hang_out_street@female_hold_arm@idle_a"
local idleAnimName = "idle_a"
local idleAnimLoaded = false

-- Menu rapide joueur
local isQuickMenuOpen = false
local isQuickMenuFocused = false -- true = focus clavier actif (peut interagir), false = peut bouger
local targetedPlayerId = nil
local targetedPlayerData = nil

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Activer le noclip
function Noclip.Enable()
    if isNoclipActive then return end

    local playerPed = PlayerPedId()

    -- Attendre que le ped soit valide
    if not DoesEntityExist(playerPed) then
        return
    end

    -- Verifier si le joueur est dans un vehicule
    local coords, heading
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        coords = GetEntityCoords(vehicle)
        heading = GetEntityHeading(vehicle)
        if Config.Debug then print('[NOCLIP] Joueur dans vehicule, coords vehicule utilisees') end
    else
        coords = GetEntityCoords(playerPed)
        heading = GetEntityHeading(playerPed)
    end

    -- Verification que les coords sont valides (pas a l'origine)
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then
        -- Attendre un frame et reessayer
        Wait(0)
        coords = GetEntityCoords(playerPed)
        heading = GetEntityHeading(playerPed)
        if Config.Debug then print('[NOCLIP] Coords etaient a 0,0,0 - retry') end
    end

    if Config.Debug then print('[NOCLIP] Position actuelle du joueur: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z) end

    -- Si le joueur est dans un vehicule, le faire sortir
    if IsPedInAnyVehicle(playerPed, false) then
        TaskLeaveAnyVehicle(playerPed, 0, 0)
        Wait(100) -- Attendre la sortie
        -- Recuperer les nouvelles coords apres sortie
        coords = GetEntityCoords(playerPed)
        heading = GetEntityHeading(playerPed)
        if Config.Debug then print('[NOCLIP] Joueur sorti du vehicule, nouvelles coords: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z) end
    end

    -- Sauvegarder la position originale
    originalCoords = coords
    originalHeading = heading

    -- Initialiser la position noclip a la position actuelle du joueur
    currentNoclipPos = vector3(coords.x, coords.y, coords.z + 0.5)
    currentCamRot = vector3(0.0, 0.0, heading)

    if Config.Debug then print('[NOCLIP] Position noclip initialisee: ' .. currentNoclipPos.x .. ', ' .. currentNoclipPos.y .. ', ' .. currentNoclipPos.z) end

    -- Charger le clipset pour eviter la T-Pose
    RequestClipSet(noclipClipset)
    local clipTimeout = 0
    while not HasClipSetLoaded(noclipClipset) and clipTimeout < 50 do
        Wait(10)
        clipTimeout = clipTimeout + 1
    end
    clipsetLoaded = HasClipSetLoaded(noclipClipset)

    -- Precharger l'animation idle pour la troisieme personne
    RequestAnimDict(idleAnimDict)
    local animTimeout = 0
    while not HasAnimDictLoaded(idleAnimDict) and animTimeout < 50 do
        Wait(10)
        animTimeout = animTimeout + 1
    end
    idleAnimLoaded = HasAnimDictLoaded(idleAnimDict)

    -- Rendre le joueur invisible pour les AUTRES joueurs
    SetEntityVisible(playerPed, false, false)
    -- Rendre le joueur invisible localement aussi (mode premiere personne par defaut)
    SetLocalPlayerVisibleLocally(false)
    SetEntityInvincible(playerPed, true)
    SetEntityCollision(playerPed, false, false)

    -- IMPORTANT: Freeze le ped pour que les autres joueurs ne voient pas l'animation de chute
    FreezeEntityPosition(playerPed, true)

    -- Arreter toutes les animations/taches en cours (empeche l'animation de chute)
    ClearPedTasksImmediately(playerPed)

    -- Teleporter le joueur a la position noclip (pour synchroniser)
    SetEntityCoords(playerPed, currentNoclipPos.x, currentNoclipPos.y, currentNoclipPos.z, false, false, false, false)
    SetEntityHeading(playerPed, heading)

    -- Creer la camera
    noclipCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(noclipCam, currentNoclipPos.x, currentNoclipPos.y, currentNoclipPos.z)
    SetCamRot(noclipCam, 0.0, 0.0, heading, 2)
    SetCamFov(noclipCam, 70.0)
    RenderScriptCams(true, true, 500, true, true)

    -- Reset mode premiere personne
    isFirstPerson = true

    isNoclipActive = true

    if Config.Debug then print('[NOCLIP] Active - Camera et joueur a: ' .. currentNoclipPos.x .. ', ' .. currentNoclipPos.y .. ', ' .. currentNoclipPos.z) end

    -- Log serveur
    TriggerServerEvent('panel:log', 'noclip_start', nil)
end

-- Desactiver le noclip
function Noclip.Disable()
    if not isNoclipActive then return end

    local playerPed = PlayerPedId()

    -- Sauvegarder la position actuelle avant de detruire la camera
    local finalPos = currentNoclipPos

    if Config.Debug then print('[NOCLIP] Desactivation - Position finale: ' .. (finalPos and (finalPos.x .. ', ' .. finalPos.y .. ', ' .. finalPos.z) or 'nil')) end

    -- Marquer comme inactif AVANT les autres operations
    isNoclipActive = false

    -- Detruire la camera
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(noclipCam, false)
    noclipCam = nil

    -- Restaurer l'etat du joueur
    FreezeEntityPosition(playerPed, false) -- Defreeze le ped
    SetEntityCollision(playerPed, true, true)
    SetEntityVisible(playerPed, true, false) -- Visible pour les autres
    SetLocalPlayerVisibleLocally(true) -- Visible localement
    SetEntityInvincible(playerPed, false)
    ResetEntityAlpha(playerPed) -- Restaurer l'opacite normale
    ClearPedTasks(playerPed) -- Nettoyer les taches/animations
    ResetPedMovementClipset(playerPed, 0.0) -- Reset le clipset
    clipsetLoaded = false
    idleAnimLoaded = false

    -- Teleporter le joueur a la position finale (garde la position exacte, pas de retour au sol)
    if finalPos then
        SetEntityCoords(playerPed, finalPos.x, finalPos.y, finalPos.z, false, false, false, false)
        if Config.Debug then print('[NOCLIP] Teleportation finale: ' .. finalPos.x .. ', ' .. finalPos.y .. ', ' .. finalPos.z) end
    end

    -- Nettoyer
    currentNoclipPos = nil
    currentCamRot = nil

    -- Reset le multiplicateur de vitesse pour la prochaine utilisation
    speedMultiplier = 1.0

    -- Log serveur
    TriggerServerEvent('panel:log', 'noclip_end', nil)
end

-- Toggle noclip
function Noclip.Toggle()
    if isNoclipActive then
        Noclip.Disable()
    else
        Noclip.Enable()
    end
end

-- Verifier si noclip actif
function Noclip.IsActive()
    return isNoclipActive
end

-- Mettre a jour la position noclip (pour teleportation en noclip)
function Noclip.SetPosition(x, y, z)
    if isNoclipActive then
        currentNoclipPos = vector3(x, y, z + 1.0)
        if noclipCam then
            SetCamCoord(noclipCam, x, y, z + 1.0)
        end
        return true
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
-- CONTROLES
-- ══════════════════════════════════════════════════════════════

-- Fonction pour changer de vue
function Noclip.ToggleView()
    isFirstPerson = not isFirstPerson
    -- Pas de notification - changement silencieux
end

-- Thread de controle du noclip
CreateThread(function()
    while true do
        if isNoclipActive and noclipCam and currentCamRot and currentNoclipPos then
            Wait(0)

            local playerPed = PlayerPedId()

            -- Verification supplementaire anti-race condition
            if not isNoclipActive or not currentCamRot then
                goto continue
            end

            -- Toggle vue avec V (INPUT_NEXT_CAMERA = 0)
            if IsDisabledControlJustPressed(0, 0) then
                Noclip.ToggleView()
            end

            -- Rotation de la camera avec la souris
            local mouseX = GetDisabledControlNormal(0, 1) -- Souris X
            local mouseY = GetDisabledControlNormal(0, 2) -- Souris Y

            local newRotX = currentCamRot.x - mouseY * 5.0
            local newRotZ = currentCamRot.z - mouseX * 5.0

            -- Limiter la rotation verticale
            if newRotX > 89.0 then newRotX = 89.0 end
            if newRotX < -89.0 then newRotX = -89.0 end

            currentCamRot = vector3(newRotX, 0.0, newRotZ)

            -- Calculer la direction
            local radZ = math.rad(newRotZ)
            local radX = math.rad(newRotX)

            local cosZ = math.cos(radZ)
            local sinZ = math.sin(radZ)
            local cosX = math.cos(radX)

            -- Gestion de la vitesse avec la molette de la souris
            -- Scroll UP (241) = augmenter la vitesse
            if IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 15) then
                speedMultiplier = speedMultiplier + speedStep
                if speedMultiplier > maxSpeedMultiplier then
                    speedMultiplier = maxSpeedMultiplier
                end
                -- Notification visuelle de la vitesse
                ShowSpeedIndicator(speedMultiplier)
            end

            -- Scroll DOWN (242) = diminuer la vitesse
            if IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 14) then
                speedMultiplier = speedMultiplier - speedStep
                if speedMultiplier < minSpeedMultiplier then
                    speedMultiplier = minSpeedMultiplier
                end
                -- Notification visuelle de la vitesse
                ShowSpeedIndicator(speedMultiplier)
            end

            -- Vitesse de base
            currentSpeed = normalSpeed

            -- Maj Gauche (Left Shift) = plus rapide (INPUT_SPRINT = 21)
            if IsDisabledControlPressed(0, 21) then
                currentSpeed = fastSpeed
            end

            -- Alt Gauche = plus lent (INPUT_CHARACTER_WHEEL = 19)
            if IsDisabledControlPressed(0, 19) then
                currentSpeed = slowSpeed
            end

            -- Appliquer le multiplicateur de vitesse
            currentSpeed = currentSpeed * speedMultiplier

            local moveX = 0.0
            local moveY = 0.0
            local moveZ = 0.0

            -- Z = Avancer (INPUT_MOVE_UP_ONLY = 32, mais on utilise le controle direct)
            -- Controle 32 = W en QWERTY, donc Z en AZERTY
            if IsDisabledControlPressed(0, 32) then
                moveX = moveX + (-sinZ * currentSpeed * 0.5)
                moveY = moveY + (cosZ * currentSpeed * 0.5)
                moveZ = moveZ + (math.sin(radX) * currentSpeed * 0.5)
            end

            -- S = Reculer (INPUT_MOVE_DOWN_ONLY = 33)
            if IsDisabledControlPressed(0, 33) then
                moveX = moveX + (sinZ * currentSpeed * 0.5)
                moveY = moveY + (-cosZ * currentSpeed * 0.5)
                moveZ = moveZ + (-math.sin(radX) * currentSpeed * 0.5)
            end

            -- Q = Gauche (INPUT_MOVE_LEFT_ONLY = 34)
            if IsDisabledControlPressed(0, 34) then
                moveX = moveX + (-cosZ * currentSpeed * 0.5)
                moveY = moveY + (-sinZ * currentSpeed * 0.5)
            end

            -- D = Droite (INPUT_MOVE_RIGHT_ONLY = 35)
            if IsDisabledControlPressed(0, 35) then
                moveX = moveX + (cosZ * currentSpeed * 0.5)
                moveY = moveY + (sinZ * currentSpeed * 0.5)
            end

            -- A = Monter (INPUT_CONTEXT = 51 pour E en QWERTY, on utilise 44 pour Q en QWERTY = A en AZERTY)
            -- Utilisons INPUT_COVER = 44 (Q en QWERTY = A en AZERTY)
            if IsDisabledControlPressed(0, 44) then
                moveZ = moveZ + (currentSpeed * 0.5)
            end

            -- E = Descendre (INPUT_CONTEXT = 51, E en QWERTY)
            if IsDisabledControlPressed(0, 51) then
                moveZ = moveZ + (-currentSpeed * 0.5)
            end

            -- Appliquer le mouvement a la position du joueur
            local newX = currentNoclipPos.x + moveX
            local newY = currentNoclipPos.y + moveY
            local newZ = currentNoclipPos.z + moveZ

            -- Stocker la nouvelle position
            currentNoclipPos = vector3(newX, newY, newZ)

            -- Mettre a jour la position du joueur
            SetEntityCoords(playerPed, newX, newY, newZ, false, false, false, false)
            SetEntityVelocity(playerPed, 0.0, 0.0, 0.0) -- Empecher la chute

            -- En premiere personne: freeze le ped (invisible)
            -- En troisieme personne: ne pas freeze pour l'animation
            if isFirstPerson then
                FreezeEntityPosition(playerPed, true)
                SetEntityHeading(playerPed, newRotZ)
            end

            -- S'assurer que le ped n'a pas d'animation de chute (seulement en 1ere personne)
            if isFirstPerson and IsPedFalling(playerPed) then
                ClearPedTasksImmediately(playerPed)
            end

            -- IMPORTANT: Toujours garder le joueur invisible pour les AUTRES joueurs
            SetEntityVisible(playerPed, false, false)

            -- Positionner la camera selon le mode de vue
            if isFirstPerson then
                -- Premiere personne: camera a la position du joueur
                SetCamCoord(noclipCam, newX, newY, newZ)
                SetCamRot(noclipCam, newRotX, 0.0, newRotZ, 2)

                -- Cacher le joueur localement aussi en premiere personne
                SetLocalPlayerVisibleLocally(false)
                SetEntityAlpha(playerPed, 0, false)

                -- Reset clipset et animation en premiere personne
                ResetPedMovementClipset(playerPed, 0.0)
                ClearPedTasks(playerPed)
            else
                -- Troisieme personne: camera derriere le joueur
                local camX = newX - (-math.sin(math.rad(newRotZ)) * thirdPersonDistance)
                local camY = newY - (math.cos(math.rad(newRotZ)) * thirdPersonDistance)
                local camZ = newZ + 2.0 - (math.sin(math.rad(newRotX)) * thirdPersonDistance * 0.5)

                SetCamCoord(noclipCam, camX, camY, camZ)
                SetCamRot(noclipCam, newRotX, 0.0, newRotZ, 2)

                -- Rendre le joueur visible LOCALEMENT seulement (semi-transparent)
                SetLocalPlayerVisibleLocally(true)
                SetEntityAlpha(playerPed, 150, false) -- Semi-transparent (0-255)

                -- Orienter le ped DOS a la camera (face a la direction de mouvement)
                local pedHeading = (newRotZ + 180.0) % 360.0
                SetEntityHeading(playerPed, pedHeading)

                -- Garder le ped freeze pour eviter les animations de chute
                FreezeEntityPosition(playerPed, true)

                -- Jouer une animation idle pour une pose naturelle (bras le long du corps)
                if not idleAnimLoaded then
                    RequestAnimDict(idleAnimDict)
                    if HasAnimDictLoaded(idleAnimDict) then
                        idleAnimLoaded = true
                    end
                end

                if idleAnimLoaded and not IsEntityPlayingAnim(playerPed, idleAnimDict, idleAnimName, 3) then
                    TaskPlayAnim(playerPed, idleAnimDict, idleAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)
                end

                -- Empecher le ped de bouger
                SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
            end

            -- Desactiver les controles normaux
            DisableControlAction(0, 0, true)   -- V (next camera)
            DisableControlAction(0, 1, true)   -- Souris X
            DisableControlAction(0, 2, true)   -- Souris Y
            DisableControlAction(0, 24, true)  -- Attaque (clic gauche)
            DisableControlAction(0, 25, true)  -- Viser
            DisableControlAction(0, 32, true)  -- W
            DisableControlAction(0, 33, true)  -- S
            DisableControlAction(0, 34, true)  -- A
            DisableControlAction(0, 35, true)  -- D
            DisableControlAction(0, 44, true)  -- Q (cover)
            DisableControlAction(0, 51, true)  -- E (context)
            DisableControlAction(0, 21, true)  -- Shift
            DisableControlAction(0, 19, true)  -- Alt
            DisableControlAction(0, 14, true)  -- Scroll down (weapon wheel)
            DisableControlAction(0, 15, true)  -- Scroll up (weapon wheel)
            DisableControlAction(0, 241, true) -- Scroll up
            DisableControlAction(0, 242, true) -- Scroll down

            -- Crosshair desactive
            -- DrawCrosshair()

            -- Dessiner l'indicateur de vitesse (si actif)
            DrawSpeedIndicator()

            -- Detecter le clic gauche pour ouvrir le menu rapide
            if IsDisabledControlJustPressed(0, 24) and not isQuickMenuOpen then
                local serverId, playerName, targetPed = GetPlayerInCrosshair()
                if serverId then
                    OpenQuickMenu(serverId, playerName, targetPed)
                end
            end

            -- Detecter le clic droit pour supprimer vehicules/objets
            if IsDisabledControlJustPressed(0, 25) and not isQuickMenuOpen then
                DeleteEntityInCrosshair()
            end

            -- Gestion du quick menu ouvert
            if isQuickMenuOpen then
                -- ALT (INPUT_CHARACTER_WHEEL = 19) pour toggle le focus clavier
                if IsDisabledControlJustPressed(0, 19) then
                    ToggleQuickMenuFocus()
                end

                -- Echap (INPUT_FRONTEND_CANCEL = 200) pour fermer le menu
                if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then
                    CloseQuickMenu()
                end

                -- Desactiver la touche Echap pour ne pas ouvrir le menu pause
                DisableControlAction(0, 200, true)
                DisableControlAction(0, 177, true)
            end

            -- HUD desactive pour un affichage plus propre
            -- DrawNoclipHUD(currentSpeed, newX, newY, newZ, isFirstPerson)
        else
            Wait(500)
        end

        ::continue::
    end
end)

-- Afficher le HUD du noclip
function DrawNoclipHUD(speed, x, y, z, firstPerson)
    local speedText = 'Normal'
    if speed == fastSpeed then
        speedText = 'Rapide'
    elseif speed == slowSpeed then
        speedText = 'Lent'
    end

    local viewText = firstPerson and '1ere' or '3eme'

    -- HUD en bas
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.0, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry('STRING')
    AddTextComponentString('~b~NOCLIP~w~ | Vue: ~c~' .. viewText .. '~w~ | Vitesse: ' .. speedText .. '~w~ | Pos: ~y~' .. string.format('%.1f, %.1f, %.1f', x, y, z))
    DrawText(0.5, 0.93)

    -- Instructions ligne 1
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.0, 0.3)
    SetTextColour(200, 200, 200, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry('STRING')
    AddTextComponentString('~w~ZQSD: Deplacement | A: Monter | E: Descendre | V: Vue | Shift: Rapide | Alt: Lent')
    DrawText(0.5, 0.95)

    -- Instructions ligne 2 (actions souris)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.0, 0.3)
    SetTextColour(200, 200, 200, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry('STRING')
    AddTextComponentString('~g~Clic Gauche~w~: Menu joueur | ~r~Clic Droit~w~: Supprimer vehicule/objet')
    DrawText(0.5, 0.975)
end

-- ══════════════════════════════════════════════════════════════
-- SUPPRESSION D'ENTITES (CLIC DROIT)
-- ══════════════════════════════════════════════════════════════

-- Supprimer le vehicule ou objet vise par le crosshair
function DeleteEntityInCrosshair()
    if not noclipCam then return end

    local camCoords = GetCamCoord(noclipCam)
    local camRot = GetCamRot(noclipCam, 2)

    -- Calculer la direction de la camera
    local radX = math.rad(camRot.x)
    local radZ = math.rad(camRot.z)

    local dirX = -math.sin(radZ) * math.cos(radX)
    local dirY = math.cos(radZ) * math.cos(radX)
    local dirZ = math.sin(radX)

    -- Point de destination du raycast (100m devant)
    local endCoords = vector3(
        camCoords.x + dirX * 100.0,
        camCoords.y + dirY * 100.0,
        camCoords.z + dirZ * 100.0
    )

    -- Raycast pour detecter les vehicules (flags: 2 = vehicules, 16 = objets, 256 = vehicules aussi)
    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 26, PlayerPedId(), 0)
    local _, hit, hitCoords, _, hitEntity = GetShapeTestResult(rayHandle)

    if hit and hitEntity and DoesEntityExist(hitEntity) then
        if IsEntityAVehicle(hitEntity) then
            -- Vehicules: tous les staffs peuvent supprimer
            DeleteVehicleEntity(hitEntity)
        elseif IsEntityAnObject(hitEntity) then
            -- Objets: verifier permission admin uniquement
            TryDeleteObject(hitEntity)
        end
    else
        -- Methode alternative: chercher le vehicule/objet le plus proche du crosshair
        local closestEntity = GetClosestEntityInCrosshair(camCoords, endCoords)

        if closestEntity and DoesEntityExist(closestEntity) then
            if IsEntityAVehicle(closestEntity) then
                -- Vehicules: tous les staffs peuvent supprimer
                DeleteVehicleEntity(closestEntity)
            elseif IsEntityAnObject(closestEntity) then
                -- Objets: verifier permission admin uniquement
                TryDeleteObject(closestEntity)
            end
        else
            TriggerEvent('panel:notification', {
                type = 'warning',
                title = 'Noclip',
                message = 'Aucun vehicule ou objet vise'
            })
        end
    end
end

-- Verifier la permission et supprimer l'objet si autorise (Admin uniquement)
function TryDeleteObject(object)
    if not DoesEntityExist(object) then return end

    -- Verifier la permission cote serveur
    ESX.TriggerServerCallback('panel:canDeleteObject', function(canDelete)
        if canDelete then
            DeleteObjectEntity(object)
        else
            TriggerEvent('panel:notification', {
                type = 'error',
                title = 'Permission refusee',
                message = 'Seuls les admins peuvent supprimer des objets'
            })
        end
    end)
end

-- Supprimer un vehicule proprement (avec eject des occupants)
function DeleteVehicleEntity(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(model)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    -- Faire sortir tous les occupants du vehicule
    local hasOccupants = false
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            TaskLeaveVehicle(ped, vehicle, 16) -- 16 = sortie immediate
            hasOccupants = true
        end
    end

    -- Utiliser un thread separe pour ne pas freeze
    CreateThread(function()
        -- Attendre un peu que les joueurs sortent (seulement s'il y avait des occupants)
        if hasOccupants then
            Wait(300)
        end

        -- Verifier si le vehicule existe toujours
        if not DoesEntityExist(vehicle) then
            TriggerEvent('panel:notification', {
                type = 'success',
                title = 'Supprime',
                message = 'Vehicule supprime: ' .. modelName .. ' [' .. plate .. ']'
            })
            return
        end

        -- Demander le controle reseau du vehicule
        local timeout = 0
        NetworkRequestControlOfEntity(vehicle)
        while not NetworkHasControlOfEntity(vehicle) and timeout < 10 do
            Wait(50)
            NetworkRequestControlOfEntity(vehicle)
            timeout = timeout + 1
        end

        if NetworkHasControlOfEntity(vehicle) and DoesEntityExist(vehicle) then
            -- Supprimer cote client
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)

            TriggerEvent('panel:notification', {
                type = 'success',
                title = 'Supprime',
                message = 'Vehicule supprime: ' .. modelName .. ' [' .. plate .. ']'
            })
        else
            -- Demander au serveur de supprimer
            TriggerServerEvent('panel:deleteVehicleByNetId', netId)

            TriggerEvent('panel:notification', {
                type = 'success',
                title = 'Supprime',
                message = 'Vehicule supprime: ' .. modelName .. ' [' .. plate .. ']'
            })
        end

        -- Log serveur
        TriggerServerEvent('panel:log', 'delete_vehicle_noclip', {model = modelName, plate = plate})
    end)
end

-- Supprimer un objet proprement
function DeleteObjectEntity(object)
    if not DoesEntityExist(object) then return end

    local model = GetEntityModel(object)
    local netId = NetworkGetNetworkIdFromEntity(object)

    -- Utiliser un thread separe pour ne pas freeze
    CreateThread(function()
        -- Demander le controle reseau
        local timeout = 0
        NetworkRequestControlOfEntity(object)
        while not NetworkHasControlOfEntity(object) and timeout < 10 do
            Wait(50)
            NetworkRequestControlOfEntity(object)
            timeout = timeout + 1
        end

        if NetworkHasControlOfEntity(object) and DoesEntityExist(object) then
            SetEntityAsMissionEntity(object, true, true)
            DeleteObject(object)

            TriggerEvent('panel:notification', {
                type = 'success',
                title = 'Supprime',
                message = 'Objet supprime'
            })
        else
            -- Demander au serveur de supprimer
            TriggerServerEvent('panel:deleteObjectByNetId', netId)

            TriggerEvent('panel:notification', {
                type = 'success',
                title = 'Supprime',
                message = 'Objet supprime'
            })
        end

        -- Log serveur
        TriggerServerEvent('panel:log', 'delete_object_noclip', {model = model})
    end)
end

-- Trouver l'entite la plus proche du centre de l'ecran
function GetClosestEntityInCrosshair(camCoords, endCoords)
    local bestEntity = nil
    local bestDist = 999

    -- Chercher les vehicules proches
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local dist = #(camCoords - vehCoords)

            if dist < 50.0 then -- Dans les 50m
                local onScreen, screenX, screenY = World3dToScreen2d(vehCoords.x, vehCoords.y, vehCoords.z)
                if onScreen then
                    -- Distance au centre de l'ecran
                    local screenDist = math.sqrt((screenX - 0.5)^2 + (screenY - 0.5)^2)
                    if screenDist < 0.1 and screenDist < bestDist then -- Dans le crosshair
                        bestDist = screenDist
                        bestEntity = vehicle
                    end
                end
            end
        end
    end

    -- Chercher les objets proches (seulement si pas de vehicule trouve)
    if not bestEntity then
        local objects = GetGamePool('CObject')
        for _, object in ipairs(objects) do
            if DoesEntityExist(object) then
                local objCoords = GetEntityCoords(object)
                local dist = #(camCoords - objCoords)

                if dist < 30.0 then -- Dans les 30m pour les objets
                    local onScreen, screenX, screenY = World3dToScreen2d(objCoords.x, objCoords.y, objCoords.z)
                    if onScreen then
                        local screenDist = math.sqrt((screenX - 0.5)^2 + (screenY - 0.5)^2)
                        if screenDist < 0.1 and screenDist < bestDist then
                            bestDist = screenDist
                            bestEntity = object
                        end
                    end
                end
            end
        end
    end

    return bestEntity
end

-- ══════════════════════════════════════════════════════════════
-- CROSSHAIR ET MENU RAPIDE
-- ══════════════════════════════════════════════════════════════

-- Dessiner le crosshair au centre de l'ecran
function DrawCrosshair()
    local centerX, centerY = 0.5, 0.5
    local size = 0.012
    local thickness = 0.002

    -- Ligne horizontale
    DrawRect(centerX, centerY, size, thickness, 255, 255, 255, 200)
    -- Ligne verticale
    DrawRect(centerX, centerY, thickness, size, 255, 255, 255, 200)
    -- Point central
    DrawRect(centerX, centerY, 0.003, 0.004, 255, 100, 100, 255)
end

-- Variables pour l'indicateur de vitesse
local speedIndicatorTimer = 0
local speedIndicatorDuration = 2000 -- 2 secondes

-- Afficher l'indicateur de vitesse (appele quand on change la vitesse)
function ShowSpeedIndicator(multiplier)
    speedIndicatorTimer = GetGameTimer() + speedIndicatorDuration
end

-- Dessiner l'indicateur de vitesse a l'ecran
function DrawSpeedIndicator()
    if GetGameTimer() < speedIndicatorTimer then
        local multiplierText = string.format('%.1fx', speedMultiplier)

        -- Couleur selon la vitesse
        local r, g, b = 255, 255, 255
        if speedMultiplier > 2.0 then
            r, g, b = 255, 100, 100 -- Rouge pour tres rapide
        elseif speedMultiplier > 1.0 then
            r, g, b = 255, 200, 100 -- Orange pour rapide
        elseif speedMultiplier < 0.5 then
            r, g, b = 100, 200, 255 -- Bleu pour lent
        elseif speedMultiplier < 1.0 then
            r, g, b = 150, 255, 150 -- Vert clair pour un peu lent
        end

        -- Fond semi-transparent
        DrawRect(0.5, 0.15, 0.08, 0.04, 0, 0, 0, 150)

        -- Texte de la vitesse
        SetTextFont(4)
        SetTextProportional(1)
        SetTextScale(0.0, 0.5)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)
        SetTextEntry('STRING')
        AddTextComponentString('~w~Vitesse: ~s~' .. multiplierText)
        DrawText(0.5, 0.135)

        -- Barre de progression visuelle
        local barWidth = 0.06
        local barHeight = 0.006
        local barX = 0.5
        local barY = 0.17

        -- Fond de la barre
        DrawRect(barX, barY, barWidth, barHeight, 50, 50, 50, 200)

        -- Barre de progression (0.1x a 10x = 0% a 100%)
        local progress = (speedMultiplier - minSpeedMultiplier) / (maxSpeedMultiplier - minSpeedMultiplier)
        local fillWidth = barWidth * progress
        local fillX = barX - (barWidth / 2) + (fillWidth / 2)
        DrawRect(fillX, barY, fillWidth, barHeight, r, g, b, 255)
    end
end

-- Obtenir le joueur vise par le crosshair
function GetPlayerInCrosshair()
    if not noclipCam then return nil end

    local camCoords = GetCamCoord(noclipCam)
    local camRot = GetCamRot(noclipCam, 2)

    -- Calculer la direction de la camera
    local radX = math.rad(camRot.x)
    local radZ = math.rad(camRot.z)

    local dirX = -math.sin(radZ) * math.cos(radX)
    local dirY = math.cos(radZ) * math.cos(radX)
    local dirZ = math.sin(radX)

    -- Point de destination du raycast (100m devant)
    local endCoords = vector3(
        camCoords.x + dirX * 100.0,
        camCoords.y + dirY * 100.0,
        camCoords.z + dirZ * 100.0
    )

    -- Raycast pour detecter les peds
    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 8, PlayerPedId(), 0)
    local _, hit, hitCoords, _, hitEntity = GetShapeTestResult(rayHandle)

    if hit and hitEntity and IsEntityAPed(hitEntity) and not IsPedAPlayer(hitEntity) == false then
        -- Trouver le serverId du joueur
        for _, playerId in ipairs(GetActivePlayers()) do
            if GetPlayerPed(playerId) == hitEntity then
                return GetPlayerServerId(playerId), GetPlayerName(playerId), hitEntity
            end
        end
    end

    -- Methode alternative: verifier la distance au centre de l'ecran pour chaque joueur
    local myPed = PlayerPedId()
    local bestTarget = nil
    local bestDist = 999

    for _, playerId in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= myPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(camCoords - targetCoords)

            if dist < 50.0 then -- Dans les 50m
                local onScreen, screenX, screenY = World3dToScreen2d(targetCoords.x, targetCoords.y, targetCoords.z)
                if onScreen then
                    -- Distance au centre de l'ecran
                    local screenDist = math.sqrt((screenX - 0.5)^2 + (screenY - 0.5)^2)
                    if screenDist < 0.05 and screenDist < bestDist then -- Dans le crosshair
                        bestDist = screenDist
                        bestTarget = {
                            serverId = GetPlayerServerId(playerId),
                            name = GetPlayerName(playerId),
                            ped = targetPed
                        }
                    end
                end
            end
        end
    end

    if bestTarget then
        return bestTarget.serverId, bestTarget.name, bestTarget.ped
    end

    return nil, nil, nil
end

-- Ouvrir le menu rapide pour un joueur
function OpenQuickMenu(serverId, playerName, targetPed)
    if not serverId then return end

    isQuickMenuOpen = true
    isQuickMenuFocused = false -- Par defaut, on peut bouger
    targetedPlayerId = serverId

    -- Recuperer les infos du joueur
    local health = GetEntityHealth(targetPed) - 100
    local maxHealth = GetEntityMaxHealth(targetPed) - 100
    local armor = GetPedArmour(targetPed)
    local coords = GetEntityCoords(targetPed)

    if health < 0 then health = 0 end
    if maxHealth < 100 then maxHealth = 100 end

    -- Recuperer le groupe de l'admin qui ouvre le menu
    local myGroup = 'user'
    local xPlayer = ESX.GetPlayerData()
    if xPlayer and xPlayer.group then
        myGroup = xPlayer.group
    end

    targetedPlayerData = {
        serverId = serverId,
        name = playerName,
        health = health,
        maxHealth = maxHealth,
        armor = armor,
        coords = {x = coords.x, y = coords.y, z = coords.z},
        adminGroup = myGroup -- Groupe de l'admin pour les permissions
    }

    -- Envoyer au NUI
    -- Par defaut: pas de focus clavier (ZQSD fonctionne), mais curseur souris actif
    SetNuiFocus(false, true)
    SendNUIMessage({
        type = 'openQuickMenu',
        player = targetedPlayerData,
        focusMode = false
    })
end

-- Activer/Desactiver le focus clavier du menu (ALT pour toggle)
function ToggleQuickMenuFocus()
    if not isQuickMenuOpen then return end

    isQuickMenuFocused = not isQuickMenuFocused

    if isQuickMenuFocused then
        -- Focus actif: peut interagir avec le menu (taper du texte, etc.)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'quickMenuFocusChanged',
            focused = true
        })
    else
        -- Focus desactive: peut bouger avec ZQSD
        SetNuiFocus(false, true)
        SendNUIMessage({
            type = 'quickMenuFocusChanged',
            focused = false
        })
    end
end

-- Fermer le menu rapide
function CloseQuickMenu()
    isQuickMenuOpen = false
    isQuickMenuFocused = false
    targetedPlayerId = nil
    targetedPlayerData = nil

    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeQuickMenu'
    })
end

-- NUI Callbacks pour le menu rapide
RegisterNUICallback('quickMenuAction', function(data, cb)
    local action = data.action
    local targetId = data.targetId

    if action == 'teleport' then
        -- TP vers le joueur
        ESX.TriggerServerCallback('panel:gotoPlayer', function(result)
            if result and result.success then
                -- Mettre a jour la position noclip
                if result.coords then
                    currentNoclipPos = vector3(result.coords.x, result.coords.y, result.coords.z + 1.0)
                end
            end
        end, targetId)
        CloseQuickMenu()
    elseif action == 'bring' then
        -- Amener le joueur vers nous
        if currentNoclipPos then
            TriggerServerEvent('panel:bringPlayer', targetId, {
                x = currentNoclipPos.x,
                y = currentNoclipPos.y,
                z = currentNoclipPos.z
            })
        end
        CloseQuickMenu()
    elseif action == 'return' then
        -- Retourner le joueur a sa position precedente
        TriggerServerEvent('panel:returnPlayer', targetId)
        CloseQuickMenu()
    elseif action == 'spectate' then
        CloseQuickMenu()
        Noclip.Disable()
        Wait(500)
        TriggerEvent('panel:spectate', targetId)
    elseif action == 'kick' then
        -- Garder le menu ouvert et demander la raison
        SendNUIMessage({
            type = 'showKickInput',
            targetId = targetId
        })
    elseif action == 'confirmKick' then
        -- Kick avec raison
        TriggerServerEvent('panel:kickPlayer', targetId, data.reason or 'Kick par un administrateur')
        CloseQuickMenu()
    elseif action == 'freeze' then
        TriggerServerEvent('panel:freezePlayer', targetId)
    elseif action == 'heal' then
        -- Heal le joueur
        TriggerServerEvent('panel:healPlayer', targetId)
        CloseQuickMenu()
    elseif action == 'armor' then
        -- Donner de l'armure au joueur
        TriggerServerEvent('panel:armorPlayer', targetId)
        CloseQuickMenu()
    elseif action == 'confirmMessage' then
        -- Envoyer un message au joueur
        if data.message and data.message ~= '' then
            TriggerServerEvent('panel:sendMessageToPlayer', targetId, data.message)
        end
        CloseQuickMenu()
    elseif action == 'confirmBan' then
        -- Ban le joueur
        TriggerServerEvent('panel:banPlayerFromQuickMenu', targetId, data.reason or 'Aucune raison', data.duration or '1d')
        CloseQuickMenu()
    elseif action == 'confirmVehicle' then
        -- Spawn un vehicule pour le joueur
        if data.model and data.model ~= '' then
            TriggerServerEvent('panel:spawnVehicleForPlayer', targetId, data.model, data.color or 5)
        end
        CloseQuickMenu()
    elseif action == 'close' then
        CloseQuickMenu()
    end

    cb({success = true})
end)

RegisterNUICallback('closeQuickMenu', function(data, cb)
    CloseQuickMenu()
    cb({success = true})
end)

-- Callback pour que le NUI puisse demander le focus clavier (quand on clique sur un input)
RegisterNUICallback('requestKeyboardFocus', function(data, cb)
    if isQuickMenuOpen then
        isQuickMenuFocused = true
        SetNuiFocus(true, true)
    end
    cb({success = true})
end)

-- Callback pour que le NUI puisse relacher le focus clavier
RegisterNUICallback('releaseKeyboardFocus', function(data, cb)
    if isQuickMenuOpen then
        isQuickMenuFocused = false
        SetNuiFocus(false, true)
    end
    cb({success = true})
end)

-- ══════════════════════════════════════════════════════════════
-- COMMANDES ET KEYBIND
-- ══════════════════════════════════════════════════════════════

-- Commande pour toggle noclip (keybind)
RegisterCommand('+panel_noclip', function()
    -- Verifier les permissions via le serveur
    TriggerServerEvent('panel:checkNoclipPermission')
end, false)

RegisterCommand('-panel_noclip', function() end, false)

-- Enregistrer la touche (configurable dans Paramètres > Raccourcis clavier)
RegisterKeyMapping('+panel_noclip', 'Panel Admin - Noclip', 'keyboard', 'F2')

-- Commande /noclip pour le staff
RegisterCommand('noclip', function()
    -- Verifier les permissions via le serveur (meme verification que le keybind)
    TriggerServerEvent('panel:checkNoclipPermission')
end, false)

-- Suggestion de la commande
TriggerEvent('chat:addSuggestion', '/noclip', 'Activer/Desactiver le mode noclip (Staff)')

-- Event de reponse du serveur pour la permission
RegisterNetEvent('panel:noclipAllowed', function()
    Noclip.Toggle()
end)

RegisterNetEvent('panel:noclipDenied', function()
    TriggerEvent('panel:notification', {
        type = 'error',
        title = 'Noclip',
        message = 'Vous n\'avez pas la permission d\'utiliser le noclip'
    })
end)

-- ══════════════════════════════════════════════════════════════
-- CLEANUP
-- ══════════════════════════════════════════════════════════════

-- Nettoyer si le joueur se deconnecte ou si la resource s'arrete
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isNoclipActive then
            Noclip.Disable()
        end
        -- Nettoyer les fantomes de deconnexion
        CleanupAllDisconnectGhosts()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- FANTOMES DE DECONNEXION
-- ══════════════════════════════════════════════════════════════

-- Cache des fantomes de deconnexion
local disconnectGhosts = {}
local GHOST_DURATION = 5 * 60 * 1000 -- 5 minutes en millisecondes

-- Modele de ped pour les fantomes
local ghostModel = `mp_m_freemode_01`

-- Recevoir les infos de deconnexion depuis le serveur
RegisterNetEvent('panel:playerDisconnected', function(ghostData)
    if not ghostData or not ghostData.coords then return end

    -- Creer un identifiant unique pour ce fantome
    local ghostId = ghostData.serverId .. '_' .. ghostData.timestamp

    -- Stocker les infos du fantome
    disconnectGhosts[ghostId] = {
        serverId = ghostData.serverId,
        name = ghostData.name,
        coords = ghostData.coords,
        timestamp = GetGameTimer(),
        reason = ghostData.reason,
        ped = nil, -- Sera cree quand le noclip est actif
        blip = nil
    }

    if Config and Config.Debug then
        print('^3[GHOST]^0 Fantome de deconnexion ajoute: ' .. ghostData.name .. ' (ID: ' .. ghostData.serverId .. ')')
    end
end)

-- Creer un ped fantome
local function CreateGhostPed(ghostData)
    if ghostData.ped and DoesEntityExist(ghostData.ped) then
        return ghostData.ped
    end

    -- Charger le modele
    RequestModel(ghostModel)
    local timeout = 0
    while not HasModelLoaded(ghostModel) and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(ghostModel) then
        return nil
    end

    -- Creer le ped
    local ped = CreatePed(4, ghostModel, ghostData.coords.x, ghostData.coords.y, ghostData.coords.z - 1.0, 0.0, false, false)

    if ped and DoesEntityExist(ped) then
        -- Configurer le ped fantome
        SetEntityAlpha(ped, 150, false) -- Semi-transparent
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)

        -- Animation idle
        local animDict = "amb@world_human_hang_out_street@female_hold_arm@idle_a"
        RequestAnimDict(animDict)
        local animTimeout = 0
        while not HasAnimDictLoaded(animDict) and animTimeout < 30 do
            Wait(10)
            animTimeout = animTimeout + 1
        end
        if HasAnimDictLoaded(animDict) then
            TaskPlayAnim(ped, animDict, "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
        end

        -- Rendre le ped rouge/orange pour indiquer un fantome
        SetPedDefaultComponentVariation(ped)
    end

    SetModelAsNoLongerNeeded(ghostModel)

    return ped
end

-- Supprimer un ped fantome
local function DeleteGhostPed(ghostId)
    local ghost = disconnectGhosts[ghostId]
    if ghost then
        if ghost.ped and DoesEntityExist(ghost.ped) then
            DeleteEntity(ghost.ped)
        end
        if ghost.blip and DoesBlipExist(ghost.blip) then
            RemoveBlip(ghost.blip)
        end
        ghost.ped = nil
        ghost.blip = nil
    end
end

-- Nettoyer tous les fantomes
function CleanupAllDisconnectGhosts()
    for ghostId, ghost in pairs(disconnectGhosts) do
        DeleteGhostPed(ghostId)
    end
    disconnectGhosts = {}
end

-- Dessiner le texte 3D au-dessus du fantome
local function DrawGhostText3D(x, y, z, text, subText)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z + 1.2)

    if onScreen then
        -- Texte principal (nom du joueur)
        SetTextScale(0.0, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 150, 50, 255) -- Orange
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(screenX, screenY)

        -- Sous-texte (ID et temps restant)
        SetTextScale(0.0, 0.25)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(200, 200, 200, 200)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString(subText)
        DrawText(screenX, screenY + 0.025)

        -- Indicateur "DECONNECTE"
        SetTextScale(0.0, 0.2)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 100, 100, 255) -- Rouge
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString("~r~[DECONNECTE]")
        DrawText(screenX, screenY - 0.03)
    end
end

-- Thread pour gerer les fantomes de deconnexion
CreateThread(function()
    while true do
        local sleepTime = 500

        if isNoclipActive then
            sleepTime = 0
            local currentTime = GetGameTimer()
            local ghostsToRemove = {}

            for ghostId, ghost in pairs(disconnectGhosts) do
                -- Verifier si le fantome a expire (5 minutes)
                local elapsed = currentTime - ghost.timestamp
                if elapsed >= GHOST_DURATION then
                    table.insert(ghostsToRemove, ghostId)
                else
                    -- Creer le ped si necessaire
                    if not ghost.ped or not DoesEntityExist(ghost.ped) then
                        ghost.ped = CreateGhostPed(ghost)
                    end

                    -- Calculer le temps restant
                    local remainingMs = GHOST_DURATION - elapsed
                    local remainingMin = math.floor(remainingMs / 60000)
                    local remainingSec = math.floor((remainingMs % 60000) / 1000)

                    -- Dessiner le texte
                    local mainText = ghost.name
                    local subText = "ID: " .. ghost.serverId .. " | " .. string.format("%d:%02d", remainingMin, remainingSec) .. " restant"

                    DrawGhostText3D(ghost.coords.x, ghost.coords.y, ghost.coords.z, mainText, subText)

                    -- Dessiner un marqueur au sol
                    DrawMarker(
                        1, -- Type: cercle
                        ghost.coords.x, ghost.coords.y, ghost.coords.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        1.5, 1.5, 0.5,
                        255, 100, 50, 100, -- Orange semi-transparent
                        false, false, 2, nil, nil, false
                    )
                end
            end

            -- Supprimer les fantomes expires
            for _, ghostId in ipairs(ghostsToRemove) do
                DeleteGhostPed(ghostId)
                disconnectGhosts[ghostId] = nil
                if Config and Config.Debug then
                    print('^3[GHOST]^0 Fantome expire et supprime: ' .. ghostId)
                end
            end
        else
            -- Noclip desactive: supprimer tous les peds fantomes mais garder les donnees
            for ghostId, ghost in pairs(disconnectGhosts) do
                if ghost.ped and DoesEntityExist(ghost.ped) then
                    DeleteEntity(ghost.ped)
                    ghost.ped = nil
                end
                if ghost.blip and DoesBlipExist(ghost.blip) then
                    RemoveBlip(ghost.blip)
                    ghost.blip = nil
                end

                -- Verifier si le fantome a expire
                local elapsed = GetGameTimer() - ghost.timestamp
                if elapsed >= GHOST_DURATION then
                    disconnectGhosts[ghostId] = nil
                end
            end
        end

        Wait(sleepTime)
    end
end)

-- Export global
_G.Noclip = Noclip
