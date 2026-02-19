-- ============================================================
-- FANCA_ANTITANK INTEGRATION
-- Prevents kills/hits in safe zones and between teammates
-- ============================================================

-- Check if a player is in their team's safe zone (server-side)
local function IsPlayerInSafeZone(playerId)
    local team = Gunward.Server.Teams.GetPlayerTeam(playerId)
    if not team then return false end

    local teamData = Config.Teams[team]
    if not teamData then return false end

    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local spawn = teamData.spawn
    local dist = #(coords - vector3(spawn.x, spawn.y, spawn.z))

    return dist <= Config.SafeZoneRadius
end

-- Check if two players should be protected from each other
local function ShouldBlockDamage(targetId, attackerId)
    if not targetId or not attackerId then return false end

    -- Convert to numbers in case they come as strings
    targetId = tonumber(targetId)
    attackerId = tonumber(attackerId)

    if not targetId or not attackerId then return false end
    if targetId == attackerId then return false end

    local targetTeam = Gunward.Server.Teams.GetPlayerTeam(targetId)
    local attackerTeam = Gunward.Server.Teams.GetPlayerTeam(attackerId)

    -- If neither is in gunward, skip
    if not targetTeam and not attackerTeam then return false end

    -- Safe zone: victim in safe zone
    if IsPlayerInSafeZone(targetId) then
        print('[GUNWARD-ANTITANK] BLOCK: victim ' .. targetId .. ' is in safe zone')
        return true
    end

    -- Safe zone: attacker in safe zone
    if IsPlayerInSafeZone(attackerId) then
        print('[GUNWARD-ANTITANK] BLOCK: attacker ' .. attackerId .. ' is in safe zone')
        return true
    end

    -- Same team = block
    if targetTeam and attackerTeam and targetTeam == attackerTeam then
        print('[GUNWARD-ANTITANK] BLOCK: same team (' .. targetTeam .. ') - attacker ' .. attackerId .. ' -> victim ' .. targetId)
        return true
    end

    return false
end

-- ============================================================
-- HOOK: fanca_antitank:kill (cancel kill before death executes)
-- ============================================================
AddEventHandler('fanca_antitank:kill', function(targetId, playerId)
    print('[GUNWARD-ANTITANK] fanca_antitank:kill fired - target:' .. tostring(targetId) .. ' attacker:' .. tostring(playerId))

    targetId = tonumber(targetId)
    playerId = tonumber(playerId)

    if ShouldBlockDamage(targetId, playerId) then
        CancelEvent()
        TriggerClientEvent('gunward:client:restoreHealth', targetId)
        print('[GUNWARD-ANTITANK] KILL CANCELLED')
        return
    end

    -- Legitimate kill: process it
    if not targetId or not playerId then return end
    if not Gunward.Server.Teams.IsPlayerInGunward(targetId) then return end
    if not Gunward.Server.Teams.IsPlayerInGunward(playerId) then return end

    -- Stats (fire-and-forget async DB updates)
    Gunward.Server.Database.AddKill(playerId)
    Gunward.Server.Database.AddDeath(targetId)

    -- Push updated stats to all Gunward players after a short delay to let
    -- the DB writes commit before we SELECT the updated values.
    local _killerId = playerId
    local _victimId = targetId
    Citizen.SetTimeout(350, function()
        Gunward.Server.Database.PushKillStatsUpdate(_killerId, _victimId)
    end)

    -- Get player names
    local killerName = GetPlayerName(playerId) or 'Unknown'
    local victimName = GetPlayerName(targetId) or 'Unknown'

    -- Kill feed to all players in gunward bucket
    local killfeedData = {
        killerName = killerName,
        killerId = playerId,
        victimName = victimName,
        victimId = targetId,
    }
    TriggerClientEvent('gunward:client:killfeed', -1, killfeedData)

    -- Remove victim's purchased weapons (server inventory)
    Gunward.Server.WeaponShop.CleanupPlayerWeapons(targetId)

    -- Trigger death/respawn on victim client
    local victimTeam = Gunward.Server.Teams.GetPlayerTeam(targetId)
    TriggerClientEvent('gunward:client:onDeath', targetId, playerId, victimTeam)

    print('[GUNWARD-ANTITANK] KILL PROCESSED: ' .. killerName .. ' [' .. playerId .. '] killed ' .. victimName .. ' [' .. targetId .. ']')
end)

-- ============================================================
-- HOOK: fanca_antitank:hit (cancel hit before damage applies)
-- ============================================================
AddEventHandler('fanca_antitank:hit', function(targetId, playerId)
    print('[GUNWARD-ANTITANK] fanca_antitank:hit fired - target:' .. tostring(targetId) .. ' attacker:' .. tostring(playerId))

    if ShouldBlockDamage(targetId, playerId) then
        CancelEvent()
        TriggerClientEvent('gunward:client:restoreHealth', tonumber(targetId))
        print('[GUNWARD-ANTITANK] HIT CANCELLED')
    end
end)

-- ============================================================
-- HOOK: weaponDamageEvent (native FiveM, earliest possible)
-- ============================================================
RegisterNetEvent('weaponDamageEvent', function(sender, data)
    local attackerId = source
    if not data or not data.hitGlobalIds or #data.hitGlobalIds == 0 then return end

    local targetEntity = NetworkGetEntityFromNetworkId(data.hitGlobalIds[1])
    if not targetEntity or targetEntity == 0 then return end
    if not IsPedAPlayer(targetEntity) then return end

    local targetPlayer = NetworkGetEntityOwner(targetEntity)
    if not targetPlayer then return end
    local targetId = GetPlayerServerId and attackerId -- server-side, source is already serverId

    -- On server side, we can't easily get targetId from weaponDamageEvent
    -- This hook is less reliable, the kill/hit hooks above are the main protection
end)

print('[GUNWARD-ANTITANK] Antitank integration loaded successfully')
