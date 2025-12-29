fx_version 'cerulean'
games { 'rdr3', 'gta5' }

author 'Torou'
description 'Standalone Staff Chat System with Advanced UI'
version '1.0.0'

lua54 'yes'

server_script 'server/main.lua'
client_script 'client/main.lua'
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

ui_page 'html/staffchat.html'

files {
    'html/staffchat.html',
    'html/staffchat.css',
    'html/staffchat.js',
}

