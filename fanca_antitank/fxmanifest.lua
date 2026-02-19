fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal 'yes'
game_priority "high"

author "Fancazista"
github "https://github.com/Fancazista/"
discord "https://discord.gg/cHsUDEhfqn/"
tebex "https://fanca.tebex.io/"

name "Anti-tank system"
description "Make sure when someone have to die, they die. No matter what"
version "1.5.15"

shared_scripts {
	"config.lua",
	"shared.lua",
}

server_scripts {
	'config_server.lua',
	'server.lua',
}
client_script 'client.lua'

ui_page 'web/index.html'
files {
	'web/index.html',
	'web/**/*',

	'stream/hud_reticle.gfx',
}

escrow_ignore {
	'config_server.lua',
	'config.lua',
}

dependency '/assetpacks'