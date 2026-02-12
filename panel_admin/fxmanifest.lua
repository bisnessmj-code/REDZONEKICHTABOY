shared_script '@WaveShield/resource/include.lua'

--[[
    Panel Administration Fight League
    Version: 1.0.0
    Framework: ESX Legacy
    Description: Panel d'administration complet pour serveur FiveM Fight League
]]

fx_version 'cerulean'
game 'gta5'

name 'panel_admin'
author 'Fight League'
description 'Panel Administration FiveM - Fight League'
version '1.0.0'

lua54 'yes'

-- Dépendances
dependencies {
    'es_extended',
    'oxmysql'
}

-- Fichiers partagés (chargés avant client/server)
shared_scripts {
    '@es_extended/imports.lua',
    'config/config.lua',
    'config/permissions.lua',
    'config/commands.lua',
    'shared/enums.lua',
    'shared/locales.lua'
}

-- Scripts serveur
server_scripts {
    'server/services/database.lua',
    'server/utils/helpers.lua',
    'server/utils/validators.lua',
    'server/modules/auth.lua',
    'server/modules/players.lua',
    'server/modules/sanctions.lua',
    'server/modules/economy.lua',
    'server/modules/vehicles.lua',
    'server/modules/teleport.lua',
    'server/modules/events.lua',
    'server/modules/announcements.lua',
    'server/modules/logs.lua',
    'server/modules/reports.lua',
    'server/modules/staff-chat.lua',
    'server/modules/staff-roles.lua',
    'server/modules/commands.lua',
    'server/modules/command-logger.lua',
    'server/services/discord.lua',
    'server/main.lua'
}

-- Scripts client
client_scripts {
    'client/modules/nui_bridge.lua',
    'client/modules/keybinds.lua',
    'client/modules/spectate.lua',
    'client/modules/deathlog.lua',
    'client/modules/noclip.lua',
    'client/modules/esp.lua',
    'client/modules/admin_commands.lua',
    'client/modules/repair-key.lua',
    'client/modules/command-logger.lua',
    'client/main.lua'
}

-- Interface NUI
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/css/*.css',
    'nui/css/components/*.css',
    'nui/js/*.js',
    'nui/js/modules/*.js',
    'nui/js/services/*.js',
    'nui/js/utils/*.js',
    'nui/sounds/*.mp3',
    'nui/sounds/*.ogg',
    'nui/sounds/*.wav',
    'nui/img/*.png',
    'nui/img/*.jpg',
    'nui/img/*.jpeg'
}

-- Exports serveur
server_exports {
    'isPlayerBanned',
    'addLog',
    'hasPermission',
    'getStaffInfo',
    'addSanction',
    'getPlayerSanctions'
}

-- Exports client
exports {
    'openPanel',
    'closePanel',
    'isOpen'
}

dependency '/assetpacks'