GCModuleTest.Register('identity.resource_restart_restores_selection', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(51, 'restart@example.test', 'register_5100')
    local character = GCIdentityService.CreateCharacter(51, {
        protocolVersion = 1,
        requestId = 'request_5101',
        firstName = 'Restart',
        lastName = 'Safe'
    })
    GCIdentityService.SelectCharacter(51, {
        protocolVersion = 1,
        requestId = 'request_5102',
        characterId = character.id
    })

    GCIdentityStates.ClearAll()
    GCIdentityRateLimit.ClearAll()
    local snapshot, recoverError = GCIdentityService.Resolve(51)
    GCModuleTest.ExpectNil(recoverError, 'session recovery succeeds')
    GCModuleTest.ExpectEqual(snapshot.state, 'ready', 'selected identity returns to ready')
    GCModuleTest.ExpectEqual(snapshot.selectedCharacter.id, character.id, 'selection survives restart')
end)

GCModuleTest.Register('identity.registration_restart_creates_no_account', 'runtime', function()
    local memory = IdentityTest.Reset()
    local first = GCIdentityService.Resolve(52)
    GCModuleTest.ExpectEqual(first.state, 'registration_required', 'first session needs registration')
    GCIdentityStates.ClearAll()
    local second = GCIdentityService.Resolve(52)
    GCModuleTest.ExpectEqual(second.state, 'registration_required', 'restart restores registration flow')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'recovery never auto-creates account')
end)

GCModuleTest.Register('identity.core_restart_rebuilds_online_sessions', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(53, 'core-restart@example.test', 'register_5300')
    IdentityTest.SetOnlinePlayers({ '53' })
    IdentityTest.EmitEvent('onResourceStop', 0, 'gc_core')
    GCModuleTest.ExpectNil(GCIdentityStates.Get(53), 'core stop clears cached identity session')
    IdentityTest.EmitEvent('onResourceStart', 0, 'gc_core')
    GCModuleTest.ExpectNotNil(GCIdentityStates.Get(53), 'core start rebuilds online identity session')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(53), 'recovered account is authorized')
end)

GCModuleTest.Register('identity.disconnect_clears_runtime_not_persistence', 'runtime', function()
    IdentityTest.Reset()
    local initial = IdentityTest.ResolveAndRegister(54, 'drop@example.test', 'register_5400')
    IdentityTest.EmitEvent('playerDropped', 54)
    GCModuleTest.ExpectNil(GCIdentityStates.Get(54), 'drop clears runtime state')
    local snapshot = GCIdentityService.Resolve(54)
    GCModuleTest.ExpectNotNil(snapshot.account, 'persistent account resolves after reconnect')
    GCModuleTest.ExpectEqual(snapshot.account.id, initial.account.id, 'reconnect reuses account')
end)

GCModuleTest.Register('identity.storage_failure_never_becomes_not_found', 'runtime', function()
    local memory = IdentityTest.Reset()
    memory.SetFailure('GC-IDENTITY-DATABASE-QUERY-FAILED')
    local snapshot, resolveError = GCIdentityService.Resolve(55)
    GCModuleTest.ExpectNil(snapshot, 'failed database returns no identity')
    GCModuleTest.ExpectEqual(
        resolveError,
        'GC-IDENTITY-DATABASE-QUERY-FAILED',
        'database error remains distinct from missing account'
    )
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'database failure creates no account')
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(55), 'database failure fails closed')
end)

GCModuleTest.Register('identity.hello_during_database_bootstrap_waits_for_recovery', 'runtime', function()
    IdentityTest.Reset()
    GCIdentityService.SetAvailable(false)
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 56, {
        protocolVersion = 1
    })
    GCModuleTest.ExpectEqual(
        #IdentityTest.clientEvents,
        0,
        'bootstrap race does not flash a misleading client error'
    )
    GCIdentityService.SetAvailable(true)
end)

GCModuleTest.Register('identity.hello_while_core_is_not_ready_retries_silently', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.core.ready[57] = false
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 57, {
        protocolVersion = 1
    })
    GCModuleTest.ExpectEqual(
        #IdentityTest.clientEvents,
        0,
        'transient core readiness race does not become a terminal UI error'
    )
end)

GCModuleTest.Register('identity.degraded_database_returns_terminal_diagnostic', 'runtime', function()
    IdentityTest.Reset()
    GCIdentityService.SetAvailable(false)
    GCIdentityDatabase.MarkRuntimeFailure('GC-IDENTITY-DATABASE-UNAVAILABLE')
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 58, {
        protocolVersion = 1
    })
    GCModuleTest.ExpectEqual(#IdentityTest.clientEvents, 1, 'degraded database answers the client')
    GCModuleTest.ExpectEqual(
        IdentityTest.LastClientEvent().payload.code,
        'GC-IDENTITY-DATABASE-UNAVAILABLE',
        'database outage has a visible stable diagnostic'
    )
end)
