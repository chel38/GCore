local currentSnapshot
local helloGeneration = 0
local helloAcknowledged = false
local requestSequence = 0
local uiReady = false
local uiOpen = false
local restrictionGeneration = 0
local pendingRequests = {}

local validStates = {
    uninitialized = true,
    loading = true,
    registration_required = true,
    registering = true,
    authorized = true,
    character_required = true,
    character_selected = true,
    ready = true,
    error = true,
    disconnecting = true
}

local function validPublicCharacter(character)
    return type(character) == 'table'
        and type(character.id) == 'number'
        and type(character.firstName) == 'string'
        and type(character.lastName) == 'string'
        and type(character.createdAt) == 'number'
end

local function validSnapshot(payload)
    if type(payload) ~= 'table'
        or payload.protocolVersion ~= GCIdentityVersion.protocol
        or type(payload.state) ~= 'string'
        or not validStates[payload.state]
        or type(payload.characters) ~= 'table'
        or type(payload.limits) ~= 'table'
        or type(payload.limits.maxCharacters) ~= 'number'
        or type(payload.passwordAuthentication) ~= 'boolean' then
        return false
    end

    if payload.account ~= nil and (
        type(payload.account) ~= 'table'
        or type(payload.account.id) ~= 'number'
        or type(payload.account.email) ~= 'string'
        or type(payload.account.status) ~= 'string'
        or type(payload.account.createdAt) ~= 'number'
    ) then
        return false
    end

    for _, character in ipairs(payload.characters) do
        if not validPublicCharacter(character) then
            return false
        end
    end

    return payload.selectedCharacter == nil
        or validPublicCharacter(payload.selectedCharacter)
end

local function nextRequestId()
    requestSequence = requestSequence + 1
    return ('identity_%d_%d'):format(GetGameTimer(), requestSequence)
end

local function setRestricted(restricted)
    if uiOpen == restricted then
        return
    end

    uiOpen = restricted
    restrictionGeneration = restrictionGeneration + 1
    local generation = restrictionGeneration
    SetNuiFocus(restricted, restricted)

    local ped = PlayerPedId()

    if ped and ped ~= 0 and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, restricted)
    end

    if restricted and GCIdentityConfig.client.restrictControls then
        CreateThread(function()
            while uiOpen and generation == restrictionGeneration do
                DisableAllControlActions(0)
                Wait(0)
            end
        end)
    end
end

local function sendSnapshotToNui()
    if not uiReady or not currentSnapshot then
        return
    end

    SendNUIMessage({
        type = 'snapshot',
        payload = currentSnapshot
    })
end

local function applySnapshot(payload)
    currentSnapshot = payload
    helloAcknowledged = true
    pendingRequests = {}

    if payload.state == 'ready' then
        setRestricted(false)
    else
        setRestricted(true)
    end

    sendSnapshotToNui()
    print(('[GC][IDENTITY] state=%s characters=%d'):format(
        payload.state,
        #payload.characters
    ))
end

local function startHello()
    helloGeneration = helloGeneration + 1
    local generation = helloGeneration
    helloAcknowledged = false

    CreateThread(function()
        for _ = 1, GCIdentityConfig.clientHello.maximumAttempts do
            if generation ~= helloGeneration or helloAcknowledged then
                return
            end

            TriggerServerEvent(GCIdentityEvents.server.hello, {
                protocolVersion = GCIdentityVersion.protocol
            })
            Wait(GCIdentityConfig.clientHello.retryIntervalMs)
        end
    end)
end

local function beginRequest(action, eventName, payload)
    if pendingRequests[action] then
        return nil, 'GC-IDENTITY-CLIENT-REQUEST-PENDING'
    end

    local requestId = nextRequestId()
    pendingRequests[action] = requestId
    payload.protocolVersion = GCIdentityVersion.protocol
    payload.requestId = requestId
    TriggerServerEvent(eventName, payload)
    return requestId
end

GCIdentityClientSecurity.RegisterServerEvent(
    GCIdentityEvents.client.snapshot,
    function(payload)
        if not validSnapshot(payload) then
            return
        end

        applySnapshot(payload)
    end
)

GCIdentityClientSecurity.RegisterServerEvent(
    GCIdentityEvents.client.rejected,
    function(payload)
        if type(payload) ~= 'table'
            or type(payload.code) ~= 'string'
            or (payload.requestId ~= nil and type(payload.requestId) ~= 'string') then
            return
        end

        if payload.requestId then
            for action, requestId in pairs(pendingRequests) do
                if requestId == payload.requestId then
                    pendingRequests[action] = nil
                end
            end
        end

        if uiReady then
            SendNUIMessage({ type = 'rejected', payload = payload })
        end

        print(('[GC][IDENTITY] request rejected: %s'):format(payload.code))
    end
)

RegisterNUICallback(GCIdentityNuiCallbacks.ready, function(_, callback)
    uiReady = true
    sendSnapshotToNui()
    callback({ ok = true })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.registerAccount, function(data, callback)
    local requestId, requestError = beginRequest(
        'registration',
        GCIdentityEvents.server.registerAccount,
        { email = type(data) == 'table' and data.email or nil }
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.createCharacter, function(data, callback)
    local requestId, requestError = beginRequest(
        'createCharacter',
        GCIdentityEvents.server.createCharacter,
        {
            firstName = type(data) == 'table' and data.firstName or nil,
            lastName = type(data) == 'table' and data.lastName or nil
        }
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.selectCharacter, function(data, callback)
    local requestId, requestError = beginRequest(
        'selectCharacter',
        GCIdentityEvents.server.selectCharacter,
        { characterId = type(data) == 'table' and tonumber(data.characterId) or nil }
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.refresh, function(_, callback)
    startHello()
    callback({ ok = true })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.exit, function(_, callback)
    TriggerServerEvent(GCIdentityEvents.server.exit, {
        protocolVersion = GCIdentityVersion.protocol
    })
    callback({ ok = true })
end)

RegisterCommand('gcidentity', function()
    startHello()
end, false)

RegisterCommand('gcregister', function(_, arguments)
    beginRequest('registration', GCIdentityEvents.server.registerAccount, {
        email = arguments[1]
    })
end, false)

RegisterCommand('gccreate', function(_, arguments)
    beginRequest('createCharacter', GCIdentityEvents.server.createCharacter, {
        firstName = arguments[1],
        lastName = arguments[2]
    })
end, false)

RegisterCommand('gcselect', function(_, arguments)
    beginRequest('selectCharacter', GCIdentityEvents.server.selectCharacter, {
        characterId = tonumber(arguments[1])
    })
end, false)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == 'gc_core' then
        startHello()

        CreateThread(function()
            Wait(GCIdentityConfig.client.nuiReadyTimeoutMs)

            if currentSnapshot and currentSnapshot.state ~= 'ready' and not uiReady then
                print('[GC][IDENTITY] [GC-IDENTITY-NUI-NOT-READY] NUI did not acknowledge readiness')
            end
        end)
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'gc_core' then
        helloGeneration = helloGeneration + 1
        helloAcknowledged = false
        currentSnapshot = nil
        pendingRequests = {}
        setRestricted(true)
    elseif resourceName == GetCurrentResourceName() then
        setRestricted(false)
    end
end)
