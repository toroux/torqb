shared_scripts { '@FiniAC/fini_events.lua' }

fx_version "cerulean"
games { "gta5" }

shared_scripts {
    '@ox_lib/init.lua',
	'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

client_scripts {
    '@NativeUI/NativeUI.lua',
    '@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
    'client/*.lua',
}
lua54 'yes'
