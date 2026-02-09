shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

author 'KICHTABOY'
description 'Système de Guerre de Territoire - Event-Driven & Optimisé'
version '1.2.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/permissions.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/events.lua',
    'server/callbacks.lua',
    'server/teams.lua',
    'server/database.lua',
    'server/game.lua',
    'server/discord.lua',
    'server/ped.lua'
}

client_scripts {
    'client/main.lua',
    'client/events.lua',
    'client/ui.lua',
    'client/ped.lua',
    'client/zones.lua',
    'client/outfits.lua',
    'client/game.lua',
    'client/ui_game.lua',
    'client/spectator.lua',
    'client/friendly_fire.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logobackground.png'
}

dependencies {
    'es_extended',
    'oxmysql'
}