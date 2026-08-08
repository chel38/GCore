-- RU: Конфигурация системы спавна игрока.
-- EN: Player spawn system configuration.

-- RU: Корневая таблица конфигурации.
-- EN: Root configuration table.
GCConfig = GCConfig or {}

-- RU: Настройки спавна.
-- EN: Spawn settings.
GCConfig.Spawn = {
    -- RU: Точка спавна по умолчанию. Координаты не жёстко прописаны в логике.
    -- EN: Default spawn point. Coordinates are not hardcoded in the logic.
    default = {
        -- RU: Координата X.
        -- EN: X coordinate.
        x = -1037.65,

        -- RU: Координата Y.
        -- EN: Y coordinate.
        y = -2737.72,

        -- RU: Координата Z.
        -- EN: Z coordinate.
        z = 20.17,

        -- RU: Направление взгляда в градусах.
        -- EN: Heading in degrees.
        heading = 329.0,

        -- RU: Модель педа игрока по умолчанию.
        -- EN: Default player ped model.
        model = `mp_m_freemode_01`
    },

    -- RU: Время жизни решения о спавне в миллисекундах.
    -- EN: Spawn decision lifetime in milliseconds.
    decisionLifetimeMs = 30000,

    -- RU: Тайм-аут загрузки модели в миллисекундах.
    -- EN: Model load timeout in milliseconds.
    modelLoadTimeoutMs = 10000,

    -- RU: Тайм-аут загрузки коллизии в миллисекундах.
    -- EN: Collision load timeout in milliseconds.
    collisionLoadTimeoutMs = 10000,

    -- RU: Тайм-аут клиентского спавна в миллисекундах.
    -- EN: Client spawn timeout in milliseconds.
    clientSpawnTimeoutMs = 20000,

    -- RU: Длительность затемнения экрана в миллисекундах.
    -- EN: Screen fade-out duration in milliseconds.
    fadeOutDurationMs = 500,

    -- RU: Длительность появления изображения в миллисекундах.
    -- EN: Screen fade-in duration in milliseconds.
    fadeInDurationMs = 1000
}