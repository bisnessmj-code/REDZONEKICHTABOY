-- ==========================================
-- CONSTANTES PARTAGÉES CLIENT/SERVER
-- ==========================================

Constants = {}

-- États des joueurs
Constants.PlayerState = {
    IDLE = 0,
    IN_LOBBY = 1,
    IN_TEAM_RED = 2,
    IN_TEAM_BLUE = 3,
    IN_GAME = 4,
    DEAD_IN_GAME = 5,
    SPECTATING = 6
}

-- États du jeu
Constants.GameState = {
    WAITING = 'waiting',        -- En attente de joueurs
    STARTING = 'starting',      -- Démarrage imminent
    IN_PROGRESS = 'in_progress',-- Partie en cours
    ROUND_END = 'round_end',    -- Fin de round
    GAME_END = 'game_end'       -- Fin de partie
}

-- Types d'équipes
Constants.Teams = {
    NONE = 'none',
    RED = 'red',
    BLUE = 'blue'
}

-- Actions possibles
Constants.Actions = {
    JOIN_LOBBY = 'join_lobby',
    SELECT_TEAM = 'select_team',
    QUIT_GDT = 'quit_gdt',
    CHANGE_TEAM = 'change_team'
}

-- Limites
Constants.Limits = {
    MIN_HEALTH = 100,
    MAX_DISTANCE_CHECK = 2.0,
    MARKER_DRAW_DISTANCE = 15.0
}

-- Messages d'erreur
Constants.Errors = {
    PLAYER_NOT_FOUND = 'Joueur introuvable',
    INVALID_STATE = 'État invalide',
    COOLDOWN_ACTIVE = 'Action trop rapide',
    ALREADY_IN_TEAM = 'Déjà dans une équipe',
    NO_OUTFIT_SAVED = 'Aucune tenue sauvegardée'
}

return Constants
