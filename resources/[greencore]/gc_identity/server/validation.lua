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

local allowedClientFailures = {
    ['GC-IDENTITY-NUI-NOT-READY'] = true
}

local function trim(value)
    return value:match('^%s*(.-)%s*$')
end

local function collapseSpaces(value)
    return trim(value):gsub('%s+', ' ')
end

local function validDomain(domain)
    if not domain:find('.', 1, true)
        or domain:find('..', 1, true)
        or not domain:match('^[a-z0-9.-]+$')
        or not domain:match('^[a-z0-9]')
        or not domain:match('[a-z0-9]$') then
        return false
    end

    for label in domain:gmatch('[^.]+') do
        if #label > 63
            or not label:match('^[a-z0-9]')
            or not label:match('[a-z0-9]$') then
            return false
        end
    end

    return true
end

function GCIdentityValidation.NormalizeEmail(value)
    if type(value) ~= 'string' then
        return nil
    end

    local email = trim(value):lower()

    if #email < GCIdentityConfig.accounts.emailMinBytes
        or #email > GCIdentityConfig.accounts.emailMaxBytes
        or email:match('[%z\1-\31\127%s]') then
        return nil
    end

    local localPart, domain = email:match('^([^@]+)@([^@]+)$')

    if not localPart or #localPart > 64
        or not localPart:match("^[a-z0-9.!#$%%&'*+/=?^_`{|}~-]+$")
        or localPart:sub(1, 1) == '.'
        or localPart:sub(-1) == '.'
        or localPart:find('..', 1, true)
        or not validDomain(domain) then
        return nil
    end

    return email
end

function GCIdentityValidation.NormalizeFullName(value)
    if type(value) ~= 'string' or value:match('[%z\1-\31\127]') then
        return nil
    end

    local normalized = collapseSpaces(value)
    local firstName, lastName = normalized:match('^([A-Za-z]+) ([A-Za-z]+)$')
    if not firstName or not lastName
        or #firstName < GCIdentityConfig.accounts.firstNameMinBytes
        or #firstName > GCIdentityConfig.accounts.firstNameMaxBytes
        or #lastName < GCIdentityConfig.accounts.lastNameMinBytes
        or #lastName > GCIdentityConfig.accounts.lastNameMaxBytes then
        return nil
    end

    return {
        firstName = firstName,
        lastName = lastName,
        displayName = firstName .. ' ' .. lastName
    }
end

local function normalizeName(value)
    if type(value) ~= 'string' then
        return nil
    end

    local normalized = trim(value)

    if #normalized < GCIdentityConfig.characters.nameMinBytes
        or #normalized > GCIdentityConfig.characters.nameMaxBytes
        or normalized:match('[%z\1-\31\127]')
        or normalized:match('[%d<>/\\{}%[%]|@#$%%%^&*=+~`;:!?]') then
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

function GCIdentityValidation.ValidateRegistration(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true,
        email = true,
        fullName = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end

    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end

    local email = GCIdentityValidation.NormalizeEmail(payload.email)
    local name = GCIdentityValidation.NormalizeFullName(payload.fullName)

    if not email then
        return nil, 'GC-IDENTITY-REGISTRATION-INVALID'
    end
    if not name then
        return nil, 'GC-IDENTITY-NAME-INVALID'
    end

    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId,
        email = email,
        firstName = name.firstName,
        lastName = name.lastName,
        displayName = name.displayName
    }
end

local function validateRequestOnly(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end
    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end
    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end
    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId
    }
end

function GCIdentityValidation.ValidateChangeRegistrationEmail(payload)
    return validateRequestOnly(payload)
end

function GCIdentityValidation.ValidateFinalizeRegistration(payload)
    return validateRequestOnly(payload)
end

function GCIdentityValidation.ValidateCompleteProfile(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true,
        fullName = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end
    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end
    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end
    local name = GCIdentityValidation.NormalizeFullName(payload.fullName)
    if not name then
        return nil, 'GC-IDENTITY-NAME-INVALID'
    end
    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId,
        firstName = name.firstName,
        lastName = name.lastName,
        displayName = name.displayName
    }
end

function GCIdentityValidation.ValidateVerificationCode(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true,
        code = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end
    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end
    if type(payload.code) ~= 'string' or not payload.code:match('^%d%d%d%d%d%d$') then
        return nil, 'GC-IDENTITY-EMAIL-CODE-INVALID'
    end
    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId,
        code = payload.code
    }
end

function GCIdentityValidation.ValidateResendVerification(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        requestId = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end
    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end
    if not validateRequestId(payload.requestId) then
        return nil, 'GC-IDENTITY-PAYLOAD-REQUEST-ID'
    end
    return {
        protocolVersion = payload.protocolVersion,
        requestId = payload.requestId
    }
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
        return nil, 'GC-IDENTITY-CHARACTER-INVALID'
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

function GCIdentityValidation.ValidateExit(payload)
    if not exactKeys(payload, { protocolVersion = true }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end

    return { protocolVersion = payload.protocolVersion }
end

function GCIdentityValidation.ValidateClientFailure(payload)
    if not exactKeys(payload, {
        protocolVersion = true,
        code = true
    }) then
        return nil, 'GC-IDENTITY-PAYLOAD-SCHEMA'
    end

    if not validateProtocol(payload.protocolVersion) then
        return nil, 'GC-IDENTITY-PROTOCOL-MISMATCH'
    end

    if type(payload.code) ~= 'string' or not allowedClientFailures[payload.code] then
        return nil, 'GC-IDENTITY-CLIENT-FAILURE-INVALID'
    end

    return {
        protocolVersion = payload.protocolVersion,
        code = payload.code
    }
end
