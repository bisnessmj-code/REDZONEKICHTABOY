-- Script helper pour obtenir vos coordonnées
-- Ajoutez ce fichier temporairement dans client_scripts du fxmanifest.lua
-- puis utilisez /getpos dans le jeu pour copier vos coordonnées

RegisterCommand('getpos', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local coordsText = string.format("{x = %.2f, y = %.2f, z = %.2f, heading = %.2f}", coords.x, coords.y, coords.z, heading)

    print("^2Coordonnées copiées:^0 " .. coordsText)
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"Coords", coordsText}
    })

    -- Copier dans le presse-papier (si vous avez un système de clipboard)
    -- Sinon, copiez manuellement depuis la console F8
end, false)
