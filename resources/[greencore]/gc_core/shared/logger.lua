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

    local formatted = formatMessage(level, errorCode, message, data)

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