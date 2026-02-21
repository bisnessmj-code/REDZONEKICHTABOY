Config = {}

-- Position de départ du joueur
Config.PlayerStartPosition = {
    x = -1965.191162,
    y = 3332.742920,
    z = 32.953125,
    heading = 240.944886
}

-- 10 positions où les bots vont spawn (rotation 1-10 puis recommence)
Config.BotSpawnPositions = {
    {x = -1954.114258, y = 3326.742920, z = 32.953125, heading = 48.188972},
    {x = -1948.971436, y = 3328.786866, z = 32.953125, heading = 56.692914},
    {x = -1947.665894, y = 3322.180176, z = 32.953125, heading = 65.196854},
    {x = -1957.714234, y = 3322.773682, z = 32.953125, heading = 53.858268},
    {x = -1955.037354, y = 3330.329590, z = 32.953125, heading = 59.527558},
    {x = -1954.852784, y = 3323.063720, z = 32.953125, heading = 53.858268},
    {x = -1948.865966, y = 3331.595704, z = 32.953125, heading = 59.527558},
    {x = -1958.241700, y = 3325.753906, z = 32.953125, heading = 59.527558},
    {x = -1956.817626, y = 3332.281250, z = 32.953125, heading = 65.196854},
    {x = -1954.391236, y = 3320.861572, z = 32.953125, heading = 59.527558}
}

-- Position du PED pour ouvrir le menu
Config.MenuPedPosition = {
    x = -5825.327636,
    y = -905.472534,
    z = 501.489990,
    heading = 269.291352
}

-- Modèle du PED pour le menu
Config.MenuPedModel = "s_m_y_swat_01" -- Modèle du PED (peut être changé)

-- Distance d'interaction avec le PED
Config.InteractionDistance = 2.0

-- Durée de la partie en secondes
Config.GameDuration = 90 -- 1 minute 30

-- Récompense en fin de partie
Config.Reward = 2000

-- Hash du modèle de ped pour les bots
Config.BotModel = "mp_m_freemode_01" -- Modèle du bot (hitbox plus précise)
-- Autres modèles possibles: "a_m_y_skater_01", "s_m_y_dealer_01", "ig_clay"
