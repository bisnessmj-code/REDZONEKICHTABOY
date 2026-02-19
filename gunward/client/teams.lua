Gunward.Client.Teams = {}

local currentTeam = nil
local isInGunward = false
local nuiOpen = false
local savedOutfit = nil

function Gunward.Client.Teams.GetCurrent()
    return currentTeam
end

function Gunward.Client.Teams.IsInGunward()
    return isInGunward
end

-- Outfit save/restore functions (must be declared before use)
local function SaveCurrentOutfit()
    local ped = PlayerPedId()
    local outfit = {components = {}, props = {}}
    for i = 0, 11 do
        outfit.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i),
        }
    end
    for i = 0, 2 do
        outfit.props[i] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i),
        }
    end
    return outfit
end

local function RestoreOutfit()
    if not savedOutfit then return end
    local ped = PlayerPedId()
    for i = 0, 11 do
        local comp = savedOutfit.components[i]
        if comp then
            SetPedComponentVariation(ped, i, comp.drawable, comp.texture, comp.palette)
        end
    end
    for i = 0, 2 do
        local prop = savedOutfit.props[i]
        if prop then
            if prop.drawable == -1 then
                ClearPedProp(ped, i)
            else
                SetPedPropIndex(ped, i, prop.drawable, prop.texture, true)
            end
        end
    end
    savedOutfit = nil
end

function Gunward.Client.Teams.OpenSelection()
    if currentTeam then
        Gunward.Client.Utils.Notify(Lang('team_already_in'), 'error')
        return
    end

    -- Single async callback — returns teams counts, leaderboard, profile,
    -- timer info and server player count in one round-trip.
    ESX.TriggerServerCallback('gunward:server:getStatsUI', function(data)
        if not data then return end

        local teamCounts = data.teamCounts or {}
        local teams = {}
        for _, name in ipairs(Config.TeamOrder) do
            local d = Config.Teams[name]
            teams[#teams + 1] = {
                name    = name,
                label   = d.label,
                color   = d.color,
                current = teamCounts[name] or 0,
                max     = d.maxPlayers,
            }
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action        = 'openGunwardUI',
            teams         = teams,
            leaderboard   = data.leaderboard   or {},
            myStats       = data.myStats,
            myPosition    = data.myPosition,
            myIdent       = data.myIdent,
            serverPlayers = data.serverPlayers  or 0,
            timerInfo     = data.timerInfo      or {},
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

    savedOutfit = SaveCurrentOutfit()
    Gunward.Client.Teams.ApplyOutfit(teamName)

    -- Spawn les PEDs de la team (visibles uniquement dans le mode de jeu)
    Gunward.Client.VehicleShop.CreatePed(teamName)
    Gunward.Client.WeaponShop.CreatePed(teamName)
    Gunward.Client.WeaponShop.CreateSellPed(teamName)
    Gunward.Client.LeavePeds.CreatePed(teamName)

    -- Créer les blips des zones safe
    Gunward.Client.SafeZone.CreateBlips()

    Gunward.Client.Utils.Notify(Lang('team_joined', Config.Teams[teamName].label), 'success')

    Gunward.Debug('Joined team:', teamName)
end)

RegisterNetEvent('gunward:client:removedFromGunward', function()
    currentTeam = nil
    isInGunward = false
    RestoreOutfit()

    -- Supprimer les blips des zones safe
    Gunward.Client.SafeZone.RemoveBlips()

    -- Supprimer les PEDs
    Gunward.Client.VehicleShop.DeletePed()
    Gunward.Client.WeaponShop.DeletePed()
    Gunward.Client.WeaponShop.DeleteSellPed()
    Gunward.Client.LeavePeds.DeletePed()

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
