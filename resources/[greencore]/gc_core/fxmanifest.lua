-- RU: Манифест ресурса gc_core.
-- EN: gc_core resource manifest.

fx_version 'cerulean'
game 'gta5'

-- RU: Включаем Lua 5.4.
-- EN: Enable Lua 5.4.
lua54 'yes'

author 'GreenCore Team'
description 'GreenCore modular engine core resource'
version '0.1.0'

-- RU: Подключаем общие файлы, доступные серверу и клиенту.
-- EN: Load shared files available to both server and client.
shared_scripts {
    'config/general.lua',
    'config/connection.lua',
    'config/spawn.lua',
    'config/security.lua',
    'config/logging.lua',
    'config/diagnostics.lua',

    'locales/en.lua',
    'locales/ru.lua',
    'locales/custom.example.lua',

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

-- RU: Подключаем тесты на серверной стороне после основной логики.
-- RU: Тесты запускаются только при включённом developmentMode (tests/run.lua).
-- EN: Load tests on the server side after the main logic.
-- EN: Tests run only when developmentMode is enabled (tests/run.lua).
server_scripts {
    'tests/test_runner.lua',
    'tests/validation_test.lua',
    'tests/states_test.lua',
    'tests/sessions_test.lua',
    'tests/connection_test.lua',
    'tests/spawn_test.lua',
    'tests/rate_limit_test.lua',
    'tests/notifications_test.lua',
    'tests/run.lua'
}