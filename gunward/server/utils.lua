ESX = exports['es_extended']:getSharedObject()

Gunward.Server.Utils = {}

function Gunward.Server.Utils.Notify(source, msg, type, duration)
    TriggerClientEvent('gunward:client:notify', source, msg, type, duration)
end

function Gunward.Server.Utils.NotifyAll(msg, type, duration)
    TriggerClientEvent('gunward:client:notify', -1, msg, type, duration)
end

-- ── HasPermission ────────────────────────────────────────────────────────────
-- Checks the player's ESX group (from the `users` table) against the allowed
-- roles list. Falls back to FiveM ACE permissions for non-ESX setups.
-- Console (source = 0) always has permission.
function Gunward.Server.Utils.HasPermission(source, roles)
    if not roles or #roles == 0 then return true end

    -- Console always allowed
    if source == 0 then return true end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local playerGroup = xPlayer.getGroup() or ''

    for _, role in ipairs(roles) do
        -- Primary check: ESX group stored in `users` table
        if playerGroup == role then
            return true
        end
        -- Fallback: FiveM ACE permission (for server.cfg-based setups)
        local aceData = Config.Roles[role]
        if aceData and IsPlayerAceAllowed(source, aceData.ace) then
            return true
        end
    end

    return false
end

function Gunward.Server.Utils.GetPlayerName(source)
    return GetPlayerName(source) or 'Unknown'
end
