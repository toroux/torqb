fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'Hitman Queue System.'

shared_scripts {
    -- '@ox_lib/init.lua', -- Temporarily removed
    'shared.lua',
}

client_scripts {
    'bridge/client/**.lua',
    'cl_contract.lua',
}

server_scripts {
    'bridge/server/**.lua',
    'sv_config.lua',
    'sv_contract.lua',
}

escrow_ignore {
    'bridge/client/**.lua',
    'bridge/server/**.lua',
    'shared.lua',
    'sv_config.lua',
}

lua54 'yes'

dependency '/assetpacks'