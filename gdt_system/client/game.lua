-- ==========================================
-- CLIENT GAME - GESTION DU JEU (v3.1 ZONE STABLE)
-- ==========================================
-- ✅ CORRECTIONS :
-- 1. Zone de combat ne clignote plus (dessin à 0ms)
-- 2. Logique optimisée (vérifications à 100ms)
-- 3. Threads séparés pour performances
-- ==========================================

local InCombatZone = false
local OutsideZoneStartTime = 0
local IsDead = false
local InGame = false
local StaminaThreadActive = false
local WeaponGiven = false
local IsPlayerStabilized = false
local CombatZoneGracePeriod = 0

local CurrentCombatZone = {
    center = vector3(0, 0, 0),
    radius = 100.0,
    damagePerSecond = 5,
    damageTickRate = 500,
    warningDistance = 10.0
}

-- ==========================================
-- DÉFINIR LA ZONE DE COMBAT
-- ==========================================

RegisterNetEvent('gdt:client:setCombatZone', function(zoneData)
    if not zoneData then return end
    
    CurrentCombatZone = {
        center = zoneData.center or vector3(0, 0, 0),
        radius = zoneData.radius or 100.0,
        damagePerSecond = zoneData.damagePerSecond or 5,
        damageTickRate = zoneData.damageTickRate or 500,
        warningDistance = zoneData.warningDistance or 10.0
    }
    
end)

-- ==========================================
-- TÉLÉPORTATION AU SPAWN DE COMBAT
-- ==========================================

RegisterNetEvent('gdt:client:teleportToSpawn', function(spawnPos)
    local ped = PlayerPedId()
    
    IsPlayerStabilized = false
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(ped, spawnPos.w)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    InGame = true
    WeaponGiven = false
    
    Citizen.CreateThread(function()
        Wait(2000)
        IsPlayerStabilized = true
    end)
    
    StartInfiniteStamina()
end)

-- ==========================================
-- TÉLÉPORTATION FIN DE PARTIE
-- ==========================================

RegisterNetEvent('gdt:client:teleportToEnd', function(endPos)
    local ped = PlayerPedId()
    
    IsPlayerStabilized = false
    InGame = false
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, endPos.x, endPos.y, endPos.z, false, false, false, true)
    SetEntityHeading(ped, endPos.w)
    
    HideTeamZones()
    StopCombatZone()
    SetInGDT(false)
    SetCurrentTeam(Constants.Teams.NONE)
    IsDead = false
    WeaponGiven = false
    
    Wait(500)
    DoScreenFadeIn(500)
    
end)

-- ==========================================
-- RÉANIMER LE JOUEUR
-- ==========================================

RegisterNetEvent('gdt:client:revivePlayer', function()
    local ped = PlayerPedId()
    
    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
        local coords = GetEntityCoords(ped)
        
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
        SetPlayerInvincible(PlayerId(), false)
        ClearPedBloodDamage(ped)
        
    end
    
    IsDead = false
end)

-- ==========================================
-- SOIGNER LE JOUEUR
-- ==========================================

RegisterNetEvent('gdt:client:healPlayer', function()
    local ped = PlayerPedId()

    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100) -- Armure complète (kevlar) à chaque round
    ClearPedBloodDamage(ped)
end)

-- ==========================================
-- DONNER UNE ARME
-- ==========================================

RegisterNetEvent('gdt:client:giveWeapon', function(weaponName, ammo)
    local ped = PlayerPedId()
    

    
    RemoveAllPedWeapons(ped, true)
    
    Wait(200)
    
    local weaponHash = GetHashKey(weaponName)
    GiveWeaponToPed(ped, weaponHash, ammo, false, true)
    
    Wait(200)
    
    SetCurrentPedWeapon(ped, weaponHash, true)
    
    Wait(100)
    
    local finalWeapon = GetSelectedPedWeapon(ped)
    
    if finalWeapon == weaponHash then
        WeaponGiven = true
        ESX.ShowNotification('Arme équipée : '..weaponName)
    else
        Citizen.CreateThread(function()
            Wait(500)
            
            SetCurrentPedWeapon(ped, weaponHash, true)
            
            Wait(200)
            
            local retryWeapon = GetSelectedPedWeapon(ped)
            if retryWeapon == weaponHash then
                WeaponGiven = true
                ESX.ShowNotification('Arme équipée : '..weaponName)
            else
                ESX.ShowNotification('ERREUR : Arme non équipée')
            end
        end)
    end
end)

-- ==========================================
-- VÉRIFICATION AUTOMATIQUE DE L'ARME
-- ==========================================

RegisterNetEvent('gdt:client:verifyWeapon', function(weaponName, ammo)
    Citizen.CreateThread(function()
        Wait(2000)
        
        local ped = PlayerPedId()
        local expectedHash = GetHashKey(weaponName)
        local currentWeapon = GetSelectedPedWeapon(ped)
        
        if currentWeapon ~= expectedHash then
            RemoveAllPedWeapons(ped, true)
            Wait(200)
            GiveWeaponToPed(ped, expectedHash, ammo, false, true)
            Wait(200)
            SetCurrentPedWeapon(ped, expectedHash, true)
            
            Wait(200)
            
            local finalCheck = GetSelectedPedWeapon(ped)
            if finalCheck == expectedHash then
                ESX.ShowNotification('Arme corrigée')
            else
                ESX.ShowNotification('ERREUR CRITIQUE : Contactez un admin')
            end
        end
    end)
end)

-- ==========================================
-- DÉMARRER LA ZONE DE COMBAT
-- ==========================================

RegisterNetEvent('gdt:client:startCombatZone', function()
    CombatZoneGracePeriod = GetGameTimer() + 3000
    InCombatZone = true
    
    
    StartCombatZoneThread()
end)

RegisterNetEvent('gdt:client:stopCombatZone', function()
    InCombatZone = false
    OutsideZoneStartTime = 0
    CombatZoneGracePeriod = 0
end)

function StopCombatZone()
    InCombatZone = false
    OutsideZoneStartTime = 0
    CombatZoneGracePeriod = 0
end

-- ==========================================
-- THREAD DE LA ZONE DE COMBAT (VERSION STABLE - ZONE BLANCHE)
-- ==========================================

function StartCombatZoneThread()
    -- ==========================================
    -- THREAD 1 : DESSIN DE LA ZONE (0ms - PRIORITÉ AFFICHAGE)
    -- ==========================================
    Citizen.CreateThread(function()
        while InCombatZone do
            local zoneCenter = CurrentCombatZone.center
            local radius = CurrentCombatZone.radius
            
            -- ✅ Dessiner le marker à CHAQUE frame pour éviter le clignotement
            DrawMarker(
                1, -- Type cylindre
                zoneCenter.x, zoneCenter.y, zoneCenter.z - 100.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                radius * 2.0, radius * 2.0, 200.0,
                255, 255, 255, 80, -- ✅ MODIFIÉ : BLANC au lieu de rouge (255, 0, 0)
                false, false, 2, nil, nil, false
            )
            
            Wait(0) -- ✅ CRITIQUE : 0ms pour un affichage fluide sans clignotement
        end
        

    end)
    
    -- ==========================================
    -- THREAD 2 : LOGIQUE DE LA ZONE (100ms - OPTIMISÉ)
    -- ==========================================
    Citizen.CreateThread(function()
        while InCombatZone do
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            
            local zoneCenter = CurrentCombatZone.center
            local radius = CurrentCombatZone.radius
            
            local distance = #(playerCoords - zoneCenter)
            
            -- 🛡️ Vérifier période de grâce ET stabilisation
            local now = GetGameTimer()
            local isInGracePeriod = (now < CombatZoneGracePeriod)
            
            if distance > radius then
                -- 🚨 Joueur HORS ZONE
                
                -- Ignorer si en période de grâce OU non stabilisé
                if isInGracePeriod or not IsPlayerStabilized then
                    if isInGracePeriod then
                        -- Afficher un warning visuel mais pas de dégâts
                        DrawText3D(playerCoords.x, playerCoords.y, playerCoords.z + 1.0, 'Stabilisation en cours...')
                    end
                    
                    -- Reset le timer pour éviter dégâts immédiats après grâce
                    OutsideZoneStartTime = 0
                else
                    -- Joueur hors zone et pas en grâce : APPLIQUER DÉGÂTS
                    if OutsideZoneStartTime == 0 then
                        OutsideZoneStartTime = GetGameTimer()
                        ESX.ShowNotification('⚠️ REVIENS DANS LA ZONE !')
                    end
                    
                    local timeOutside = GetGameTimer() - OutsideZoneStartTime
                    
                    if timeOutside >= CurrentCombatZone.damageTickRate then
                        local currentHealth = GetEntityHealth(ped)
                        local newHealth = currentHealth - CurrentCombatZone.damagePerSecond
                        
                        if newHealth <= 100 then
                            newHealth = 0
                        end
                        
                        SetEntityHealth(ped, newHealth)
                        OutsideZoneStartTime = GetGameTimer()
                        
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
                    end
                end
            else
                -- ✅ Joueur DANS la zone
                OutsideZoneStartTime = 0
            end
            
            -- ⚠️ Warning bordure proche
            local distToBorder = radius - distance
            if distToBorder < CurrentCombatZone.warningDistance and distToBorder > 0 then
                DrawText3D(playerCoords.x, playerCoords.y, playerCoords.z + 1.0, 'Attention : Bordure proche')
            end
            
            Wait(100) -- ✅ Optimisé : logique toutes les 100ms suffit
        end
        
    end)
    
    -- ==========================================
    -- THREAD DE DÉTECTION DE MORT (INCHANGÉ)
    -- ==========================================
    Citizen.CreateThread(function()
        while InCombatZone do
            local ped = PlayerPedId()
            
            if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
                if not IsDead then
                    IsDead = true
                    
                    local killerPed = GetPedSourceOfDeath(ped)
                    local killerServerId = nil
                    
                    if killerPed and killerPed ~= 0 and IsPedAPlayer(killerPed) then
                        killerServerId = NetworkGetPlayerIndexFromPed(killerPed)
                        
                        if killerServerId and killerServerId ~= -1 then
                            killerServerId = GetPlayerServerId(killerServerId)
                        else
                            killerServerId = nil
                        end
                    end
                    
                    local isTeamkill = false
                    
                    if killerServerId then
                        isTeamkill = exports['gdt_system']:IsTeammate(killerServerId)

                    end
                    
                    TriggerServerEvent('gdt:server:playerDied', killerServerId)
                    
                    if not isTeamkill then
                        local myTeam = GetCurrentTeam()
                        if myTeam and (myTeam == Constants.Teams.RED or myTeam == Constants.Teams.BLUE) then

                            Wait(2000)
                            StartSpectatorMode(myTeam)
                        end
                    else

                        ESX.ShowNotification('🚫 TEAMKILL ! Tu as été réanimé.')
                        
                        Wait(2000)
                        
                        local coords = GetEntityCoords(ped)
                        local heading = GetEntityHeading(ped)
                        
                        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
                        SetPlayerInvincible(PlayerId(), false)
                        ClearPedBloodDamage(ped)
                        SetEntityHealth(ped, GetEntityMaxHealth(ped))
                        SetPedArmour(ped, 100) -- Remettre l'armure après teamkill

                        Wait(200)
                        
                        local weaponName = Config.StartWeapon.weapon
                        local weaponAmmo = Config.StartWeapon.ammo
                        local weaponHash = GetHashKey(weaponName)
                        
                        RemoveAllPedWeapons(PlayerPedId(), true)
                        Wait(100)
                        GiveWeaponToPed(PlayerPedId(), weaponHash, weaponAmmo, false, true)
                        Wait(100)
                        SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)
                        

                        
                        IsDead = false
                    end
                end
            end
            
            Wait(1000)
        end
        

    end)
end

-- ==========================================
-- STAMINA INFINIE
-- ==========================================

function StartInfiniteStamina()
    if StaminaThreadActive or not Config.Gameplay.infiniteStamina then return end
    
    StaminaThreadActive = true
    
    Citizen.CreateThread(function()
        while InGame and Config.Gameplay.infiniteStamina do
            local playerId = PlayerId()
            
            ResetPlayerStamina(playerId)
            SetRunSprintMultiplierForPlayer(playerId, 1.05)
            SetSwimMultiplierForPlayer(playerId, 1.05)
            
            Wait(500)
        end
        
        StaminaThreadActive = false
    end)
end

-- ==========================================
-- KILLFEED - RÉCEPTION
-- ==========================================

RegisterNetEvent('gdt:client:showKillfeed', function(killerName, killerId, victimName, victimId)
    if not Config.Killfeed.enabled then return end
    
    SendNUIMessage({
        action = 'addKill',
        killer = {
            name = killerName,
            id = killerId
        },
        victim = {
            name = victimName,
            id = victimId
        },
        duration = Config.Killfeed.displayDuration
    })
end)

-- ==========================================
-- FONCTION UTILITAIRE : TEXTE 3D
-- ==========================================

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

function GetCurrentTeamForSpectator()
    return GetCurrentTeam()
end

exports('GetCurrentTeamForSpectator', GetCurrentTeamForSpectator)