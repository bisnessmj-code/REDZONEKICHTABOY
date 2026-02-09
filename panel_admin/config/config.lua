--[[
    Configuration Générale - Panel Admin Fight League
    Ce fichier contient tous les paramètres configurables du panel
]]

Config = {}

-- ══════════════════════════════════════════════════════════════
-- CONFIGURATION GÉNÉRALE
-- ══════════════════════════════════════════════════════════════

Config.ServerName = 'Fight League'
Config.PanelVersion = '1.0.0'
Config.Debug = false -- Activer pour logs détaillés en console

-- ══════════════════════════════════════════════════════════════
-- KEYBINDS
-- ══════════════════════════════════════════════════════════════

Config.OpenKey = 'F7' -- Touche pour ouvrir le panel
Config.ReportsKey = 'F8' -- Touche pour ouvrir directement les Reports/Tickets
Config.CloseOnEscape = true -- Fermer avec Echap

-- Touche de réparation véhicule (modifiable dans les paramètres FiveM)
Config.RepairKey = {
    Enabled = true,
    DefaultKey = 'F9', -- Touche par défaut (modifiable par le joueur dans Paramètres > Raccourcis clavier > FiveM)
    AllowedGroups = {'user', 'staff', 'organisateur', 'responsable', 'admin', 'owner'}, -- Groupes autorisés
    Cooldown = 5, -- Cooldown en secondes entre chaque réparation
    NotifyOnRepair = true -- Afficher une notification lors de la réparation
}

-- ══════════════════════════════════════════════════════════════
-- INTERFACE NUI
-- ══════════════════════════════════════════════════════════════

Config.UI = {
    DefaultTheme = 'dark', -- 'dark' ou 'light'
    Language = 'fr', -- 'fr' ou 'en'
    AnimationSpeed = 200, -- ms
    RefreshInterval = 5000, -- Rafraîchissement auto liste joueurs (ms)
    MaxPlayersPerPage = 20, -- Pagination liste joueurs
    NotificationDuration = 5000 -- Durée notifications (ms)
}

-- ══════════════════════════════════════════════════════════════
-- SANCTIONS
-- ══════════════════════════════════════════════════════════════

Config.Sanctions = {
    -- Seuils d'avertissement automatique
    WarnThresholds = {
        {count = 3, action = 'kick', reason = 'Trop d\'avertissements (3)'},
        {count = 5, action = 'ban_temp', duration = 24, reason = 'Trop d\'avertissements (5)'},
        {count = 7, action = 'ban_perm', reason = 'Trop d\'avertissements (7)'}
    },

    -- Durées de ban par défaut (en heures)
    DefaultBanDurations = {
        {label = '1 heure', value = 1},
        {label = '6 heures', value = 6},
        {label = '12 heures', value = 12},
        {label = '24 heures', value = 24},
        {label = '3 jours', value = 72},
        {label = '7 jours', value = 168},
        {label = '30 jours', value = 720},
        {label = 'Permanent', value = -1}
    },
    -- Raisons prédéfinies
    PredefinedReasons = {
        warn = {
            'Comportement inapproprié',
            'Spam chat',
            'Irrespect envers les joueurs',
            'Non-respect des règles',
            'Autres (spécifier)'
        },
        kick = {
            'AFK prolongé',
            'Comportement toxique',
            'Non-respect des règles',
            'Interruption d\'événement',
            'Autres (spécifier)'
        },
        ban = {
            'Cheat/Hack',
            'Exploitation de bug',
            'Harcèlement',
            'Comportement toxique répété',
            'Tricherie en événement',
            'Autres (spécifier)'
        }
    }
}

-- ══════════════════════════════════════════════════════════════
-- ÉCONOMIE
-- ══════════════════════════════════════════════════════════════

Config.Economy = {
    MaxSingleTransaction = 1000000, -- Montant max en une fois
    RequireReason = true, -- Obliger une raison pour les transactions
    LogAllTransactions = true, -- Logger toutes les transactions

    -- Montants rapides prédéfinis
    QuickAmounts = {
        {label = '1K', value = 1000},
        {label = '5K', value = 5000},
        {label = '10K', value = 10000},
        {label = '50K', value = 50000},
        {label = '100K', value = 100000}
    }
}

-- ══════════════════════════════════════════════════════════════
-- TÉLÉPORTATION
-- ══════════════════════════════════════════════════════════════

Config.Teleport = {
    DefaultLocations = {
        {name = 'Spawn Principal', category = 'spawn', coords = vector3(-5817.7, -917.9, 502.4), heading = 205.0},
        {name = 'Commissariat', category = 'admin', coords = vector3(428.0, -981.0, 30.7), heading = 0.0},
        {name = 'Hopital', category = 'admin', coords = vector3(298.0, -584.0, 43.3), heading = 0.0},
        {name = 'Arene Fight', category = 'event', coords = vector3(0.0, 0.0, 0.0), heading = 0.0}
    },
    Categories = {
        {id = 'spawn', label = 'Points de spawn', icon = 'fa-home'},
        {id = 'admin', label = 'Lieux admin', icon = 'fa-shield'},
        {id = 'event', label = 'Événements', icon = 'fa-trophy'},
        {id = 'custom', label = 'Personnalisé', icon = 'fa-star'}
    }
}

-- ══════════════════════════════════════════════════════════════
-- VÉHICULES
-- ══════════════════════════════════════════════════════════════

Config.Vehicles = {
    -- Véhicules favoris par défaut
    DefaultFavorites = {
        {spawn = 'adder', display = 'Adder', category = 'super'},
        {spawn = 't20', display = 'T20', category = 'super'},
        {spawn = 'zentorno', display = 'Zentorno', category = 'super'},
        {spawn = 'elegy2', display = 'Elegy RH8', category = 'sports'},
        {spawn = 'sultan', display = 'Sultan', category = 'sports'}
    },

    Categories = {
        {id = 'super', label = 'Super', icon = 'fa-rocket'},
        {id = 'sports', label = 'Sports', icon = 'fa-car'},
        {id = 'muscle', label = 'Muscle', icon = 'fa-bolt'},
        {id = 'utility', label = 'Utilitaire', icon = 'fa-truck'},
        {id = 'helicopter', label = 'Hélicoptère', icon = 'fa-helicopter'},
        {id = 'boat', label = 'Bateau', icon = 'fa-ship'}
    },

    SpawnDistance = 5.0, -- Distance de spawn devant le joueur
    DeleteRadius = 10.0 -- Rayon de suppression véhicules
}

-- ══════════════════════════════════════════════════════════════
-- ÉVÉNEMENTS FIGHT LEAGUE
-- ══════════════════════════════════════════════════════════════

Config.Events = {
    MaxParticipants = 70, -- Nombre max de participants
    RegistrationTimeout = 300, -- Temps inscription (secondes)

    Types = {
        {id = 'fight', label = 'Combat', icon = 'fa-fist-raised'},
        {id = 'tournament', label = 'Tournoi', icon = 'fa-trophy'},
        {id = 'training', label = 'Entraînement', icon = 'fa-dumbbell'},
        {id = 'meeting', label = 'Réunion', icon = 'fa-users'},
        {id = 'other', label = 'Autre', icon = 'fa-calendar'}
    },

    -- Routing buckets disponibles
    AvailableBuckets = {0, 1, 2, 3, 4, 5}
}

-- ══════════════════════════════════════════════════════════════
-- LOGS & MONITORING
-- ══════════════════════════════════════════════════════════════

Config.Logs = {
    Enabled = true,
    RetentionDays = 30, -- Garder les logs pendant 30 jours

    -- Catégories à logger
    Categories = {
        'auth', -- Connexions au panel
        'player', -- Actions sur joueurs
        'sanction', -- Warns/kicks/bans
        'economy', -- Transactions économiques
        'teleport', -- Téléportations
        'vehicle', -- Spawn/delete véhicules
        'event', -- Gestion événements
        'announce', -- Annonces
        'config' -- Modifications config
    }
}

-- ══════════════════════════════════════════════════════════════
-- DISCORD WEBHOOKS
-- ══════════════════════════════════════════════════════════════

Config.Discord = {
    Enabled = true,

    --[[
        ═══════════════════════════════════════════════════════════
        SECURITE: Les webhooks sont dans server.cfg (pas ici!)
        Cela empeche les cheaters de dump les URLs.

        Ajoutez ces lignes dans votre server.cfg:
        ═══════════════════════════════════════════════════════════

        # Panel Admin - Discord Webhooks (SECURISE)
        set discord_webhook_sanctions "https://discord.com/api/webhooks/..."
        set discord_webhook_economy "https://discord.com/api/webhooks/..."
        set discord_webhook_events "https://discord.com/api/webhooks/..."
        set discord_webhook_logs "https://discord.com/api/webhooks/..."
        set discord_webhook_deaths "https://discord.com/api/webhooks/..."
        set discord_webhook_staffRoles "https://discord.com/api/webhooks/..."
        set discord_webhook_commands "https://discord.com/api/webhooks/..."
        set discord_webhook_gdt "https://discord.com/api/webhooks/..."
        set discord_webhook_cvc "https://discord.com/api/webhooks/..."

        ═══════════════════════════════════════════════════════════
    ]]

    -- IDs des roles Discord pour les mentions (optionnel)
    RoleIds = {
        gdt = '',
        cvc = ''
    },

    -- Apparence du bot Discord
    BotName = 'Panel Fight League',
    BotAvatar = 'https://i.ibb.co/vpck0Wv/4-KLOGOzezegfze.png'
}

-- ══════════════════════════════════════════════════════════════
-- SÉCURITÉ
-- ══════════════════════════════════════════════════════════════

Config.Security = {
    SessionTimeout = 3600, -- Timeout session (secondes)
    MaxLoginAttempts = 5, -- Tentatives max avant blocage
    RateLimitPerMinute = 60, -- Actions max par minute
    LogSuspiciousActivity = true -- Logger activité suspecte
}

-- ══════════════════════════════════════════════════════════════
-- COMMAND LOGGER - Log des commandes joueurs sur Discord
-- ══════════════════════════════════════════════════════════════

Config.CommandLogger = {
    Enabled = true,

    -- Commandes a ignorer (ne pas logger)
    IgnoredCommands = {
        'say', 'me', 'ooc', 'do', 'twt', 'tweet', -- Chat RP
        'report', 'help', 'commands', 'cmds', -- Commandes basiques
        'id', 'pos', 'coords', -- Info
        'e', 'emote', 'anim', -- Emotes
        'repairkey' -- Commande de reparation vehicule
    },

    -- Logger uniquement certains groupes (vide = tous les groupes)
    -- Exemple: {'user'} pour logger uniquement les users
    OnlyGroups = {},

    -- Ignorer certains groupes (ne pas logger ces groupes)
    -- Exemple: {'admin', 'owner'} pour ne pas logger les admins
    IgnoredGroups = {},

    -- Couleur de l'embed Discord (en decimal)
    EmbedColor = 16744448 -- Orange
}
