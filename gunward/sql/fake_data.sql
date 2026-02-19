-- ============================================================
-- GUNWARD — Fake data for testing (20 players)
-- Run this AFTER the main gunward.sql schema is in place.
-- DELETE FROM gunward_stats WHERE identifier LIKE 'fake:%';
-- ============================================================

INSERT INTO `gunward_stats` (`identifier`, `name`, `kills`, `deaths`, `bank`) VALUES
('fake:001', 'Shadow_X',     87, 14, 8700),
('fake:002', 'Viper_01',     74, 18, 7400),
('fake:003', 'KnightFall',   66, 22, 6600),
('fake:004', 'Maverick',     58, 25, 5800),
('fake:005', 'Reaper_99',    51, 30, 5100),
('fake:006', 'Phantom',      47, 28, 4700),
('fake:007', 'Blaze',        43, 32, 4300),
('fake:008', 'Toxin',        39, 29, 3900),
('fake:009', 'Ace_High',     35, 31, 3500),
('fake:010', 'Rogue',        31, 33, 3100),
('fake:011', 'Wraith',       28, 30, 2800),
('fake:012', 'Thunder',      25, 28, 2500),
('fake:013', 'Spectre',      22, 26, 2200),
('fake:014', 'Cobra',        19, 24, 1900),
('fake:015', 'Falcon',       16, 22, 1600),
('fake:016', 'Raptor',       13, 20, 1300),
('fake:017', 'Bandit',       11, 19, 1100),
('fake:018', 'Ghost_II',      8, 18,  800),
('fake:019', 'Nemesis',       5, 16,  500),
('fake:020', 'Rookie_X',      2, 12,  200)
ON DUPLICATE KEY UPDATE
    name   = VALUES(name),
    kills  = VALUES(kills),
    deaths = VALUES(deaths),
    bank   = VALUES(bank);

-- Pour supprimer les fakes : DELETE FROM gunward_stats WHERE identifier LIKE 'fake:%';
