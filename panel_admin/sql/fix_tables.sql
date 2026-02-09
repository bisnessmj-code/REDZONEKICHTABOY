-- ══════════════════════════════════════════════════════════════
-- CORRECTIONS COMPLÈTES - Panel Admin Fight League
-- Exécute ce script COMPLET dans phpMyAdmin
-- ══════════════════════════════════════════════════════════════

-- 1. Corriger l'ENUM de panel_logs pour ajouter 'system'
ALTER TABLE `panel_logs`
MODIFY COLUMN `category` ENUM('auth', 'player', 'sanction', 'economy', 'teleport', 'vehicle', 'event', 'system') NOT NULL DEFAULT 'system';

-- 2. Créer la table panel_statistics_daily si elle n'existe pas
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
    `events_held` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Créer la table panel_announcements si elle n'existe pas
CREATE TABLE IF NOT EXISTS `panel_announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) DEFAULT NULL,
    `message` TEXT NOT NULL,
    `type` ENUM('chat', 'notification', 'popup', 'all') DEFAULT 'chat',
    `priority` ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
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

-- 4. Créer la table panel_player_notes si elle n'existe pas
CREATE TABLE IF NOT EXISTS `panel_player_notes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `target_identifier` VARCHAR(60) NOT NULL,
    `content` TEXT NOT NULL,
    `category` ENUM('general', 'warning', 'positive', 'report', 'follow_up') DEFAULT 'general',
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_target` (`target_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Créer la table panel_player_connections si elle n'existe pas
CREATE TABLE IF NOT EXISTS `panel_player_connections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(100) DEFAULT NULL,
    `connected_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `disconnected_at` DATETIME DEFAULT NULL,
    `duration_minutes` INT DEFAULT 0,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_connected_at` (`connected_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. S'assurer que panel_staff a toutes les colonnes
-- (Cette commande ignorera si les colonnes existent déjà)
ALTER TABLE `panel_staff`
ADD COLUMN IF NOT EXISTS `preferences` JSON DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `last_panel_access` DATETIME DEFAULT NULL;

-- 7. S'assurer que panel_sanctions a toutes les colonnes
ALTER TABLE `panel_sanctions`
ADD COLUMN IF NOT EXISTS `revoked_by` VARCHAR(60) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS `revoked_at` DATETIME DEFAULT NULL;

-- ══════════════════════════════════════════════════════════════
-- VERIFICATION
-- ══════════════════════════════════════════════════════════════
-- Après l'exécution, vérifie que tu n'as pas d'erreur
-- Les "Duplicate column" sont normales et signifient que la colonne existait déjà

-- ══════════════════════════════════════════════════════════════
-- IMPORTANT POUR LES SANCTIONS
-- ══════════════════════════════════════════════════════════════
-- Les sanctions (warn/kick/ban) nécessitent le grade 'responsable' ou supérieur
-- Le grade 'staff' ne peut PAS sanctionner, seulement voir les joueurs
--
-- Vérifie ton grade avec cette commande dans le serveur:
-- /group (ou regarde dans ta base de données users)
--
-- Grades avec permissions sanctions:
-- - responsable (level 60): warn, kick, ban temp
-- - admin (level 80): + ban perm, unban
-- - owner (level 100): toutes les permissions
-- j'étais responsable j'ai reussis a ban avec la license un membre qui était admin 
