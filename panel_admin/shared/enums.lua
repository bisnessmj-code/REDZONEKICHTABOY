--[[
    Constantes Partagées - Panel Admin Fight League
    Énumérations utilisées côté client et serveur
]]

Enums = {}

-- ══════════════════════════════════════════════════════════════
-- TYPES DE SANCTIONS
-- ══════════════════════════════════════════════════════════════

Enums.SanctionType = {
    WARN = 'warn',
    KICK = 'kick',
    BAN_TEMP = 'ban_temp',
    BAN_PERM = 'ban_perm'
}

Enums.SanctionStatus = {
    ACTIVE = 'active',
    EXPIRED = 'expired',
    REVOKED = 'revoked'
}

-- ══════════════════════════════════════════════════════════════
-- TYPES DE LOGS
-- ══════════════════════════════════════════════════════════════

-- Catégories de logs (doivent correspondre à l'ENUM dans panel_logs)
-- Valeurs valides: 'auth', 'player', 'sanction', 'economy', 'teleport', 'vehicle', 'event', 'system', 'death'
Enums.LogCategory = {
    AUTH = 'auth',
    PLAYER = 'player',
    SANCTION = 'sanction',
    ECONOMY = 'economy',
    TELEPORT = 'teleport',
    VEHICLE = 'vehicle',
    EVENT = 'event',
    ANNOUNCE = 'system', -- Mapped to system car pas dans l'ENUM
    CONFIG = 'system',   -- Mapped to system car pas dans l'ENUM
    SYSTEM = 'system',
    DEATH = 'death',
    REPORT = 'player'    -- Mapped to player car pas dans l'ENUM
}

Enums.LogAction = {
    -- Auth
    PANEL_OPEN = 'panel_open',
    PANEL_CLOSE = 'panel_close',

    -- Player
    VIEW_PLAYER = 'view_player',
    SPECTATE_START = 'spectate_start',
    SPECTATE_END = 'spectate_end',
    PLAYER_REVIVE = 'player_revive',
    PLAYER_HEAL = 'player_heal',
    PLAYER_FREEZE = 'player_freeze',
    PLAYER_UNFREEZE = 'player_unfreeze',
    PLAYER_SETGROUP = 'player_setgroup',

    -- Sanctions
    WARN_ADD = 'warn_add',
    KICK_PLAYER = 'kick_player',
    BAN_ADD = 'ban_add',
    BAN_REMOVE = 'unban',
    SANCTION_REMOVE = 'sanction_remove',

    -- Economy
    MONEY_ADD = 'money_add',
    MONEY_REMOVE = 'money_remove',
    MONEY_SET = 'money_set',

    -- Teleport
    TP_COORDS = 'tp_coords',
    TP_PLAYER = 'tp_player',
    TP_BRING = 'tp_bring',
    TP_GOTO = 'tp_goto',
    TP_RETURN = 'tp_return',
    TP_RETURN_PLAYER = 'tp_return_player',

    -- Vehicle
    VEHICLE_SPAWN = 'vehicle_spawn',
    VEHICLE_DELETE = 'vehicle_delete',
    VEHICLE_REPAIR = 'vehicle_repair',

    -- Event
    EVENT_CREATE = 'event_create',
    EVENT_START = 'event_start',
    EVENT_END = 'event_end',
    EVENT_CANCEL = 'event_cancel',

    -- Announce
    ANNOUNCE_SEND = 'announce_send',
    ANNOUNCE_SCHEDULE = 'announce_schedule',

    -- Death
    DEATH_PVP = 'death_pvp',
    DEATH_SUICIDE = 'death_suicide',
    DEATH_ENVIRONMENT = 'death_environment'
}

-- ══════════════════════════════════════════════════════════════
-- TYPES D'ÉVÉNEMENTS
-- ══════════════════════════════════════════════════════════════

Enums.EventType = {
    FIGHT = 'fight',
    TOURNAMENT = 'tournament',
    TRAINING = 'training',
    MEETING = 'meeting',
    OTHER = 'other'
}

Enums.EventStatus = {
    DRAFT = 'draft',
    SCHEDULED = 'scheduled',
    ACTIVE = 'active',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled'
}

Enums.ParticipantStatus = {
    REGISTERED = 'registered',
    CONFIRMED = 'confirmed',
    CHECKED_IN = 'checked_in',
    ELIMINATED = 'eliminated',
    WINNER = 'winner',
    NO_SHOW = 'no_show'
}

-- ══════════════════════════════════════════════════════════════
-- TYPES D'ANNONCES
-- ══════════════════════════════════════════════════════════════

Enums.AnnounceType = {
    CHAT = 'chat',
    NOTIFICATION = 'notification',
    POPUP = 'popup',
    ALL = 'all'
}

Enums.AnnouncePriority = {
    LOW = 'low',
    NORMAL = 'normal',
    HIGH = 'high',
    URGENT = 'urgent'
}

-- ══════════════════════════════════════════════════════════════
-- TYPES DE NOTES
-- ══════════════════════════════════════════════════════════════

Enums.NoteCategory = {
    GENERAL = 'general',
    WARNING = 'warning',
    POSITIVE = 'positive',
    REPORT = 'report',
    FOLLOW_UP = 'follow_up'
}

-- ══════════════════════════════════════════════════════════════
-- TYPES D'ÉCONOMIE
-- ══════════════════════════════════════════════════════════════

Enums.MoneyType = {
    CASH = 'money',
    BANK = 'bank',
    BLACK = 'black_money'
}

Enums.EconomyAction = {
    ADD = 'add',
    REMOVE = 'remove',
    SET = 'set'
}

-- ══════════════════════════════════════════════════════════════
-- STATUTS PANEL
-- ══════════════════════════════════════════════════════════════

Enums.PanelView = {
    DASHBOARD = 'dashboard',
    PLAYERS = 'players',
    PLAYER_DETAIL = 'player_detail',
    SANCTIONS = 'sanctions',
    ECONOMY = 'economy',
    TELEPORT = 'teleport',
    VEHICLES = 'vehicles',
    EVENTS = 'events',
    ANNOUNCEMENTS = 'announcements',
    LOGS = 'logs',
    SETTINGS = 'settings'
}

-- ══════════════════════════════════════════════════════════════
-- TYPES DE NOTIFICATIONS
-- ══════════════════════════════════════════════════════════════

Enums.NotifyType = {
    SUCCESS = 'success',
    ERROR = 'error',
    WARNING = 'warning',
    INFO = 'info'
}

-- ══════════════════════════════════════════════════════════════
-- CODES D'ERREUR
-- ══════════════════════════════════════════════════════════════

Enums.ErrorCode = {
    NO_PERMISSION = 'NO_PERMISSION',
    INVALID_PARAMS = 'INVALID_PARAMS',
    PLAYER_NOT_FOUND = 'PLAYER_NOT_FOUND',
    PLAYER_OFFLINE = 'PLAYER_OFFLINE',
    DATABASE_ERROR = 'DATABASE_ERROR',
    RATE_LIMITED = 'RATE_LIMITED',
    INVALID_GRADE = 'INVALID_GRADE',
    CANNOT_SELF_ACTION = 'CANNOT_SELF_ACTION',
    TARGET_HIGHER_GRADE = 'TARGET_HIGHER_GRADE',
    ALREADY_BANNED = 'ALREADY_BANNED',
    NOT_BANNED = 'NOT_BANNED'
}

-- ══════════════════════════════════════════════════════════════
-- IDENTIFIANTS JOUEUR
-- ══════════════════════════════════════════════════════════════

Enums.IdentifierType = {
    STEAM = 'steam',
    LICENSE = 'license',
    DISCORD = 'discord',
    LIVE = 'live',
    XBL = 'xbl',
    IP = 'ip',
    FIVEM = 'fivem'
}
