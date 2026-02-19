Config = {}

Config.logLevelClient = 1           -- 0 = Désactiver, 1 = Infos, 2 = Avertissements, 3 = Erreurs, 4 = Debug
Config.logLevelServer = 0           -- 0 = Désactiver, 1 = Infos, 2 = Avertissements, 3 = Erreurs, 4 = Debug

Config.benchmark = false            -- Mettre sur true pour voir le temps nécessaire pour tuer un joueur
Config.reviveCommand = false        -- Mettre sur true pour activer la commande /revive (pour soi-même)
Config.reviveOnScriptStart = false  -- Réanime le joueur quand le script démarre
Config.reviveOnDeath = false        -- Réanime le joueur automatiquement après sa mort (après 5 secondes)

Config.disableHelmetArmor = true    -- Mettre sur true pour désactiver la protection des casques
Config.disableHeadshots = false     -- Mettre sur true pour désactiver les dégâts de type "headshot"
Config.hitDedupDebounceMs = 350     -- Temps minimum (ms) pour ignorer les balles en double sur un même joueur

Config.forceDeathAfterHeadshots = 2 -- Nombre de headshots nécessaires pour forcer la mort du joueur
Config.oneHeadshotWeapons = {       -- Armes qui tuent en un seul headshot (même si le joueur a de l'armure)
    [`WEAPON_PISTOL`] = true,
    [`WEAPON_PISTOL_MK2`] = true,
    [`WEAPON_COMBATPISTOL`] = true,
    [`WEAPON_APPISTOL`] = true,
    [`WEAPON_REVOLVER`] = true,
    [`WEAPON_REVOLVER_MK2`] = true,
    [`WEAPON_MACHINEPISTOL`] = true,
    [`WEAPON_PISTOL50`] = true,
    [`WEAPON_HEAVYPISTOL`] = true,
    [`WEAPON_MARKSMANPISTOL`] = true,
    [`WEAPON_DOUBLEACTION`] = true,
    [`WEAPON_VINTAGEPISTOL`] = true,
    [`WEAPON_SNSPISTOL`] = true,
    [`WEAPON_SNSPISTOL_MK2`] = true,
}

Config.extraBones = { -- Os supplémentaires à détecter comme des headshots
    [39317] = true,   -- Cou
    [35731] = true,   -- Cou (Arrière)
}

Config.extraComponents = { -- Éléments supplémentaires à détecter
    [19] = true,           -- Cou
}

Config.ignoreGodmode = true -- Mettre sur true pour tuer même les joueurs en godmode
Config.bypassAcePerms = {   -- Les joueurs avec ces permissions ACE ne seront PAS tués (même si ignoreGodmode est true)
    -- ["permission"] = true,
}
Config.maxValidDistance = 500.0    -- Distance maximale de détection des joueurs (en mètres)
Config.maxValidDistanceWeapons = { -- Distance maximale de détection par arme spécifique (en mètres)
    -- [`WEAPON_PISTOL`] = 150.0, -- exemple
}
Config.killLockTimeout = 1000 -- Temps (ms) utilisé pour "valider" une cible après une mort enregistrée

Config.hideReticle = false    -- Mettre sur true pour cacher le réticule en visant (désactive aussi la croix de mort)
-- Config.fixRedCross = true -- Mettre sur true pour laisser la croix rouge apparaître sur le tueur
Config.customKillFeed = {
    enabled = false,        -- Activer le flux de mort (killfeed) personnalisé
    duration = 350,        -- Durée d'affichage du killfeed en millisecondes
    useImage = true,       -- Utiliser une image plutôt qu'une forme créée manuellement
    showAnimation = false, -- Jouer une animation d'apparition (zoom)
    showForNPCs = true,    -- Afficher aussi les morts impliquant des PNJ (bots)
}

Config.excludedWeapons = { -- Armes exclues du système anti-tank
    [`WEAPON_UNARMED`] = true,
    [`WEAPON_STUNGUN`] = true,
    [`WEAPON_FIREEXTINGUISHER`] = true,
    [`WEAPON_FLAREGUN`] = true,
    [`WEAPON_PETROLCAN`] = true,
    [`WEAPON_HOMINGLAUNCHER`] = true,
    [`WEAPON_RPG`] = true,
    [`WEAPON_MINIGUN`] = true,
    [`WEAPON_GRENADELAUNCHER`] = true,
    [`WEAPON_GRENADELAUNCHER_SMOKE`] = true,
    [`WEAPON_COMPACTLAUNCHER`] = true,
    [`WEAPON_RAILGUN`] = true,
    [`WEAPON_RAYMINIGUN`] = true,
    [`WEAPON_RAYPISTOL`] = true,
    [`WEAPON_RAYCARBINE`] = true,
    [`WEAPON_BZGAS`] = true,
    [`WEAPON_GRENADE`] = true,
    [`WEAPON_SMOKEGRENADE`] = true,
    [`WEAPON_STICKYBOMB`] = true,
    [`WEAPON_PROXMINE`] = true,
    [`WEAPON_PIPEBOMB`] = true,
    [`WEAPON_MOLOTOV`] = true,
    [`WEAPON_SNOWBALL`] = true,
    [`WEAPON_FIREWORK`] = true,
    [`WEAPON_BALL`] = true,
    [`WEAPON_KNIFE`] = true,
    [`WEAPON_NIGHTSTICK`] = true,
    [`WEAPON_HAMMER`] = true,
    [`WEAPON_BAT`] = true,
    [`WEAPON_CROWBAR`] = true,
    [`WEAPON_BOTTLE`] = true,
    [`WEAPON_DAGGER`] = true,
    [`WEAPON_WRENCH`] = true,
    [`WEAPON_FLASHLIGHT`] = true,
    [`WEAPON_SWITCHBLADE`] = true,
    [`WEAPON_MACHETE`] = true,
    [`WEAPON_BATTLEAXE`] = true,
    [`WEAPON_HATCHET`] = true,
}

-- Effets d'écran
Config.effectDuration = 2500            -- Durée des effets d'écran en millisecondes
Config.victimEffect = ""    --  DeathFailOut Effet pour la victime (laisser vide "" pour désactiver)
Config.killerEffect = "" -- SuccessFranklin Effet pour le tueur (laisser vide "" pour désactiver)

-- Effets sonores
Config.audioNameKiller = "" -- Nom du son pour le tueur (vide "" pour désactiver)
Config.audioNameVictim = ""     -- Nom du son pour la victime (vide "" pour désactiver)
Config.audioRef = ""       -- Référence audio (vide "" pour désactiver)

-- Ralenti à la mort (Slow motion)
Config.slowMotion = {
    enabled = false,  -- Mettre sur false pour désactiver
    duration = 2000, -- Durée du ralenti en millisecondes
    factor = 0.3     -- Intensité du ralenti (1.0 = normal, 0.0 = ultra lent)
}

-- Tremblement de caméra à la mort
Config.cameraShake = {
    enabled = false,  -- Mettre sur false pour désactiver
    duration = 2000, -- Durée du tremblement en millisecondes
    intensity = 0.5  -- Intensité du tremblement
}

-- Caméra à la troisième personne à la mort
Config.cameraOnDeath = {
    enabled = false,  -- Mettre sur false pour désactiver
    duration = 2000, -- Durée d'activation de la caméra en millisecondes
}

-- Options Expérimentales
Config.enableOnlyHeadshotHits = false               -- Activer UNIQUEMENT les dégâts par headshot
Config.experimentalDeath = true                    -- Améliore le système de mort (tester si compatible avec votre serveur)
Config.experimentalDetection = true                 -- Améliore le système de détection des touches
Config.experimentalDetectionDebug = false           -- Activer le mode debug pour le système de détection
Config.experimentalShotDebounceMs = 80              -- Temps minimum entre deux tirs expérimentaux
Config.experimentalDetectionPrecisionRadius = 0.250 -- Tolérance de détection (plus haut = plus permissif) 0.145 