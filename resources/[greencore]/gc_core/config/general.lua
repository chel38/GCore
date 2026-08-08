-- RU: Общая конфигурация GreenCore.
-- EN: GreenCore general configuration.

-- RU: Корневая таблица конфигурации. Создаётся один раз и используется всеми модулями.
-- EN: Root configuration table. Created once and used by all modules.
GCConfig = GCConfig or {}

-- RU: Общие настройки ядра.
-- EN: Core general settings.
GCConfig.General = {
    -- RU: Язык по умолчанию для сообщений игрокам.
    -- EN: Default language for player-facing messages.
    locale = 'ru',

    -- RU: Запасной язык, если перевод отсутствует в основном языке.
    -- EN: Fallback language when a translation is missing in the primary language.
    fallbackLocale = 'en',

    -- RU: Включает подробные отладочные сообщения.
    -- EN: Enables verbose debug messages.
    debug = false,

    -- RU: Режим разработки. Включает дополнительные проверки.
    -- EN: Development mode. Enables additional checks.
    developmentMode = true,

    -- RU: Версия публичного API. Модули проверяют её перед использованием.
    -- EN: Public API version. Modules check it before use.
    apiVersion = 1,

    -- RU: Версия сетевого протокола между клиентом и сервером.
    -- EN: Network protocol version between client and server.
    protocolVersion = 1
}

-- RU: Настройки тестов.
-- RU: Тесты НЕ запускаются автоматически при обычном запуске gc_core.
-- RU: Разрешаются только явно: config enabled или convar gc_runTests 1.
-- EN: Test settings.
-- EN: Tests do NOT run automatically on a normal gc_core startup.
-- EN: They are enabled only explicitly: config enabled or convar gc_runTests 1.
GCConfig.Tests = {
    -- RU: Включены ли тесты. По умолчанию выключено для продакшена.
    -- EN: Whether tests are enabled. Disabled by default for production.
    enabled = false,

    -- RU: Имя convar для запуска тестов (например, set gc_runTests 1).
    -- EN: Convar name to run tests (e.g., set gc_runTests 1).
    convar = 'gc_runTests'
}