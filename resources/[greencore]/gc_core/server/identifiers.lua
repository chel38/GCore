-- RU: Сервис идентификаторов игрока GreenCore.
-- EN: GreenCore player identifier service.

-- RU: Таблица сервиса идентификаторов.
-- EN: Identifier service table.
GCIdentifiers = {}

--- RU:
--- Маскирует идентификатор, оставляя только первые и последние символы.
---
--- EN:
--- Masks an identifier, keeping only the first and last characters.
---
--- @param identifier string Identifier to mask
--- @return string masked Masked identifier
function GCIdentifiers.Mask(identifier)
    if type(identifier) ~= 'string' then
        return '<invalid>'
    end

    -- RU: Находим разделитель типа и значения.
    -- EN: Find the type/value separator.
    local separatorIndex = identifier:find(':')

    if not separatorIndex then
        return '<invalid>'
    end

    local idType = identifier:sub(1, separatorIndex)
    local idValue = identifier:sub(separatorIndex + 1)

    -- RU: Если значение слишком короткое, маскируем полностью.
    -- EN: If the value is too short, mask it entirely.
    if #idValue <= 8 then
        return idType .. '****'
    end

    -- RU: Оставляем первые 4 и последние 4 символа значения.
    -- EN: Keep the first 4 and last 4 characters of the value.
    local firstPart = idValue:sub(1, 4)
    local lastPart = idValue:sub(-4)
    local middleLength = #idValue - 8

    return idType .. firstPart .. string.rep('*', middleLength) .. lastPart
end

--- RU:
--- Собирает все идентификаторы игрока.
---
--- EN:
--- Collects all identifiers of a player.
---
--- @param playerSource number FiveM server player source
--- @return table identifiers Table of identifiers
function GCIdentifiers.GetAll(playerSource)
    local identifiers = {}

    -- RU: Проверяем корректность source.
    -- EN: Validate the source.
    if type(playerSource) ~= 'number' then
        return identifiers
    end

    -- RU: Получаем все идентификаторы через FiveM API.
    -- EN: Get all identifiers through the FiveM API.
    local rawIdentifiers = GetPlayerIdentifiers(playerSource)

    if type(rawIdentifiers) ~= 'table' then
        return identifiers
    end

    -- RU: Разбираем каждый идентификатор.
    -- EN: Parse each identifier.
    for _, rawIdentifier in ipairs(rawIdentifiers) do
        local separatorIndex = rawIdentifier:find(':')

        if separatorIndex then
            local idType = rawIdentifier:sub(1, separatorIndex - 1)
            local idValue = rawIdentifier:sub(separatorIndex + 1)

            identifiers[idType] = idType .. ':' .. idValue
        end
    end

    return identifiers
end

--- RU:
--- Возвращает идентификатор игрока по типу.
---
--- EN:
--- Returns a player identifier by type.
---
--- @param playerSource number FiveM server player source
--- @param identifierType string Identifier type like "license"
--- @return string|nil identifier Identifier value
function GCIdentifiers.GetByType(playerSource, identifierType)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil
    end

    if type(identifierType) ~= 'string' then
        return nil
    end

    local identifiers = GCIdentifiers.GetAll(playerSource)

    return identifiers[identifierType]
end

--- RU:
--- Возвращает основной идентификатор игрока (license или license2).
---
--- EN:
--- Returns the primary identifier of a player (license or license2).
---
--- @param playerSource number FiveM server player source
--- @return string|nil primaryIdentifier Primary identifier
--- @return string|nil primaryType Primary identifier type
function GCIdentifiers.GetPrimary(playerSource)
    -- RU: Проверяем корректность source.
    -- EN: Validate the source.
    if type(playerSource) ~= 'number' then
        return nil, nil
    end

    local identifiers = GCIdentifiers.GetAll(playerSource)

    -- RU: Пробуем основной тип.
    -- EN: Try the primary type.
    local primary = identifiers[GCConstants.primaryIdentifierType]

    if primary then
        return primary, GCConstants.primaryIdentifierType
    end

    -- RU: Пробуем запасной тип, если разрешено конфигурацией.
    -- EN: Try the fallback type if allowed by configuration.
    if GCConfig.Connection.allowLicense2Fallback then
        local fallback = identifiers[GCConstants.fallbackIdentifierType]

        if fallback then
            return fallback, GCConstants.fallbackIdentifierType
        end
    end

    return nil, nil
end

--- RU:
--- Сравнивает два идентификатора.
---
--- EN:
--- Compares two identifiers.
---
--- @param firstIdentifier string First identifier
--- @param secondIdentifier string Second identifier
--- @return boolean equal Whether the identifiers are equal
function GCIdentifiers.Compare(firstIdentifier, secondIdentifier)
    if type(firstIdentifier) ~= 'string' then
        return false
    end

    if type(secondIdentifier) ~= 'string' then
        return false
    end

    return firstIdentifier == secondIdentifier
end