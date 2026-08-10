GCModuleTest.Register('identity.state_machine_registration_flow', 'unit', function()
    IdentityTest.Reset()
    local session = GCIdentityStates.Create(11)
    GCModuleTest.ExpectEqual(session.state, 'uninitialized', 'session starts uninitialized')
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'loading'), 'loading allowed')
    GCModuleTest.ExpectTrue(
        GCIdentityStates.Transition(11, 'registration_required'),
        'registration_required allowed'
    )
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'registering'), 'registering allowed')
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'authorized'), 'authorized allowed')
    GCModuleTest.ExpectTrue(
        GCIdentityStates.Transition(11, 'character_required'),
        'character_required allowed'
    )
    GCModuleTest.ExpectTrue(
        GCIdentityStates.Transition(11, 'character_selected'),
        'character_selected allowed'
    )
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'ready'), 'ready allowed')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(11), 'ready identity is authorized')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsReady(11), 'ready predicate is exact')
end)

GCModuleTest.Register('identity.state_machine_rejects_skip', 'unit', function()
    IdentityTest.Reset()
    GCIdentityStates.Create(12)
    local transitioned, transitionError = GCIdentityStates.Transition(12, 'ready')
    GCModuleTest.ExpectFalse(transitioned, 'uninitialized cannot skip to ready')
    GCModuleTest.ExpectEqual(
        transitionError,
        'GC-IDENTITY-STATE-TRANSITION-INVALID',
        'invalid transition has stable code'
    )
end)

GCModuleTest.Register('identity.state_generation_rejects_stale_work', 'runtime', function()
    IdentityTest.Reset()
    local first = GCIdentityStates.Create(13)
    local firstGeneration = first.generation
    GCIdentityStates.Remove(13)
    local second = GCIdentityStates.Create(13)
    GCModuleTest.ExpectFalse(
        GCIdentityStates.IsCurrent(13, firstGeneration),
        'removed session generation becomes stale'
    )
    GCModuleTest.ExpectTrue(
        GCIdentityStates.IsCurrent(13, second.generation),
        'replacement generation is current'
    )
end)

GCModuleTest.Register('identity.state_disconnect_cleanup', 'unit', function()
    IdentityTest.Reset()
    GCIdentityStates.Create(14)
    GCIdentityService.Disconnect(14)
    GCModuleTest.ExpectNil(GCIdentityStates.Get(14), 'disconnect removes runtime session')
end)
