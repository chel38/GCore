-- RU: Сервис валидации payload GreenCore.
-- EN: GreenCore payload validation service.

-- RU: Таблица сервиса валидации.
-- EN: Validation service table.
GCValidation = {}

--- RU:
--- Проверяет payload события готовности клиента.
---
--- EN:
--- Validates the client readiness event payload.
---
--- @param payload any Payload to validate
--- @return boolean isValid Whether the payload is valid
--- @return string|nil errorCode Error code
function GCValidation.ClientReady(payload)
    -- RU: Payload должен быть таблицей.
    -- EN: Payload must be a table.
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: clientVersion должен быть строкой.
    -- EN: clientVersion must be a string.
    if type(payload.clientVersion) ~= 'string' then
        return false, 'GC-PAYLOAD-VERSION-001'
    end

    -- RU: clientVersion не должен превышать допустимую длину.
    -- EN: clientVersion must not exceed the allowed length.
    if #payload.clientVersion > GCConstants.maxClientVersionLength then
        return false, 'GC-PAYLOAD-VERSION-002'
    end

    -- RU: protocolVersion должен быть числом.
    -- EN: protocolVersion must be a number.
    if type(payload.protocolVersion) ~= 'number' then
        return false, 'GC-PAYLOAD-PROTOCOL-001'
    end

    -- RU: protocolVersion должен быть целым числом.
    -- EN: protocolVersion must be an integer.
    if math.floor(payload.protocolVersion) ~= payload.protocolVersion then
        return false, 'GC-PAYLOAD-PROTOCOL-002'
    end

    -- RU: locale, если указан, должен быть строкой.
    -- EN: locale, if provided, must be a string.
    if payload.locale ~= nil and type(payload.locale) ~= 'string' then
        return false, 'GC-PAYLOAD-LOCALE-001'
    end

    -- RU: locale не должен превышать допустимую длину.
    -- EN: locale must not exceed the allowed length.
    if payload.locale ~= nil and #payload.locale > GCConstants.maxLocaleLength then
        return false, 'GC-PAYLOAD-LOCALE-002'
    end

    return true
end

--- RU:
--- Проверяет payload запроса спавна.
---
--- EN:
--- Validates the spawn request payload.
---
--- @param payload any Payload to validate
--- @return boolean isValid Whether the payload is valid
--- @return string|nil errorCode Error code
function GCValidation.RequestSpawn(payload)
    -- RU: Payload должен быть таблицей.
    -- EN: Payload must be a table.
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    return true
end

--- RU:
--- Проверяет payload подтверждения спавна.
---
--- EN:
--- Validates the spawn confirmation payload.
---
--- @param payload any Payload to validate
--- @return boolean isValid Whether the payload is valid
--- @return string|nil errorCode Error code
function GCValidation.ConfirmSpawn(payload)
    -- RU: Payload должен быть таблицей.
    -- EN: Payload must be a table.
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: decisionId должен быть строкой.
    -- EN: decisionId must be a string.
    if type(payload.decisionId) ~= 'string' then
        return false, 'GC-PAYLOAD-DECISION-001'
    end

    -- RU: decisionId не должен превышать допустимую длину.
    -- EN: decisionId must not exceed the allowed length.
    if #payload.decisionId > 128 then
        return false, 'GC-PAYLOAD-DECISION-002'
    end

    return true
end

--- RU:
--- Проверяет payload сообщения об ошибке клиента.
---
--- EN:
--- Validates the client error report payload.
---
--- @param payload any Payload to validate
--- @return boolean isValid Whether the payload is valid
--- @return string|nil errorCode Error code
function GCValidation.ReportClientError(payload)
    -- RU: Payload должен быть таблицей.
    -- EN: Payload must be a table.
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: errorCode должен быть строкой.
    -- EN: errorCode must be a string.
    if type(payload.errorCode) ~= 'string' then
        return false, 'GC-PAYLOAD-ERROR-001'
    end

    -- RU: errorCode не должен превышать допустимую длину.
    -- EN: errorCode must not exceed the allowed length.
    if #payload.errorCode > GCConstants.maxErrorReasonLength then
        return false, 'GC-PAYLOAD-ERROR-002'
    end

    return true
end