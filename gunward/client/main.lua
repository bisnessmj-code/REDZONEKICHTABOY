ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    Gunward.Debug('Client initializing...')

    -- Create selection ped
    Gunward.Client.Ped.Create()

    -- Start interaction thread
    Gunward.Client.Ped.StartInteractionThread()

    Gunward.Debug('Client initialized')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Gunward.Client.Ped.Delete()
    Gunward.Client.Teams.CloseSelection()
end)
