-- RU: Сервис rate limit GreenCore.
-- EN: GreenCore rate limit service.

-- RU: Таблица сервиса rate limit.
-- EN: Rate limit service table.
GCRateLimit = {}

-- RU: Внутреннее хранилище данных rate limit.
-- EN: Internal rate limit data storage.
local rateData = {}

-- RU: Временные метки нарушений; записи вне окна удаляются.
-- EN: Violation timestamps; entries outside the configured window expire.
local violations = {}

local function pruneViolations(playerSource, now)
    local timestamps = violations[playerSource]

    if type(timestamps) ~= 'table' then
        return {}
    end

    local windowMs = GCConfig.Security.violationWindowMs or 60000
    local retained = {}

    for _, timestamp in ipairs(timestamps) do
        if now - timestamp <= windowMs then
            retained[#retained + 1] = timestamp
        end
    end

    violations[playerSource] = retained
    return retained
end

--- RU:
--- Проверяет, не превышен ли лимит для действия игрока.
---
--- EN:
--- Checks whether the limit for a player action is exceeded.
---
--- @param playerSource number FiveM server player source
--- @param actionName string Action name like "clientReady"
--- @return boolean allowed Whether the action is allowed
--- @return string|nil errorCode Error code
function GCRateLimit.Check(playerSource, actionName)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return false, 'GC-RATE-LIMIT-001'
    end

    if type(actionName) ~= 'string' then
        return false, 'GC-RATE-LIMIT-001'
    end

    -- RU: Получаем настройки лимита для действия.
    -- EN: Get the limit settings for the action.
    local limitConfig = GCConfig.Security.rateLimits[actionName]

    if not limitConfig then
        return true
    end

    -- RU: Получаем данные игрока.
    -- EN: Get the player data.
    local playerData = rateData[playerSource]

    if not playerData then
        return true
    end

    -- RU: Получаем данные действия.
    -- EN: Get the action data.
    local actionData = playerData[actionName]

    if not actionData then
        return true
    end

    local now = GCUtils.NowMs()

    -- RU: Проверяем минимальный интервал между запросами.
    -- EN: Check the minimum interval between requests.
    if actionData.lastRequestAt and (now - actionData.lastRequestAt) < limitConfig.intervalMs then
        return false, 'GC-RATE-LIMIT-001'
    end

    -- RU: Проверяем количество попыток в окне.
    -- EN: Check the number of attempts within the window.
    if actionData.attempts and actionData.windowStartAt then
        if (now - actionData.windowStartAt) <= limitConfig.windowMs then
            if actionData.attempts >= limitConfig.maxAttempts then
                return false, 'GC-RATE-LIMIT-001'
            end
        end
    end

    return true
end

--- RU:
--- Записывает факт выполнения действия игроком.
---
--- EN:
--- Records the fact that a player performed an action.
---
--- @param playerSource number FiveM server player source
--- @param actionName string Action name
function GCRateLimit.Record(playerSource, actionName)
    if type(playerSource) ~= 'number' then
        return
    end

    if type(actionName) ~= 'string' then
        return
    end

    local limitConfig = GCConfig.Security.rateLimits[actionName]

    if not limitConfig then
        return
    end

    local now = GCUtils.NowMs()

    -- RU: Инициализируем данные игрока.
    -- EN: Initialize the player data.
    if not rateData[playerSource] then
        rateData[playerSource] = {}
    end

    local playerData = rateData[playerSource]

    -- RU: Инициализируем данные действия.
    -- EN: Initialize the action data.
    if not playerData[actionName] then
        playerData[actionName] = {
            attempts = 0,
            windowStartAt = now,
            lastRequestAt = nil
        }
    end

    local actionData = playerData[actionName]

    -- RU: Сбрасываем окно, если оно истекло.
    -- EN: Reset the window if it has expired.
    if (now - actionData.windowStartAt) > limitConfig.windowMs then
        actionData.windowStartAt = now
        actionData.attempts = 0
    end

    -- RU: Увеличиваем счётчик попыток.
    -- EN: Increment the attempt counter.
    actionData.attempts = actionData.attempts + 1
    actionData.lastRequestAt = now
end

--- RU:
--- Сбрасывает данные rate limit для действия игрока.
---
--- EN:
--- Resets the rate limit data for a player action.
---
--- @param playerSource number FiveM server player source
--- @param actionName string Action name
function GCRateLimit.Reset(playerSource, actionName)
    if type(playerSource) ~= 'number' then
        return
    end

    if type(actionName) ~= 'string' then
        return
    end

    if rateData[playerSource] then
        rateData[playerSource][actionName] = nil
    end
end

--- RU:
--- Удаляет все данные rate limit игрока.
---
--- EN:
--- Removes all rate limit data for a player.
---
--- @param playerSource number FiveM server player source
function GCRateLimit.RemovePlayer(playerSource)
    if type(playerSource) ~= 'number' then
        return
    end

    rateData[playerSource] = nil
    violations[playerSource] = nil
end

--- RU:
--- Очищает все данные rate limit.
---
--- EN:
--- Clears all rate limit data.
function GCRateLimit.ClearAll()
    rateData = {}
    violations = {}
end

--- RU:
--- Регистрирует нарушение rate limit игроком.
---
--- EN:
--- Registers a rate limit violation by a player.
---
--- @param playerSource number FiveM server player source
--- @return boolean shouldKick Whether the player should be kicked
function GCRateLimit.RegisterViolation(playerSource)
    if type(playerSource) ~= 'number' then
        return false
    end

    local now = GCUtils.NowMs()
    local timestamps = pruneViolations(playerSource, now)
    timestamps[#timestamps + 1] = now
    violations[playerSource] = timestamps

    local maxViolations = GCConfig.Security.maxViolationsPerWindow or 10
    return #timestamps >= maxViolations
end

function GCRateLimit.GetViolationCount(playerSource)
    if type(playerSource) ~= 'number' then
        return 0
    end

    return #pruneViolations(playerSource, GCUtils.NowMs())
end
