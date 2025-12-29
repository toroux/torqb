
fx_version 'cerulean'
game 'gta5'

--#################################--
--####### Made With Love <3 #######--
--############ Pluto ##############--
--############# ❤ ################--
--#################################--

shared_script {
	'config.lua'
}

client_scripts {
	'client/*.lua',
	'config.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua',
	'config.lua',
}

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/style.css',
	'html/script.js',
}

lua54 'yes'

escrow_ignore {
	"config.lua",
}
dependency '/assetpacks'