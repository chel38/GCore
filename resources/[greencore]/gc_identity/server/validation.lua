GCIdentityValidation = {}

local function isInteger(value)
    return type(value) == 'number' and value % 1 == 0
end

local function exactKeys(payload, allowed)
    if type(payload) ~= 'table' then
        return false
    end

    local seen = 0

    for key in pairs(payload) do
        if not allowed[key] then
            return false
        end

        seen = seen + 1
    end

    local expected = 0

    for _ in pairs(allowed) do
        expected = expected + 1
    end

    return seen == expected
end

local function validateProtocol(protocolVersion)
    return isInteger(protocolVersion)
        and protocolVersion == GCIdentityVersion.protocol
end

local function validateRequestId(requestId)
    return type(requestId) == 'string'
        and #requestId >= 8
        and #requestId <= 64
        and requestId:match('^[A-Za-z0-9_-]+$') ~= nil
end

local function normalizeName(value)
    if type(value) ~= 'string' then
        return nil
    end

    local normalized = value:match('^%s*(.-)%s*$')

    if #normalized < GCIdentityConfig.characters.nameMinBytes
        or #normalized > GCIdentityConfig.characters.nameMaxBytes
        or normalized:match('[%z\1-\31\127]')
        or normalized:match('[<>/\\{}%[%]|]') then
        return nil
    end

    return normalized
end

function GCIdentityValidation.ValidateHello(payload)
    if not exactKeys(payload, { protocolVersion = true }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end

    return { protocolVersion = payload.protocolVersion }
end

function GCIdentityValidation.ValidateCreateCharacter(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true,
        firstName = true,
        lastName = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end

    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end

    local firstName = normalizeName(payload.firstName)
    local lastName = normalizeName(payload.lastName)

    if not firstName or not lastName then
        return nil, 'GC-IDENTITY-PAYLOAD-NAME'
    end

    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId,
        firstName = firstName,
        lastName = lastName
    }
end

function GCIdentityValidation.ValidateSelectCharacter(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true,
        characterId = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end

    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end

    if not isInteger(payload.characterId) or payload.characterId <= 0 then
        return nil, 'GC-IDENTITY-PAYLOAD-CHARACTER-ID'
    end

    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId,
        characterId = payload.characterId
    }
end
