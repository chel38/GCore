local currentSnapshot
local helloGeneration = 0
local helloAcknowledged = false
local requestSequence = 0
local uiReady = false
local uiOpen = false
local uiFailure
local clientFailureReported = false
local restrictionGeneration = 0
local nuiWatchGeneration = 0
local pendingRequests = {}
local loadingScreenHandedOff = false
local debugLog

local validStates = {
    uninitialized = true,
    loading = true,
    registration_required = true,
    registering = true,
    email_verification_pending = true,
    registration_verified = true,
    registration_finalizing = true,
    profile_completion_required = true,
    auth_verification_required = true,
    authorized = true,
    spawn_releasing = true,
    post_spawn_identity = true,
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
        or (payload.locale ~= 'ru' and payload.locale ~= 'en')
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
        or type(payload.account.firstName) ~= 'string'
        or type(payload.account.lastName) ~= 'string'
        or type(payload.account.displayName) ~= 'string'
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

    if payload.verification ~= nil and (
        type(payload.verification) ~= 'table'
        or (payload.verification.type ~= 'registration'
            and payload.verification.type ~= 'authentication')
        or type(payload.verification.maskedEmail) ~= 'string'
        or type(payload.verification.expiresIn) ~= 'number'
        or type(payload.verification.resendIn) ~= 'number'
    ) then
        return false
    end

    if payload.registration ~= nil and (
        type(payload.registration) ~= 'table'
        or type(payload.registration.fullName) ~= 'string'
        or type(payload.registration.email) ~= 'string'
        or type(payload.registration.emailVerified) ~= 'boolean'
        or type(payload.registration.profileOnly) ~= 'boolean'
    ) then
        return false
    end

    return payload.selectedCharacter == nil
        or validPublicCharacter(payload.selectedCharacter)
end

local function handoffLoadingScreen()
    if loadingScreenHandedOff then
        return
    end

    loadingScreenHandedOff = true
    if type(ShutdownLoadingScreen) == 'function' then
        ShutdownLoadingScreen()
    end
    if type(ShutdownLoadingScreenNui) == 'function' then
        ShutdownLoadingScreenNui()
    end
    debugLog('FiveM loading screen handed off to identity NUI')
end

local function nextRequestId()
    requestSequence = requestSequence + 1
    return ('identity_%d_%d'):format(GetGameTimer(), requestSequence)
end

debugLog = function(message)
    if GCIdentityConfig.client.debug then
        print(('[GC][IDENTITY][CLIENT] %s'):format(message))
    end
end

local function setRestricted(restricted)
    if uiOpen == restricted then
        return
    end

    uiOpen = restricted
    restrictionGeneration = restrictionGeneration + 1
    local generation = restrictionGeneration
    SetNuiFocus(restricted, restricted)
    debugLog(restricted and 'NUI focus acquired' or 'NUI focus released')

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

local function sendCurrentStateToNui()
    if not uiReady then
        return
    end

    if currentSnapshot then
        SendNUIMessage({
            type = 'snapshot',
            payload = currentSnapshot
        })
    elseif uiFailure then
        SendNUIMessage({
            type = 'lifecycleError',
            payload = { code = uiFailure }
        })
    end
end

local function applySnapshot(payload)
    currentSnapshot = payload
    uiFailure = nil
    helloAcknowledged = true
    pendingRequests = {}

    -- EN: Focus is acquired only after the JS-ready callback. A loaded HTML page
    -- is not evidence that the NUI bundle can render or answer callbacks.
    -- RU: Focus выдаётся только после JS-ready callback. Загруженный HTML ещё не
    -- доказывает, что NUI bundle умеет отрисоваться и отвечать на callbacks.
    if uiReady then
        handoffLoadingScreen()
        setRestricted(payload.state ~= 'ready')
    else
        setRestricted(false)
    end

    sendCurrentStateToNui()
    print(('[GC][IDENTITY] state=%s characters=%d'):format(
        payload.state,
        #payload.characters
    ))
end

local function applyLifecycleFailure(code)
    uiFailure = code
    helloAcknowledged = true
    pendingRequests = {}

    if uiReady then
        setRestricted(true)
        sendCurrentStateToNui()
    else
        setRestricted(false)
    end

    print(('[GC][IDENTITY][CLIENT] [%s] Identity lifecycle stopped safely'):format(code))
end

local function reportClientFailure(code)
    if clientFailureReported then
        return
    end

    clientFailureReported = true
    setRestricted(false)
    TriggerServerEvent(GCIdentityEvents.server.clientFailure, {
        protocolVersion = GCIdentityVersion.protocol,
        code = code
    })
end

local function armNuiReadyWatchdog()
    nuiWatchGeneration = nuiWatchGeneration + 1
    local generation = nuiWatchGeneration

    CreateThread(function()
        Wait(GCIdentityConfig.client.nuiReadyTimeoutMs)

        if generation ~= nuiWatchGeneration or uiReady then
            return
        end

        print('[GC][IDENTITY][CLIENT] [GC-IDENTITY-NUI-NOT-READY] NUI JS did not acknowledge readiness')
        reportClientFailure('GC-IDENTITY-NUI-NOT-READY')
    end)
end

local function startHello()
    helloGeneration = helloGeneration + 1
    local generation = helloGeneration
    helloAcknowledged = false
    uiFailure = nil
    clientFailureReported = false

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

        if generation == helloGeneration and not helloAcknowledged then
            applyLifecycleFailure('GC-IDENTITY-HELLO-TIMEOUT')
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

        if not payload.requestId and not currentSnapshot then
            applyLifecycleFailure(payload.code)
        elseif uiReady then
            SendNUIMessage({ type = 'rejected', payload = payload })
        end

        print(('[GC][IDENTITY] request rejected: %s'):format(payload.code))
    end
)

RegisterNUICallback(GCIdentityNuiCallbacks.ready, function(_, callback)
    uiReady = true
    nuiWatchGeneration = nuiWatchGeneration + 1

    if currentSnapshot then
        handoffLoadingScreen()
        setRestricted(currentSnapshot.state ~= 'ready')
    elseif uiFailure then
        setRestricted(true)
    end

    sendCurrentStateToNui()
    debugLog('NUI JS ready callback received')
    callback({ ok = true })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.sendRegistrationCode, function(data, callback)
    local requestId, requestError = beginRequest(
        'registration',
        GCIdentityEvents.server.sendRegistrationCode,
        {
            fullName = type(data) == 'table' and data.fullName or nil,
            email = type(data) == 'table' and data.email or nil
        }
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.changeRegistrationEmail, function(_, callback)
    local requestId, requestError = beginRequest(
        'changeRegistrationEmail',
        GCIdentityEvents.server.changeRegistrationEmail,
        {}
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.finalizeRegistration, function(_, callback)
    local requestId, requestError = beginRequest(
        'finalizeRegistration',
        GCIdentityEvents.server.finalizeRegistration,
        {}
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.completeProfile, function(data, callback)
    local requestId, requestError = beginRequest(
        'completeProfile',
        GCIdentityEvents.server.completeProfile,
        { fullName = type(data) == 'table' and data.fullName or nil }
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.verifyEmail, function(data, callback)
    local requestId, requestError = beginRequest(
        'verifyEmail',
        GCIdentityEvents.server.verifyEmail,
        { code = type(data) == 'table' and data.code or nil }
    )
    callback({ ok = requestId ~= nil, requestId = requestId, code = requestError })
end)

RegisterNUICallback(GCIdentityNuiCallbacks.resendVerification, function(_, callback)
    local requestId, requestError = beginRequest(
        'resendVerification',
        GCIdentityEvents.server.resendVerification,
        {}
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
    beginRequest('registration', GCIdentityEvents.server.sendRegistrationCode, {
        fullName = table.concat({ arguments[1] or '', arguments[2] or '' }, ' '),
        email = arguments[3]
    })
end, false)

RegisterCommand('gcverify', function(_, arguments)
    beginRequest('verifyEmail', GCIdentityEvents.server.verifyEmail, {
        code = arguments[1]
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
        if resourceName == GetCurrentResourceName() then
            loadingScreenHandedOff = false
        end
        startHello()

        if resourceName == GetCurrentResourceName() then
            armNuiReadyWatchdog()
        end
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'gc_core' then
        helloGeneration = helloGeneration + 1
        helloAcknowledged = false
        currentSnapshot = nil
        uiFailure = nil
        pendingRequests = {}
        setRestricted(false)

        if uiReady then
            SendNUIMessage({ type = 'reset' })
        end
    elseif resourceName == GetCurrentResourceName() then
        nuiWatchGeneration = nuiWatchGeneration + 1
        setRestricted(false)
    end
end)
