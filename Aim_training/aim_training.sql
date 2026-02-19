-- Table pour le classement Aim Training
CREATE TABLE IF NOT EXISTS `aim_training_leaderboard` (
  `identifier` varchar(60) NOT NULL,
  `name` varchar(100) NOT NULL,
  `kills` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  FAKE DATA — 10 joueurs pour tester le classement
-- ============================================================
INSERT INTO `aim_training_leaderboard` (`identifier`, `name`, `kills`) VALUES
('steam:110000112a4f8b1', 'Shadow_X',     47),
('steam:110000108c3d2e7', 'Viper_01',     43),
('steam:110000115e9a1f4', 'KnightFall',   39),
('steam:11000010d7b6c83', 'Maverick',     35),
('steam:110000109f2e5a6', 'Reaper',       31),
('steam:110000111c8d4b2', 'Phantom',      28),
('steam:11000010e3a7f91', 'Blaze',        24),
('steam:110000106b1d9e5', 'Toxin',        20),
('steam:110000113a5c2f8', 'Ghost',        16),
('steam:11000010f4b8d3a', 'Nemesis',      12)
ON DUPLICATE KEY UPDATE `kills` = VALUES(`kills`), `name` = VALUES(`name`);
