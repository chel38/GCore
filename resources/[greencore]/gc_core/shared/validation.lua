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

--- RU:
--- Проверяет, что версия протокола клиента строго совпадает с версией сервера.
--- Строгое сравнение, а не только проверка типа, предотвращает продолжение
--- lifecycle при несовместимой версии клиента.
---
--- EN:
--- Checks that the client protocol version strictly matches the server version.
--- Strict comparison, not just a type check, prevents continuing the lifecycle
--- with an incompatible client version.
---
--- @param payloadProtocol any Client protocol version from the payload
--- @return boolean matches Whether the protocol versions match
--- @return string|nil errorCode Error code if they do not match
function GCValidation.ProtocolMatches(payloadProtocol)
    -- RU: Протокол должен быть числом.
    -- EN: The protocol must be a number.
    if type(payloadProtocol) ~= 'number' then
        return false, 'GC-PROTOCOL-MISMATCH-001'
    end

    -- RU: Протокол должен быть целым числом.
    -- EN: The protocol must be an integer.
    if math.floor(payloadProtocol) ~= payloadProtocol then
        return false, 'GC-PROTOCOL-MISMATCH-001'
    end

    -- RU: Строгое сравнение с версией сервера.
    -- EN: Strict comparison with the server version.
    if payloadProtocol ~= GCConfig.General.protocolVersion then
        return false, 'GC-PROTOCOL-MISMATCH-001'
    end

    return true
end

--- RU:
--- Проверяет payload ответа о готовности к resync после рестарта.
---
--- EN:
--- Validates the resync-ready response payload after a restart.
---
--- @param payload any Payload to validate
--- @return boolean isValid Whether the payload is valid
--- @return string|nil errorCode Error code
function GCValidation.ResyncReady(payload)
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

    -- RU: isPedAlive, если указан, должен быть булевым.
    -- EN: isPedAlive, if provided, must be a boolean.
    if payload.isPedAlive ~= nil and type(payload.isPedAlive) ~= 'boolean' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    return true
end

--- RU:
--- Проверяет решение о спавне, полученное клиентом (payload spawnApproved).
--- Клиент не доверяет payload полностью; этот валидатор проверяет минимально
--- необходимые поля перед выполнением спавна.
---
--- EN:
--- Validates the spawn decision received by the client (spawnApproved payload).
--- The client does not fully trust the payload; this validator checks the
--- minimum required fields before performing the spawn.
---
--- @param payload any Spawn decision payload
--- @return boolean isValid Whether the payload is valid
--- @return string|nil errorCode Error code
function GCValidation.SpawnApproved(payload)
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

    -- RU: position должен быть таблицей.
    -- EN: position must be a table.
    if type(payload.position) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: Координаты должны быть числами.
    -- EN: Coordinates must be numbers.
    if type(payload.position.x) ~= 'number' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if type(payload.position.y) ~= 'number' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if type(payload.position.z) ~= 'number' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if type(payload.position.heading) ~= 'number' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: ped должен быть таблицей с именем модели.
    -- EN: ped must be a table with a model name.
    if type(payload.ped) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: ped.name должен быть непустой строкой.
    -- EN: ped.name must be a non-empty string.
    if type(payload.ped.name) ~= 'string' or #payload.ped.name == 0 then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    -- RU: ped.hash, если указан, должен быть числом.
    -- EN: ped.hash, if provided, must be a number.
    if payload.ped.hash ~= nil and type(payload.ped.hash) ~= 'number' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    return true
end