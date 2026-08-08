-- RU: Утилиты GreenCore.
-- EN: GreenCore utilities.

-- RU: Таблица утилит ядра.
-- EN: Core utilities table.
GCUtils = {}

--- RU:
--- Проверяет, является ли значение числом.
---
--- EN:
--- Checks whether a value is a number.
---
--- @param value any Value to check
--- @return boolean isNumber Whether the value is a number
function GCUtils.IsNumber(value)
    return type(value) == 'number'
end

--- RU:
--- Проверяет, является ли значение целым числом.
---
--- EN:
--- Checks whether a value is an integer.
---
--- @param value any Value to check
--- @return boolean isInteger Whether the value is an integer
function GCUtils.IsInteger(value)
    return type(value) == 'number' and math.floor(value) == value
end

--- RU:
--- Проверяет, является ли значение непустой строкой.
---
--- EN:
--- Checks whether a value is a non-empty string.
---
--- @param value any Value to check
--- @return boolean isNonEmptyString Whether the value is a non-empty string
function GCUtils.IsNonEmptyString(value)
    return type(value) == 'string' and #value > 0
end

--- RU:
--- Проверяет, является ли значение булевым.
---
--- EN:
--- Checks whether a value is a boolean.
---
--- @param value any Value to check
--- @return boolean isBoolean Whether the value is a boolean
function GCUtils.IsBoolean(value)
    return type(value) == 'boolean'
end

--- RU:
--- Проверяет, является ли значение таблицей.
---
--- EN:
--- Checks whether a value is a table.
---
--- @param value any Value to check
--- @return boolean isTable Whether the value is a table
function GCUtils.IsTable(value)
    return type(value) == 'table'
end

--- RU:
--- Проверяет, является ли значение nil.
---
--- EN:
--- Checks whether a value is nil.
---
--- @param value any Value to check
--- @return boolean isNil Whether the value is nil
function GCUtils.IsNil(value)
    return value == nil
end

--- RU:
--- Проверяет, находится ли число в заданном диапазоне (включительно).
---
--- EN:
--- Checks whether a number is within a given range (inclusive).
---
--- @param value number Value to check
--- @param min number Minimum value
--- @param max number Maximum value
--- @return boolean inRange Whether the value is in range
function GCUtils.IsInRange(value, min, max)
    if type(value) ~= 'number' then
        return false
    end

    return value >= min and value <= max
end

--- RU:
--- Проверяет, находится ли строка в заданном диапазоне длины (включительно).
---
--- EN:
--- Checks whether a string length is within a given range (inclusive).
---
--- @param value string String to check
--- @param min number Minimum length
--- @param max number Maximum length
--- @return boolean inRange Whether the length is in range
function GCUtils.IsStringLengthInRange(value, min, max)
    if type(value) ~= 'string' then
        return false
    end

    local length = #value

    return length >= min and length <= max
end

--- RU:
--- Проверяет, содержится ли значение в списке.
---
--- EN:
--- Checks whether a value is contained in a list.
---
--- @param list table List of values
--- @param value any Value to look for
--- @return boolean contains Whether the value is in the list
function GCUtils.Contains(list, value)
    if type(list) ~= 'table' then
        return false
    end

    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end

    return false
end

--- RU:
--- Возвращает текущее время в миллисекундах.
---
--- EN:
--- Returns the current time in milliseconds.
---
--- @return number timeMs Current time in milliseconds
function GCUtils.NowMs()
    return GetGameTimer()
end

--- RU:
--- Возвращает текущее время в секундах.
---
--- EN:
--- Returns the current time in seconds.
---
--- @return number timeSec Current time in seconds
function GCUtils.NowSec()
    return os.time()
end

--- RU:
--- Генерирует случайный идентификатор на чистом Lua.
---
--- EN:
--- Generates a random identifier in pure Lua.
---
--- @param prefix string Prefix for the identifier
--- @return string identifier Generated identifier
function GCUtils.GenerateId(prefix)
    local randomPart = ''

    for _ = 1, 16 do
        randomPart = randomPart .. string.format('%02x', math.random(0, 255))
    end

    return ('%s:%s'):format(prefix, randomPart)
end

--- RU:
--- Генерирует UUID-подобный идентификатор на чистом Lua.
---
--- EN:
--- Generates a UUID-like identifier in pure Lua.
---
--- @param prefix string Prefix for the identifier
--- @return string identifier Generated identifier
function GCUtils.GenerateUuid(prefix)
    local function randomHex(length)
        local result = ''

        for _ = 1, length do
            result = result .. string.format('%x', math.random(0, 15))
        end

        return result
    end

    local uuid = ('%s-%s-%s-%s-%s'):format(
        randomHex(8),
        randomHex(4),
        randomHex(4),
        randomHex(4),
        randomHex(12)
    )

    return ('%s:%s'):format(prefix, uuid)
end

--- RU:
--- Безопасно копирует таблицу (неглубокое копирование).
---
--- EN:
--- Safely copies a table (shallow copy).
---
--- @param source table Source table
--- @return table copy Copied table
function GCUtils.ShallowCopy(source)
    if type(source) ~= 'table' then
        return nil
    end

    local copy = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

--- RU:
--- Безопасно копирует таблицу (глубокое копирование).
---
--- EN:
--- Safely copies a table (deep copy).
---
--- @param source table Source table
--- @return table copy Copied table
function GCUtils.DeepCopy(source)
    if type(source) ~= 'table' then
        return source
    end

    local copy = {}

    for key, value in pairs(source) do
        if type(value) == 'table' then
            copy[key] = GCUtils.DeepCopy(value)
        else
            copy[key] = value
        end
    end

    return copy
end

--- RU:
--- Ограничивает строку до заданной максимальной длины.
---
--- EN:
--- Truncates a string to a given maximum length.
---
--- @param value string String to truncate
--- @param maxLength number Maximum length
--- @return string truncated Truncated string
function GCUtils.Truncate(value, maxLength)
    if type(value) ~= 'string' then
        return ''
    end

    if #value <= maxLength then
        return value
    end

    return value:sub(1, maxLength)
end