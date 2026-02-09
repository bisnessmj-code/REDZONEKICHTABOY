-- ════════════════════════════════════════════════════════════
-- REPAIR DATABASE - Panel Admin Fight League
-- Répare la base de données (compatible MySQL 5.7+)
-- ════════════════════════════════════════════════════════════

-- Supprimer et recréer panel_player_notes (cause de l'erreur actuelle)
DROP TABLE IF EXISTS `panel_player_notes`;

CREATE TABLE `panel_player_notes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `target_identifier` VARCHAR(60) NOT NULL,
    `target_name` VARCHAR(100) DEFAULT NULL,
    `content` TEXT NOT NULL,
    `category` ENUM('general','warning','positive','report','follow_up') DEFAULT 'general',
    `staff_identifier` VARCHAR(60) NOT NULL,
    `staff_name` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_notes_target` (`target_identifier`),
    INDEX `idx_notes_staff` (`staff_identifier`),
    INDEX `idx_notes_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Notes sur les joueurs par le staff';

-- Insérer une note de test pour vérifier que ça fonctionne
INSERT INTO `panel_player_notes`
    (`target_identifier`, `target_name`, `content`, `category`, `staff_identifier`, `staff_name`)
VALUES
    ('test:000', 'Joueur Test', 'Note de test - vous pouvez supprimer cette ligne', 'general', 'system', 'System');

SELECT '✅ Table panel_player_notes réparée avec succès!' AS message;
SELECT 'ℹ️  Redémarrez la ressource: restart panel_admin' AS info;
