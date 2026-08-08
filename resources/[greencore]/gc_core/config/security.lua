-- RU: Конфигурация безопасности GreenCore.
-- EN: GreenCore security configuration.

-- RU: Корневая таблица конфигурации.
-- EN: Root configuration table.
GCConfig = GCConfig or {}

-- RU: Настройки безопасности.
-- EN: Security settings.
GCConfig.Security = {
    -- RU: Максимальное количество нарушений rate limit до отключения игрока.
    -- EN: Maximum rate limit violations before disconnecting the player.
    maxViolationsBeforeKick = 10,

    -- RU: Настройки rate limit для каждого сетевого события.
    -- EN: Rate limit settings for each network event.
    rateLimits = {
        -- RU: Ограничение для события готовности клиента.
        -- EN: Rate limit for the client readiness event.
        clientReady = {
            -- RU: Минимальный интервал между запросами в миллисекундах.
            -- EN: Minimum interval between requests in milliseconds.
            intervalMs = 3000,

            -- RU: Максимальное количество попыток в окне.
            -- EN: Maximum attempts within the window.
            maxAttempts = 3,

            -- RU: Размер окна в миллисекундах.
            -- EN: Window size in milliseconds.
            windowMs = 15000
        },

        -- RU: Ограничение для запроса спавна.
        -- EN: Rate limit for the spawn request.
        requestSpawn = {
            intervalMs = 5000,
            maxAttempts = 3,
            windowMs = 30000
        },

        -- RU: Ограничение для подтверждения спавна.
        -- EN: Rate limit for the spawn confirmation.
        confirmSpawn = {
            intervalMs = 2000,
            maxAttempts = 5,
            windowMs = 15000
        },

        -- RU: Ограничение для сообщения об ошибке клиента.
        -- EN: Rate limit for the client error report.
        reportClientError = {
            intervalMs = 1000,
            maxAttempts = 10,
            windowMs = 30000
        }
    }
}