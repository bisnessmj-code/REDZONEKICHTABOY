-- ============================================================
-- Fix: rows that have an empty name (pre-migration rows).
-- This is a one-time cleanup. After this, the Lua code
-- keeps names in sync automatically on every UI open.
-- ============================================================

-- Show which rows are affected before updating
SELECT identifier, name, kills, deaths, bank
FROM gunward_stats
WHERE name = '' OR name IS NULL;

-- NOTE: We can't auto-fill real FiveM names from SQL alone
-- (FiveM player names live in the game server, not the DB).
-- The fix_empty_names sets a readable placeholder so it doesn't
-- show the raw license string.
-- The correct name will be written automatically next time
-- the player opens the Gunward UI (getStatsUI callback).

UPDATE gunward_stats
SET name = CONCAT('Player_', LEFT(identifier, 6))
WHERE (name = '' OR name IS NULL)
  AND identifier NOT LIKE 'fake:%';
