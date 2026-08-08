-- RU: Regression tests: локальный TriggerEvent не может выполнить server-only handler.
-- EN: Regression tests: a local TriggerEvent cannot execute a server-only handler.

local serverOnlyEvents = {
    GCEvents.Client.connectionAccepted,
    GCEvents.Client.spawnApproved,
    GCEvents.Client.spawnRejected,
    GCEvents.Client.spawnConfirmed,
    GCEvents.Client.forceResync,
    GCEvents.Client.notify
}

for _, eventName in ipairs(serverOnlyEvents) do
    GCTest.Register(('client_event_security.local_spoof.%s'):format(eventName), function()
        local previousSource = source
        local executions = 0
        local guarded = GCClientSecurity.GuardServerEvent(function()
            executions = executions + 1
        end)

        source = 0
        local localAccepted = guarded({ forged = true })
        source = SERVER_EVENT_SOURCE_FOR_TESTS or 65535
        local serverAccepted = guarded({ valid = true })
        source = previousSource

        GCTest.ExpectFalse(localAccepted, eventName .. ' rejects local origin')
        GCTest.ExpectEqual(executions, 1, eventName .. ' executes only server origin')
        GCTest.ExpectTrue(serverAccepted, eventName .. ' accepts server origin')

        if GCTestHarness and type(TriggerEvent) == 'function' then
            local productionAccepted = TriggerEvent(eventName, { forged = true })
            GCTest.ExpectFalse(productionAccepted, eventName .. ' production handler rejects TriggerEvent spoof')
        end
    end, 'security')
end

GCTest.Register('client_readiness.initial_hello_requires_only_loaded_resource', function()
    if not GCTestHarness then
        GCTest.ExpectTrue(true, 'standalone client-native harness owns this regression')
        return
    end

    local originalSessionStarted = NetworkIsSessionStarted
    local originalPlayerActive = NetworkIsPlayerActive
    local originalPlayerId = PlayerId
    local originalPlayerPedId = PlayerPedId
    local originalEntityExists = DoesEntityExist
    local activePlayer

    NetworkIsSessionStarted = function() return false end
    NetworkIsPlayerActive = function(player)
        activePlayer = player
        return false
    end
    PlayerId = function() return 7 end
    PlayerPedId = function() return 0 end
    DoesEntityExist = function() return false end

    local ready = GCClientReadiness.IsClientReady()

    NetworkIsSessionStarted = originalSessionStarted
    NetworkIsPlayerActive = originalPlayerActive
    PlayerId = originalPlayerId
    PlayerPedId = originalPlayerPedId
    DoesEntityExist = originalEntityExists

    GCTest.ExpectTrue(ready, 'loaded client resource can send hello before network activation')
    GCTest.ExpectNil(activePlayer, 'inactive initial player cannot gate the hello handshake')
    GCTest.ExpectTrue(ready, 'missing initial player ped cannot deadlock server-owned spawning')
end, 'runtime')

GCTest.Register('client_readiness.hello_retries_are_bounded', function()
    if not GCTestHarness then
        GCTest.ExpectTrue(true, 'standalone client retry harness owns this regression')
        return
    end

    local originalTrigger = TriggerServerEvent
    local originalDiagnostics = GCClientDiagnostics
    local originalInterval = GCConfig.Connection.clientHelloRetryIntervalMs
    local originalMaxAttempts = GCConfig.Connection.clientHelloMaxAttempts
    local originalTimeout = GCConfig.Connection.clientReadyTimeoutMs
    local attempts = 0

    TriggerServerEvent = function() attempts = attempts + 1 end
    GCClientDiagnostics = { Report = function() end }
    GCConfig.Connection.clientHelloRetryIntervalMs = 1
    GCConfig.Connection.clientHelloMaxAttempts = 3
    GCConfig.Connection.clientReadyTimeoutMs = 100
    GCClientReadiness.Reset()

    GCClientReadiness.WaitForReadiness()

    TriggerServerEvent = originalTrigger
    GCClientDiagnostics = originalDiagnostics
    GCConfig.Connection.clientHelloRetryIntervalMs = originalInterval
    GCConfig.Connection.clientHelloMaxAttempts = originalMaxAttempts
    GCConfig.Connection.clientReadyTimeoutMs = originalTimeout

    GCTest.ExpectEqual(attempts, 3, 'hello retries stop at the configured attempt limit')
end, 'runtime')

GCTest.Register('client_readiness.server_ack_stops_retries', function()
    if not GCTestHarness then
        GCTest.ExpectTrue(true, 'standalone client ACK harness owns this regression')
        return
    end

    local originalTrigger = TriggerServerEvent
    local attempts = 0

    GCClientReadiness.Reset()
    TriggerServerEvent = function()
        attempts = attempts + 1
        GCClientReadiness.Acknowledge()
    end

    GCClientReadiness.WaitForReadiness()
    TriggerServerEvent = originalTrigger

    GCTest.ExpectEqual(attempts, 1, 'first valid server ACK cancels the retry loop')
end, 'runtime')

GCTest.Register('client_readiness.retry_cadence_respects_server_rate_limits', function()
    local interval = GCConfig.Connection.clientHelloRetryIntervalMs

    for _, actionName in ipairs({ 'clientReady', 'resyncReady' }) do
        local limit = GCConfig.Security.rateLimits[actionName]
        local attemptsPerWindow = math.floor(limit.windowMs / interval) + 1

        GCTest.ExpectTrue(interval >= limit.intervalMs, actionName .. ' retry interval respects minimum rate interval')
        GCTest.ExpectTrue(attemptsPerWindow <= limit.maxAttempts, actionName .. ' retry cadence fits the rate window')
    end
end, 'security')
