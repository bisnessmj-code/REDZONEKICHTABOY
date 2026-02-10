-- ==========================================
-- CLIENT FRIENDLY FIRE - ANTI-TEAMKILL SYSTEM (v3.0 FINAL)
-- ==========================================
-- ? CORRECTION MAJEURE : Activation UNIQUEMENT quand la partie d�marre
-- ? PAS d'activation lors de la s�lection d'�quipe (lobby)
-- ==========================================

local FriendlyFireProtection = {
    active = false,
    myTeam = nil,
    myServerId = nil,
    teammatesCache = {},
    lastCacheUpdate = 0,
    cacheUpdateInterval = 500
}

local FFConfig = {
    enabled = true,
    showWarning = true,
    warningCooldown = 2000,
    disableMeleeDamage = true,
    disableVehicleDamage = true
}

local lastWarningTime = 0

-- ==========================================
-- ACTIVER LA PROTECTION
-- ==========================================

function StartFriendlyFireProtection(team)
    if not FFConfig.enabled then return end
    if FriendlyFireProtection.active then
        StopFriendlyFireProtection()
        Wait(200)
    end
    
    FriendlyFireProtection.active = true
    FriendlyFireProtection.myTeam = team
    FriendlyFireProtection.myServerId = GetPlayerServerId(PlayerId())
    FriendlyFireProtection.teammatesCache = {}
    
    TriggerServerEvent('gdt:server:requestTeammates', team)
    StartFriendlyFireThreads()
end

function StopFriendlyFireProtection()
    if not FriendlyFireProtection.active then return end
    
    
    FriendlyFireProtection.active = false
    FriendlyFireProtection.myTeam = nil
    FriendlyFireProtection.myServerId = nil
    FriendlyFireProtection.teammatesCache = {}
end

function UpdateTeammatesCache()
    local now = GetGameTimer()
    if (now - FriendlyFireProtection.lastCacheUpdate) < FriendlyFireProtection.cacheUpdateInterval then
        return
    end
    
    FriendlyFireProtection.lastCacheUpdate = now
    TriggerServerEvent('gdt:server:requestTeammates', FriendlyFireProtection.myTeam)
end

RegisterNetEvent('gdt:client:updateTeammatesCache', function(teammates)
    if not FriendlyFireProtection.active then return end
    
    FriendlyFireProtection.teammatesCache = {}
    
    local count = 0
    for _, teammate in ipairs(teammates) do
        if teammate.id ~= FriendlyFireProtection.myServerId then
            FriendlyFireProtection.teammatesCache[teammate.id] = true
            count = count + 1
        end
    end
end)

function IsTeammate(targetServerId)
    if not FriendlyFireProtection.active then return false end
    if not targetServerId or targetServerId == 0 then return false end
    if targetServerId == FriendlyFireProtection.myServerId then return false end
    
    return FriendlyFireProtection.teammatesCache[targetServerId] == true
end

function GetServerIdFromPed(ped)
    if not ped or ped == 0 then return nil end
    if not IsPedAPlayer(ped) then return nil end
    
    local playerIndex = NetworkGetPlayerIndexFromPed(ped)
    if playerIndex == -1 then return nil end
    
    return GetPlayerServerId(playerIndex)
end

function ShowFriendlyFireWarning()
    if not FFConfig.showWarning then return end
    
    local now = GetGameTimer()
    if (now - lastWarningTime) < FFConfig.warningCooldown then return end
    
    lastWarningTime = now
    ShakeGameplayCam('HAND_SHAKE', 0.1)
end

function StartFriendlyFireThreads()
    -- Thread principal : tir + melee
    Citizen.CreateThread(function()
        while FriendlyFireProtection.active do
            UpdateTeammatesCache()

            if IsPlayerFreeAiming(PlayerId()) then
                local success, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())

                if success and targetEntity and targetEntity ~= 0 then
                    if IsEntityAPed(targetEntity) and IsPedAPlayer(targetEntity) then
                        local targetServerId = GetServerIdFromPed(targetEntity)

                        if targetServerId and IsTeammate(targetServerId) then
                            DisablePlayerFiring(PlayerId(), true)

                            if IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) then
                                ShowFriendlyFireWarning()
                            end

                            SetEntityCanBeDamaged(targetEntity, false)
                            Citizen.SetTimeout(100, function()
                                if DoesEntityExist(targetEntity) then
                                    SetEntityCanBeDamaged(targetEntity, true)
                                end
                            end)
                        end
                    end
                end
            end

            if FFConfig.disableMeleeDamage and IsPedInMeleeCombat(PlayerPedId()) then
                local meleeTarget = GetMeleeTargetForPed(PlayerPedId())
                if meleeTarget and meleeTarget ~= 0 and IsPedAPlayer(meleeTarget) then
                    local targetServerId = GetServerIdFromPed(meleeTarget)
                    if targetServerId and IsTeammate(targetServerId) then
                        ClearPedTasks(PlayerPedId())
                        ShowFriendlyFireWarning()
                    end
                end
            end

            Wait(50)
        end
    end)

    -- ✅ P3 #13 : Thread véhicule - protection collision coéquipiers
    if FFConfig.disableVehicleDamage then
        Citizen.CreateThread(function()
            while FriendlyFireProtection.active do
                local myPed = PlayerPedId()
                local inVehicle = IsPedInAnyVehicle(myPed, false)
                local hasNearbyTeammateVehicle = false

                -- Vérifier si un coéquipier est dans un véhicule à proximité
                if not inVehicle then
                    for teammateId, _ in pairs(FriendlyFireProtection.teammatesCache) do
                        local playerIndex = GetPlayerFromServerId(teammateId)
                        if playerIndex ~= -1 then
                            local teammatePed = GetPlayerPed(playerIndex)
                            if teammatePed and teammatePed ~= 0 and DoesEntityExist(teammatePed) then
                                if IsPedInAnyVehicle(teammatePed, false) then
                                    hasNearbyTeammateVehicle = true
                                    break
                                end
                            end
                        end
                    end
                end

                if inVehicle or hasNearbyTeammateVehicle then
                    local myVehicle = inVehicle and GetVehiclePedIsIn(myPed, false) or nil

                    for teammateId, _ in pairs(FriendlyFireProtection.teammatesCache) do
                        local playerIndex = GetPlayerFromServerId(teammateId)
                        if playerIndex ~= -1 then
                            local teammatePed = GetPlayerPed(playerIndex)
                            if teammatePed and teammatePed ~= 0 and DoesEntityExist(teammatePed) then
                                -- Si je suis en véhicule : désactiver collision avec les peds coéquipiers
                                if myVehicle and myVehicle ~= 0 then
                                    SetEntityNoCollisionEntity(myVehicle, teammatePed, true)
                                end

                                -- Si un coéquipier est en véhicule : désactiver collision avec moi
                                if IsPedInAnyVehicle(teammatePed, false) then
                                    local teammateVehicle = GetVehiclePedIsIn(teammatePed, false)
                                    if teammateVehicle and teammateVehicle ~= 0 then
                                        SetEntityNoCollisionEntity(teammateVehicle, myPed, true)
                                    end
                                end
                            end
                        end
                    end

                    Wait(0) -- Chaque frame pour les collisions véhicule
                else
                    Wait(500) -- Idle : pas de véhicule impliqué
                end
            end
        end)
    end
end

-- ==========================================
-- ? CORRECTION : NE PLUS ACTIVER SUR applyTeamOutfit
-- ==========================================
-- On SUPPRIME l'activation automatique lors de la s�lection d'�quipe
-- La protection s'active UNIQUEMENT lors du teleportToSpawn (d�but de partie)

-- ==========================================
-- ? ACTIVATION LORS DU D�BUT DE PARTIE
-- ==========================================

RegisterNetEvent('gdt:client:teleportToSpawn', function(spawnPos)
    Citizen.CreateThread(function()
        Wait(500) -- Attendre t�l�portation compl�te
        
        local currentTeam = GetCurrentTeam()
        
        
        if currentTeam and (currentTeam == Constants.Teams.RED or currentTeam == Constants.Teams.BLUE) then
            StartFriendlyFireProtection(currentTeam)
        end
    end)
end)

-- ==========================================
-- D�SACTIVATION EN FIN DE PARTIE
-- ==========================================

RegisterNetEvent('gdt:client:teleportToEnd', function(endPos)
    StopFriendlyFireProtection()
end)

RegisterNetEvent('gdt:client:restorePlayer', function(originalOutfit)
    StopFriendlyFireProtection()
end)

-- ==========================================
-- EXPORTS
-- ==========================================

exports('StartFriendlyFireProtection', StartFriendlyFireProtection)
exports('StopFriendlyFireProtection', StopFriendlyFireProtection)
exports('IsTeammate', IsTeammate)
exports('IsFriendlyFireActive', function() return FriendlyFireProtection.active end)