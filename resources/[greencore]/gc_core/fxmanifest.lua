-- RU: Манифест ресурса gc_core.
-- RU: Весь production runtime написан на Lua (сервер, клиент, shared, config).
-- EN: gc_core resource manifest.
-- EN: The entire runtime is written in Lua (server, client, shared, config, locales, tests).

fx_version 'cerulean'
game 'gta5'

-- RU: Примечание: директива lua54 не добавляется, так как для текущего FXServer
-- RU: она является необязательной и больше не требуется.
-- EN: Note: the lua54 directive is not added because it is optional for the
-- EN: current FXServer and is no longer required.

author 'GCore Project'
description 'GreenCore modular engine core resource'
version '0.1.2-alpha'

-- RU: Подключаем общие файлы, доступные серверу и клиенту.
-- RU: custom.example.lua НЕ подключается в runtime — он перенесён в examples/locales.
-- EN: Load shared files available to both server and client.
-- EN: custom.example.lua is NOT loaded at runtime — it moved to examples/locales.
shared_scripts {
    'config/general.lua',
    'config/connection.lua',
    'config/spawn.lua',
    'config/security.lua',
    'config/logging.lua',
    'config/diagnostics.lua',

    'locales/en.lua',
    'locales/ru.lua',

    'shared/bootstrap.lua',
    'shared/runtime.lua',
    'shared/version.lua',
    'shared/constants.lua',
    'shared/errors.lua',
    'shared/utils.lua',
    'shared/ids.lua',
    'shared/events.lua',
    'shared/locale.lua',
    'shared/logger.lua',
    'shared/validation.lua'
}

-- RU: Подключаем серверные файлы в осознанном порядке.
-- EN: Load server files in a deliberate order.
server_scripts {
    'server/bootstrap.lua',
    'server/identifiers.lua',
    'server/sessions.lua',
    'server/states.lua',
    'server/rate_limit.lua',
    'server/security.lua',
    'server/ped_provider.lua',
    'server/spawn_location.lua',
    'server/connection.lua',
    'server/spawn.lua',
    'server/players.lua',
    'server/notifications.lua',
    'server/events.lua',
    'server/api.lua',
    'server/exports.lua',
    'server/diagnostics.lua',
    'server/test_loader.lua',
    'server/main.lua'
}

-- RU: Подключаем клиентские файлы в осознанном порядке.
-- EN: Load client files in a deliberate order.
client_scripts {
    'client/bootstrap.lua',
    'client/state.lua',
    'client/readiness.lua',
    'client/spawn.lua',
    'client/events.lua',
    'client/diagnostics.lua',
    'client/main.lua'
}

-- RU: Тесты упаковываются, но не исполняются в production runtime. Явный
-- RU: server/test_loader.lua загружает их только при gc_runTests=1.
-- EN: Tests are packaged but never executed in production runtime. The explicit
-- EN: server/test_loader.lua loads them only when gc_runTests=1.
files {
    'tests/*.lua'
}
