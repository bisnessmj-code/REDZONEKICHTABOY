-- ==========================================
-- FAKE DATA - CLASSEMENT TOP 20 GDT
-- A executer apres gdt_kills.sql
-- ==========================================

INSERT INTO `gdt_kills` (`identifier`, `name`, `kills`) VALUES
('steam:110000100000001', 'KICHTABOY', 247),
('steam:110000100000002', 'DarkSniper', 198),
('steam:110000100000003', 'LeFrancais', 176),
('steam:110000100000004', 'ShadowKill3r', 154),
('steam:110000100000005', 'NexusZz', 139),
('steam:110000100000006', 'BlazeRunner', 127),
('steam:110000100000007', 'ToxicVenom', 118),
('steam:110000100000008', 'AlphaWolf', 105),
('steam:110000100000009', 'CyberFox', 97),
('steam:110000100000010', 'GhostRider', 88),
('steam:110000100000011', 'IronFist', 82),
('steam:110000100000012', 'StormBreaker', 74),
('steam:110000100000013', 'ViperX', 69),
('steam:110000100000014', 'PhantomAce', 61),
('steam:110000100000015', 'ZeroGravity', 55),
('steam:110000100000016', 'NovaFlash', 48),
('steam:110000100000017', 'ThunderBolt', 42),
('steam:110000100000018', 'RogueAgent', 35),
('steam:110000100000019', 'NightHawk', 28),
('steam:110000100000020', 'SilentDeath', 21)
ON DUPLICATE KEY UPDATE `kills` = VALUES(`kills`), `name` = VALUES(`name`);
