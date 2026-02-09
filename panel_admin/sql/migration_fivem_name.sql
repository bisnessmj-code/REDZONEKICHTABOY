-- Migration pour ajouter le nom FiveM dans la table users

-- Ajouter la colonne fivem_name si elle n'existe pas
ALTER TABLE `users`
ADD COLUMN IF NOT EXISTS `fivem_name` VARCHAR(100) DEFAULT NULL AFTER `lastname`;

-- Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS `idx_fivem_name` ON `users` (`fivem_name`);

-- Message de confirmation
SELECT 'Migration complete: colonne fivem_name ajoutee a la table users' AS message;
