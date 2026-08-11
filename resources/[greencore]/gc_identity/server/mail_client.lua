GCIdentityMailClient = {}

local health = { status = 'unknown', code = nil, checkedAt = nil }
local requestGeneration = 0

local function setHealth(status, code)
    health.status = status
    health.code = code
    health.checkedAt = os.time()
end

local function decodeSuccess(statusCode, body, expectedStatus)
    if statusCode ~= expectedStatus or type(body) ~= 'string' or body == '' then
        return false
    end
    local ok, payload = pcall(json.decode, body)
    return ok and type(payload) == 'table' and payload.ok == true
end

local function request(path, method, body, expectedStatus, callback, stillCurrent)
    local valid, configError = GCIdentitySecurityConfig.ValidateMailBoundary()
    if not valid then
        setHealth('unavailable', configError)
        callback(false, configError)
        return
    end

    requestGeneration = requestGeneration + 1
    local generation = requestGeneration
    local completed = false

    local function finish(success, code)
        if completed or generation ~= requestGeneration and method == 'GET' then
            return
        end
        completed = true
        if stillCurrent and not stillCurrent() then
            return
        end
        callback(success, code)
    end

    SetTimeout(GCIdentityConfig.mail.requestTimeoutMs, function()
        if not completed then
            setHealth('unavailable', 'GC-IDENTITY-MAIL-TIMEOUT')
            finish(false, 'GC-IDENTITY-MAIL-TIMEOUT')
        end
    end)

    PerformHttpRequest(
        GCIdentitySecurityConfig.MailUrl():gsub('/$', '') .. path,
        function(statusCode, responseBody)
            if completed then
                return
            end
            local success = decodeSuccess(statusCode, responseBody, expectedStatus)
            if success then
                setHealth('healthy', nil)
                finish(true, nil)
            else
                setHealth('unavailable', 'GC-IDENTITY-MAIL-SEND-FAILED')
                finish(false, 'GC-IDENTITY-MAIL-SEND-FAILED')
            end
        end,
        method,
        body or '',
        {
            ['Content-Type'] = 'application/json',
            ['X-GCore-Mail-Token'] = GCIdentitySecurityConfig.MailToken()
        }
    )
end

function GCIdentityMailClient.CheckHealth(callback)
    request('/health', 'GET', '', 200, function(success, code)
        if callback then callback(success, code) end
    end)
end

function GCIdentityMailClient.SendVerification(email, code, verificationType, callback, stillCurrent)
    request(
        '/v1/email/verification',
        'POST',
        json.encode({ email = email, code = code, type = verificationType }),
        202,
        callback,
        stillCurrent
    )
end

function GCIdentityMailClient.GetHealth()
    return {
        status = health.status,
        code = health.code,
        checkedAt = health.checkedAt
    }
end
