CREATE TABLE IF NOT EXISTS `gunward_stats` (
    `identifier`   VARCHAR(60)  NOT NULL,
    `name`         VARCHAR(50)  DEFAULT '',
    `kills`        INT          DEFAULT 0,
    `deaths`       INT          DEFAULT 0,
    `wins`         INT          DEFAULT 0,
    `games_played` INT          DEFAULT 0,
    `bank`         INT          DEFAULT 0,
    `last_played`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Migration: add columns if table already exists
ALTER TABLE `gunward_stats` ADD COLUMN IF NOT EXISTS `bank` INT DEFAULT 0;
ALTER TABLE `gunward_stats` ADD COLUMN IF NOT EXISTS `name` VARCHAR(50) DEFAULT '';
