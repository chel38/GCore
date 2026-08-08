-- RU: Полные contract tests Public Server API v1.
-- EN: Complete Public Server API v1 contract tests.

local apiMethods = {
    'GetVersion',
    'GetVersionString',
    'GetApiVersion',
    'GetProtocolVersion',
    'IsPlayerConnected',
    'IsPlayerReady',
    'IsPlayerSpawned',
    'GetPlayerState',
    'GetPlayerSession',
    'GetPlayerIdentifier',
    'CanUseGameplayFeatures',
    'RequestPlayerSpawn',
    'NotifyPlayer',
    'NotifyAll'
}

local function createApiSession(playerSource)
    local temporarySource = 80000 + playerSource
    local identifiers = {
        license = 'license:api-' .. tostring(playerSource),
        discord = 'discord:api-' .. tostring(playerSource)
    }
    GCSessions.CreatePendingConnection(
        temporarySource,
        'ApiPlayer' .. tostring(playerSource),
        identifiers,
        identifiers.license,
        'license'
    )
    local session = GCSessions.PromotePendingConnection(temporarySource, playerSource)
    GCStates.Set(playerSource, 'validated', 'api_test')
    GCStates.Set(playerSource, 'joining', 'api_test')
    return session
end

local function advanceToSpawned(playerSource)
    GCStates.Set(playerSource, 'client_ready', 'api_test')
    GCStates.Set(playerSource, 'spawn_pending', 'api_test')
    GCStates.Set(playerSource, 'spawning', 'api_test')
    GCStates.Set(playerSource, 'spawn_confirming', 'api_test')
    GCStates.Set(playerSource, 'spawned', 'api_test')
end

local function cleanupApiSession(playerSource)
    GCSpawn.RemovePlayerDecisions(playerSource)
    GCSessions.Remove(playerSource, 'api_test_cleanup')
end

GCTest.Register('api.v1_all_methods_exist', function()
    for _, methodName in ipairs(apiMethods) do
        GCTest.ExpectEqual(type(GCAPI[methodName]), 'function', methodName .. ' exists in API v1')
    end
end, 'contract')

GCTest.Register('api.version_contract', function()
    local dto = GCAPI.GetVersion()

    GCTest.ExpectEqual(type(dto), 'table', 'GetVersion returns table')
    GCTest.ExpectEqual(dto.version, GCVersion.GetString(), 'version DTO matches source of truth')
    GCTest.ExpectEqual(type(GCAPI.GetVersionString()), 'string', 'GetVersionString returns string')
    GCTest.ExpectEqual(type(GCAPI.GetApiVersion()), 'number', 'GetApiVersion returns integer number')
    GCTest.ExpectTrue(GCUtils.IsInteger(GCAPI.GetApiVersion()), 'API version is integer')
    GCTest.ExpectEqual(type(GCAPI.GetProtocolVersion()), 'number', 'GetProtocolVersion returns integer number')
    GCTest.ExpectTrue(GCUtils.IsInteger(GCAPI.GetProtocolVersion()), 'protocol version is integer')

    dto.resource.patch = 999
    dto.apiVersion = 999
    GCTest.ExpectFalse(GCAPI.GetVersion().resource.patch == 999, 'resource DTO is isolated')
    GCTest.ExpectEqual(GCAPI.GetApiVersion(), GCVersion.api, 'API DTO mutation cannot affect internal version')
end, 'contract')

GCTest.Register('api.connection_state_contract', function()
    createApiSession(201)

    GCTest.ExpectTrue(GCAPI.IsPlayerConnected(201), 'active session is connected')
    GCTest.ExpectFalse(GCAPI.IsPlayerReady(201), 'joining is not ready')
    GCTest.ExpectFalse(GCAPI.IsPlayerSpawned(201), 'joining is not spawned')
    GCTest.ExpectEqual(GCAPI.GetPlayerState(201), 'joining', 'GetPlayerState returns lifecycle value')
    GCTest.ExpectFalse(GCAPI.CanUseGameplayFeatures(201), 'joining cannot use gameplay')

    advanceToSpawned(201)
    GCTest.ExpectTrue(GCAPI.IsPlayerReady(201), 'spawned session is ready')
    GCTest.ExpectTrue(GCAPI.IsPlayerSpawned(201), 'spawned predicate is exact')
    GCTest.ExpectTrue(GCAPI.CanUseGameplayFeatures(201), 'API v1 gameplay means exactly spawned')

    cleanupApiSession(201)
    GCTest.ExpectFalse(GCAPI.IsPlayerConnected(201), 'removed session is disconnected')
    GCTest.ExpectNil(GCAPI.GetPlayerState(201), 'disconnected state lookup is nil')
end, 'contract')

GCTest.Register('api.invalid_source_contract', function()
    for _, invalidSource in ipairs({ '1', -1, 0, 1.5 }) do
        GCTest.ExpectFalse(GCAPI.IsPlayerConnected(invalidSource), 'invalid source is not connected')
        GCTest.ExpectFalse(GCAPI.IsPlayerReady(invalidSource), 'invalid source is not ready')
        GCTest.ExpectFalse(GCAPI.IsPlayerSpawned(invalidSource), 'invalid source is not spawned')
        GCTest.ExpectNil(GCAPI.GetPlayerState(invalidSource), 'invalid source state is nil')
        GCTest.ExpectNil(GCAPI.GetPlayerSession(invalidSource), 'invalid source DTO is nil')
        GCTest.ExpectFalse(GCAPI.CanUseGameplayFeatures(invalidSource), 'invalid source cannot use gameplay')
    end

    local decision, errorCode = GCAPI.RequestPlayerSpawn('1')
    GCTest.ExpectNil(decision, 'invalid source creates no spawn decision')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-TYPE-001', 'invalid source has stable API error')
end, 'security')

GCTest.Register('api.player_session_public_dto_contract', function()
    local session = createApiSession(202)
    session.metadata.locale = 'ru'
    session.security = { violations = 99 }
    session.rateLimit = { tokens = 0 }
    local dto = GCAPI.GetPlayerSession(202)

    GCTest.ExpectEqual(type(dto), 'table', 'GetPlayerSession returns Public DTO')
    GCTest.ExpectEqual(dto.source, 202, 'DTO includes source')
    GCTest.ExpectEqual(dto.locale, 'ru', 'DTO includes non-sensitive locale')
    GCTest.ExpectNil(dto.identifiers, 'DTO excludes identifiers')
    GCTest.ExpectNil(dto.primaryIdentifier, 'DTO excludes primary identifier')
    GCTest.ExpectNil(dto.security, 'DTO excludes security state')
    GCTest.ExpectNil(dto.rateLimit, 'DTO excludes rate-limit state')
    GCTest.ExpectNil(dto.spawnDecision, 'DTO excludes spawn decisions')

    dto.state = 'spawned'
    dto.playerName = 'Mutated'
    GCTest.ExpectEqual(session.state, 'joining', 'DTO state mutation cannot affect session')
    GCTest.ExpectFalse(session.playerName == 'Mutated', 'DTO text mutation cannot affect session')
    cleanupApiSession(202)
end, 'security')

GCTest.Register('api.player_identifier_contract', function()
    createApiSession(203)

    GCTest.ExpectEqual(GCAPI.GetPlayerIdentifier(203, 'license'), 'license:api-203', 'license snapshot is returned')
    GCTest.ExpectEqual(GCAPI.GetPlayerIdentifier(203, 'discord'), 'discord:api-203', 'requested allowed type is returned')
    GCTest.ExpectNil(GCAPI.GetPlayerIdentifier(203, 'unknown'), 'unknown identifier type is nil')
    GCTest.ExpectNil(GCAPI.GetPlayerIdentifier(203, nil), 'missing identifier type is nil')
    GCTest.ExpectNil(GCAPI.GetPlayerIdentifier('203', 'license'), 'invalid source identifier is nil')

    cleanupApiSession(203)
    GCTest.ExpectNil(GCAPI.GetPlayerIdentifier(203, 'license'), 'disconnected identifier is nil')
end, 'security')

GCTest.Register('api.request_player_spawn_state_contract', function()
    createApiSession(204)
    local joiningDecision, joiningError = GCAPI.RequestPlayerSpawn(204)
    GCTest.ExpectNil(joiningDecision, 'joining cannot bypass lifecycle')
    GCTest.ExpectEqual(joiningError, 'GC-SPAWN-DECISION-001', 'incorrect state has stable error')

    GCStates.Set(204, 'client_ready', 'api_test')
    local decision, requestError = GCAPI.RequestPlayerSpawn(204)
    GCTest.ExpectNotNil(decision, 'client_ready can request spawn')
    GCTest.ExpectNil(requestError, 'valid request has no error')
    GCTest.ExpectTrue(GCStates.Is(204, 'spawn_confirming'), 'public API uses full state machine')

    local duplicate, duplicateError = GCAPI.RequestPlayerSpawn(204)
    GCTest.ExpectNil(duplicate, 'spawn_confirming duplicate creates no decision')
    GCTest.ExpectEqual(duplicateError, 'GC-SPAWN-DECISION-001', 'duplicate request is rejected')
    GCTest.ExpectEqual(GCSessions.Get(204).spawnDecision, decision, 'duplicate keeps original transaction')
    cleanupApiSession(204)

    GCSessions.CreateRecoveredSession(205, 'Recovered205', {
        license = 'license:api-recovered-205'
    }, 'license:api-recovered-205', 'license')
    local resyncDecision = GCAPI.RequestPlayerSpawn(205)
    GCTest.ExpectNil(resyncDecision, 'resyncing cannot bypass recovery handshake')
    cleanupApiSession(205)

    createApiSession(206)
    advanceToSpawned(206)
    local spawnedDecision = GCAPI.RequestPlayerSpawn(206)
    GCTest.ExpectNil(spawnedDecision, 'spawned duplicate creates no second spawn')
    cleanupApiSession(206)
end, 'security')

GCTest.Register('api.notification_contract', function()
    createApiSession(207)
    local originalPlayer = GCNotifications.SendToPlayer
    local originalAll = GCNotifications.SendToAll
    local playerCall = nil
    local allCall = nil

    GCNotifications.SendToPlayer = function(playerSource, message, notificationType)
        playerCall = { playerSource, message, notificationType }
        return true
    end
    GCNotifications.SendToAll = function(message, notificationType)
        allCall = { message, notificationType }
        return true
    end

    local playerSuccess = GCAPI.NotifyPlayer(207, 'Hello', 'success')
    local allSuccess = GCAPI.NotifyAll('Maintenance', 'warning')

    GCNotifications.SendToPlayer = originalPlayer
    GCNotifications.SendToAll = originalAll

    GCTest.ExpectTrue(playerSuccess, 'NotifyPlayer delegates validated server-side side effect')
    GCTest.ExpectEqual(playerCall[1], 207, 'NotifyPlayer preserves target')
    GCTest.ExpectEqual(playerCall[2], 'Hello', 'NotifyPlayer preserves message')
    GCTest.ExpectEqual(playerCall[3], 'success', 'NotifyPlayer preserves type')
    GCTest.ExpectTrue(allSuccess, 'NotifyAll delegates broadcast side effect')
    GCTest.ExpectEqual(allCall[1], 'Maintenance', 'NotifyAll preserves message')
    GCTest.ExpectEqual(allCall[2], 'warning', 'NotifyAll preserves type')

    local invalidSuccess, invalidError = GCAPI.NotifyPlayer('207', 'Hello')
    GCTest.ExpectFalse(invalidSuccess, 'NotifyPlayer rejects invalid target before side effect')
    GCTest.ExpectEqual(invalidError, 'GC-NOTIFY-001', 'invalid target has stable error')

    local longMessage = string.rep('x', 300)
    local serviceSuccess = GCAPI.NotifyPlayer(207, longMessage, 'info')
    GCTest.ExpectTrue(serviceSuccess, 'notification service accepts and bounds long message')
    cleanupApiSession(207)
end, 'contract')
