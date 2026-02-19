Config.KOTH = {
    RotationTime = 900,   -- 15 min en secondes
    CheckInterval = 3000, -- vérif toutes les 3s (ms)
    Reward = 1000,        -- récompense par joueur
    ZoneRadius = 60.0,    -- rayon de la zone
    Zones = {
        { coords = vector3(171.57, -1677.23, 33.66), label = 'Zone Sud' },
        { coords = vector3(146.64, -1300.67, 28.96), label = 'Zone Centre' },
        { coords = vector3(202.50, -933.75, 30.68), label = 'Zone Nord' },
        { coords = vector3(969.16, -1523.56, 31.05), label = 'Zone Est' },
    }
}
