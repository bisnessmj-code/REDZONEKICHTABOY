-- =====================================================
-- Panel Admin Fight League - Installation SQL
-- Version: 1.0
-- Compatible avec: MySQL 5.7+ / MariaDB 10.2+
-- =====================================================
-- Instructions:
-- 1. Importez ce fichier dans votre base de données
-- 2. Assurez-vous que votre serveur ESX est configuré
-- 3. Redémarrez votre serveur FiveM
-- =====================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- TABLE: panel_logs (Audit Trail - Historique des actions)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `category` VARCHAR(50) NOT NULL COMMENT 'auth, player, sanction, economy, teleport, vehicle, event, announce, config, death, report',
    `action` VARCHAR(100) NOT NULL,
    `staff_identifier` VARCHAR(60) DEFAULT NULL,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `target_identifier` VARCHAR(60) DEFAULT NULL,
    `target_name` VARCHAR(100) DEFAULT NULL,
    `details` JSON DEFAULT NULL,
    `staff_server_id` INT(11) DEFAULT NULL,
    `target_server_id` INT(11) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category`),
    KEY `idx_staff_identifier` (`staff_identifier`),
    KEY `idx_target_identifier` (`target_identifier`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_sanctions (Historique des sanctions)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_sanctions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(20) NOT NULL COMMENT 'warn, kick, ban_temp, ban_perm',
    `target_identifier` VARCHAR(60) NOT NULL,
    `target_name` VARCHAR(100) NOT NULL,
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) NOT NULL,
    `reason` VARCHAR(500) NOT NULL,
    `duration_hours` INT(11) DEFAULT NULL COMMENT 'NULL pour warn/kick, -1 pour permanent',
    `expires_at` DATETIME DEFAULT NULL,
    `status` VARCHAR(20) DEFAULT 'active' COMMENT 'active, revoked, expired',
    `revoked_by` VARCHAR(60) DEFAULT NULL,
    `revoked_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_type` (`type`),
    KEY `idx_target_identifier` (`target_identifier`),
    KEY `idx_staff_identifier` (`staff_identifier`),
    KEY `idx_status` (`status`),
    KEY `idx_expires_at` (`expires_at`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_bans (Bans actifs - Lookup optimisé)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_bans` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `steam_id` VARCHAR(60) DEFAULT NULL,
    `discord_id` VARCHAR(60) DEFAULT NULL,
    `license` VARCHAR(60) DEFAULT NULL,
    `ip` VARCHAR(45) DEFAULT NULL,
    `reason` VARCHAR(500) NOT NULL,
    `banned_by` VARCHAR(60) NOT NULL,
    `banned_by_name` VARCHAR(100) NOT NULL,
    `expires_at` DATETIME DEFAULT NULL COMMENT 'NULL = permanent',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_identifier` (`identifier`),
    KEY `idx_steam_id` (`steam_id`),
    KEY `idx_discord_id` (`discord_id`),
    KEY `idx_license` (`license`),
    KEY `idx_ip` (`ip`),
    KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_staff (Suivi des membres du staff)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_staff` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) NOT NULL,
    `staff_group` VARCHAR(50) NOT NULL,
    `preferences` JSON DEFAULT NULL,
    `last_panel_access` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_identifier` (`identifier`),
    KEY `idx_staff_group` (`staff_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_statistics_daily (Statistiques journalières)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_statistics_daily` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `date` DATE NOT NULL,
    `unique_players` INT(11) DEFAULT 0,
    `peak_players` INT(11) DEFAULT 0,
    `new_players` INT(11) DEFAULT 0,
    `total_playtime_minutes` INT(11) DEFAULT 0,
    `warns_count` INT(11) DEFAULT 0,
    `kicks_count` INT(11) DEFAULT 0,
    `bans_count` INT(11) DEFAULT 0,
    `money_added` BIGINT(20) DEFAULT 0,
    `money_removed` BIGINT(20) DEFAULT 0,
    `vehicles_spawned` INT(11) DEFAULT 0,
    `teleports_count` INT(11) DEFAULT 0,
    `events_held` INT(11) DEFAULT 0,
    `announcements_sent` INT(11) DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_economy_logs (Logs des transactions)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_economy_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `target_identifier` VARCHAR(60) NOT NULL,
    `target_name` VARCHAR(100) NOT NULL,
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) NOT NULL,
    `action` VARCHAR(20) NOT NULL COMMENT 'add, remove, set',
    `money_type` VARCHAR(20) NOT NULL COMMENT 'cash, bank, black_money',
    `amount` BIGINT(20) NOT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_target_identifier` (`target_identifier`),
    KEY `idx_staff_identifier` (`staff_identifier`),
    KEY `idx_action` (`action`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_events (Événements Fight League)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_events` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `type` VARCHAR(30) NOT NULL COMMENT 'fight, tournament, training, meeting, other',
    `status` VARCHAR(20) DEFAULT 'draft' COMMENT 'draft, scheduled, active, completed, cancelled',
    `created_by` VARCHAR(60) NOT NULL,
    `created_by_name` VARCHAR(100) NOT NULL,
    `max_participants` INT(11) DEFAULT 0,
    `location_name` VARCHAR(100) DEFAULT NULL,
    `location_coords` VARCHAR(100) DEFAULT NULL COMMENT 'Format: x,y,z ou JSON',
    `scheduled_at` DATETIME DEFAULT NULL,
    `started_at` DATETIME DEFAULT NULL,
    `ended_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_type` (`type`),
    KEY `idx_status` (`status`),
    KEY `idx_created_by` (`created_by`),
    KEY `idx_scheduled_at` (`scheduled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_event_participants (Participants aux événements)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_event_participants` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `event_id` INT(11) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `status` VARCHAR(20) DEFAULT 'registered' COMMENT 'registered, confirmed, completed',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_event_player` (`event_id`, `identifier`),
    KEY `idx_event_id` (`event_id`),
    KEY `idx_identifier` (`identifier`),
    CONSTRAINT `fk_event_participants_event` FOREIGN KEY (`event_id`)
        REFERENCES `panel_events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_reports (Système de tickets/reports)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_reports` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `player_id` INT(11) DEFAULT NULL COMMENT 'Server ID (volatile)',
    `player_identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `message` TEXT NOT NULL,
    `response` TEXT DEFAULT NULL COMMENT 'Réponse du staff',
    `status` VARCHAR(20) DEFAULT 'pending' COMMENT 'pending, in_progress, resolved, deleted',
    `claimed_by` VARCHAR(60) DEFAULT NULL,
    `claimed_by_name` VARCHAR(100) DEFAULT NULL,
    `claimed_at` DATETIME DEFAULT NULL,
    `resolved_at` DATETIME DEFAULT NULL,
    `responded_by` VARCHAR(60) DEFAULT NULL,
    `responded_by_name` VARCHAR(100) DEFAULT NULL,
    `responded_at` DATETIME DEFAULT NULL,
    `deleted_by` VARCHAR(60) DEFAULT NULL,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_player_identifier` (`player_identifier`),
    KEY `idx_status` (`status`),
    KEY `idx_claimed_by` (`claimed_by`),
    KEY `idx_resolved_at` (`resolved_at`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_vehicle_favorites (Véhicules favoris)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_vehicle_favorites` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `spawn_name` VARCHAR(50) NOT NULL COMMENT 'Nom du modèle véhicule',
    `display_name` VARCHAR(100) NOT NULL,
    `category` VARCHAR(30) NOT NULL COMMENT 'super, sports, muscle, utility, helicopter, boat',
    `is_global` TINYINT(1) DEFAULT 0 COMMENT '0=personnel, 1=global pour tout le staff',
    `staff_identifier` VARCHAR(60) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category`),
    KEY `idx_is_global` (`is_global`),
    KEY `idx_staff_identifier` (`staff_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_saved_locations (Emplacements de téléportation)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_saved_locations` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `category` VARCHAR(30) NOT NULL COMMENT 'spawn, admin, event, custom',
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `heading` FLOAT DEFAULT 0,
    `created_by` VARCHAR(60) NOT NULL,
    `is_public` TINYINT(1) DEFAULT 1 COMMENT '0=personnel, 1=public',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category`),
    KEY `idx_is_public` (`is_public`),
    KEY `idx_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_announcements (Annonces serveur)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_announcements` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(100) DEFAULT NULL,
    `message` TEXT NOT NULL,
    `type` VARCHAR(20) NOT NULL COMMENT 'chat, notification, advanced',
    `priority` VARCHAR(20) DEFAULT 'normal' COMMENT 'low, normal, high, critical',
    `created_by` VARCHAR(60) NOT NULL,
    `created_by_name` VARCHAR(100) NOT NULL,
    `is_sent` TINYINT(1) DEFAULT 0,
    `sent_at` DATETIME DEFAULT NULL,
    `is_scheduled` TINYINT(1) DEFAULT 0,
    `scheduled_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_type` (`type`),
    KEY `idx_priority` (`priority`),
    KEY `idx_is_sent` (`is_sent`),
    KEY `idx_scheduled_at` (`scheduled_at`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_staff_chat (Chat interne du staff)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_staff_chat` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) NOT NULL,
    `staff_group` VARCHAR(50) NOT NULL,
    `message` VARCHAR(500) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_staff_identifier` (`staff_identifier`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_player_notes (Notes sur les joueurs)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_player_notes` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `target_identifier` VARCHAR(60) NOT NULL,
    `content` TEXT NOT NULL,
    `category` VARCHAR(30) DEFAULT 'general' COMMENT 'general, warning, positive, info',
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_target_identifier` (`target_identifier`),
    KEY `idx_staff_identifier` (`staff_identifier`),
    KEY `idx_category` (`category`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- TABLE: panel_player_connections (Historique connexions)
-- =====================================================
CREATE TABLE IF NOT EXISTS `panel_player_connections` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `connected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `disconnected_at` DATETIME DEFAULT NULL,
    `session_duration_minutes` INT(11) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_connected_at` (`connected_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================
-- DONNÉES PAR DÉFAUT: Emplacements de téléportation
-- =====================================================
INSERT INTO `panel_saved_locations` (`name`, `category`, `x`, `y`, `z`, `heading`, `created_by`, `is_public`) VALUES
('Spawn Principal', 'spawn', -5817.7, -917.9, 502.4, 0, 'system', 1),
('Commissariat', 'admin', 428.0, -981.0, 30.7, 0, 'system', 1),
('Hopital', 'admin', 298.0, -584.0, 43.3, 0, 'system', 1),
('Arene Fight', 'event', 0.0, 0.0, 0.0, 0, 'system', 1)
ON DUPLICATE KEY UPDATE `name` = `name`;

-- =====================================================
-- DONNÉES PAR DÉFAUT: Véhicules favoris globaux
-- =====================================================
INSERT INTO `panel_vehicle_favorites` (`spawn_name`, `display_name`, `category`, `is_global`, `staff_identifier`) VALUES
('adder', 'Adder', 'super', 1, NULL),
('zentorno', 'Zentorno', 'super', 1, NULL),
('t20', 'T20', 'super', 1, NULL),
('elegy2', 'Elegy RH8', 'sports', 1, NULL),
('comet2', 'Comet', 'sports', 1, NULL),
('dominator', 'Dominator', 'muscle', 1, NULL),
('buzzard', 'Buzzard', 'helicopter', 1, NULL),
('frogger', 'Frogger', 'helicopter', 1, NULL),
('speeder', 'Speeder', 'boat', 1, NULL)
ON DUPLICATE KEY UPDATE `display_name` = `display_name`;

-- =====================================================
-- INITIALISATION: Statistiques du jour
-- =====================================================
INSERT IGNORE INTO `panel_statistics_daily` (`date`) VALUES (CURDATE());

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- INSTALLATION TERMINÉE
-- =====================================================
-- Tables créées: 15
-- - panel_logs
-- - panel_sanctions
-- - panel_bans
-- - panel_staff
-- - panel_statistics_daily
-- - panel_economy_logs
-- - panel_events
-- - panel_event_participants
-- - panel_reports
-- - panel_vehicle_favorites
-- - panel_saved_locations
-- - panel_announcements
-- - panel_staff_chat
-- - panel_player_notes
-- - panel_player_connections
-- =====================================================
