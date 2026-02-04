fx_version 'cerulean'

game 'gta5'

author 'OpenAI Assistant'

description 'QBCore gas station tank business with upgrades and fuel ordering'

version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

lua54 'yes'
