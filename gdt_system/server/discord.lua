-- ==========================================
-- SERVER DISCORD - CLASSEMENT WEBHOOK
-- ==========================================

local lastSendTime = 0
local SEND_COOLDOWN = 60

-- ==========================================
-- ENVOI DU CLASSEMENT SUR DISCORD
-- ==========================================

function SendLeaderboardToDiscord()
    local webhookUrl = GetConvar('gdt_discord_webhook', '')

    if webhookUrl == '' then
        print('^1[GDT System] ^7Webhook Discord non configure. Ajoute "set gdt_discord_webhook" dans ton server.cfg')
        return
    end

    -- Cooldown pour eviter le spam
    local now = os.time()
    if (now - lastSendTime) < SEND_COOLDOWN then
        print('^3[GDT System] ^7Classement Discord deja envoye recemment, patiente.')
        return
    end
    lastSendTime = now

    Database.GetTop20Killers(function(results)
        if not results or #results == 0 then
            print('^3[GDT System] ^7Aucun joueur dans le classement.')
            return
        end

        -- Limiter a 15
        local top15 = {}
        for i = 1, math.min(15, #results) do
            table.insert(top15, results[i])
        end

        -- Construire le classement
        local lines = {}
        for i, player in ipairs(top15) do
            local rank = ''
            if i == 1 then
                rank = '\xF0\x9F\xA5\x87'
            elseif i == 2 then
                rank = '\xF0\x9F\xA5\x88'
            elseif i == 3 then
                rank = '\xF0\x9F\xA5\x89'
            else
                rank = '**`#' .. i .. '`**'
            end

            table.insert(lines, rank .. '  ' .. player.name .. '  \xE2\x80\xA2  **' .. player.kills .. '** kills')
        end

        local leaderboardText = table.concat(lines, '\n')

        -- Date du jour
        local dateStr = os.date('%d/%m/%Y \xC3\xA0 %Hh%M')

        -- Embed Discord
        local embed = {
            {
                description = '\n' .. leaderboardText .. '\n',
                color = 2829617,
                author = {
                    name = 'CLASSEMENT GDT',
                    icon_url = 'https://r2.fivemanage.com/65OINTV6xwj2vOK7XWptj/logo.png'
                },
                thumbnail = {
                    url = 'https://r2.fivemanage.com/65OINTV6xwj2vOK7XWptj/logo.png'
                },
                footer = {
                    text = dateStr .. '  \xE2\x80\xA2  Top ' .. #top15 .. ' joueurs'
                }
            }
        }

        PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
            if statusCode >= 200 and statusCode < 300 then
                print('^2[GDT System] ^7Classement envoye sur Discord.')
            else
                print('^1[GDT System] ^7Erreur envoi Discord (code: ' .. tostring(statusCode) .. ')')
            end
        end, 'POST', json.encode({
            username = 'GDT System',
            avatar_url = 'https://r2.fivemanage.com/65OINTV6xwj2vOK7XWptj/logo.png',
            embeds = embed
        }), {
            ['Content-Type'] = 'application/json'
        })
    end)
end

-- ==========================================
-- COMMANDE ADMIN : /gtleaderboard
-- ==========================================

RegisterCommand('gtleaderboard', function(source, args)
    if source ~= 0 and not Permissions.IsAdmin(source) then
        return TriggerClientEvent('esx:showNotification', source, Config.Notifications.noPermission)
    end

    SendLeaderboardToDiscord()

    if source ~= 0 then
        TriggerClientEvent('esx:showNotification', source, '~g~Classement envoye sur Discord !')
    end
end, false)

-- ==========================================
-- ENVOI AUTOMATIQUE A 8H00 ET 20H00
-- ==========================================

Citizen.CreateThread(function()
    Wait(10000)

    -- Horaires d'envoi (en heures)
    local sendTimes = { 8, 20 }

    while true do
        local currentHour = tonumber(os.date('%H'))
        local currentMin  = tonumber(os.date('%M'))
        local nowMinutes = currentHour * 60 + currentMin

        -- Trouver le prochain horaire d'envoi
        local waitMinutes = nil
        local nextHour = nil

        for _, hour in ipairs(sendTimes) do
            local targetMinutes = hour * 60
            if targetMinutes > nowMinutes then
                local diff = targetMinutes - nowMinutes
                if not waitMinutes or diff < waitMinutes then
                    waitMinutes = diff
                    nextHour = hour
                end
            end
        end

        -- Si aucun horaire restant aujourd'hui, prendre le premier de demain
        if not waitMinutes then
            local firstTarget = sendTimes[1] * 60
            waitMinutes = (24 * 60 - nowMinutes) + firstTarget
            nextHour = sendTimes[1]
        end

        local waitMs = waitMinutes * 60 * 1000

        print('^2[GDT System] ^7Prochain classement Discord dans ' .. waitMinutes .. ' minutes (' .. math.floor(waitMinutes / 60) .. 'h' .. string.format('%02d', waitMinutes % 60) .. ') - prevu a ' .. nextHour .. 'h00')

        Wait(waitMs)

        print('^2[GDT System] ^7Envoi automatique du classement Discord (' .. nextHour .. 'h00)...')
        SendLeaderboardToDiscord()

        -- Attendre 1 minute pour eviter double envoi
        Wait(60000)
    end
end)
