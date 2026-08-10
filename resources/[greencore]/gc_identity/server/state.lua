GCIdentityStates = {}

local sessions = {}
local allowedTransitions = {
    unknown = { account_required = true, error = true },
    account_required = { authorized = true, error = true },
    authorized = { character_required = true, ready = true, error = true },
    character_required = { ready = true, error = true },
    ready = { character_required = true, error = true },
    error = { unknown = true }
}

local function validSource(playerSource)
    return type(playerSource) == 'number'
        and playerSource > 0
        and playerSource % 1 == 0
end

function GCIdentityStates.Create(playerSource)
    if not validSource(playerSource) then
        return nil, 'GC-IDENTITY-SOURCE-INVALID'
    end

    if sessions[playerSource] then
        return sessions[playerSource]
    end

    sessions[playerSource] = {
        source = playerSource,
        state = 'unknown',
        accountId = nil,
        selectedCharacterId = nil,
        processedRequests = {},
        processedOrder = {}
    }

    return sessions[playerSource]
end

function GCIdentityStates.Get(playerSource)
    return validSource(playerSource) and sessions[playerSource] or nil
end

function GCIdentityStates.Remove(playerSource)
    sessions[playerSource] = nil
end

function GCIdentityStates.ClearAll()
    sessions = {}
end

function GCIdentityStates.Transition(playerSource, nextState)
    local session = GCIdentityStates.Get(playerSource)

    if not session then
        return false, 'GC-IDENTITY-STATE-SESSION-MISSING'
    end

    if session.state == nextState then
        return true
    end

    if not allowedTransitions[session.state]
        or allowedTransitions[session.state][nextState] ~= true then
        return false, 'GC-IDENTITY-STATE-TRANSITION-INVALID'
    end

    session.state = nextState
    return true
end

function GCIdentityStates.IsAuthorized(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    return session ~= nil and (
        session.state == 'authorized'
        or session.state == 'character_required'
        or session.state == 'ready'
    )
end

function GCIdentityStates.IsReady(playerSource)
    local session = GCIdentityStates.Get(playerSource)
    return session ~= nil and session.state == 'ready'
end

function GCIdentityStates.GetProcessed(playerSource, action, requestId)
    local session = GCIdentityStates.Get(playerSource)
    local key = ('%s:%s'):format(action, requestId)
    return session and session.processedRequests[key] or nil
end

function GCIdentityStates.RecordProcessed(playerSource, action, requestId, result)
    local session = GCIdentityStates.Get(playerSource)

    if not session then
        return false
    end

    local key = ('%s:%s'):format(action, requestId)

    if not session.processedRequests[key] then
        table.insert(session.processedOrder, key)
    end

    session.processedRequests[key] = result

    while #session.processedOrder > GCIdentityConfig.replayCacheSize do
        local oldest = table.remove(session.processedOrder, 1)
        session.processedRequests[oldest] = nil
    end

    return true
end
