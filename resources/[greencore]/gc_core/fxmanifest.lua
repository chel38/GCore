-- RU: Манифест ресурса gc_core.
-- RU: Весь runtime написан на Lua (сервер, клиент, shared, config, locales, tests).
-- EN: gc_core resource manifest.
-- EN: The entire runtime is written in Lua (server, client, shared, config, locales, tests).

fx_version 'cerulean'
game 'gta5'

-- RU: Примечание: директива lua54 не добавляется, так как для текущего FXServer
-- RU: она является необязательной и больше не требуется.
-- EN: Note: the lua54 directive is not added because it is optional for the
-- EN: current FXServer and is no longer required.

author 'GreenCore Team'
description 'GreenCore modular engine core resource'
version '0.1.0'

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
    'shared/version.lua',
    'shared/constants.lua',
    'shared/errors.lua',
    'shared/utils.lua',
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
    'server/exports.lua',
    'server/diagnostics.lua',
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

-- RU: Подключаем тесты на серверной стороне.
-- RU: Тесты регистрируются, но ЗАПУСКАЮТСЯ только при GCConfig.Tests.enabled
-- RU: или convar gc_runTests 1 (см. tests/run.lua). По умолчанию выключено.
-- EN: Load tests on the server side.
-- EN: Tests are registered but only RUN when GCConfig.Tests.enabled is set or
-- EN: the gc_runTests convar is 1 (see tests/run.lua). Disabled by default.
server_scripts {
    'tests/test_runner.lua',
    'tests/validation_test.lua',
    'tests/states_test.lua',
    'tests/sessions_test.lua',
    'tests/connection_test.lua',
    'tests/spawn_test.lua',
    'tests/protocol_test.lua',
    'tests/ped_provider_test.lua',
    'tests/logger_test.lua',
    'tests/rate_limit_test.lua',
    'tests/notifications_test.lua',
    'tests/run.lua'
}