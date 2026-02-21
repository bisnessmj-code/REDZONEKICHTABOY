-- ============================================================
-- GUNWARD — Discord Webhook (classement automatique)
--
-- Configuration dans server.cfg :
--   set gunward_webhook   "https://discord.com/api/webhooks/..."
--   set gunward_tz_offset "1"   ← UTC+1 (hiver CET)
--                          "2"  ← UTC+2 (été CEST)
--
-- Envoi automatique à 08:00 et 20:00 (heure française).
-- Commande manuelle : /gw_classement (admin, staff, responsable, organisateur)
-- ============================================================

local ALLOWED_GROUPS = { admin = true, staff = true, responsable = true, organisateur = true }
local THUMBNAIL_URL  = 'https://r2.fivemanage.com/65OINTV6xwj2vOK7XWptj/logo.png'
local SEND_HOURS     = { [8] = true, [20] = true }

-- ── HELPERS ─────────────────────────────────────────────────────────────────

local function GetWebhook()
    local url = GetConvar('gunward_webhook', '')
    if url == '' then
        print('[GUNWARD-WEBHOOK] ⚠  gunward_webhook non défini dans server.cfg')
    end
    return url
end

local function GetFrenchTime()
    local offset = tonumber(GetConvar('gunward_tz_offset', '1')) or 1
    return os.date('*t', os.time() + offset * 3600)
end

-- Tronque un nom à maxLen caractères
local function TruncName(name, maxLen)
    name = tostring(name or 'Inconnu')
    if name == '' then name = 'Inconnu' end
    if #name > maxLen then return name:sub(1, maxLen - 1) .. '.' end
    return name
end

-- ── BUILD & SEND EMBED ───────────────────────────────────────────────────────
--
--  #    JOUEUR              KILLS   MORTS    K/D
--  -----------------------------------------------
--  01   kichtaboy              87      14   6.21
--  02   Viper_01               74      18   4.11
--  ...
--
-- Podium (description, hors code block) :
--   🥇 **kichtaboy**   🥈 **Viper_01**   🥉 **KnightFall**

local ROW_FMT  = ' %02d  %-17s  %5d  %5d   %5s'
local HEAD_FMT = ' %-4s %-17s  %5s  %5s   %5s'
local SEP_LEN  = 47

local function BuildTable(rows)
    local lines = {}

    lines[#lines + 1] = string.format(HEAD_FMT, '#', 'JOUEUR', 'KILLS', 'MORTS', 'K/D')
    lines[#lines + 1] = string.rep('-', SEP_LEN)

    for i, row in ipairs(rows) do
        local name = TruncName(row.name, 17)
        local kd   = string.format('%.2f', tonumber(row.kd) or 0)
        lines[#lines + 1] = string.format(ROW_FMT,
            i,
            name,
            tonumber(row.kills)  or 0,
            tonumber(row.deaths) or 0,
            kd
        )
    end

    if #rows == 0 then
        lines[#lines + 1] = ' Aucune statistique disponible.'
    end

    return table.concat(lines, '\n')
end

-- Podium sur une ligne dans la description (emojis hors code block = OK)
local function BuildPodiumLine(rows)
    if #rows == 0 then return '' end
    local medals = { '🥇', '🥈', '🥉' }
    local parts  = {}
    for i = 1, math.min(3, #rows) do
        local name = TruncName(rows[i].name, 20)
        parts[#parts + 1] = medals[i] .. ' **' .. name .. '**'
    end
    return table.concat(parts, '   \u{00A0}   ')
end

local function SendLeaderboard(notifySource)
    local webhookUrl = GetWebhook()
    if webhookUrl == '' then
        if notifySource then
            TriggerClientEvent('gunward:client:notify', notifySource,
                'Webhook non configuré dans server.cfg', 'error')
        end
        return
    end

    MySQL.query([[
        SELECT name, kills, deaths,
               ROUND(kills / GREATEST(deaths, 1), 2) AS kd
        FROM gunward_stats
        WHERE kills > 0 OR deaths > 0
        ORDER BY kills DESC, kd DESC
        LIMIT 15
    ]], {}, function(rows)
        rows = rows or {}

        local playerTable = BuildTable(rows)
        local podiumLine  = BuildPodiumLine(rows)

        -- Description : podium + sous-titre
        local desc = ''
        if podiumLine ~= '' then
            desc = podiumLine .. '\n\u{200B}'
        end
        desc = desc .. '*Top ' .. math.max(#rows, 1) .. ' joueurs  —  classement par kills*'

        -- Date French
        local t       = GetFrenchTime()
        local dateStr = string.format('%02d/%02d/%04d  %02d:%02d',
            t.day, t.month, t.year, t.hour, t.min)
        local isoTs   = os.date('!%Y-%m-%dT%H:%M:%S.000Z', os.time())

        local payload = json.encode({
            embeds = {{
                title       = '🏆  CLASSEMENT  KOTH',
                description = desc,
                color       = 0xCC0000,
                thumbnail   = { url = THUMBNAIL_URL },
                fields      = {
                    {
                        name   = '\u{200B}',
                        value  = '```\n' .. playerTable .. '\n```',
                        inline = false,
                    },
                },
                footer = {
                    text     = 'KOTH  •  ' .. dateStr,
                    icon_url = THUMBNAIL_URL,
                },
                timestamp = isoTs,
            }}
        })

        PerformHttpRequest(webhookUrl, function(code, body, headers)
            if code == 204 then
                print('[GUNWARD-WEBHOOK] ✓ Classement envoyé (' .. dateStr .. ')')
            else
                print('[GUNWARD-WEBHOOK] ✗ HTTP ' .. tostring(code) .. ' : ' .. tostring(body))
            end
        end, 'POST', payload, { ['Content-Type'] = 'application/json' })
    end)
end

-- ── SCHEDULER ────────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(5000)

    local lastSentHour = -1

    while true do
        Wait(60000)

        local t   = GetFrenchTime()
        local h   = t.hour
        local min = t.min

        if min == 0 and SEND_HOURS[h] and h ~= lastSentHour then
            lastSentHour = h
            print(string.format('[GUNWARD-WEBHOOK] Envoi planifié %02d:00 (FR)', h))
            SendLeaderboard(nil)
        elseif min ~= 0 then
            lastSentHour = -1
        end
    end
end)

-- ── COMMANDE MANUELLE ────────────────────────────────────────────────────────

RegisterCommand('gw_classement', function(source, args)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        if not ALLOWED_GROUPS[xPlayer.getGroup() or ''] then
            TriggerClientEvent('gunward:client:notify', source,
                'Permission refusée.', 'error')
            return
        end
    end

    local who = source == 0 and 'console' or (GetPlayerName(source) or tostring(source))
    print('[GUNWARD-WEBHOOK] Envoi manuel par ' .. who)
    SendLeaderboard(source ~= 0 and source or nil)

    if source ~= 0 then
        TriggerClientEvent('gunward:client:notify', source,
            'Classement envoyé sur Discord !', 'success')
    end
end, false)
