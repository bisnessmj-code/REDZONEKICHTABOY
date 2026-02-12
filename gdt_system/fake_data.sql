-- ==========================================
-- FAKE DATA POUR TESTER LE CLASSEMENT + STATS
-- A supprimer apres les tests
-- ==========================================

INSERT INTO `gdt_kills` (`identifier`, `name`, `kills`, `deaths`, `wins`, `losses`) VALUES
('char1:abc111', 'xDarkSniper', 347, 120, 45, 22),
('char1:abc222', 'KingSlayerZz', 289, 98, 38, 19),
('char1:abc333', 'NoMercyBoy', 256, 145, 30, 28),
('char1:abc444', 'ShadowKiller', 198, 110, 25, 20),
('char1:abc555', 'HeadshotPro', 187, 89, 33, 15),
('char1:abc666', 'VenomStrike', 165, 132, 20, 30),
('char1:abc777', 'BulletStorm', 154, 160, 18, 35),
('char1:abc888', 'GhostReaper', 143, 77, 28, 12),
('char1:abc999', 'IceColdd', 132, 105, 22, 24),
('char1:abd000', 'RedZoneBoss', 128, 140, 15, 32),
('char1:abd111', 'SniperElite', 115, 95, 19, 18),
('char1:abd222', 'ToxicRage', 108, 112, 14, 26),
('char1:abd333', 'NightHawk', 97, 88, 17, 16),
('char1:abd444', 'AceKilla', 89, 102, 12, 22),
('char1:abd555', 'DeathWish', 82, 78, 16, 14),
('char1:abd666', 'PhantomX', 75, 130, 8, 34),
('char1:abd777', 'WarMachine', 68, 65, 13, 11),
('char1:abd888', 'BlazeFury', 55, 90, 7, 25),
('char1:abd999', 'ColdBlood', 42, 55, 9, 15),
('char1:abe000', 'NoobMaster', 12, 180, 2, 48)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `kills` = VALUES(`kills`),
    `deaths` = VALUES(`deaths`),
    `wins` = VALUES(`wins`),
    `losses` = VALUES(`losses`);
