Config = {}

Config.Debug = true
Config.Locale = 'fr'
Config.ScriptName = 'gunward'

Config.MaxPlayersPerTeam = 32
Config.Bucket = 50

Config.ReturnCoords = vector4(-5804.479004, -918.751648, 505.337646, 269.291352) -- coords retour lobby

Config.SafeZoneRadius = 30.0 -- rayon d'invincibilité autour du spawn de chaque équipe

Config.Notify = {
    Type = 'brutal_notify', -- 'brutal_notify', 'esx', 'chat'
    DefaultDuration = 5000,
}

-- Groupes ESX avec avantages dans le Gunward
-- Véhicules : gratuits | Armes : -Config.WeaponDiscount%
Config.PrivilegedGroups = {
    vip          = true,
    staff        = true,
    organisateur = true,
    responsable  = true,
    admin        = true,
}
Config.WeaponDiscount = 30 -- réduction en % sur les armes pour les groupes ci-dessus
