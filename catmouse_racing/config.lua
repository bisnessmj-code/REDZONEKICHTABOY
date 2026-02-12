--[[
    ═══════════════════════════════════════════════════════════
    ⚙️ CATMOUSE RACING - CONFIGURATION CENTRALE (OPTIMISÉE)
    ═══════════════════════════════════════════════════════════
    
    ✅ NOUVEAU: Système de niveaux de log
]]

Config = {}

-- ═══════════════════════════════════════════════════════════
-- 🐛 DEBUG MODE & LOGGING
-- ═══════════════════════════════════════════════════════════

Config.Debug = false

--[[
    ✅ NOUVEAU: Niveaux de log
    
    Si Config.Debug = false:
        → Seules les ERREURS s'affichent (niveau ERROR)
    
    Si Config.Debug = true:
        → Utilise Config.LogLevel pour déterminer le niveau de verbosité
    
    Niveaux disponibles (du plus verbeux au moins verbeux):
    - 0 = TRACE   (Trace de l'exécution - TRÈS verbeux)
    - 1 = DEBUG   (Informations de debug)
    - 2 = INFO    (Informations importantes)
    - 3 = WARN    (Avertissements)
    - 4 = ERROR   (Erreurs uniquement)
    - 5 = NONE    (Aucun log)
    
    Recommandations:
    - Production: Config.Debug = false (seules les erreurs)
    - Développement: Config.Debug = true, LogLevel = 2 (INFO)
    - Debug intensif: Config.Debug = true, LogLevel = 0 (TRACE)
]]
Config.LogLevel = 2  -- INFO par défaut quand Debug = true

-- ═══════════════════════════════════════════════════════════
-- 👮 GROUPES ADMIN
-- ═══════════════════════════════════════════════════════════
Config.AdminGroups = {
    ['owner'] = true,
    ['admin'] = true,
    ['staff'] = true,
    ['responsable'] = true
}

-- ═══════════════════════════════════════════════════════════
-- 🏆 SYSTÈME ELO
-- ═══════════════════════════════════════════════════════════
Config.Elo = {
    enabled = true,
    defaultElo = 1000,
    kFactor = 32,
    dynamicKFactor = true,
    kFactorNew = 40,
    kFactorHigh = 24,
    minChange = 5,
    maxChange = 50,
    minElo = 0,
    saveHistory = true,
    identifierPriority = { 'license', 'steam', 'discord', 'fivem' }
}

-- ═══════════════════════════════════════════════════════════
-- 🏆 LEADERBOARD 3D (OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════
Config.Leaderboard = {
    enabled = false,
    position = vector3(-825.406738, -919.120850, 6504.518066),
    renderDistance = 15.0,
    refreshInterval = 300000, -- 5 minutes (cache serveur)
    title = "~y~🏆 TOP 3 CLASSEMENT 🏆",
    titleScale = 0.5,
    textScale = 0.4,
    titleOffset = 1.2,
    startOffset = 0.8,
    lineSpacing = 0.25,
    medals = {
        [1] = "~y~🥇",
        [2] = "~c~🥈",
        [3] = "~o~🥉"
    },
    colors = {
        title = { r = 255, g = 215, b = 0 },
        [1] = { r = 255, g = 215, b = 0 },
        [2] = { r = 192, g = 192, b = 192 },
        [3] = { r = 205, g = 127, b = 50 }
    },
    showFooter = false
}

-- ═══════════════════════════════════════════════════════════
-- 🎯 PED CONFIGURATION
-- ═══════════════════════════════════════════════════════════
Config.Ped = {
    model = 'a_m_y_runner_01',
    coords = vector4(-5823.230957, -919.068115, 501.490234, 269.291351),
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    invincible = true,
    freeze = true,
    useOxTarget = false,
    interactionDistance = 2.5,
    targetLabel = '🏁 Jeu de Course',
    targetIcon = 'fas fa-flag-checkered'
}

-- ═══════════════════════════════════════════════════════════
-- 🏁 POSITIONS DE JEU
-- ═══════════════════════════════════════════════════════════
Config.Positions = {
    spawns = {
        {
            name = "Terminal",
            runner = vector4(-14.624176, -1721.287964, 29.431518, 11.338582),
            hunter = vector4(-10.483516, -1736.901124, 29.296752, 14.173228)
        },
        {
            name = "Chumash",
            runner = vector4(-1536.619751, -399.573608, 41.445435, 317.480316),
            hunter = vector4(-1547.367065, -412.325287, 41.495972, 320.314972)
        },
        {
            name = "Paleto Bay",
            runner = vector4(1357.806641, -575.367004, 73.881348, 59.527554),
            hunter = vector4(1370.848389, -582.804382, 73.864502, 59.527554)
        }
    },
    
    randomSpawns = true,
    
    exit = vector4(-5803.938477, -919.068115, 503.191162, 87.874016)
}

-- ═══════════════════════════════════════════════════════════
-- 🚗 VÉHICULES
-- ═══════════════════════════════════════════════════════════
Config.Vehicle = {
    availableModels = {
        'sultan',
        'blitz',
        'srspback',
        'issi7',
        'tailgater2'
    },
    randomSelection = true,
    primaryColor = 0,
    secondaryColor = 0,
    invincible = false,
    lockDoors = true,
    engineOn = true,
    fullPerformance = true  -- ✅ Spawn les véhicules avec performances maximales
}

-- ═══════════════════════════════════════════════════════════
-- 🎮 PARAMÈTRES DE COURSE
-- ═══════════════════════════════════════════════════════════
Config.Race = {
    maxRounds = 3,
    countdownDuration = 3000,
    roundDuration = 180000,
    escapeDistance = 200.0,
    captureDistance = 7.5,
    captureToleranceDistance = 0.9, -- Zone de tolérance pour continuer la capture
    captureToleranceSpeedLimit = 50.0, -- Vitesse max pendant la capture en cours
    captureSpeedLimit = 3.5,
    captureDuration = 5000,
    captureResetOnEscape = true,
    bucketRange = {
        min = 2000,
        max = 4000
    },
    inviteTimeout = 30000,
    autoCleanup = true,
    cleanupInterval = 60000
}

-- ═══════════════════════════════════════════════════════════
-- 🛡️ SÉCURITÉ VÉHICULE (OPTIMISÉ)
-- ═══════════════════════════════════════════════════════════
Config.VehicleSecurity = {
    enabled = true,
    checkInterval = 1000,  -- ✅ OPTIMISÉ: 1 seconde au lieu de 500ms
    flipped = {
        enabled = true,
        gracePeriod = 3000,
        minAngle = 120
    },
    airborne = {
        enabled = true,
        maxAltitude = 15.0,
        maxDuration = 2000,
        checkGroundDistance = true
    },
    destroyed = {
        enabled = true,
        instantLoss = true
    }
}

-- ═══════════════════════════════════════════════════════════
-- 🔍 MATCHMAKING
-- ═══════════════════════════════════════════════════════════
Config.Matchmaking = {
    enabled = true,
    maxQueueTime = 300000,
    checkInterval = 2000,
    notifyOnMatch = true,
    soundOnMatch = true
}

-- ═══════════════════════════════════════════════════════════
-- 🔒 RESTRICTIONS DE FILE D'ATTENTE
-- ═══════════════════════════════════════════════════════════
Config.Queue = {
    restrictionDistance = 2.0,
    showHelpTextNearPed = true
}

-- ═══════════════════════════════════════════════════════════
-- 🎬 ANIMATIONS
-- ═══════════════════════════════════════════════════════════
Config.Animations = {
    victory = {
        dict = 'anim@mp_player_intcelebrationmale@golf',
        name = 'golf',
        duration = 3000
    },
    defeat = {
        dict = 'anim@mp_player_intcelebrationmale@face_palm',
        name = 'face_palm',
        duration = 3000
    },
    countdown = {
        showNumbers = true,
        sound = true
    }
}

-- ═══════════════════════════════════════════════════════════
-- 🎨 INTERFACE NUI
-- ═══════════════════════════════════════════════════════════
Config.UI = {
    backgroundImage = 'background.png',
    resolution = { width = 1920, height = 1080 },
    title = 'JEU DE COURSE',
    subtitle = 'CHASSEUR VS FUYARD',
    hud = {
        showTimer = true,
        showRound = true,
        showDistance = true,
        showCaptureBar = true,
        showRole = true
    },
    hudPositions = {
        timer = 'top-center',
        round = 'top-left',
        distance = 'bottom-center',
        captureBar = 'center',
        role = 'top-right'
    }
}

-- ═══════════════════════════════════════════════════════════
-- 🔔 NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════
Config.Notifications = {
    duration = 5000,
    maxVisible = 3,
    position = 'top-right',
    fadeInDuration = 300,
    fadeOutDuration = 300
}

-- ═══════════════════════════════════════════════════════════
-- 📝 RÈGLEMENT
-- ═══════════════════════════════════════════════════════════
Config.Rules = {
    {
        title = 'COMMANDE POUR QUITTE',
        description = '/leavequeue commande pour quitte la file d attente'
    },
    {
        title = 'OBJECTIF FUYARD',
        description = 'Atteindre 150m de distance du chasseur OU survivre 3 minutes.'
    },
    {
        title = 'OBJECTIF CHASSEUR',
        description = 'Bloquer le fuyard et maintenir la capture pendant 4 secondes.'
    },
    {
        title = 'FORMAT',
        description = 'Best of 3 rounds. Les rôles s\'inversent à chaque round.'
    },
    {
        title = 'RÈGLES',
        description = 'Interdiction de sortir du véhicule ou d\'utiliser des armes.'
    },
    {
        title = '⚠️ INFRACTIONS',
        description = 'Véhicule retourné >3s, saut >15m pendant >2s, destruction ou eau = DÉFAITE.'
    }
}

-- ═══════════════════════════════════════════════════════════
-- 🛡️ SÉCURITÉ
-- ═══════════════════════════════════════════════════════════
Config.Security = {
    checkPlayerExists = true,
    checkPlayerOnline = true,
    preventSelfInvite = true,
    checkAlreadyInRace = true,
    checkAlreadyInQueue = true,
    logInvitations = true,
    logRaceResults = true
}

-- ═══════════════════════════════════════════════════════════
-- 🎨 TEXTES PERSONNALISABLES
-- ═══════════════════════════════════════════════════════════
Config.Texts = {
    ui_title = 'JEU DE COURSE',
    ui_subtitle = 'CHASSEUR VS FUYARD',
    ui_rules_title = 'RÈGLEMENT',
    ui_close_btn = 'FERMER',
    ui_queue_btn = 'REJOINDRE LA FILE',
    ui_leave_queue_btn = 'QUITTER LA FILE',
    
    invite_sent = 'Invitation envoyée à %s',
    invite_received = 'Invitation reçue de %s',
    invite_accepted = '%s a accepté votre invitation !',
    invite_declined = '%s a refusé votre invitation.',
    invite_expired = 'L\'invitation a expiré.',
    
    already_in_race = 'Vous êtes déjà en course.',
    target_in_race = 'Ce joueur est déjà en course.',
    player_not_found = 'Joueur introuvable.',
    cannot_invite_self = 'Vous ne pouvez pas vous inviter vous-même.',
    
    queue_joined = 'Vous avez rejoint la file d\'attente.',
    queue_left = 'Vous avez quitté la file d\'attente.',
    queue_already = 'Vous êtes déjà dans la file.',
    queue_match_found = 'Adversaire trouvé ! Préparation...',
    queue_timeout = 'Temps d\'attente expiré.',
    queue_restriction = '🔒 Recherche en cours ! Tapez /leavequeue pour annuler.',
    
    race_starting = 'La course commence !',
    race_round = 'ROUND %d/%d',
    race_role_hunter = 'CHASSEUR',
    race_role_runner = 'FUYARD',
    race_countdown_go = 'GO !',
    race_timer_expired = 'Temps écoulé !',
    
    result_runner_escaped = 'Le fuyard s\'est échappé !',
    result_runner_captured = 'Le fuyard a été capturé !',
    result_time_up = 'Temps écoulé - Chasseur gagne !',
    result_victory = 'VICTOIRE !',
    result_defeat = 'DÉFAITE !',
    result_final_winner = '%s remporte le match !',
    result_final_score = 'Score final: %d - %d',
    
    player_disconnected = '%s s\'est déconnecté',
    player_quit = '%s a quitté la partie',
    win_by_forfeit = 'Victoire par forfait !',
    lose_by_forfeit = 'Défaite par forfait',
    opponent_disconnected_title = 'ADVERSAIRE DÉCONNECTÉ',
    opponent_quit_title = 'ADVERSAIRE A QUITTÉ',
    forfeit_warning = '⚠️ Quitter entraîne une pénalité ELO',
    
    violation_flipped = '🚫 Véhicule retourné - DÉFAITE !',
    violation_airborne = '🚫 Saut abusif détecté - DÉFAITE !',
    violation_destroyed = '🚫 Véhicule détruit/submergé - DÉFAITE !',
    violation_warning_flipped = '⚠️ Véhicule retourné ! Redressez-vous rapidement !',
    
    elo_gain = 'ELO: +%d (%d → %d)',
    elo_loss = 'ELO: -%d (%d → %d)',
    
    cmd_usage = 'Usage: /1v1course [ID du joueur]',
    cmd_invalid_id = 'ID de joueur invalide.'
}

-- ═══════════════════════════════════════════════════════════
-- 🔊 SONS
-- ═══════════════════════════════════════════════════════════
Config.Sounds = {
    countdown = { name = 'TIMER_STOP', set = 'HUD_MINI_GAME_SOUNDSET' },
    go = { name = 'CHECKPOINT_PERFECT', set = 'HUD_MINI_GAME_SOUNDSET' },
    capture_start = { name = 'PICK_UP', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    capture_complete = { name = 'CHECKPOINT_NORMAL', set = 'HUD_MINI_GAME_SOUNDSET' },
    victory = { name = 'CHECKPOINT_PERFECT', set = 'HUD_MINI_GAME_SOUNDSET' },
    defeat = { name = 'CHECKPOINT_MISSED', set = 'HUD_MINI_GAME_SOUNDSET' },
    match_found = { name = 'Menu_Accept', set = 'Phone_SoundSet_Default' },
    violation = { name = 'LOSER', set = 'HUD_AWARDS' }
}
