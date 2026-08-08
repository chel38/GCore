-- RU: Конфигурация логирования GreenCore.
-- EN: GreenCore logging configuration.

-- RU: Корневая таблица конфигурации.
-- EN: Root configuration table.
GCConfig = GCConfig or {}

-- RU: Настройки логирования.
-- EN: Logging settings.
GCConfig.Logging = {
    -- RU: Минимальный уровень логирования: TRACE, DEBUG, INFO, WARN, ERROR, CRITICAL.
    -- EN: Minimum logging level: TRACE, DEBUG, INFO, WARN, ERROR, CRITICAL.
    level = 'INFO',

    -- RU: Показывать ли временную метку в сообщениях.
    -- EN: Whether to show a timestamp in messages.
    showTimestamp = true,

    -- RU: Показывать ли имя ресурса в сообщениях.
    -- EN: Whether to show the resource name in messages.
    showResourceName = true,

    -- RU: Маскировать ли чувствительные данные (license, IP, discord).
    -- EN: Whether to mask sensitive data (license, IP, discord).
    maskSensitiveData = true,

    -- RU: Локализовать ли сообщения логов.
    -- EN: Whether to localize log messages.
    localizedMessages = true
}