Gunward.Client.Utils = {}

function Gunward.Client.Utils.Notify(msg, type, duration)
    type = type or 'info'
    duration = duration or Config.Notify.DefaultDuration

    if Config.Notify.Type == 'brutal_notify' then
        exports['brutal_notify']:SendAlert(msg, type, duration)
    elseif Config.Notify.Type == 'esx' then
        ESX.ShowNotification(msg)
    elseif Config.Notify.Type == 'chat' then
        TriggerEvent('chat:addMessage', {args = {'[GUNWARD]', msg}})
    end
end

function Gunward.Client.Utils.DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

function Gunward.Client.Utils.LoadModel(model)
    if type(model) == 'string' then model = GetHashKey(model) end
    if not IsModelValid(model) then return false end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    return true
end

function Gunward.Client.Utils.LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

-- Event relay from server
RegisterNetEvent('gunward:client:notify', function(msg, type, duration)
    Gunward.Client.Utils.Notify(msg, type, duration)
end)
