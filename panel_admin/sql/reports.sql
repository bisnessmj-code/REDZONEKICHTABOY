-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE: panel_reports
-- Gestion des tickets de support des joueurs
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `panel_reports` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `player_id` INT(11) NOT NULL COMMENT 'Server ID du joueur au moment du report',
    `player_identifier` VARCHAR(60) NOT NULL COMMENT 'Identifier unique du joueur',
    `player_name` VARCHAR(50) NOT NULL COMMENT 'Nom du joueur',
    `message` TEXT NOT NULL COMMENT 'Contenu du report',
    `status` ENUM('pending', 'in_progress', 'resolved', 'deleted') NOT NULL DEFAULT 'pending',
    `claimed_by` VARCHAR(60) DEFAULT NULL COMMENT 'Identifier du staff qui a pris en charge',
    `claimed_by_name` VARCHAR(50) DEFAULT NULL COMMENT 'Nom du staff',
    `claimed_at` DATETIME DEFAULT NULL,
    `response` TEXT DEFAULT NULL COMMENT 'Reponse du staff',
    `responded_by` VARCHAR(60) DEFAULT NULL,
    `responded_by_name` VARCHAR(50) DEFAULT NULL,
    `responded_at` DATETIME DEFAULT NULL,
    `resolved_at` DATETIME DEFAULT NULL,
    `deleted_by` VARCHAR(60) DEFAULT NULL,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`),
    KEY `idx_player_identifier` (`player_identifier`),
    KEY `idx_claimed_by` (`claimed_by`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index pour les recherches frequentes
CREATE INDEX IF NOT EXISTS `idx_reports_status_created` ON `panel_reports` (`status`, `created_at` DESC);
