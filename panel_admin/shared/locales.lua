--[[
    Traductions - Panel Admin Fight League
    Support multilingue FR/EN
]]

Locales = {}

-- Langue par défaut
Locales.Current = 'fr'

-- ══════════════════════════════════════════════════════════════
-- TRADUCTIONS FRANÇAISES
-- ══════════════════════════════════════════════════════════════

Locales.fr = {
    -- Général
    ['panel_title'] = 'Panel Administration',
    ['loading'] = 'Chargement...',
    ['save'] = 'Sauvegarder',
    ['cancel'] = 'Annuler',
    ['confirm'] = 'Confirmer',
    ['close'] = 'Fermer',
    ['search'] = 'Rechercher...',
    ['no_results'] = 'Aucun résultat',
    ['error'] = 'Erreur',
    ['success'] = 'Succès',
    ['warning'] = 'Attention',
    ['info'] = 'Information',

    -- Navigation
    ['nav_dashboard'] = 'Dashboard',
    ['nav_players'] = 'Joueurs',
    ['nav_sanctions'] = 'Sanctions',
    ['nav_economy'] = 'Économie',
    ['nav_teleport'] = 'Téléportation',
    ['nav_vehicles'] = 'Véhicules',
    ['nav_events'] = 'Événements',
    ['nav_announcements'] = 'Annonces',
    ['nav_logs'] = 'Logs',
    ['nav_settings'] = 'Paramètres',

    -- Dashboard
    ['dashboard_players_online'] = 'Joueurs en ligne',
    ['dashboard_staff_online'] = 'Staff en ligne',
    ['dashboard_events_active'] = 'Événements actifs',
    ['dashboard_sanctions_today'] = 'Sanctions aujourd\'hui',
    ['dashboard_recent_activity'] = 'Activité récente',

    -- Joueurs
    ['players_list'] = 'Liste des joueurs',
    ['players_online'] = 'En ligne',
    ['players_offline'] = 'Hors ligne',
    ['player_id'] = 'ID',
    ['player_name'] = 'Nom',
    ['player_identifier'] = 'Identifiant',
    ['player_group'] = 'Groupe',
    ['player_playtime'] = 'Temps de jeu',
    ['player_first_join'] = 'Première connexion',
    ['player_last_seen'] = 'Dernière connexion',
    ['player_actions'] = 'Actions',

    -- Actions joueur
    ['action_spectate'] = 'Spectate',
    ['action_teleport'] = 'Téléporter',
    ['action_bring'] = 'Amener',
    ['action_goto'] = 'Aller vers',
    ['action_warn'] = 'Avertir',
    ['action_kick'] = 'Expulser',
    ['action_ban'] = 'Bannir',
    ['action_revive'] = 'Réanimer',
    ['action_heal'] = 'Soigner',
    ['action_freeze'] = 'Freeze',
    ['action_unfreeze'] = 'Unfreeze',
    ['action_set_money'] = 'Modifier argent',
    ['action_view_profile'] = 'Voir profil',

    -- Sanctions
    ['sanction_warn'] = 'Avertissement',
    ['sanction_kick'] = 'Expulsion',
    ['sanction_ban_temp'] = 'Ban temporaire',
    ['sanction_ban_perm'] = 'Ban permanent',
    ['sanction_reason'] = 'Raison',
    ['sanction_duration'] = 'Durée',
    ['sanction_expires'] = 'Expire le',
    ['sanction_by'] = 'Par',
    ['sanction_date'] = 'Date',
    ['sanction_status_active'] = 'Actif',
    ['sanction_status_expired'] = 'Expiré',
    ['sanction_status_revoked'] = 'Révoqué',

    -- Économie
    ['economy_cash'] = 'Espèces',
    ['economy_bank'] = 'Banque',
    ['economy_black'] = 'Argent sale',
    ['economy_add'] = 'Ajouter',
    ['economy_remove'] = 'Retirer',
    ['economy_set'] = 'Définir',
    ['economy_amount'] = 'Montant',

    -- Téléportation
    ['tp_to_coords'] = 'Coordonnées',
    ['tp_to_marker'] = 'Marqueur',
    ['tp_to_player'] = 'Vers joueur',
    ['tp_saved_locations'] = 'Lieux sauvegardés',
    ['tp_add_location'] = 'Ajouter lieu',

    -- Véhicules
    ['vehicle_spawn'] = 'Spawn véhicule',
    ['vehicle_delete'] = 'Supprimer',
    ['vehicle_repair'] = 'Réparer',
    ['vehicle_favorites'] = 'Favoris',
    ['vehicle_model'] = 'Modèle',

    -- Événements
    ['event_create'] = 'Créer événement',
    ['event_name'] = 'Nom',
    ['event_type'] = 'Type',
    ['event_status'] = 'Statut',
    ['event_participants'] = 'Participants',
    ['event_start'] = 'Démarrer',
    ['event_end'] = 'Terminer',
    ['event_cancel'] = 'Annuler',

    -- Annonces
    ['announce_send'] = 'Envoyer annonce',
    ['announce_message'] = 'Message',
    ['announce_type'] = 'Type',
    ['announce_priority'] = 'Priorité',
    ['announce_schedule'] = 'Programmer',

    -- Logs
    ['logs_category'] = 'Catégorie',
    ['logs_action'] = 'Action',
    ['logs_staff'] = 'Staff',
    ['logs_target'] = 'Cible',
    ['logs_details'] = 'Détails',
    ['logs_date'] = 'Date',

    -- Erreurs (codes générés par Enums.ErrorCode)
    ['error_NO_PERMISSION'] = 'Vous n\'avez pas la permission d\'effectuer cette action',
    ['error_PLAYER_NOT_FOUND'] = 'Joueur introuvable',
    ['error_PLAYER_OFFLINE'] = 'Le joueur est hors ligne',
    ['error_INVALID_PARAMS'] = 'Paramètres invalides',
    ['error_DATABASE_ERROR'] = 'Erreur de base de données',
    ['error_RATE_LIMITED'] = 'Trop de requêtes, veuillez patienter',
    ['error_CANNOT_SELF_ACTION'] = 'Vous ne pouvez pas effectuer cette action sur vous-même',
    ['error_TARGET_HIGHER_GRADE'] = 'La cible a un grade supérieur ou égal au vôtre',
    ['error_INVALID_GRADE'] = 'Grade invalide',
    ['error_ALREADY_BANNED'] = 'Ce joueur est déjà banni',
    ['error_NOT_BANNED'] = 'Ce joueur n\'est pas banni',
    ['error_unknown'] = 'Une erreur inconnue est survenue',

    -- Erreurs spécifiques
    ['error_invalid_reason'] = 'La raison doit contenir au moins 5 caractères',
    ['error_invalid_duration'] = 'Durée invalide',
    ['error_invalid_amount'] = 'Montant invalide',
    ['error_insufficient_funds'] = 'Fonds insuffisants',
    ['error_invalid_coordinates'] = 'Coordonnées invalides',
    ['error_invalid_vehicle'] = 'Modèle de véhicule invalide',

    -- Confirmations
    ['confirm_kick'] = 'Voulez-vous vraiment expulser ce joueur ?',
    ['confirm_ban'] = 'Voulez-vous vraiment bannir ce joueur ?',
    ['confirm_unban'] = 'Voulez-vous vraiment débannir ce joueur ?',
    ['confirm_delete'] = 'Voulez-vous vraiment supprimer cet élément ?',

    -- Succès
    ['success_warn'] = 'Le joueur a été averti.',
    ['success_kick'] = 'Le joueur a été expulsé.',
    ['success_ban'] = 'Le joueur a été banni.',
    ['success_unban'] = 'Le joueur a été débanni.',
    ['success_money'] = 'L\'argent a été modifié.',
    ['success_teleport'] = 'Téléportation effectuée.',
    ['success_vehicle'] = 'Véhicule spawné.',
    ['success_announce'] = 'Annonce envoyée.'
}

-- ══════════════════════════════════════════════════════════════
-- TRADUCTIONS ANGLAISES
-- ══════════════════════════════════════════════════════════════

Locales.en = {
    -- General
    ['panel_title'] = 'Admin Panel',
    ['loading'] = 'Loading...',
    ['save'] = 'Save',
    ['cancel'] = 'Cancel',
    ['confirm'] = 'Confirm',
    ['close'] = 'Close',
    ['search'] = 'Search...',
    ['no_results'] = 'No results',
    ['error'] = 'Error',
    ['success'] = 'Success',
    ['warning'] = 'Warning',
    ['info'] = 'Information',

    -- Navigation
    ['nav_dashboard'] = 'Dashboard',
    ['nav_players'] = 'Players',
    ['nav_sanctions'] = 'Sanctions',
    ['nav_economy'] = 'Economy',
    ['nav_teleport'] = 'Teleport',
    ['nav_vehicles'] = 'Vehicles',
    ['nav_events'] = 'Events',
    ['nav_announcements'] = 'Announcements',
    ['nav_logs'] = 'Logs',
    ['nav_settings'] = 'Settings',

    -- Dashboard
    ['dashboard_players_online'] = 'Players online',
    ['dashboard_staff_online'] = 'Staff online',
    ['dashboard_events_active'] = 'Active events',
    ['dashboard_sanctions_today'] = 'Sanctions today',
    ['dashboard_recent_activity'] = 'Recent activity',

    -- Players
    ['players_list'] = 'Players list',
    ['players_online'] = 'Online',
    ['players_offline'] = 'Offline',
    ['player_id'] = 'ID',
    ['player_name'] = 'Name',
    ['player_identifier'] = 'Identifier',
    ['player_group'] = 'Group',
    ['player_playtime'] = 'Playtime',
    ['player_first_join'] = 'First join',
    ['player_last_seen'] = 'Last seen',
    ['player_actions'] = 'Actions',

    -- Player actions
    ['action_spectate'] = 'Spectate',
    ['action_teleport'] = 'Teleport',
    ['action_bring'] = 'Bring',
    ['action_goto'] = 'Go to',
    ['action_warn'] = 'Warn',
    ['action_kick'] = 'Kick',
    ['action_ban'] = 'Ban',
    ['action_revive'] = 'Revive',
    ['action_heal'] = 'Heal',
    ['action_freeze'] = 'Freeze',
    ['action_unfreeze'] = 'Unfreeze',
    ['action_set_money'] = 'Set money',
    ['action_view_profile'] = 'View profile',

    -- Sanctions
    ['sanction_warn'] = 'Warning',
    ['sanction_kick'] = 'Kick',
    ['sanction_ban_temp'] = 'Temporary ban',
    ['sanction_ban_perm'] = 'Permanent ban',
    ['sanction_reason'] = 'Reason',
    ['sanction_duration'] = 'Duration',
    ['sanction_expires'] = 'Expires',
    ['sanction_by'] = 'By',
    ['sanction_date'] = 'Date',
    ['sanction_status_active'] = 'Active',
    ['sanction_status_expired'] = 'Expired',
    ['sanction_status_revoked'] = 'Revoked',

    -- Economy
    ['economy_cash'] = 'Cash',
    ['economy_bank'] = 'Bank',
    ['economy_black'] = 'Black money',
    ['economy_add'] = 'Add',
    ['economy_remove'] = 'Remove',
    ['economy_set'] = 'Set',
    ['economy_amount'] = 'Amount',

    -- Teleport
    ['tp_to_coords'] = 'Coordinates',
    ['tp_to_marker'] = 'Marker',
    ['tp_to_player'] = 'To player',
    ['tp_saved_locations'] = 'Saved locations',
    ['tp_add_location'] = 'Add location',

    -- Vehicles
    ['vehicle_spawn'] = 'Spawn vehicle',
    ['vehicle_delete'] = 'Delete',
    ['vehicle_repair'] = 'Repair',
    ['vehicle_favorites'] = 'Favorites',
    ['vehicle_model'] = 'Model',

    -- Events
    ['event_create'] = 'Create event',
    ['event_name'] = 'Name',
    ['event_type'] = 'Type',
    ['event_status'] = 'Status',
    ['event_participants'] = 'Participants',
    ['event_start'] = 'Start',
    ['event_end'] = 'End',
    ['event_cancel'] = 'Cancel',

    -- Announcements
    ['announce_send'] = 'Send announcement',
    ['announce_message'] = 'Message',
    ['announce_type'] = 'Type',
    ['announce_priority'] = 'Priority',
    ['announce_schedule'] = 'Schedule',

    -- Logs
    ['logs_category'] = 'Category',
    ['logs_action'] = 'Action',
    ['logs_staff'] = 'Staff',
    ['logs_target'] = 'Target',
    ['logs_details'] = 'Details',
    ['logs_date'] = 'Date',

    -- Errors (codes generated by Enums.ErrorCode)
    ['error_NO_PERMISSION'] = 'You don\'t have permission to perform this action',
    ['error_PLAYER_NOT_FOUND'] = 'Player not found',
    ['error_PLAYER_OFFLINE'] = 'Player is offline',
    ['error_INVALID_PARAMS'] = 'Invalid parameters',
    ['error_DATABASE_ERROR'] = 'Database error',
    ['error_RATE_LIMITED'] = 'Too many requests, please wait',
    ['error_CANNOT_SELF_ACTION'] = 'You cannot perform this action on yourself',
    ['error_TARGET_HIGHER_GRADE'] = 'Target has a higher or equal rank than you',
    ['error_INVALID_GRADE'] = 'Invalid rank',
    ['error_ALREADY_BANNED'] = 'This player is already banned',
    ['error_NOT_BANNED'] = 'This player is not banned',
    ['error_unknown'] = 'An unknown error occurred',

    -- Specific errors
    ['error_invalid_reason'] = 'Reason must be at least 5 characters',
    ['error_invalid_duration'] = 'Invalid duration',
    ['error_invalid_amount'] = 'Invalid amount',
    ['error_insufficient_funds'] = 'Insufficient funds',
    ['error_invalid_coordinates'] = 'Invalid coordinates',
    ['error_invalid_vehicle'] = 'Invalid vehicle model',

    -- Confirmations
    ['confirm_kick'] = 'Are you sure you want to kick this player?',
    ['confirm_ban'] = 'Are you sure you want to ban this player?',
    ['confirm_unban'] = 'Are you sure you want to unban this player?',
    ['confirm_delete'] = 'Are you sure you want to delete this item?',

    -- Success
    ['success_warn'] = 'Player has been warned.',
    ['success_kick'] = 'Player has been kicked.',
    ['success_ban'] = 'Player has been banned.',
    ['success_unban'] = 'Player has been unbanned.',
    ['success_money'] = 'Money has been modified.',
    ['success_teleport'] = 'Teleportation complete.',
    ['success_vehicle'] = 'Vehicle spawned.',
    ['success_announce'] = 'Announcement sent.'
}

-- ══════════════════════════════════════════════════════════════
-- FONCTION DE TRADUCTION
-- ══════════════════════════════════════════════════════════════

function _L(key, ...)
    local lang = Locales[Locales.Current] or Locales.fr
    local text = lang[key] or Locales.fr[key] or key

    -- Remplacer les placeholders %s, %d, etc.
    if ... then
        text = string.format(text, ...)
    end

    return text
end

-- Changer la langue
function Locales.SetLanguage(lang)
    if Locales[lang] then
        Locales.Current = lang
        return true
    end
    return false
end

-- Obtenir la langue actuelle
function Locales.GetLanguage()
    return Locales.Current
end
