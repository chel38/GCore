-- RU: Провайдер модели педа GreenCore.
-- EN: GreenCore ped model provider.

-- RU: Провайдер отделяет "КАК выбрать модель" от "КАК заспавнить игрока".
-- RU: Сегодня реализован случайный выбор из белого списка. В будущем здесь можно
-- RU: подключить систему персонажа (gc_appearance / character model) без
-- RU: переписывания GCSpawn и всего lifecycle спавна.
-- EN: The provider separates "HOW to choose a model" from "HOW to spawn a player".
-- EN: Today it implements random selection from a whitelist. In the future this can
-- EN: plug into a character system (gc_appearance / character model) without
-- EN: rewriting GCSpawn and the entire spawn lifecycle.

-- RU: Таблица провайдера педа.
-- EN: Ped provider table.
GCPedProvider = {}

-- RU: Список чувствительных/недопустимых моделей. На первой версии пустой,
-- RU: но здесь удобно фиксировать решения о том, что нельзя использовать.
-- EN: List of sensitive or invalid models. Empty in the first version, but a good
-- EN: place to record decisions about what must not be used.
local forbiddenSuffixes = {}

-- RU: Кэш валидности списка моделей. Пересчитывается при изменении конфигурации.
-- EN: Cache of the model list validity. Recalculated when the configuration changes.
local modelCache = nil

-- RU: Флаг, что конфигурация уже была проверена.
-- EN: Flag that the configuration has already been validated.
local configValidated = false

--- RU:
--- Проверяет корректность конфигурации белого списка ped.
--- Минимальные требования: models существует, является table, не пуст,
--- каждая запись string, нет пустых строк, нет дубликатов.
--- При ошибке логируется предупреждение, но сервер не останавливается
--- (используется fallback ped).
---
--- EN:
--- Validates the ped whitelist configuration.
--- Minimum requirements: models exists, is a table, is not empty, each entry is a
--- string, no empty strings, no duplicates.
--- On error a warning is logged, but the server is not stopped
--- (the fallback ped is used instead).
---
--- @return table models Valid model names list
--- @return string|nil errorCode Error code if the list is invalid
function GCPedProvider.ValidateConfig()
    -- RU: Если конфигурация уже проверена, возвращаем кэшированный результат.
    -- EN: If the configuration was already validated, return the cached result.
    if configValidated then
        return modelCache, nil
    end

    configValidated = true

    local randomPed = GCConfig.Spawn.randomPed

    -- RU: Проверяем, что randomPed является таблицей.
    -- EN: Verify that randomPed is a table.
    if type(randomPed) ~= 'table' then
        GCLogger.Warn('GC-SPAWN-PED-CONFIG-001', 'randomPed config is not a table, using fallback ped')
        modelCache = {}
        return modelCache, 'GC-SPAWN-PED-CONFIG-001'
    end

    -- RU: Проверяем, что models является таблицей.
    -- EN: Verify that models is a table.
    local models = randomPed.models

    if type(models) ~= 'table' then
        GCLogger.Warn('GC-SPAWN-PED-CONFIG-001', 'randomPed.models is not a table, using fallback ped')
        modelCache = {}
        return modelCache, 'GC-SPAWN-PED-CONFIG-001'
    end

    -- RU: Собираем только валидные записи (непустые строки, без дубликатов).
    -- EN: Collect only valid entries (non-empty strings, no duplicates).
    local seen = {}
    local validModels = {}

    for _, model in ipairs(models) do
        -- RU: Запись должна быть непустой строкой.
        -- EN: The entry must be a non-empty string.
        if type(model) ~= 'string'
            or #model == 0
            or #model > GCConstants.maxPedModelLength
            or not GCPedProvider.IsModelAllowed(model) then
            GCLogger.Warn('GC-SPAWN-PED-INVALID-001', 'Invalid model entry in whitelist, skipped', {
                model = tostring(model)
            })
        elseif seen[model] then
            -- RU: Отбрасываем дубликат.
            -- EN: Drop the duplicate.
            GCLogger.Warn('GC-SPAWN-PED-INVALID-001', 'Duplicate model in whitelist, skipped', {
                model = model
            })
        else
            seen[model] = true
            table.insert(validModels, model)
        end
    end

    -- RU: Если валидных записей нет, возвращаем пустой список (будет fallback).
    -- EN: If there are no valid entries, return an empty list (fallback will be used).
    if #validModels == 0 then
        GCLogger.Warn('GC-SPAWN-PED-CONFIG-001', 'Ped whitelist is empty, using fallback ped')
        modelCache = {}
        return modelCache, 'GC-SPAWN-PED-CONFIG-001'
    end

    modelCache = validModels
    return modelCache, nil
end

--- RU:
--- Сбрасывает кэш валидации конфигурации.
--- Полезен для тестов и потенциального hot-reload конфигурации, чтобы
--- провайдер перечитал список моделей заново.
---
--- EN:
--- Resets the configuration validation cache.
--- Useful for tests and potential config hot-reload so the provider re-reads
--- the model list.
function GCPedProvider.ResetConfigCache()
    configValidated = false
    modelCache = nil
end

--- RU:
--- Возвращает валидный белый список моделей педа.
--- Если список пуст или невалиден, возвращается пустой список.
--- Реальный fallback применяется вызывающей стороной (GCSpawn).
---
--- EN:
--- Returns a valid ped model whitelist.
--- If the list is empty or invalid, an empty list is returned.
--- The actual fallback is applied by the caller (GCSpawn).
---
--- @return table models Valid model names list
function GCPedProvider.GetModels()
    local models, _ = GCPedProvider.ValidateConfig()
    return models
end

--- RU:
--- Проверяет, можно ли использовать модель (не входит в запрещённые категории).
--- На первой версии запрещённые суффиксы не заданы, но метод оставлен для
--- будущих правил безопасности.
---
--- EN:
--- Checks whether a model may be used (not in a forbidden category).
--- In the first version no forbidden suffixes are set, but the method is kept
--- for future safety rules.
---
--- @param modelName string Model name
--- @return boolean allowed Whether the model is allowed
function GCPedProvider.IsModelAllowed(modelName)
    if type(modelName) ~= 'string' then
        return false
    end

    for _, suffix in ipairs(forbiddenSuffixes) do
        if modelName:find(suffix, 1, true) then
            return false
        end
    end

    return true
end

--- RU:
--- Разрешает модель педа для игрока.
--- Сегодня: случайный выбор из белого списка с защитой от немедленного повтора.
--- В будущем: модель персонажа из gc_appearance.
---
--- EN:
--- Resolves the ped model for a player.
--- Today: random selection from a whitelist with immediate-repeat protection.
--- In the future: a character model from gc_appearance.
---
--- @param playerSource number FiveM server player source
--- @param session table Player session
--- @param excludedModels table|nil Set of models already attempted by this session
--- @return table|nil pedDefinition Table with name (and hash if available)
--- @return string|nil errorCode Error code
function GCPedProvider.Resolve(playerSource, session, excludedModels)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SPAWN-PED-INVALID-001'
    end

    -- RU: Если случайный выбор отключён, используем fallback ped.
    -- EN: If random selection is disabled, use the fallback ped.
    local randomPed = GCConfig.Spawn.randomPed

    excludedModels = type(excludedModels) == 'table' and excludedModels or {}

    if type(randomPed) ~= 'table' or not randomPed.enabled then
        local fallback = GCPedProvider.ResolveFallback()
        return excludedModels[fallback.name] and nil or fallback,
            excludedModels[fallback.name] and 'GC-SPAWN-PED-EXHAUSTED-001' or nil
    end

    local models = GCPedProvider.GetModels()

    -- RU: Если список пуст, используем fallback ped.
    -- EN: If the list is empty, use the fallback ped.
    local candidates = {}

    for _, modelName in ipairs(models) do
        if not excludedModels[modelName]
            and (not randomPed.avoidImmediateRepeat or not session or session.lastPed ~= modelName) then
            candidates[#candidates + 1] = modelName
        end
    end

    if #candidates == 0 and session and session.lastPed then
        for _, modelName in ipairs(models) do
            if not excludedModels[modelName] then
                candidates[#candidates + 1] = modelName
            end
        end
    end

    if #candidates == 0 then
        local fallback = GCPedProvider.ResolveFallback()

        if excludedModels[fallback.name] then
            return nil, 'GC-SPAWN-PED-EXHAUSTED-001'
        end

        return fallback
    end

    -- RU: Выбираем случайный индекс. Для выбора педа криптографическая
    -- RU: случайность не требуется (см. раздел "Random PED и Random generator").
    -- EN: Pick a random index. Cryptographic randomness is not required for
    -- EN: picking a ped (see "Random PED and Random generator" section).
    local selectedModel = candidates[math.random(1, #candidates)]

    -- RU: Формируем определение педа. Hash вычисляется сервером, если доступен joaat.
    -- EN: Build the ped definition. The hash is computed server-side if joaat is available.
    local hash = nil

    if type(joaat) == 'function' then
        hash = joaat(selectedModel)
    end

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseSpawn then
        GCLogger.Debug('GC-SPAWN-PED-100', 'Random PED selected', {
            source = playerSource,
            ped = selectedModel
        })
    end

    return {
        name = selectedModel,
        hash = hash
    }
end

--- RU:
--- Возвращает определение fallback ped из конфигурации.
---
--- EN:
--- Returns the fallback ped definition from the configuration.
---
--- @return table pedDefinition Fallback ped definition
function GCPedProvider.ResolveFallback()
    local fallbackName = GCConfig.Spawn.fallbackPed or 'mp_m_freemode_01'

    local hash = nil

    if type(joaat) == 'function' then
        hash = joaat(fallbackName)
    end

    return {
        name = fallbackName,
        hash = hash
    }
end
