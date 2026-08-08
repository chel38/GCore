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

    -- RU: Максимальное время ожидания готовности клиента в миллисекундах.
    -- EN: Maximum client readiness wait time in milliseconds.
    clientReadyTimeoutMs = 30000
}