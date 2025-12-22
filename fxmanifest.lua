shared_script "@ThnAC/native.lua"
shared_script "@ThnAC/natives.lua"
fx_version 'cerulean'
game 'gta5'

author 'zNex'
description 'Painel de Buff'
version '1.0.0'

ui_page 'web/dist/index.html'


files {
    'web/dist/index.html',
    'web/dist/assets/**/*'
}

client_scripts {
    "@vrp/lib/utils.lua",
    'client.lua',
}

server_scripts {
    "@vrp/lib/utils.lua",
    "server.lua"
}