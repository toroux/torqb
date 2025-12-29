author 'Adele Lover'
version '8.8.8'
description 'Airdrop Management System'

shared_script "@ReaperV4/bypass.lua"
lua54 "yes"

shared_scripts { '@FiniAC/fini_events.lua' }
fx_version "cerulean"
game "gta5"

ui_page 'html/nui.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    "client/*.lua"
}

server_scripts {
    "server/*.lua"
}

files {
    'html/nui.html',
    'html/audio/annoucement.ogg',
}

lua54 'yes'
