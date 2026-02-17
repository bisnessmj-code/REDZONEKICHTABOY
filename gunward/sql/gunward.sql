CREATE TABLE IF NOT EXISTS `gunward_stats` (
    `identifier` VARCHAR(60) NOT NULL,
    `kills` INT DEFAULT 0,
    `deaths` INT DEFAULT 0,
    `wins` INT DEFAULT 0,
    `games_played` INT DEFAULT 0,
    `last_played` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
