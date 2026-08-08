-- RU: Пример манифеста будущего Lua-модуля GreenCore.
-- EN: Example manifest for a future GreenCore Lua module.

fx_version 'cerulean'
game 'gta5'

-- RU: Включаем Lua 5.4.
-- EN: Enable Lua 5.4.
lua54 'yes'

author 'GreenCore Team'
description 'Example future module for GreenCore'
version '0.1.0'

-- RU: Подключаем серверные файлы.
-- EN: Load server files.
server_scripts {
    'server/main.lua'
}

-- RU: Подключаем клиентские файлы.
-- EN: Load client files.
client_scripts {
    'client/main.lua'
}