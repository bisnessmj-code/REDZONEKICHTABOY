-- ==========================================
-- CLIENT OUTFITS - GESTION DES TENUES
-- ==========================================

-- ==========================================
-- RÉCUPÉRER LA TENUE ACTUELLE DU JOUEUR
-- ==========================================

function GetCurrentOutfit()
    local ped = PlayerPedId()
    
    local outfit = {
        ['tshirt_1'] = GetPedDrawableVariation(ped, 8),
        ['tshirt_2'] = GetPedTextureVariation(ped, 8),
        ['torso_1'] = GetPedDrawableVariation(ped, 11),
        ['torso_2'] = GetPedTextureVariation(ped, 11),
        ['decals_1'] = GetPedDrawableVariation(ped, 10),
        ['decals_2'] = GetPedTextureVariation(ped, 10),
        ['arms'] = GetPedDrawableVariation(ped, 3),
        ['pants_1'] = GetPedDrawableVariation(ped, 4),
        ['pants_2'] = GetPedTextureVariation(ped, 4),
        ['shoes_1'] = GetPedDrawableVariation(ped, 6),
        ['shoes_2'] = GetPedTextureVariation(ped, 6),
        ['helmet_1'] = GetPedPropIndex(ped, 0),
        ['helmet_2'] = GetPedPropTextureIndex(ped, 0),
        ['chain_1'] = GetPedDrawableVariation(ped, 7),
        ['chain_2'] = GetPedTextureVariation(ped, 7),
        ['ears_1'] = GetPedPropIndex(ped, 2),
        ['ears_2'] = GetPedPropTextureIndex(ped, 2),
        ['bags_1'] = GetPedDrawableVariation(ped, 5),
        ['bags_2'] = GetPedTextureVariation(ped, 5),
        ['mask_1'] = GetPedDrawableVariation(ped, 1),
        ['mask_2'] = GetPedTextureVariation(ped, 1),
        ['bproof_1'] = GetPedDrawableVariation(ped, 9),
        ['bproof_2'] = GetPedTextureVariation(ped, 9)
    }
    
    return outfit
end

-- ==========================================
-- APPLIQUER UNE TENUE D'ÉQUIPE
-- ==========================================

function ApplyTeamOutfit(team)
    if not Utils.IsValidTeam(team) then return end
    
    local ped = PlayerPedId()
    local isMale = (GetEntityModel(ped) == GetHashKey('mp_m_freemode_01'))
    local outfit = isMale and Config.Outfits[team].male or Config.Outfits[team].female
    
    -- Application des vêtements
    SetPedComponentVariation(ped, 8, outfit['tshirt_1'], outfit['tshirt_2'], 0)      -- T-shirt
    SetPedComponentVariation(ped, 11, outfit['torso_1'], outfit['torso_2'], 0)       -- Veste
    SetPedComponentVariation(ped, 10, outfit['decals_1'], outfit['decals_2'], 0)     -- Décalques
    SetPedComponentVariation(ped, 3, outfit['arms'], 0, 0)                            -- Bras
    SetPedComponentVariation(ped, 4, outfit['pants_1'], outfit['pants_2'], 0)        -- Pantalon
    SetPedComponentVariation(ped, 6, outfit['shoes_1'], outfit['shoes_2'], 0)        -- Chaussures
    SetPedComponentVariation(ped, 7, outfit['chain_1'], outfit['chain_2'], 0)        -- Accessoires
    SetPedComponentVariation(ped, 5, outfit['bags_1'], outfit['bags_2'], 0)          -- Sacs
    SetPedComponentVariation(ped, 1, outfit['mask_1'], outfit['mask_2'], 0)          -- Masque
    SetPedComponentVariation(ped, 9, outfit['bproof_1'], outfit['bproof_2'], 0)      -- Gilet
    
    -- Application des accessoires
    if outfit['helmet_1'] ~= -1 then
        SetPedPropIndex(ped, 0, outfit['helmet_1'], outfit['helmet_2'], true)
    else
        ClearPedProp(ped, 0)
    end
    
    if outfit['ears_1'] ~= -1 then
        SetPedPropIndex(ped, 2, outfit['ears_1'], outfit['ears_2'], true)
    else
        ClearPedProp(ped, 2)
    end
    
    Utils.Debug('Tenue d\'équipe '..team..' appliquée')
end

-- ==========================================
-- RESTAURER LA TENUE ORIGINALE
-- ==========================================

function RestoreOutfit(outfit)
    if not outfit then
        Utils.Debug('Aucune tenue à restaurer')
        return
    end
    
    local ped = PlayerPedId()
    
    -- Restauration des vêtements
    SetPedComponentVariation(ped, 8, outfit['tshirt_1'], outfit['tshirt_2'], 0)
    SetPedComponentVariation(ped, 11, outfit['torso_1'], outfit['torso_2'], 0)
    SetPedComponentVariation(ped, 10, outfit['decals_1'], outfit['decals_2'], 0)
    SetPedComponentVariation(ped, 3, outfit['arms'], 0, 0)
    SetPedComponentVariation(ped, 4, outfit['pants_1'], outfit['pants_2'], 0)
    SetPedComponentVariation(ped, 6, outfit['shoes_1'], outfit['shoes_2'], 0)
    SetPedComponentVariation(ped, 7, outfit['chain_1'], outfit['chain_2'], 0)
    SetPedComponentVariation(ped, 5, outfit['bags_1'], outfit['bags_2'], 0)
    SetPedComponentVariation(ped, 1, outfit['mask_1'], outfit['mask_2'], 0)
    SetPedComponentVariation(ped, 9, outfit['bproof_1'], outfit['bproof_2'], 0)
    
    -- Restauration des accessoires
    if outfit['helmet_1'] ~= -1 then
        SetPedPropIndex(ped, 0, outfit['helmet_1'], outfit['helmet_2'], true)
    else
        ClearPedProp(ped, 0)
    end
    
    if outfit['ears_1'] ~= -1 then
        SetPedPropIndex(ped, 2, outfit['ears_1'], outfit['ears_2'], true)
    else
        ClearPedProp(ped, 2)
    end
    
    Utils.Debug('Tenue originale restaurée')
end

-- ==========================================
-- EXPORTS
-- ==========================================

exports('GetCurrentOutfit', GetCurrentOutfit)
exports('ApplyTeamOutfit', ApplyTeamOutfit)
exports('RestoreOutfit', RestoreOutfit)
