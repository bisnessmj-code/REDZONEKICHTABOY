Gunward.Client.SafeZone = {}

local blips = {}
local isInSafeZone = false
local lastHealth = nil

-- ============================================================
-- BLIPS
-- ============================================================

function Gunward.Client.SafeZone.CreateBlips()
    Gunward.Client.SafeZone.RemoveBlips()

    for teamName, data in pairs(Config.Teams) do
        local spawn = data.spawn

        -- Cercle de rayon sur la carte
        local radiusBlip = AddBlipForRadius(spawn.x, spawn.y, spawn.z, Config.SafeZoneRadius)
        SetBlipColour(radiusBlip, data.blipColor)
        SetBlipAlpha(radiusBlip, 80)
        blips[#blips + 1] = radiusBlip

        -- Point central avec le nom
        local pointBlip = AddBlipForCoord(spawn.x, spawn.y, spawn.z)
        SetBlipSprite(pointBlip, 487) -- Shield icon
        SetBlipColour(pointBlip, data.blipColor)
        SetBlipScale(pointBlip, 0.8)
        SetBlipAsShortRange(pointBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.label .. ' - Safe Zone')
        EndTextCommandSetBlipName(pointBlip)
        blips[#blips + 1] = pointBlip
    end

    Gunward.Debug('Safe zone blips created')
end

function Gunward.Client.SafeZone.RemoveBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
    Gunward.Debug('Safe zone blips removed')
end

-- ============================================================
-- SAFE ZONE (invincibilité au spawn de sa team)
-- ============================================================

CreateThread(function()
    while true do
        local currentTeam = Gunward.Client.Teams.GetCurrent()
        local inGunward = Gunward.Client.Teams.IsInGunward()

        if inGunward and currentTeam then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local spawnCoords = Config.Teams[currentTeam].spawn
            local dist = #(coords - vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z))

            if dist <= Config.SafeZoneRadius then
                if not isInSafeZone then
                    isInSafeZone = true
                    SetEntityInvincible(ped, true)
                    Gunward.Client.Utils.Notify('Zone Safe - Vous êtes protégé', 'info')
                    Gunward.Debug('Entered safe zone')
                end
            else
                if isInSafeZone then
                    isInSafeZone = false
                    SetEntityInvincible(ped, false)
                    Gunward.Client.Utils.Notify('Vous quittez la Zone Safe', 'warning')
                    Gunward.Debug('Left safe zone')
                end
            end
        else
            if isInSafeZone then
                isInSafeZone = false
                SetEntityInvincible(PlayerPedId(), false)
            end
        end

        Wait(500)
    end
end)

-- ============================================================
-- ANTI-TEAM KILL
-- ============================================================

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local attacker = args[2]

    -- Vérifier que les deux sont des peds joueurs
    if not DoesEntityExist(victim) or not DoesEntityExist(attacker) then return end
    if not IsPedAPlayer(victim) or not IsPedAPlayer(attacker) then return end
    if victim == attacker then return end

    local myTeam = Gunward.Client.Teams.GetCurrent()
    if not myTeam then return end

    -- Récupérer le serverId de l'attaquant et de la victime
    local attackerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
    local victimServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victim))

    local attackerTeam = Player(attackerServerId).state.gunwardTeam
    local victimTeam = Player(victimServerId).state.gunwardTeam

    if not attackerTeam or not victimTeam then return end

    -- Si même équipe → restaurer la santé de la victime
    if attackerTeam == victimTeam then
        local victimPed = victim
        -- Stocker la santé avant les dégâts et restaurer
        SetEntityHealth(victimPed, GetEntityMaxHealth(victimPed))
        -- Restaurer aussi l'armure
        SetPedArmour(victimPed, GetPedArmour(victimPed))

        Gunward.Debug('Team kill prevented:', attackerServerId, '->', victimServerId)
    end
end)

-- ============================================================
-- FANCA_ANTITANK CLIENT-SIDE FALLBACK (Layer 3)
-- If server-side cancel didn't work fast enough, resurrect
-- ============================================================

-- Helper: check if an attacker (by serverId) is on my team
local function IsOnMyTeam(attackerServerId)
    if not attackerServerId or attackerServerId <= 0 then return false end
    local myTeam = Gunward.Client.Teams.GetCurrent()
    if not myTeam then return false end
    local attackerTeam = Player(attackerServerId).state.gunwardTeam
    return attackerTeam and attackerTeam == myTeam
end

-- Helper: force resurrect and restore health
local function ForceProtect()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        ped = PlayerPedId()
    end

    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    SetEntityInvincible(ped, true)
    ClearPedBloodDamage(ped)

    -- Re-enter vehicle if was in one
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        local seat = -1 -- driver by default
        if not IsVehicleSeatFree(vehicle, -1) then
            for i = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                if IsVehicleSeatFree(vehicle, i) then
                    seat = i
                    break
                end
            end
        end
        TaskWarpPedIntoVehicle(ped, vehicle, seat)
    end

    -- Remove invincibility after short delay (unless still in safe zone)
    SetTimeout(500, function()
        if not isInSafeZone then
            SetEntityInvincible(PlayerPedId(), false)
        end
    end)
end

-- Restore health when server cancels antitank damage
RegisterNetEvent('gunward:client:restoreHealth', function()
    ForceProtect()
end)

-- Client fallback: fanca_antitank:gotHit
AddEventHandler('fanca_antitank:gotHit', function(attacker, attackerServerId, hitLocation, weaponHash, weaponName, dying, isHeadshot, withMeleeWeapon, damage, enduranceDamage)
    if not Gunward.Client.Teams.IsInGunward() then return end

    -- Safe zone protection
    if isInSafeZone then
        ForceProtect()
        return
    end

    -- Team kill protection
    if IsOnMyTeam(attackerServerId) then
        ForceProtect()
        if dying then
            -- Multiple attempts to ensure survival
            for i = 1, 5 do
                SetTimeout(i * 150, function()
                    ForceProtect()
                end)
            end
        end
    end
end)

-- Client fallback: fanca_antitank:effect (kill effect)
AddEventHandler('fanca_antitank:effect', function(isVictim, otherId, killerData)
    if not isVictim then return end
    if not Gunward.Client.Teams.IsInGunward() then return end

    if isInSafeZone or IsOnMyTeam(otherId) then
        SetTimeout(50, function() ForceProtect() end)
        for i = 1, 8 do
            SetTimeout(i * 150, function()
                ForceProtect()
            end)
        end
    end
end)

-- Client fallback: fanca_antitank:killed
AddEventHandler('fanca_antitank:killed', function(targetId, targetPed, playerId, playerPed, killDistance, killerData)
    if not Gunward.Client.Teams.IsInGunward() then return end
    local myServerId = GetPlayerServerId(PlayerId())
    if targetId ~= myServerId then return end

    if isInSafeZone or IsOnMyTeam(playerId) then
        SetTimeout(50, function() ForceProtect() end)
        for i = 1, 8 do
            SetTimeout(i * 150, function()
                ForceProtect()
            end)
        end
    end
end)

-- Track health for anti-team kill restoration
CreateThread(function()
    while true do
        if Gunward.Client.Teams.IsInGunward() then
            lastHealth = GetEntityHealth(PlayerPedId())
        end
        Wait(100)
    end
end)
