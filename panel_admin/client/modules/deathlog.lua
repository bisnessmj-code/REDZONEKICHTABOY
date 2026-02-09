--[[
    Death Log - Panel Admin Fight League
    Detection des morts et des kills
]]

local DeathLog = {}
local isDead = false
local lastDeath = 0
local deathCauses = {}

-- Initialisation (doit etre dans un thread)
Citizen.CreateThread(function()
    if Config.Debug then print('[DEATH LOG] Module charge!') end

    -- Causes de mort traduites
    deathCauses = {
        -- Armes
        [GetHashKey('WEAPON_UNARMED')] = 'Coups de poing',
        [GetHashKey('WEAPON_KNIFE')] = 'Couteau',
        [GetHashKey('WEAPON_PISTOL')] = 'Pistolet',
        [GetHashKey('WEAPON_COMBATPISTOL')] = 'Pistolet de combat',
        [GetHashKey('WEAPON_APPISTOL')] = 'Pistolet AP',
        [GetHashKey('WEAPON_PISTOL50')] = 'Pistolet .50',
        [GetHashKey('WEAPON_MICROSMG')] = 'Micro SMG',
        [GetHashKey('WEAPON_SMG')] = 'SMG',
        [GetHashKey('WEAPON_ASSAULTSMG')] = 'SMG d\'assaut',
        [GetHashKey('WEAPON_ASSAULTRIFLE')] = 'Fusil d\'assaut',
        [GetHashKey('WEAPON_CARBINERIFLE')] = 'Carabine',
        [GetHashKey('WEAPON_ADVANCEDRIFLE')] = 'Fusil avance',
        [GetHashKey('WEAPON_MG')] = 'Mitrailleuse',
        [GetHashKey('WEAPON_COMBATMG')] = 'Mitrailleuse de combat',
        [GetHashKey('WEAPON_PUMPSHOTGUN')] = 'Fusil a pompe',
        [GetHashKey('WEAPON_SAWNOFFSHOTGUN')] = 'Fusil a canon scie',
        [GetHashKey('WEAPON_ASSAULTSHOTGUN')] = 'Fusil d\'assaut',
        [GetHashKey('WEAPON_BULLPUPSHOTGUN')] = 'Fusil Bullpup',
        [GetHashKey('WEAPON_SNIPERRIFLE')] = 'Fusil de sniper',
        [GetHashKey('WEAPON_HEAVYSNIPER')] = 'Sniper lourd',
        [GetHashKey('WEAPON_MARKSMANRIFLE')] = 'Fusil de precision',
        [GetHashKey('WEAPON_GRENADELAUNCHER')] = 'Lance-grenades',
        [GetHashKey('WEAPON_RPG')] = 'Lance-roquettes',
        [GetHashKey('WEAPON_MINIGUN')] = 'Minigun',
        [GetHashKey('WEAPON_GRENADE')] = 'Grenade',
        [GetHashKey('WEAPON_STICKYBOMB')] = 'Bombe collante',
        [GetHashKey('WEAPON_MOLOTOV')] = 'Cocktail Molotov',
        [GetHashKey('WEAPON_BAT')] = 'Batte de baseball',
        [GetHashKey('WEAPON_CROWBAR')] = 'Pied de biche',
        [GetHashKey('WEAPON_GOLFCLUB')] = 'Club de golf',
        [GetHashKey('WEAPON_HAMMER')] = 'Marteau',
        [GetHashKey('WEAPON_HATCHET')] = 'Hachette',
        [GetHashKey('WEAPON_MACHETE')] = 'Machette',
        [GetHashKey('WEAPON_SWITCHBLADE')] = 'Couteau a cran',
        [GetHashKey('WEAPON_BOTTLE')] = 'Bouteille',
        -- Causes environnementales
        [GetHashKey('WEAPON_DROWNING')] = 'Noyade',
        [GetHashKey('WEAPON_DROWNING_IN_VEHICLE')] = 'Noyade en vehicule',
        [GetHashKey('WEAPON_FALL')] = 'Chute',
        [GetHashKey('WEAPON_EXHAUSTION')] = 'Epuisement',
        [GetHashKey('WEAPON_FIRE')] = 'Feu',
        [GetHashKey('WEAPON_EXPLOSION')] = 'Explosion',
        [GetHashKey('WEAPON_ELECTRIC_FENCE')] = 'Electrocution',
        [GetHashKey('WEAPON_BLEEDING')] = 'Saignement',
        [GetHashKey('WEAPON_BARBED_WIRE')] = 'Fil barbele',
        [GetHashKey('WEAPON_HIT_BY_WATER_CANNON')] = 'Canon a eau',
        -- Vehicules
        [GetHashKey('WEAPON_RAMMED_BY_CAR')] = 'Ecrase par vehicule',
        [GetHashKey('WEAPON_RUN_OVER_BY_CAR')] = 'Renverse par vehicule',
        [GetHashKey('WEAPON_VEHICLE_ROCKET')] = 'Roquette de vehicule',
    }
end)

-- Commande de test
RegisterCommand('testdeath', function()
    if Config.Debug then print('[DEATH LOG] Test manuel declenche!') end
    TriggerServerEvent('panel:playerDeath', {
        killerServerId = nil,
        deathCause = 'Test manuel',
        isSuicide = false,
        weaponHash = 0
    })
end, false)

-- Obtenir le nom de la cause de mort
function DeathLog.GetDeathCause(weaponHash)
    if deathCauses[weaponHash] then
        return deathCauses[weaponHash]
    end
    if weaponHash == 0 then
        return 'Inconnu'
    end
    return 'Arme inconnue'
end

-- Ecouter l'event ESX de mort
AddEventHandler('esx:onPlayerDeath', function(data)
    if Config.Debug then print('[DEATH LOG] esx:onPlayerDeath!') end
    local playerPed = PlayerPedId()
    local killerPed = data.killerPed
    local deathCause = data.deathCause or 'Inconnu'

    local killerServerId = nil
    if killerPed and killerPed ~= 0 and killerPed ~= playerPed then
        if IsPedAPlayer(killerPed) then
            killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killerPed))
        end
    end

    TriggerServerEvent('panel:playerDeath', {
        killerServerId = killerServerId,
        deathCause = deathCause,
        isSuicide = (killerPed == playerPed),
        weaponHash = data.weaponHash or 0
    })
end)

-- Event baseevents
AddEventHandler('baseevents:onPlayerDied', function(killerType, coords)
    if Config.Debug then print('[DEATH LOG] baseevents:onPlayerDied!') end
    TriggerServerEvent('panel:playerDeath', {
        killerServerId = nil,
        deathCause = killerType or 'Inconnu',
        isSuicide = false,
        weaponHash = 0
    })
end)

AddEventHandler('baseevents:onPlayerKilled', function(killerId, data)
    if Config.Debug then print('[DEATH LOG] baseevents:onPlayerKilled! Killer: ' .. tostring(killerId)) end
    local deathCause = 'Inconnu'
    if data and data.weaponhash then
        deathCause = DeathLog.GetDeathCause(data.weaponhash)
    end

    TriggerServerEvent('panel:playerDeath', {
        killerServerId = killerId,
        deathCause = deathCause,
        isSuicide = false,
        weaponHash = data and data.weaponhash or 0
    })
end)

-- Detection native de la mort
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local playerPed = PlayerPedId()
        local currentTime = GetGameTimer()

        if IsEntityDead(playerPed) and not isDead then
            if currentTime - lastDeath > 5000 then
                isDead = true
                lastDeath = currentTime

                local killerPed = GetPedSourceOfDeath(playerPed)
                local causeOfDeath = GetPedCauseOfDeath(playerPed)
                local deathCause = DeathLog.GetDeathCause(causeOfDeath)

                local killerServerId = nil
                local isSuicide = false

                if killerPed and killerPed ~= 0 and killerPed ~= playerPed then
                    if IsPedAPlayer(killerPed) then
                        killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killerPed))
                    elseif IsEntityAVehicle(killerPed) then
                        local driver = GetPedInVehicleSeat(killerPed, -1)
                        if driver and driver ~= 0 and IsPedAPlayer(driver) then
                            killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(driver))
                            if deathCause == 'Inconnu' then
                                deathCause = 'Ecrase par vehicule'
                            end
                        end
                    end
                elseif killerPed == playerPed then
                    isSuicide = true
                end

                if Config.Debug then print('[DEATH LOG] Mort native detectee! Killer: ' .. tostring(killerServerId) .. ', Cause: ' .. deathCause) end

                TriggerServerEvent('panel:playerDeath', {
                    killerServerId = killerServerId,
                    deathCause = deathCause,
                    isSuicide = isSuicide,
                    weaponHash = causeOfDeath
                })
            end
        elseif not IsEntityDead(playerPed) then
            isDead = false
        end
    end
end)

_G.DeathLog = DeathLog
