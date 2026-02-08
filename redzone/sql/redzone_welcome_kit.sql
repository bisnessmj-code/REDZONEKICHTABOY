-- =====================================================
-- REDZONE LEAGUE - Table Kit de Bienvenue
-- =====================================================
-- Cette table stocke les joueurs ayant deja recupere
-- le kit de bienvenue (une seule fois par joueur).
-- =====================================================

CREATE TABLE IF NOT EXISTS `redzone_welcome_kit` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(100) NOT NULL,
    `name` VARCHAR(50) DEFAULT 'Inconnu',
    `claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
