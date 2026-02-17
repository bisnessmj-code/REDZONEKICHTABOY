Gunward.Client.Teams = {}

local currentTeam = nil
local isInGunward = false
local nuiOpen = false

function Gunward.Client.Teams.GetCurrent()
    return currentTeam
end

function Gunward.Client.Teams.IsInGunward()
    return isInGunward
end

function Gunward.Client.Teams.OpenSelection()
    if currentTeam then
        Gunward.Client.Utils.Notify(Lang('team_already_in'), 'error')
        return
    end

    ESX.TriggerServerCallback('gunward:server:getTeamCounts', function(counts)
        local teams = {}
        for _, name in ipairs(Config.TeamOrder) do
            local data = Config.Teams[name]
            teams[#teams + 1] = {
                name = name,
                label = data.label,
                color = data.color,
                current = counts[name] or 0,
                max = data.maxPlayers,
            }
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openTeamSelect',
            teams = teams,
            title = Lang('team_select_title'),
        })
        nuiOpen = true
    end)
end

function Gunward.Client.Teams.CloseSelection()
    if not nuiOpen then return end
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeUI'})
    nuiOpen = false
end

RegisterNUICallback('selectTeam', function(data, cb)
    cb('ok')
    Gunward.Client.Teams.CloseSelection()

    local teamName = data.team
    if not Gunward.IsValidTeam(teamName) then
        Gunward.Client.Utils.Notify(Lang('team_invalid'), 'error')
        return
    end

    TriggerServerEvent('gunward:server:joinTeam', teamName)
end)

RegisterNUICallback('closeUI', function(_, cb)
    cb('ok')
    Gunward.Client.Teams.CloseSelection()
end)

RegisterNetEvent('gunward:client:teamJoined', function(teamName)
    currentTeam = teamName
    isInGunward = true

    Gunward.Client.Teams.ApplyOutfit(teamName)
    Gunward.Client.Utils.Notify(Lang('team_joined', Config.Teams[teamName].label), 'success')

    Gunward.Debug('Joined team:', teamName)
end)

RegisterNetEvent('gunward:client:removedFromGunward', function()
    currentTeam = nil
    isInGunward = false
    Gunward.Debug('Removed from Gunward')
end)

function Gunward.Client.Teams.ApplyOutfit(teamName)
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01') and 'male' or 'female'
    local outfit = Config.Outfits[teamName] and Config.Outfits[teamName][gender]

    if not outfit then
        Gunward.Debug('No outfit found for', teamName, gender)
        return
    end

    local componentMap = {
        ['tshirt_1']  = {id = 8,  texture_key = 'tshirt_2'},
        ['torso_1']   = {id = 11, texture_key = 'torso_2'},
        ['arms']      = {id = 3,  texture_key = 'arms_2'},
        ['pants_1']   = {id = 4,  texture_key = 'pants_2'},
        ['shoes_1']   = {id = 6,  texture_key = 'shoes_2'},
        ['bproof_1']  = {id = 9,  texture_key = 'bproof_2'},
        ['bags_1']    = {id = 5,  texture_key = 'bags_2'},
    }

    for comp, info in pairs(componentMap) do
        if outfit[comp] then
            SetPedComponentVariation(ped, info.id, outfit[comp], outfit[info.texture_key] or 0, 0)
        end
    end

    if outfit['helmet_1'] then
        if outfit['helmet_1'] == -1 then
            ClearPedProp(ped, 0)
        else
            SetPedPropIndex(ped, 0, outfit['helmet_1'], outfit['helmet_2'] or 0, true)
        end
    end

    Gunward.Debug('Outfit applied for', teamName, gender)
end
