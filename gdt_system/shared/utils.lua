-- ==========================================
-- UTILITAIRES PARTAGÉS
-- ==========================================

Utils = {}

-- Affiche un message de debug si activé
function Utils.Debug(message)
    if Config.EnableDebug then
        print('^3[GDT DEBUG]^7 ' .. tostring(message))
    end
end

-- Arrondit un nombre à N décimales
function Utils.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Vérifie si une table contient une valeur
function Utils.TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Compte le nombre d'éléments dans une table
function Utils.TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Copie profonde d'une table
function Utils.DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[Utils.DeepCopy(key)] = Utils.DeepCopy(value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Convertit une équipe en couleur hexadécimale
function Utils.GetTeamColor(team)
    if team == Constants.Teams.RED then
        return ''
    elseif team == Constants.Teams.BLUE then
        return ''
    else
        return ''
    end
end

-- Convertit une équipe en nom lisible
function Utils.GetTeamName(team)
    if team == Constants.Teams.RED then
        return 'Rouge'
    elseif team == Constants.Teams.BLUE then
        return 'Bleue'
    else
        return 'Aucune'
    end
end

-- Valide si une équipe existe
function Utils.IsValidTeam(team)
    return team == Constants.Teams.RED or team == Constants.Teams.BLUE
end

-- Calcule la distance entre deux vecteurs
function Utils.GetDistance(coords1, coords2)
    if not coords1 or not coords2 then return 999999.9 end
    
    local x1, y1, z1 = coords1.x, coords1.y, coords1.z
    local x2, y2, z2 = coords2.x, coords2.y, coords2.z
    
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

return Utils