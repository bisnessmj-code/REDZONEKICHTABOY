Config = {}

-- Position de départ du joueur
Config.PlayerStartPosition = {
    x = 13.081318,
    y = -1097.340698,
    z = 29.819092,
    heading = 337.322846
}

-- 10 positions où les bots vont spawn (rotation 1-10 puis recommence)
Config.BotSpawnPositions = {
    {x = 14.676924, y = -1083.824218, z = 29.785400, heading = 155.905518},
    {x = 21.956046, y = -1083.336304, z = 29.785400, heading = 161.574798},
    {x = 16.773626, y = -1079.551636, z = 29.785400, heading = 161.574798},
    {x = 21.296704, y = -1077.679078, z = 29.785400, heading = 153.070878},
    {x = 20.123078, y = -1087.898926, z = 29.785400, heading = 153.070878},
    {x = 13.239560, y = -1086.843994, z = 29.785400, heading = 161.574798},
    {x = 23.248352, y = -1077.876954, z = 29.785400, heading = 153.070878},
    {x = 16.575824, y = -1088.070312, z = 29.785400, heading = 153.070878},
    {x = 19.648352, y = -1088.940674, z = 29.785400, heading = 164.409454},
    {x = 18.698902, y = -1079.512084, z = 29.785400, heading = 164.409454}
}

-- Position du PED pour ouvrir le menu
Config.MenuPedPosition = {
    x = -5809.081542,
    y = -932.479126,
    z = 501.489990, -- -1 pour que le ped soit au sol
    heading = 351.496064
}

-- Modèle du PED pour le menu
Config.MenuPedModel = "a_m_m_business_01" -- Modèle du PED (peut être changé)

-- Distance d'interaction avec le PED
Config.InteractionDistance = 2.0

-- Durée de la partie en secondes
Config.GameDuration = 90 -- 1 minute 30

-- Récompense en fin de partie
Config.Reward = 2000

-- Hash du modèle de ped pour les bots
Config.BotModel = "mp_m_freemode_01" -- Modèle du bot (hitbox plus précise)
-- Autres modèles possibles: "a_m_y_skater_01", "s_m_y_dealer_01", "ig_clay"
