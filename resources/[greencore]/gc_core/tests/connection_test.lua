-- RU: Тесты подключения GreenCore.
-- EN: GreenCore connection tests.

-- RU: Тест маскировки идентификатора.
-- EN: Test of identifier masking.
GCTest.Register('connection.mask_identifier', function()
    local masked = GCIdentifiers.Mask('license:12ab34cd56ef7890')

    GCTest.ExpectNotNil(masked, 'identifier is masked')
    GCTest.ExpectTrue(masked:find('^license:') ~= nil, 'masked identifier keeps type prefix')
    GCTest.ExpectTrue(masked:find('12ab34cd56ef7890', 1, true) == nil, 'masked identifier hides full value')
end)

-- RU: Тест маскировки короткого идентификатора.
-- EN: Test of masking a short identifier.
GCTest.Register('connection.mask_short_identifier', function()
    local masked = GCIdentifiers.Mask('license:abc')

    GCTest.ExpectNotNil(masked, 'short identifier is masked')
    GCTest.ExpectTrue(masked:find('^license:') ~= nil, 'short masked identifier keeps type prefix')
end)

-- RU: Тест маскировки невалидного идентификатора.
-- EN: Test of masking an invalid identifier.
GCTest.Register('connection.mask_invalid_identifier', function()
    local masked = GCIdentifiers.Mask(123)

    GCTest.ExpectEqual(masked, '<invalid>', 'invalid identifier returns <invalid>')
end)

-- RU: Тест сравнения идентификаторов.
-- EN: Test of identifier comparison.
GCTest.Register('connection.compare_identifiers', function()
    GCTest.ExpectTrue(GCIdentifiers.Compare('license:abc', 'license:abc'), 'equal identifiers match')
    GCTest.ExpectFalse(GCIdentifiers.Compare('license:abc', 'license:def'), 'different identifiers do not match')
    GCTest.ExpectFalse(GCIdentifiers.Compare(nil, 'license:abc'), 'nil identifier does not match')
end)

-- RU: Тест получения основного идентификатора.
-- EN: Test of getting the primary identifier.
GCTest.Register('connection.get_primary', function()
    -- RU: Создаём тестовую сессию с license через pending + promote.
    -- EN: Create a test session with license via pending + promote.
    local identifiers = {
        license = 'license:test-primary-1'
    }

    GCSessions.CreatePendingConnection(60010, 'TestPlayer10', identifiers, identifiers.license, 'license')
    local session, _ = GCSessions.PromotePendingConnection(60010, 10)

    GCTest.ExpectNotNil(session, 'session is created')
    GCTest.ExpectEqual(session.primaryIdentifierType, 'license', 'primary type is license')
    GCTest.ExpectEqual(session.primaryIdentifier, 'license:test-primary-1', 'primary identifier is correct')

    GCSessions.Remove(10, 'test_cleanup')
end)

-- RU: Тест получения запасного идентификатора.
-- EN: Test of getting the fallback identifier.
GCTest.Register('connection.get_fallback', function()
    -- RU: Создаём тестовую сессию только с license2.
    -- EN: Create a test session with only license2.
    local identifiers = {
        license2 = 'license2:test-fallback-1'
    }

    GCSessions.CreatePendingConnection(60011, 'TestPlayer11', identifiers, identifiers.license2, 'license2')
    local session, _ = GCSessions.PromotePendingConnection(60011, 11)

    GCTest.ExpectNotNil(session, 'session is created')
    GCTest.ExpectEqual(session.primaryIdentifierType, 'license2', 'primary type is license2')
    GCTest.ExpectEqual(session.primaryIdentifier, 'license2:test-fallback-1', 'fallback identifier is correct')

    GCSessions.Remove(11, 'test_cleanup')
end)

GCTest.Register('connection.deferral_references_are_not_captured_by_timer', function()
    local originalSource = source
    local originalGetAll = GCIdentifiers.GetAll
    local originalSetTimeout = SetTimeout
    local scheduledTimers = 0
    local calls = {}
    local doneArity

    source = 60046
    GCIdentifiers.GetAll = function()
        return { license = 'license:deferral-lifetime-60046' }
    end
    SetTimeout = function()
        scheduledTimers = scheduledTimers + 1
    end

    local deferrals = {
        defer = function() calls[#calls + 1] = 'defer' end,
        update = function() calls[#calls + 1] = 'update' end,
        done = function(...)
            doneArity = select('#', ...)
            calls[#calls + 1] = 'done'
        end
    }

    GCConnection.HandleConnecting('DeferralLifetime', function() end, deferrals)

    source = originalSource
    GCIdentifiers.GetAll = originalGetAll
    SetTimeout = originalSetTimeout

    GCTest.ExpectEqual(scheduledTimers, 0, 'runtime-owned deferral references are never captured by SetTimeout')
    GCTest.ExpectEqual(table.concat(calls, ','), 'defer,update,done', 'deferral lifecycle completes in the event coroutine')
    GCTest.ExpectEqual(doneArity, 0, 'successful deferral calls Cfx done with no explicit nil argument')
    GCTest.ExpectNotNil(GCSessions.GetPendingConnection(60046), 'validated connection remains pending for playerJoining')

    GCSessions.RemovePendingConnection(60046)
end, 'runtime')

GCTest.Register('connection.deferral_deadline_is_bounded', function()
    local originalSource = source
    local originalNowMs = GCUtils.NowMs
    local originalGetAll = GCIdentifiers.GetAll
    local originalTimeout = GCConfig.Connection.deferralTimeoutMs
    local nowCalls = 0
    local identifiersRead = false
    local doneMessage

    source = 60047
    GCConfig.Connection.deferralTimeoutMs = 1
    GCUtils.NowMs = function()
        nowCalls = nowCalls + 1
        return nowCalls == 1 and 0 or 2
    end
    GCIdentifiers.GetAll = function()
        identifiersRead = true
        return {}
    end

    GCConnection.HandleConnecting('DeferralDeadline', function() end, {
        defer = function() end,
        update = function() end,
        done = function(message) doneMessage = message end
    })

    source = originalSource
    GCUtils.NowMs = originalNowMs
    GCIdentifiers.GetAll = originalGetAll
    GCConfig.Connection.deferralTimeoutMs = originalTimeout

    GCTest.ExpectTrue(identifiersRead, 'temporary-source identifiers are captured before the first yield')
    GCTest.ExpectEqual(doneMessage, GC_T(GCConfig.General.locale or 'en', 'connection.timeout'), 'deadline returns stable timeout message')
    GCTest.ExpectNil(GCSessions.GetPendingConnection(60047), 'timed out connection leaves no pending state')
end, 'runtime')

local function recoveredSession(playerSource)
    return GCSessions.CreateRecoveredSession(
        playerSource,
        'Recovered' .. tostring(playerSource),
        { license = 'license:recovery-' .. tostring(playerSource) },
        'license:recovery-' .. tostring(playerSource),
        'license'
    )
end

local function handshake(overrides)
    local payload = {
        clientVersion = GCVersion.GetString(),
        protocolVersion = GCVersion.GetProtocolVersion(),
        locale = 'en'
    }

    for key, value in pairs(overrides or {}) do
        payload[key] = value
    end

    return payload
end

GCTest.Register('recovery.lost_force_resync_client_ready_succeeds', function()
    local session = recoveredSession(40)
    local original = GCPlayers.HasAuthoritativeLivePed
    GCPlayers.HasAuthoritativeLivePed = function() return true end

    local success, errorCode = GCConnection.HandleClientReady(40, handshake())
    GCPlayers.HasAuthoritativeLivePed = original

    GCTest.ExpectTrue(success, 'ordinary clientReady completes recovered session')
    GCTest.ExpectNil(errorCode, 'recovery clientReady has no error')
    GCTest.ExpectTrue(GCStates.Is(40, 'spawned'), 'authoritative live ped restores spawned')
    GCTest.ExpectNil(session.metadata.clientPedAliveHint, 'clientReady creates no authoritative ped hint')
    GCSessions.Remove(40, 'test_cleanup')
end, 'integration')

GCTest.Register('recovery.client_hint_never_overrides_server', function()
    local session = recoveredSession(41)
    local original = GCPlayers.HasAuthoritativeLivePed
    GCPlayers.HasAuthoritativeLivePed = function() return false end

    local success = GCConnection.HandleResyncReady(41, handshake({ isPedAlive = true }))
    GCPlayers.HasAuthoritativeLivePed = original

    GCTest.ExpectTrue(success, 'recovery enters safe spawn flow')
    GCTest.ExpectTrue(session.metadata.clientPedAliveHint, 'client hint is retained for diagnostics')
    GCTest.ExpectFalse(GCStates.Is(41, 'spawned'), 'fake alive hint cannot set spawned')
    GCTest.ExpectTrue(GCStates.Is(41, 'spawn_confirming'), 'server creates a verified spawn transaction')
    GCSpawn.RemovePlayerDecisions(41)
    GCSessions.Remove(41, 'test_cleanup')
end, 'security')

GCTest.Register('recovery.duplicate_hello_is_idempotent', function()
    local session = recoveredSession(42)
    local original = GCPlayers.HasAuthoritativeLivePed
    GCPlayers.HasAuthoritativeLivePed = function() return true end

    local first = GCConnection.HandleClientReady(42, handshake())
    local second = GCConnection.HandleClientReady(42, handshake())
    GCPlayers.HasAuthoritativeLivePed = original

    GCTest.ExpectTrue(first, 'first hello succeeds')
    GCTest.ExpectTrue(second, 'duplicate hello succeeds idempotently')
    GCTest.ExpectEqual(GCSessions.Get(42), session, 'duplicate hello keeps the same session')
    GCTest.ExpectTrue(GCStates.Is(42, 'spawned'), 'duplicate hello keeps spawned state')
    GCSessions.Remove(42, 'test_cleanup')
end, 'integration')

GCTest.Register('recovery.stale_resync_ready_does_not_change_state', function()
    local identifiers = { license = 'license:stale-resync-43' }
    GCSessions.CreatePendingConnection(60043, 'Player43', identifiers, identifiers.license, 'license')
    GCSessions.PromotePendingConnection(60043, 43)
    GCStates.Set(43, 'validated', 'test')
    GCStates.Set(43, 'joining', 'test')
    GCStates.Set(43, 'client_ready', 'test')
    GCStates.Set(43, 'spawn_pending', 'test')

    local success = GCConnection.HandleResyncReady(43, handshake({ isPedAlive = true }))

    GCTest.ExpectTrue(success, 'stale resyncReady is acknowledged safely')
    GCTest.ExpectTrue(GCStates.Is(43, 'spawn_pending'), 'stale response changes no lifecycle state')
    GCSessions.Remove(43, 'test_cleanup')
end, 'security')

GCTest.Register('recovery.protocol_mismatch_is_rejected', function()
    recoveredSession(44)
    local success, errorCode = GCConnection.HandleClientReady(44, handshake({ protocolVersion = 999 }))

    GCTest.ExpectFalse(success, 'incompatible recovery hello is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PROTOCOL-MISMATCH-001', 'stable protocol error is returned')
    GCTest.ExpectTrue(GCStates.Is(44, 'resyncing'), 'protocol mismatch cannot advance recovery')
    GCSessions.Remove(44, 'test_cleanup')
end, 'security')

GCTest.Register('recovery.timeout_is_bounded_and_cleans_lifecycle', function()
    if not GCTestHarness then
        GCTest.ExpectTrue(true, 'standalone timer harness owns this regression')
        return
    end

    local originalGetPlayers = GetPlayers
    local originalGetAll = GCIdentifiers.GetAll
    local originalGetPrimary = GCIdentifiers.GetPrimary
    local timeout = GCConfig.Connection.resyncReadyTimeoutMs
    local interval = GCConfig.Connection.resyncForceIntervalMs
    local maxAttempts = GCConfig.Connection.resyncForceMaxAttempts

    GetPlayers = function() return { '45' } end
    GCIdentifiers.GetAll = function() return { license = 'license:recovery-timeout-45' } end
    GCIdentifiers.GetPrimary = function()
        return 'license:recovery-timeout-45', 'license'
    end
    GCConfig.Connection.resyncReadyTimeoutMs = 100
    GCConfig.Connection.resyncForceIntervalMs = 10
    GCConfig.Connection.resyncForceMaxAttempts = 3
    GCServerRuntime.running = true
    GCTestHarness.ClearDroppedPlayers()

    local startedAt = GCTestHarness.NowMs()
    local recovered = GCPlayers.RecoverOnlinePlayers()
    GCTestHarness.RunTimersUntil(startedAt + 100)

    GetPlayers = originalGetPlayers
    GCIdentifiers.GetAll = originalGetAll
    GCIdentifiers.GetPrimary = originalGetPrimary
    GCConfig.Connection.resyncReadyTimeoutMs = timeout
    GCConfig.Connection.resyncForceIntervalMs = interval
    GCConfig.Connection.resyncForceMaxAttempts = maxAttempts

    local session = GCSessions.Get(45)
    local drops = GCTestHarness.GetDroppedPlayers()
    GCTest.ExpectEqual(recovered, 1, 'one online player gets one recovered session')
    GCTest.ExpectEqual(session.recoveryPromptAttempts, 3, 'forceResync attempts are bounded')
    GCTest.ExpectTrue(GCStates.Is(45, 'error'), 'unanswered recovery enters error at one timeout')
    GCTest.ExpectEqual(#drops, 1, 'recovery timeout drops exactly once')

    GCSessions.Remove(45, 'test_cleanup')
    GCServerRuntime.running = nil
end, 'runtime')
