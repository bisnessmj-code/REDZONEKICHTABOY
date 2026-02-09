-- Migration: Ajout de l'ID de deban (unban_id) aux tables panel_bans et panel_sanctions
-- Executez ce script si vous avez deja installe le panel et que vous voulez ajouter le systeme d'ID de deban

-- Ajouter la colonne unban_id a panel_bans
ALTER TABLE `panel_bans`
ADD COLUMN IF NOT EXISTS `unban_id` VARCHAR(5) DEFAULT NULL UNIQUE,
ADD INDEX IF NOT EXISTS `idx_unban_id` (`unban_id`);

-- Ajouter la colonne unban_id a panel_sanctions
ALTER TABLE `panel_sanctions`
ADD COLUMN IF NOT EXISTS `unban_id` VARCHAR(5) DEFAULT NULL,
ADD INDEX IF NOT EXISTS `idx_unban_id` (`unban_id`);

-- Generer des IDs pour les bans existants qui n'en ont pas
-- Note: Cette requete va generer des IDs aleatoires pour les bans existants
UPDATE `panel_bans`
SET `unban_id` = LPAD(FLOOR(RAND() * 100000), 5, '0')
WHERE `unban_id` IS NULL;

UPDATE `panel_sanctions`
SET `unban_id` = (
    SELECT pb.unban_id FROM `panel_bans` pb
    WHERE pb.identifier = panel_sanctions.target_identifier
    LIMIT 1
)
WHERE `type` IN ('ban_temp', 'ban_perm') AND `unban_id` IS NULL;
