GCIdentityStates = {}

local sessions = {}
local nextGeneration = 0
local allowedTransitions = {
    uninitialized = { loading = true, error = true, disconnecting = true },
    loading = {
        registration_required = true,
        authorized = true,
        error = true,
        disconnecting = true
    },
    registration_required = {
        registering = true,
        loading = true,
        error = true,
        disconnecting = true
    },
    registering = {
        registration_required = true,
        authorized = true,
        error = true,
        disconnecting = true
    },
    authorized = {
        character_required = true,
        character_selected = true,
        ready = true,
        error = true,
        disconnecting = true
    },
    character_required = {
        character_selected = true,
        error = true,
        disconnecting = true
    },
    character_selected = {
        ready = true,
        character_required = true,
        error = true,
        disconnecting = true
    },
    ready = {
        loading = true,
        character_required = true,
        character_selected = true,
        error = true,
        disconnecting = true
    },
    error = { loading = true, disconnecting = true },
    disconnecting = {}
}

local function validSource(playerSource)
    return type(playerSource) == 'number'
        and playerSource > 0
        and playerSource % 1 == 0
end

local function copyArray(values)
    local result = {}

    for index, value in ipairs(values or {}) do
        result[index] = value
    end

    return result
end

function GCIdentityStates.Create(playerSource)
    if not validSource(playerSource) then
        return nil, 'GC-IDENTITY-SOURCE-INVALID'
    end

    if sessions[playerSource] then
        return sessions[playerSource]
    end

    nextGeneration = nextGeneration + 1
    sessions[playerSource] = {
        source = playerSource,
        generation = nextGeneration,
        state = 'uninitialized',
        accountId = nil,
        account = nil,
        characters = {},
        selectedCharacterId = nil,
        processedRequests = {},
        processedOrder = {}
    }

    return sessions[playerSource]
end

function GCIdentityStates.Get(playerSource)
    return validSource(playerSource) and sessions[playerSource] or nil
end

function GCIdentityStates.IsCurrent(playerSource, generation)
    local session = GCIdentityStates.Get(playerSource)
    return session ~= nil and session.generation == generation
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

    if type(nextState) ~= 'string'
        or not allowedTransitions[session.state]
        or allowedTransitions[session.state][nextState] ~= true then
        return false, 'GC-IDENTITY-STATE-TRANSITION-INVALID'
    end

    session.state = nextState
    return true
end

function GCIdentityStates.BindAccount(playerSource, account)
    local session = GCIdentityStates.Get(playerSource)

    if not session or type(account) ~= 'table' or type(account.id) ~= 'number' then
        return false, 'GC-IDENTITY-STATE-ACCOUNT-INVALID'
    end

    session.accountId = account.id
    session.account = account
    return true
end

function GCIdentityStates.SetCharacters(playerSource, characters)
    local session = GCIdentityStates.Get(playerSource)

    if not session or type(characters) ~= 'table' then
        return false, 'GC-IDENTITY-STATE-CHARACTERS-INVALID'
    end

    session.characters = copyArray(characters)
    return true
end

function GCIdentityStates.AddCharacter(playerSource, character)
    local session = GCIdentityStates.Get(playerSource)

    if not session or type(character) ~= 'table' or type(character.id) ~= 'number' then
        return false, 'GC-IDENTITY-STATE-CHARACTER-INVALID'
    end

    table.insert(session.characters, character)
    return true
end

function GCIdentityStates.SelectCharacter(playerSource, characterId)
    local session = GCIdentityStates.Get(playerSource)

    if not session then
        return false, 'GC-IDENTITY-STATE-SESSION-MISSING'
    end

    session.selectedCharacterId = characterId
    return true
end

function GCIdentityStates.IsAuthorized(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    return session ~= nil and (
        session.state == 'authorized'
        or session.state == 'character_required'
        or session.state == 'character_selected'
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
