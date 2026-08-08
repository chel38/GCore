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

    -- RU: Запасной ped, используемый, когда случайный список пуст или модель не загружается.
    -- EN: Fallback ped used when the random list is empty or a model fails to load.
    fallbackPed = 'mp_m_freemode_01',

    -- RU: Настройки случайного выбора модели педа.
    -- RU: Выбор модели всегда выполняет сервер; клиент получает уже готовое решение.
    -- EN: Random ped model selection settings.
    -- EN: The server always chooses the model; the client receives the finished decision.
    randomPed = {
        -- RU: Включён ли случайный выбор модели.
        -- EN: Whether random model selection is enabled.
        enabled = true,

        -- RU: Избегать немедленного повтора одной и той же модели подряд.
        -- EN: Avoid repeating the same model immediately.
        avoidImmediateRepeat = true,

        -- RU: Явно заданный белый список моделей. Только эти модели могут быть выбраны.
        -- EN: Explicit whitelist of models. Only these models may be selected.
        models = {
            'a_m_y_business_01',
            'a_m_y_business_02',
            'a_m_y_business_03',

            'a_m_y_hipster_01',
            'a_m_y_hipster_02',
            'a_m_y_hipster_03',

            'a_m_y_beach_01',
            'a_m_y_beach_02',

            'a_m_m_business_01',

            'a_f_y_business_01',
            'a_f_y_business_02',
            'a_f_y_business_03',
            'a_f_y_business_04',

            'a_f_y_hipster_01',
            'a_f_y_hipster_02',
            'a_f_y_hipster_03',
            'a_f_y_hipster_04',

            'a_f_y_beach_01'
        }
    },

    -- RU: Настройки повторных попыток спавна.
    -- RU: Повтор выполняется только по решению сервера, чтобы не создать бесконечный цикл.
    -- EN: Spawn retry settings.
    -- EN: Retries are executed only on server decision to avoid an infinite loop.
    retry = {
        -- RU: Включены ли повторные попытки.
        -- EN: Whether retries are enabled.
        enabled = true,

        -- RU: Общий предел решений, включая первоначальное.
        -- EN: Total decision limit, including the initial one.
        maxTotalAttempts = 4,

        -- RU: Отдельные пределы повторов той же и другой модели.
        -- EN: Separate limits for same-model and different-model retries.
        maxSamePedRetries = 1,
        maxDifferentPedRetries = 2,

        -- RU: Задержка между попытками в миллисекундах.
        -- EN: Delay between attempts in milliseconds.
        delayMs = 1000,

        -- RU: Старые имена удалены: все ограничения имеют однозначную семантику.
        -- EN: Legacy names are removed; every limit now has explicit semantics.
    },

    -- RU: Серверная проверка ped и позиции после клиентского confirmSpawn.
    -- EN: Server-side ped and position verification after client confirmSpawn.
    verification = {
        enabled = true,
        timeoutMs = 3000,
        intervalMs = 100,
        maxAttempts = 31,
        positionTolerance = 8.0,
        minimumHealth = 1
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

    -- RU: Тайм-аут затемнения экрана в миллисекундах.
    -- EN: Screen fade-out timeout in milliseconds.
    fadeOutTimeoutMs = 2000,

    -- RU: Длительность затемнения экрана в миллисекундах.
    -- EN: Screen fade-out duration in milliseconds.
    fadeOutDurationMs = 500,

    -- RU: Длительность появления изображения в миллисекундах.
    -- EN: Screen fade-in duration in milliseconds.
    fadeInDurationMs = 1000
}
