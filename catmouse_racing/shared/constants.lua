--[[
    ═══════════════════════════════════════════════════════════
    📋 CONSTANTES ET ÉNUMÉRATIONS PARTAGÉES
    ═══════════════════════════════════════════════════════════
    
    ✅ VÉRIFIÉ: Tous les événements bien définis
]]

Constants = {}

-- ═══════════════════════════════════════════════════════════
-- 📡 ÉVÉNEMENTS RÉSEAU
-- ═══════════════════════════════════════════════════════════
Constants.Events = {
    -- Invitations
    SEND_INVITATION = 'catmouse:sendInvitation',
    RECEIVE_INVITATION = 'catmouse:receiveInvitation',
    ACCEPT_INVITATION = 'catmouse:acceptInvitation',
    DECLINE_INVITATION = 'catmouse:declineInvitation',
    INVITATION_RESPONSE = 'catmouse:invitationResponse',
    
    -- Matchmaking
    JOIN_QUEUE = 'catmouse:joinQueue',
    LEAVE_QUEUE = 'catmouse:leaveQueue',
    QUEUE_UPDATE = 'catmouse:queueUpdate',
    MATCH_FOUND = 'catmouse:matchFound',
    
    -- Course
    PREPARE_RACE = 'catmouse:prepareRace',
    START_COUNTDOWN = 'catmouse:startCountdown',
    START_RACE = 'catmouse:startRace',
    END_ROUND = 'catmouse:endRound',
    END_RACE = 'catmouse:endRace',
    LEAVE_RACE = 'catmouse:leaveRace',
    
    -- ✅ CRITIQUE: Infraction véhicule
    VEHICLE_VIOLATION = 'catmouse:vehicleViolation',
    
    -- Synchronisation
    SYNC_POSITION = 'catmouse:syncPosition',
    SYNC_CAPTURE = 'catmouse:syncCapture',
    SYNC_DISTANCE = 'catmouse:syncDistance',
    
    -- Résultats
    ROUND_RESULT = 'catmouse:roundResult',
    MATCH_RESULT = 'catmouse:matchResult',
    
    -- UI
    NOTIFY = 'catmouse:notify',
    UPDATE_HUD = 'catmouse:updateHUD',
    SHOW_RESULT = 'catmouse:showResult'
}

-- ═══════════════════════════════════════════════════════════
-- 🎭 RÔLES
-- ═══════════════════════════════════════════════════════════
Constants.Role = {
    NONE = 0,
    HUNTER = 1,
    RUNNER = 2
}

Constants.RoleName = {
    [0] = 'NONE',
    [1] = 'CHASSEUR',
    [2] = 'FUYARD'
}

-- ═══════════════════════════════════════════════════════════
-- 📊 STATUTS DE COURSE
-- ═══════════════════════════════════════════════════════════
Constants.RaceStatus = {
    NONE = 0,
    WAITING = 1,
    PREPARING = 2,
    COUNTDOWN = 3,
    ACTIVE = 4,
    ENDING = 5,
    FINISHED = 6
}

Constants.RaceStatusName = {
    [0] = 'NONE',
    [1] = 'WAITING',
    [2] = 'PREPARING',
    [3] = 'COUNTDOWN',
    [4] = 'ACTIVE',
    [5] = 'ENDING',
    [6] = 'FINISHED'
}

-- ═══════════════════════════════════════════════════════════
-- 🏆 RÉSULTATS DE ROUND
-- ═══════════════════════════════════════════════════════════
Constants.RoundResult = {
    NONE = 0,
    RUNNER_ESCAPED = 1,
    RUNNER_CAPTURED = 2,
    TIME_UP = 3,
    VEHICLE_VIOLATION = 4
}

Constants.RoundResultName = {
    [0] = 'NONE',
    [1] = 'RUNNER_ESCAPED',
    [2] = 'RUNNER_CAPTURED',
    [3] = 'TIME_UP',
    [4] = 'VEHICLE_VIOLATION'
}

-- ✅ Types d'infractions véhicule
Constants.ViolationType = {
    FLIPPED = 'flipped',
    AIRBORNE = 'airborne',
    DESTROYED = 'destroyed'
}

Constants.ViolationName = {
    flipped = 'Véhicule retourné',
    airborne = 'Saut abusif',
    destroyed = 'Véhicule détruit'
}

-- ═══════════════════════════════════════════════════════════
-- 🔔 TYPES DE NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════
Constants.NotificationType = {
    INFO = 'info',
    SUCCESS = 'success',
    WARNING = 'warning',
    ERROR = 'error',
    INVITE = 'invite'
}

-- ═══════════════════════════════════════════════════════════
-- 📊 STATUTS MATCHMAKING
-- ═══════════════════════════════════════════════════════════
Constants.QueueStatus = {
    NONE = 0,
    SEARCHING = 1,
    FOUND = 2,
    CANCELLED = 3,
    TIMEOUT = 4
}

Constants.QueueStatusName = {
    [0] = 'NONE',
    [1] = 'SEARCHING',
    [2] = 'FOUND',
    [3] = 'CANCELLED',
    [4] = 'TIMEOUT'
}

-- ═══════════════════════════════════════════════════════════
-- 🎮 CONTRÔLES À DÉSACTIVER
-- ═══════════════════════════════════════════════════════════
Constants.DisabledControls = {
    75,   -- VehicleExit
    24,   -- Attack
    25,   -- Aim
    47,   -- Weapon
    58,   -- Weapon Select
    140,  -- MeleeAttackLight
    141,  -- MeleeAttackHeavy
    142,  -- MeleeAttackAlternate
    257,  -- AttackSecondary
    263,  -- MeleeAttack1
    264,  -- MeleeAttack2
    27,   -- Phone
    19,   -- CharacterWheel
    37,   -- SelectWeapon
    44,   -- Cover
    288,  -- Spawn Bike
    289,  -- Spawn Boat
    170,  -- Spawn Car
}

-- ✅ LOG DE VÉRIFICATION
