-- RU: Константы GreenCore.
-- EN: GreenCore constants.

-- RU: Таблица констант ядра.
-- EN: Core constants table.
GCConstants = {
    -- RU: Имя ресурса ядра.
    -- EN: Core resource name.
    resourceName = 'gc_core',

    -- RU: Префикс namespace для всех сетевых событий.
    -- EN: Namespace prefix for all network events.
    eventPrefix = 'gc_core',

    -- RU: Префикс для идентификаторов сессий.
    -- EN: Prefix for session identifiers.
    sessionPrefix = 'gc:session',

    -- RU: Префикс для идентификаторов решений о спавне.
    -- EN: Prefix for spawn decision identifiers.
    spawnPrefix = 'gc:spawn',

    -- RU: Максимальная длина имени игрока.
    -- EN: Maximum player name length.
    maxPlayerNameLength = 64,

    -- RU: Минимальная длина имени игрока.
    -- EN: Minimum player name length.
    minPlayerNameLength = 1,

    -- RU: Максимальная длина версии клиента.
    -- EN: Maximum client version length.
    maxClientVersionLength = 32,

    -- RU: Максимальная длина кода локали.
    -- EN: Maximum locale code length.
    maxLocaleLength = 8,

    -- RU: Максимальная длина идентификатора.
    -- EN: Maximum identifier length.
    maxIdentifierLength = 128,

    -- RU: Максимальная длина причины ошибки.
    -- EN: Maximum error reason length.
    maxErrorReasonLength = 256,

    -- RU: Список поддерживаемых типов идентификаторов.
    -- EN: List of supported identifier types.
    identifierTypes = {
        'license',
        'license2',
        'fivem',
        'discord',
        'steam',
        'xbl',
        'live',
        'ip'
    },

    -- RU: Основной тип идентификатора.
    -- EN: Primary identifier type.
    primaryIdentifierType = 'license',

    -- RU: Запасной тип идентификатора.
    -- EN: Fallback identifier type.
    fallbackIdentifierType = 'license2'
}