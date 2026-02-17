fx_version 'cerulean'
game 'gta5'

name 'gunward'
description 'Gunward - Team-based game mode'
author 'REDZONE'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config/config.lua',
    'config/config_teams.lua',
    'config/config_outfits.lua',
    'config/config_commands.lua',
    'config/config_ped.lua',
    'shared/shared.lua',
    'shared/locale.lua',
    'locales/*.lua',
}

client_scripts {
    'client/utils.lua',
    'client/ped.lua',
    'client/teams.lua',
    'client/spawn.lua',
    'client/commands.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/teams.lua',
    'server/spawn.lua',
    'server/commands.lua',
    'server/database.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/assets/logo.png',
}
