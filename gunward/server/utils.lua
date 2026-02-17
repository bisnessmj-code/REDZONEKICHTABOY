ESX = exports['es_extended']:getSharedObject()

Gunward.Server.Utils = {}

function Gunward.Server.Utils.Notify(source, msg, type, duration)
    TriggerClientEvent('gunward:client:notify', source, msg, type, duration)
end

function Gunward.Server.Utils.NotifyAll(msg, type, duration)
    TriggerClientEvent('gunward:client:notify', -1, msg, type, duration)
end

function Gunward.Server.Utils.HasPermission(source, roles)
    if not roles or #roles == 0 then return true end

    for _, role in ipairs(roles) do
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
