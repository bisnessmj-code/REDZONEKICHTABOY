shared_script '@WaveShield/resource/include.lua'

--[[
    ═══════════════════════════════════════════════════════════
    🏁 CATMOUSE RACING - FXMANIFEST
    ═══════════════════════════════════════════════════════════
    
    Script de course 1v1 Chasseur vs Fuyard
    Best of 3 rounds avec système de capture
    
    ✅ NOUVEAU: Système de sécurité anti-triche véhicule
    ✅ NOUVEAU: Commandes admin (kick joueur, kick all)
]]

fx_version 'cerulean'
game 'gta5'

name 'catmouse_racing'
description 'Course 1v1 Chasseur vs Fuyard avec matchmaking, système ELO, sécurité véhicule et commandes admin'
author 'CatMouse Racing'
version '1.3.0'

lua54 'yes'

-- ═══════════════════════════════════════════════════════════
-- 📦 FICHIERS PARTAGÉS (Client + Serveur)
-- ═══════════════════════════════════════════════════════════
shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/utils.lua'
}

-- ═══════════════════════════════════════════════════════════
-- 💻 FICHIERS CLIENT
-- ═══════════════════════════════════════════════════════════
client_scripts {
    'client/race_vehicles.lua',
    'client/vehicle_security.lua',    -- Sécurité véhicule
    'client/race_logic.lua',
    'client/race_ui.lua',
    'client/notifications.lua',
    'client/queue_restrictions.lua',
    'client/ped.lua',
    'client/leaderboard.lua',
    'client/main.lua'
}

-- ═══════════════════════════════════════════════════════════
-- 🖥️ FICHIERS SERVEUR
-- ═══════════════════════════════════════════════════════════
server_scripts {
    -- Wrapper MySQL (oxmysql, mysql-async, ghmattimysql)
    '@oxmysql/lib/MySQL.lua',    -- Si tu utilises oxmysql
    -- '@mysql-async/lib/MySQL.lua', -- Décommente si tu utilises mysql-async
    
    -- Modules serveur
    'server/elo_system.lua',
    'server/leaderboard.lua',
    'server/vehicle_violations.lua',    -- Gestionnaire d'infractions
    'server/race_session.lua',
    'server/matchmaking.lua',
    'server/events.lua',
    'server/admin_commands.lua',        -- ✅ NOUVEAU: Commandes admin
    'server/main.lua'
}

-- ═══════════════════════════════════════════════════════════
-- 🎨 INTERFACE NUI
-- ═══════════════════════════════════════════════════════════
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/*.png',
    'html/assets/*.jpg'
}

-- ═══════════════════════════════════════════════════════════
-- 🔧 DÉPENDANCES
-- ═══════════════════════════════════════════════════════════
dependencies {
    '/server:5181',  -- Minimum build
    '/onesync',      -- OneSync requis pour les routing buckets
    'oxmysql'        -- Base de données pour le système ELO
    -- 'mysql-async' -- Alternative si tu utilises mysql-async
}

-- ═══════════════════════════════════════════════════════════
-- 📝 MÉTADONNÉES
-- ═══════════════════════════════════════════════════════════
-- Recommandé : ox_target pour l'interaction avec le PED
-- Alternative : système raycast manuel intégré
-- 
-- Le système ELO nécessite une base de données MySQL
-- Exécuter sql/elo_system.sql pour créer les tables
-- 
-- ✅ v1.2.0:
-- - Détection véhicule retourné (3 secondes de grâce)
-- - Détection saut abusif (altitude/durée max)
-- - Détection véhicule détruit
-- - Défaite automatique en cas d'infraction
--
-- ✅ v1.3.0:
-- - Commandes admin : /kickcourse [id] et /kickallcourse
-- - Expulsion complète avec nettoyage et ELO
-- - Permissions ACE + liste d'identifiants