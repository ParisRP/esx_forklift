fx_version 'cerulean'
game 'gta5'

author 'ESX Forklift Job'
description 'Job réaliste de chauffeur de chariot élévateur'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'locales/*.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_fuel',
    'oxmysql'
}