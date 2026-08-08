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