-- RU: Сервис локализации GreenCore.
-- EN: GreenCore localization service.

-- RU: Таблица сервиса локализации.
-- EN: Localization service table.
GCLocale = {}

--- RU:
--- Возвращает перевод по ключу для заданного языка.
--- Использует английский язык как fallback.
--- Если перевод отсутствует, возвращает сам ключ.
---
--- EN:
--- Returns a translation by key for the given language.
--- Uses English as a fallback.
--- If the translation is missing, returns the key itself.
---
--- @param locale string Language code like "ru"
--- @param key string Translation key like "connection.accepted"
--- @param variables table|nil Variables for substitution
--- @return string message Translated message
function GCLocale.Translate(locale, key, variables)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(locale) ~= 'string' then
        locale = 'en'
    end

    if type(key) ~= 'string' then
        return key
    end

    -- RU: Ищем перевод в основном языке.
    -- EN: Look up the translation in the primary language.
    local message = nil

    if GCLocales[locale] then
        message = GCLocales[locale][key]
    end

    -- RU: Если перевод отсутствует, используем английский fallback.
    -- EN: If the translation is missing, use the English fallback.
    if message == nil and locale ~= 'en' and GCLocales.en then
        message = GCLocales.en[key]
    end

    -- RU: Если перевод всё ещё отсутствует, возвращаем ключ.
    -- EN: If the translation is still missing, return the key.
    if message == nil then
        return key
    end

    -- RU: Подставляем переменные вида {name}.
    -- EN: Substitute variables of the form {name}.
    if type(variables) == 'table' then
        for name, value in pairs(variables) do
            message = message:gsub('{' .. name .. '}', tostring(value))
        end
    end

    return message
end

--- RU:
--- Глобальная функция перевода. Удобна для вызова из любого места.
---
--- EN:
--- Global translation function. Convenient to call from anywhere.
---
--- @param locale string Language code
--- @param key string Translation key
--- @param variables table|nil Variables for substitution
--- @return string message Translated message
function GC_T(locale, key, variables)
    return GCLocale.Translate(locale, key, variables)
end