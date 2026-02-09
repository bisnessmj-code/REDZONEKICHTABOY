-- PANEL ADMIN FIGHT LEAGUE - SQL INSTALL

CREATE TABLE IF NOT EXISTS `panel_staff` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL UNIQUE,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `staff_group` VARCHAR(50) DEFAULT NULL,
    `preferences` TEXT DEFAULT NULL,
    `last_panel_access` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category` ENUM('auth','player','sanction','economy','teleport','vehicle','event','system','death') NOT NULL DEFAULT 'system',
    `action` VARCHAR(50) NOT NULL,
    `staff_identifier` VARCHAR(60) DEFAULT NULL,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `target_identifier` VARCHAR(60) DEFAULT NULL,
    `target_name` VARCHAR(100) DEFAULT NULL,
    `details` TEXT DEFAULT NULL,
    `staff_server_id` INT DEFAULT 0,
    `target_server_id` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_staff_server_id` (`staff_server_id`),
    INDEX `idx_target_server_id` (`target_server_id`),
    INDEX `idx_category` (`category`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_sanctions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` ENUM('warn','kick','ban_temp','ban_perm') NOT NULL,
    `target_identifier` VARCHAR(60) NOT NULL,
    `target_name` VARCHAR(100) DEFAULT NULL,
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `reason` TEXT NOT NULL,
    `duration_hours` INT DEFAULT NULL,
    `expires_at` DATETIME DEFAULT NULL,
    `status` ENUM('active','expired','revoked') DEFAULT 'active',
    `revoked_by` VARCHAR(60) DEFAULT NULL,
    `revoked_at` DATETIME DEFAULT NULL,
    `unban_id` VARCHAR(5) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_unban_id` (`unban_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL UNIQUE,
    `player_name` VARCHAR(100) DEFAULT NULL,
    `steam_id` VARCHAR(60) DEFAULT NULL,
    `discord_id` VARCHAR(60) DEFAULT NULL,
    `license` VARCHAR(60) DEFAULT NULL,
    `ip` VARCHAR(45) DEFAULT NULL,
    `reason` TEXT NOT NULL,
    `banned_by` VARCHAR(60) NOT NULL,
    `banned_by_name` VARCHAR(100) DEFAULT NULL,
    `expires_at` DATETIME DEFAULT NULL,
    `unban_id` VARCHAR(5) DEFAULT NULL UNIQUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_unban_id` (`unban_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_player_notes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `target_identifier` VARCHAR(60) NOT NULL,
    `target_name` VARCHAR(100) DEFAULT NULL,
    `content` TEXT NOT NULL,
    `category` ENUM('general','warning','positive','report','follow_up') DEFAULT 'general',
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_player_connections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) DEFAULT NULL,
    `steam_id` VARCHAR(60) DEFAULT NULL,
    `discord_id` VARCHAR(60) DEFAULT NULL,
    `license` VARCHAR(60) DEFAULT NULL,
    `ip` VARCHAR(45) DEFAULT NULL,
    `connected_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `disconnected_at` DATETIME DEFAULT NULL,
    `duration_minutes` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) DEFAULT NULL,
    `message` TEXT NOT NULL,
    `type` ENUM('chat','notification','popup','all') DEFAULT 'chat',
    `priority` ENUM('low','normal','high','urgent') DEFAULT 'normal',
    `created_by` VARCHAR(60) NOT NULL,
    `created_by_name` VARCHAR(100) DEFAULT NULL,
    `is_scheduled` TINYINT(1) DEFAULT 0,
    `scheduled_at` DATETIME DEFAULT NULL,
    `is_sent` TINYINT(1) DEFAULT 0,
    `sent_at` DATETIME DEFAULT NULL,
    `is_recurring` TINYINT(1) DEFAULT 0,
    `recurrence_interval` INT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_statistics_daily` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `date` DATE NOT NULL UNIQUE,
    `unique_players` INT DEFAULT 0,
    `peak_players` INT DEFAULT 0,
    `new_players` INT DEFAULT 0,
    `total_playtime_minutes` INT DEFAULT 0,
    `warns_count` INT DEFAULT 0,
    `kicks_count` INT DEFAULT 0,
    `bans_count` INT DEFAULT 0,
    `money_added` BIGINT DEFAULT 0,
    `money_removed` BIGINT DEFAULT 0,
    `vehicles_spawned` INT DEFAULT 0,
    `teleports_count` INT DEFAULT 0,
    `events_held` INT DEFAULT 0,
    `announcements_sent` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_events` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `type` ENUM('fight','tournament','training','meeting','other') DEFAULT 'fight',
    `status` ENUM('draft','scheduled','active','completed','cancelled') DEFAULT 'draft',
    `location_name` VARCHAR(255) DEFAULT NULL,
    `location_x` FLOAT DEFAULT NULL,
    `location_y` FLOAT DEFAULT NULL,
    `location_z` FLOAT DEFAULT NULL,
    `max_participants` INT DEFAULT NULL,
    `prize_pool` INT DEFAULT 0,
    `entry_fee` INT DEFAULT 0,
    `rules` TEXT DEFAULT NULL,
    `scheduled_at` DATETIME DEFAULT NULL,
    `started_at` DATETIME DEFAULT NULL,
    `ended_at` DATETIME DEFAULT NULL,
    `created_by` VARCHAR(60) NOT NULL,
    `created_by_name` VARCHAR(100) DEFAULT NULL,
    `winner_identifier` VARCHAR(60) DEFAULT NULL,
    `winner_name` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_event_participants` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event_id` INT NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) DEFAULT NULL,
    `status` ENUM('registered','confirmed','checked_in','eliminated','winner','no_show') DEFAULT 'registered',
    `position` INT DEFAULT NULL,
    `prize_won` INT DEFAULT 0,
    `registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `checked_in_at` DATETIME DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_event_matches` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event_id` INT NOT NULL,
    `round` INT DEFAULT 1,
    `match_number` INT DEFAULT 1,
    `player1_identifier` VARCHAR(60) DEFAULT NULL,
    `player1_name` VARCHAR(100) DEFAULT NULL,
    `player2_identifier` VARCHAR(60) DEFAULT NULL,
    `player2_name` VARCHAR(100) DEFAULT NULL,
    `winner_identifier` VARCHAR(60) DEFAULT NULL,
    `status` ENUM('pending','in_progress','completed','cancelled') DEFAULT 'pending',
    `started_at` DATETIME DEFAULT NULL,
    `ended_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `panel_saved_locations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `heading` FLOAT DEFAULT 0,
    `category` VARCHAR(50) DEFAULT 'general',
    `created_by` VARCHAR(60) NOT NULL,
    `created_by_name` VARCHAR(100) DEFAULT NULL,
    `is_public` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `panel_statistics_daily` (`date`) VALUES (CURDATE());
