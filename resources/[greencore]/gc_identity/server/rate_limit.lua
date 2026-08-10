GCIdentityRateLimit = {}

local windows = {}

local function nowMs()
    if type(GetGameTimer) == 'function' then
        return GetGameTimer()
    end

    return math.floor(os.clock() * 1000)
end

function GCIdentityRateLimit.Check(playerSource, action)
    local policy = GCIdentityConfig.rateLimits[action]

    if not policy then
        return false, 'GC-IDENTITY-RATE-LIMIT-CONFIG'
    end

    windows[playerSource] = windows[playerSource] or {}
    local current = nowMs()
    local window = windows[playerSource][action]

    if not window or current - window.startedAt >= policy.windowMs then
        windows[playerSource][action] = { startedAt = current, count = 1 }
        return true
    end

    if window.count >= policy.maximum then
        return false, 'GC-IDENTITY-RATE-LIMIT'
    end

    window.count = window.count + 1
    return true
end

function GCIdentityRateLimit.Clear(playerSource)
    windows[playerSource] = nil
end

function GCIdentityRateLimit.ClearAll()
    windows = {}
end
