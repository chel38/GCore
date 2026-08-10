GCModuleTest.Register('identity.state_machine_explicit_flow', 'unit', function()
    IdentityTest.Reset()
    local session = GCIdentityStates.Create(11)
    GCModuleTest.ExpectEqual(session.state, 'unknown', 'session starts unknown')
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'account_required'), 'account_required allowed')
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'authorized'), 'authorized allowed')
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'character_required'), 'character_required allowed')
    GCModuleTest.ExpectTrue(GCIdentityStates.Transition(11, 'ready'), 'ready allowed')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(11), 'ready identity is authorized')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsReady(11), 'ready predicate is exact')
end)

GCModuleTest.Register('identity.state_machine_rejects_skip', 'unit', function()
    IdentityTest.Reset()
    GCIdentityStates.Create(12)
    local transitioned, transitionError = GCIdentityStates.Transition(12, 'ready')
    GCModuleTest.ExpectFalse(transitioned, 'unknown cannot skip to ready')
    GCModuleTest.ExpectEqual(
        transitionError,
        'GC-IDENTITY-STATE-TRANSITION-INVALID',
        'invalid transition has stable code'
    )
end)

GCModuleTest.Register('identity.state_disconnect_cleanup', 'unit', function()
    IdentityTest.Reset()
    GCIdentityStates.Create(13)
    GCIdentityService.Disconnect(13)
    GCModuleTest.ExpectNil(GCIdentityStates.Get(13), 'disconnect removes runtime session')
end)
