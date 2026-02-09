-- MIGRATION: Ajout des server IDs dans les logs
-- Execute ce script si tu as deja la table panel_logs

-- Ajouter la categorie 'death' a l'ENUM si elle n'existe pas
ALTER TABLE `panel_logs`
MODIFY COLUMN `category` ENUM('auth','player','sanction','economy','teleport','vehicle','event','system','death') NOT NULL DEFAULT 'system';

-- Permettre staff_identifier NULL (pour les morts environnementales)
ALTER TABLE `panel_logs`
MODIFY COLUMN `staff_identifier` VARCHAR(60) DEFAULT NULL;

-- Ajouter les colonnes server ID
ALTER TABLE `panel_logs`
ADD COLUMN IF NOT EXISTS `staff_server_id` INT DEFAULT 0 AFTER `details`,
ADD COLUMN IF NOT EXISTS `target_server_id` INT DEFAULT 0 AFTER `staff_server_id`;

-- Ajouter les index pour la recherche par ID
CREATE INDEX IF NOT EXISTS `idx_staff_server_id` ON `panel_logs` (`staff_server_id`);
CREATE INDEX IF NOT EXISTS `idx_target_server_id` ON `panel_logs` (`target_server_id`);
CREATE INDEX IF NOT EXISTS `idx_category` ON `panel_logs` (`category`);
CREATE INDEX IF NOT EXISTS `idx_created_at` ON `panel_logs` (`created_at`);
