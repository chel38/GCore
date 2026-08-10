GCModuleTest.Register('identity.resource_restart_restores_selection', 'runtime', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(51)
    local character = GCIdentityService.CreateCharacter(51, {
        protocolVersion = 1,
        requestId = 'request_7001',
        firstName = 'Restart',
        lastName = 'Safe'
    })
    GCIdentityService.SelectCharacter(51, {
        protocolVersion = 1,
        requestId = 'request_7002',
        characterId = character.id
    })

    local loaded, loadError = IdentityTest.ReloadFromStorage()
    GCModuleTest.ExpectTrue(loaded, 'persisted repository reloads')
    GCModuleTest.ExpectNil(loadError, 'repository reload has no error')
    local snapshot, recoverError = GCIdentityService.Resolve(51)
    GCModuleTest.ExpectNil(recoverError, 'session recovery succeeds')
    GCModuleTest.ExpectEqual(snapshot.state, 'ready', 'selected identity returns to ready')
    GCModuleTest.ExpectEqual(snapshot.selectedCharacter.id, character.id, 'selection survives restart')
end)

GCModuleTest.Register('identity.core_restart_rebuilds_online_sessions', 'runtime', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(52)
    IdentityTest.SetOnlinePlayers({ '52' })
    IdentityTest.EmitEvent('onResourceStop', 0, 'gc_core')
    GCModuleTest.ExpectNil(GCIdentityStates.Get(52), 'core stop clears cached identity session')
    IdentityTest.EmitEvent('onResourceStart', 0, 'gc_core')
    GCModuleTest.ExpectNotNil(GCIdentityStates.Get(52), 'core start rebuilds online identity session')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(52), 'recovered account is authorized')
end)

GCModuleTest.Register('identity.disconnect_clears_runtime_not_persistence', 'runtime', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(53)
    IdentityTest.EmitEvent('playerDropped', 53)
    GCModuleTest.ExpectNil(GCIdentityStates.Get(53), 'drop clears runtime state')
    local snapshot = GCIdentityService.Resolve(53)
    GCModuleTest.ExpectNotNil(snapshot.account, 'persisted account resolves after reconnect')
    GCModuleTest.ExpectEqual(snapshot.account.id, 1, 'reconnect reuses persisted account')
end)

GCModuleTest.Register('identity.invalid_storage_fails_closed', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.SetInvalidStorage()
    GCModuleTest.Load('server/repository.lua')
    local loaded, loadError = GCIdentityRepository.Load()
    GCIdentityService.SetAvailable(loaded)
    GCModuleTest.ExpectFalse(loaded, 'corrupt storage is rejected')
    GCModuleTest.ExpectEqual(loadError, 'GC-IDENTITY-STORAGE-DECODE', 'decode error is stable')
    local snapshot, resolveError = GCIdentityService.Resolve(54)
    GCModuleTest.ExpectNil(snapshot, 'unloaded storage creates no identity')
    GCModuleTest.ExpectEqual(resolveError, 'GC-IDENTITY-STORAGE-NOT-LOADED', 'service fails closed')
end)
