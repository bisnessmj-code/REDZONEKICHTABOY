fx_version 'cerulean'
game 'gta5'

name 'gunward'
description 'Gunward - Team-based game mode'
author 'REDZONE'
version '1.0.0'

lua54 'yes'

dependency 'fanca_antitank'

shared_scripts {
    'config/config.lua',
    'config/config_teams.lua',
    'config/config_outfits.lua',
    'config/config_commands.lua',
    'config/config_ped.lua',
    'config/config_vehicles.lua',
    'config/config_weapons.lua',
    'config/config_koth.lua',
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
    'client/vehicleshop.lua',
    'client/weaponshop.lua',
    'client/leavepeds.lua',
    'client/safezone.lua',
    'client/death.lua',
    'client/koth.lua',
    'client/playerblips.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/teams.lua',
    'server/spawn.lua',
    'server/commands.lua',
    'server/database.lua',
    'server/vehicleshop.lua',
    'server/weaponshop.lua',
    'server/koth.lua',
    'server/main.lua',
    'server/antitank.lua',
    'server/webhook.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/css/gunward.css',
    'html/css/vehicle.css',
    'html/css/weapon.css',
    'html/css/killfeed.css',
    'html/css/announce.css',
    'html/css/koth-score.css',
    'html/js/gunward.js',
    'html/js/vehicle.js',
    'html/js/weapon.js',
    'html/js/killfeed.js',
    'html/js/announce.js',
    'html/js/koth-score.js',
    'html/assets/logo.png',
    'html/assets/background.png',
}
