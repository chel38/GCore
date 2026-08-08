-- RU: Сервис логирования GreenCore.
-- EN: GreenCore logging service.

-- RU: Таблица сервиса логирования.
-- EN: Logging service table.
GCLogger = {}

-- RU: Уровни логирования и их числовые значения.
-- EN: Logging levels and their numeric values.
local LEVELS = {
    TRACE = 10,
    DEBUG = 20,
    INFO = 30,
    WARN = 40,
    ERROR = 50,
    CRITICAL = 60
}

-- RU: Порядок уровней для сравнения.
-- EN: Level order for comparison.
local LEVEL_ORDER = {
    'TRACE',
    'DEBUG',
    'INFO',
    'WARN',
    'ERROR',
    'CRITICAL'
}

-- RU: Список чувствительных ключей, значения которых маскируются автоматически.
-- RU: Это защищает от случайной утечки идентификаторов в логах, даже если
-- RU: разработчик забыл вызвать маскирование вручную.
-- EN: List of sensitive keys whose values are masked automatically.
-- EN: This protects against accidental identifier leaks in logs even when a
-- EN: developer forgets to call masking manually.
local SENSITIVE_KEYS = {
    license = true,
    license2 = true,
    ip = true,
    discord = true,
    identifiers = true,
    primaryIdentifier = true,
    token = true,
    steam = true,
    xbl = true,
    live = true
}

--- RU:
--- Проверяет, является ли ключ чувствительным.
---
--- EN:
--- Checks whether a key is sensitive.
---
--- @param key string Key to check
--- @return boolean sensitive Whether the key is sensitive
local function isSensitiveKey(key)
    return SENSITIVE_KEYS[tostring(key)] == true
end

--- RU:
--- Маскирует строку, сохраняя только первые и последние символы.
--- Если маскирование отключено конфигурацией, значение возвращается без изменений.
---
--- EN:
--- Masks a string, keeping only the first and last characters.
--- If masking is disabled by configuration, the value is returned unchanged.
---
--- @param value any Value to mask
--- @return string masked Masked value
local function maskValue(value)
    local maskEnabled = GCConfig.Logging and GCConfig.Logging.maskSensitiveData

    -- RU: Если маскирование выключено, возвращаем строковое представление.
    -- EN: If masking is disabled, return the string representation.
    if not maskEnabled then
        return tostring(value)
    end

    local valueString = tostring(value)

    -- RU: Слишком короткие значения маскируем полностью.
    -- EN: Mask very short values entirely.
    if #valueString <= 8 then
        return '****'
    end

    -- RU: Оставляем первые 4 и последние 4 символа.
    -- EN: Keep the first 4 and last 4 characters.
    local firstPart = valueString:sub(1, 4)
    local lastPart = valueString:sub(-4)
    local middleLength = #valueString - 8

    return firstPart .. string.rep('*', middleLength) .. lastPart
end

--- RU:
--- Санитизирует таблицу данных перед логированием.
--- Рекурсивно обходит вложенные таблицы и маскирует чувствительные ключи.
---
--- EN:
--- Sanitizes a data table before logging.
--- Recursively walks nested tables and masks sensitive keys.
---
--- @param data table Data table to sanitize
--- @return table sanitized Sanitized copy of the data
local function sanitizeData(data)
    local sanitized = {}

    for key, value in pairs(data) do
        -- RU: Если значение вложенная таблица, обрабатываем её рекурсивно.
        -- EN: If the value is a nested table, process it recursively.
        if type(value) == 'table' then
            sanitized[key] = sanitizeData(value)
        elseif isSensitiveKey(key) then
            -- RU: Маскируем чувствительные значения.
            -- EN: Mask sensitive values.
            sanitized[key] = maskValue(value)
        else
            sanitized[key] = value
        end
    end

    return sanitized
end

--- RU:
--- Проверяет, разрешён ли уровень логирования конфигурацией.
---
--- EN:
--- Checks whether a logging level is allowed by the configuration.
---
--- @param level string Logging level
--- @return boolean allowed Whether the level is allowed
local function isLevelAllowed(level)
    local configLevel = GCConfig.Logging.level or 'INFO'
    local configValue = LEVELS[configLevel] or LEVELS.INFO
    local levelValue = LEVELS[level] or LEVELS.INFO

    return levelValue >= configValue
end

--- RU:
--- Форматирует сообщение лога.
---
--- EN:
--- Formats a log message.
---
--- @param level string Logging level
--- @param errorCode string Error code
--- @param message string Message
--- @param data table|nil Additional data
--- @return string formatted Formatted message
local function formatMessage(level, errorCode, message, data)
    local parts = {}

    -- RU: Добавляем префикс GreenCore.
    -- EN: Add the GreenCore prefix.
    table.insert(parts, '[GreenCore]')

    -- RU: Добавляем уровень.
    -- EN: Add the level.
    table.insert(parts, '[' .. level .. ']')

    -- RU: Добавляем код ошибки.
    -- EN: Add the error code.
    if errorCode then
        table.insert(parts, '[' .. errorCode .. ']')
    end

    -- RU: Добавляем сообщение.
    -- EN: Add the message.
    table.insert(parts, message)

    -- RU: Добавляем дополнительные данные.
    -- EN: Add additional data.
    if type(data) == 'table' then
        local dataParts = {}

        for key, value in pairs(data) do
            table.insert(dataParts, tostring(key) .. '=' .. tostring(value))
        end

        if #dataParts > 0 then
            table.insert(parts, '| ' .. table.concat(dataParts, ', '))
        end
    end

    return table.concat(parts, ' ')
end

--- RU:
--- Записывает сообщение лога с заданным уровнем.
---
--- EN:
--- Writes a log message with the given level.
---
--- @param level string Logging level
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Log(level, errorCode, message, data)
    if not isLevelAllowed(level) then
        return
    end

    -- RU: Санитизируем данные автоматически, чтобы чувствительные значения
    -- RU: (license, ip, discord и т.д.) не попадали в лог в открытом виде.
    -- EN: Sanitize the data automatically so sensitive values
    -- EN: (license, ip, discord, etc.) never reach the log in plain text.
    local safeData = data

    if type(data) == 'table' then
        safeData = sanitizeData(data)
    end

    local formatted = formatMessage(level, errorCode, message, safeData)

    -- RU: Выводим в консоль.
    -- EN: Print to console.
    print(formatted)
end

--- RU:
--- Записывает TRACE-сообщение.
---
--- EN:
--- Writes a TRACE message.
---
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Trace(errorCode, message, data)
    GCLogger.Log('TRACE', errorCode, message, data)
end

--- RU:
--- Записывает DEBUG-сообщение.
---
--- EN:
--- Writes a DEBUG message.
---
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Debug(errorCode, message, data)
    GCLogger.Log('DEBUG', errorCode, message, data)
end

--- RU:
--- Записывает INFO-сообщение.
---
--- EN:
--- Writes an INFO message.
---
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Info(errorCode, message, data)
    GCLogger.Log('INFO', errorCode, message, data)
end

--- RU:
--- Записывает WARN-сообщение.
---
--- EN:
--- Writes a WARN message.
---
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Warn(errorCode, message, data)
    GCLogger.Log('WARN', errorCode, message, data)
end

--- RU:
--- Записывает ERROR-сообщение.
---
--- EN:
--- Writes an ERROR message.
---
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Error(errorCode, message, data)
    GCLogger.Log('ERROR', errorCode, message, data)
end

--- RU:
--- Записывает CRITICAL-сообщение.
---
--- EN:
--- Writes a CRITICAL message.
---
--- @param errorCode string|nil Error code
--- @param message string Message
--- @param data table|nil Additional data
function GCLogger.Critical(errorCode, message, data)
    GCLogger.Log('CRITICAL', errorCode, message, data)
end

-- RU: Экспортируем список уровней для диагностики.
-- EN: Export the level list for diagnostics.
GCLogger.LEVELS = LEVEL_ORDER