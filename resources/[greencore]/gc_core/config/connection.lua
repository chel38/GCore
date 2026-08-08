-- RU: Конфигурация проверки подключения игрока.
-- EN: Player connection validation configuration.

-- RU: Корневая таблица конфигурации.
-- EN: Root configuration table.
GCConfig = GCConfig or {}

-- RU: Настройки проверки подключения.
-- EN: Connection validation settings.
GCConfig.Connection = {
    -- RU: Требовать ли наличие обязательного идентификатора license.
    -- EN: Whether the mandatory license identifier is required.
    requireLicense = true,

    -- RU: Разрешить ли использовать license2 как запасной идентификатор.
    -- EN: Whether to allow license2 as a fallback identifier.
    allowLicense2Fallback = true,

    -- RU: Отклонять ли повторное подключение с тем же license.
    -- EN: Whether to reject a duplicate connection with the same license.
    rejectDuplicateLicense = true,

    -- RU: Максимальное время ожидания deferrals в миллисекундах.
    -- EN: Maximum deferral wait time in milliseconds.
    deferralTimeoutMs = 15000,

    -- RU: Максимальное время жизни pending connection в миллисекундах.
    -- RU: Если за это время не произошёл playerJoining, pending connection удаляется.
    -- EN: Maximum lifetime of a pending connection in milliseconds.
    -- EN: If playerJoining does not occur within this time, the pending connection is removed.
    pendingConnectionLifetimeMs = 60000,

    -- RU: Максимальное время ожидания готовности клиента в миллисекундах.
    -- EN: Maximum client readiness wait time in milliseconds.
    clientReadyTimeoutMs = 30000,

    -- RU: Интервал и лимит повторов client hello до server ACK.
    -- EN: Client hello retry interval and limit until a server ACK arrives.
    clientHelloRetryIntervalMs = 6000,
    clientHelloMaxAttempts = 5,

    -- RU: Максимальное ожидание handshake после рестарта ресурса.
    -- EN: Maximum handshake wait after a resource restart.
    resyncReadyTimeoutMs = 15000,

    -- RU: forceResync является только подсказкой. Клиент также сам отправляет
    -- RU: clientReady при старте, поэтому потеря server push не блокирует recovery.
    -- EN: forceResync is only a prompt. The client also sends clientReady on start,
    -- EN: so losing a server push cannot block recovery.
    resyncForceMaxAttempts = 3,
    resyncForceIntervalMs = 1500
}
