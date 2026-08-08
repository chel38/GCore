-- RU: Строгая валидация всех payload на границе доверия.
-- EN: Strict validation for every payload crossing a trust boundary.

GCValidation = {}

local function onlyKeys(payload, allowed)
    for key in pairs(payload) do
        if not allowed[key] then
            return false
        end
    end

    return true
end

local function boundedString(value, maximum, allowEmpty)
    return type(value) == 'string'
        and (allowEmpty or #value > 0)
        and #value <= maximum
end

function GCValidation.ProtocolMatches(payloadProtocol)
    if not GCUtils.IsInteger(payloadProtocol) then
        return false, 'GC-PROTOCOL-MISMATCH-001'
    end

    if payloadProtocol ~= GCVersion.GetProtocolVersion() then
        return false, 'GC-PROTOCOL-MISMATCH-001'
    end

    return true
end


function GCValidation.ClientHandshake(payload, allowPedHint)
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    local allowed = { clientVersion = true, protocolVersion = true, locale = true }

    if allowPedHint then
        allowed.isPedAlive = true
    end

    if not onlyKeys(payload, allowed) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if type(payload.clientVersion) ~= 'string' then
        return false, 'GC-PAYLOAD-VERSION-001'
    end

    if #payload.clientVersion == 0 or #payload.clientVersion > GCConstants.maxClientVersionLength then
        return false, 'GC-PAYLOAD-VERSION-002'
    end

    if type(payload.protocolVersion) ~= 'number' then
        return false, 'GC-PAYLOAD-PROTOCOL-001'
    end

    if not GCUtils.IsInteger(payload.protocolVersion) then
        return false, 'GC-PAYLOAD-PROTOCOL-002'
    end

    local protocolOk, protocolError = GCValidation.ProtocolMatches(payload.protocolVersion)

    if not protocolOk then
        return false, protocolError
    end

    if payload.locale ~= nil and type(payload.locale) ~= 'string' then
        return false, 'GC-PAYLOAD-LOCALE-001'
    end

    if payload.locale ~= nil
        and (#payload.locale == 0 or #payload.locale > GCConstants.maxLocaleLength) then
        return false, 'GC-PAYLOAD-LOCALE-002'
    end

    if allowPedHint and payload.isPedAlive ~= nil and type(payload.isPedAlive) ~= 'boolean' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    return true
end

function GCValidation.ClientReady(payload)
    return GCValidation.ClientHandshake(payload, false)
end

function GCValidation.ResyncReady(payload)
    return GCValidation.ClientHandshake(payload, true)
end

function GCValidation.RequestSpawn(payload)
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if next(payload) ~= nil then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    return true
end


function GCValidation.ConfirmSpawn(payload)
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if not onlyKeys(payload, { decisionId = true }) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if not boundedString(payload.decisionId, GCConstants.maxDecisionIdLength, false) then
        return false, 'GC-PAYLOAD-DECISION-001'
    end

    return true
end


function GCValidation.ReportClientError(payload)
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if not onlyKeys(payload, { errorCode = true }) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if not boundedString(payload.errorCode, GCConstants.maxErrorReasonLength, false)
        or not GCErrors.Get(payload.errorCode) then
        return false, 'GC-PAYLOAD-ERROR-001'
    end

    return true
end

function GCValidation.SpawnApproved(payload)
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if not onlyKeys(payload, {
        decisionId = true,
        position = true,
        ped = true,
        expiresAt = true,
        attempt = true
    }) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if not boundedString(payload.decisionId, GCConstants.maxDecisionIdLength, false) then
        return false, 'GC-PAYLOAD-DECISION-001'
    end

    if type(payload.position) ~= 'table'
        or not onlyKeys(payload.position, { x = true, y = true, z = true, heading = true }) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    for _, key in ipairs({ 'x', 'y', 'z', 'heading' }) do
        if not GCUtils.IsFiniteNumber(payload.position[key]) then
            return false, 'GC-PAYLOAD-NUMBER-001'
        end
    end

    if type(payload.ped) ~= 'table' or not onlyKeys(payload.ped, { name = true, hash = true }) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if not boundedString(payload.ped.name, GCConstants.maxPedModelLength, false) then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if payload.ped.hash ~= nil and not GCUtils.IsInteger(payload.ped.hash) then
        return false, 'GC-PAYLOAD-NUMBER-001'
    end

    if payload.expiresAt ~= nil and not GCUtils.IsFiniteNumber(payload.expiresAt) then
        return false, 'GC-PAYLOAD-NUMBER-001'
    end

    if payload.attempt ~= nil and (not GCUtils.IsInteger(payload.attempt) or payload.attempt < 1) then
        return false, 'GC-PAYLOAD-NUMBER-001'
    end

    return true
end

function GCValidation.ConnectionAccepted(payload)
    if type(payload) ~= 'table'
        or not onlyKeys(payload, { apiVersion = true, protocolVersion = true })
        or not GCUtils.IsInteger(payload.apiVersion)
        or not GCUtils.IsInteger(payload.protocolVersion) then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if payload.apiVersion ~= GCVersion.GetApiVersion()
        or payload.protocolVersion ~= GCVersion.GetProtocolVersion() then
        return false, 'GC-PROTOCOL-MISMATCH-001'
    end

    return true
end

function GCValidation.SpawnRejected(payload)
    if type(payload) ~= 'table'
        or not onlyKeys(payload, { errorCode = true, retryable = true })
        or not boundedString(payload.errorCode, GCConstants.maxErrorReasonLength, false)
        or not GCErrors.Get(payload.errorCode)
        or type(payload.retryable) ~= 'boolean' then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    return true
end

function GCValidation.SpawnConfirmed(payload)
    if type(payload) ~= 'table'
        or not onlyKeys(payload, { decisionId = true, state = true })
        or payload.state ~= 'spawned' then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    if payload.decisionId ~= nil
        and not boundedString(payload.decisionId, GCConstants.maxDecisionIdLength, false) then
        return false, 'GC-PAYLOAD-DECISION-001'
    end

    return true
end

function GCValidation.Notification(payload)
    local allowedTypes = { info = true, success = true, warning = true, error = true }

    if type(payload) ~= 'table'
        or not onlyKeys(payload, { message = true, type = true })
        or not boundedString(payload.message, 256, false)
        or not allowedTypes[payload.type] then
        return false, 'GC-PAYLOAD-SCHEMA-001'
    end

    return true
end
