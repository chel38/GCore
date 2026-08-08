-- RU: Конфигурация диагностического режима GreenCore.
-- EN: GreenCore diagnostics mode configuration.

-- RU: Корневая таблица конфигурации.
-- EN: Root configuration table.
GCConfig = GCConfig or {}

-- RU: Настройки диагностики.
-- EN: Diagnostics settings.
GCConfig.Diagnostics = {
    -- RU: Включает ли диагностический режим в целом.
    -- EN: Whether the diagnostics mode is enabled overall.
    enabled = false,

    -- RU: Подробный вывод по подключению.
    -- EN: Verbose connection output.
    verboseConnection = false,

    -- RU: Подробный вывод по состояниям.
    -- EN: Verbose state output.
    verboseStates = false,

    -- RU: Подробный вывод по событиям.
    -- EN: Verbose event output.
    verboseEvents = false,

    -- RU: Подробный вывод по спавну.
    -- EN: Verbose spawn output.
    verboseSpawn = false,

    -- RU: Подробный вывод по rate limit.
    -- EN: Verbose rate limit output.
    verboseRateLimit = false,

    -- RU: Печатать ли маскированные идентификаторы.
    -- EN: Whether to print masked identifiers.
    printMaskedIdentifiers = false
}