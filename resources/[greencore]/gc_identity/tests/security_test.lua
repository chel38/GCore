GCModuleTest.Register('identity.foreign_character_is_rejected', 'security', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(31, 'owner-a@example.test', 'register_3100')
    IdentityTest.ResolveAndRegister(32, 'owner-b@example.test', 'register_3200')
    local foreign = GCIdentityService.CreateCharacter(32, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'request_3201',
        firstName = 'Foreign',
        lastName = 'Owner'
    })
    local selected, selectError = GCIdentityService.SelectCharacter(31, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'request_3101',
        characterId = foreign.id
    })
    GCModuleTest.ExpectNil(selected, 'foreign character is not selected')
    GCModuleTest.ExpectEqual(
        selectError,
        'GC-IDENTITY-CHARACTER-NOT-OWNED',
        'ownership failure has stable code'
    )
    GCModuleTest.ExpectFalse(GCIdentityStates.IsReady(31), 'foreign ID cannot make identity ready')
end)

GCModuleTest.Register('identity.network_rate_limit_rejects_abuse', 'security', function()
    IdentityTest.Reset()

    for _ = 1, GCIdentityConfig.rateLimits.hello.maximum + 1 do
        IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 33, {
            protocolVersion = GCIdentityVersion.protocol
        })
    end

    local response = IdentityTest.LastClientEvent()
    GCModuleTest.ExpectEqual(response.name, GCIdentityEvents.client.rejected, 'abuse emits rejection')
    GCModuleTest.ExpectEqual(response.payload.code, 'GC-IDENTITY-RATE-LIMIT', 'hello abuse is rate-limited')
end)

GCModuleTest.Register('identity.wrong_core_lifecycle_rejects', 'security', function()
    IdentityTest.Reset()
    IdentityTest.core.gameplay[34] = false
    GCIdentityService.Resolve(34)
    local account, registrationError = GCIdentityService.RegisterAccount(34, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'register_3400',
        email = 'wrong-state@example.test'
    })
    GCModuleTest.ExpectNil(account, 'non-gameplay player cannot register')
    GCModuleTest.ExpectEqual(
        registrationError,
        'GC-IDENTITY-CORE-GAMEPLAY-NOT-READY',
        'core lifecycle error is stable'
    )
end)

GCModuleTest.Register('identity.server_event_rejects_forged_authority_fields', 'security', function()
    IdentityTest.Reset()
    IdentityTest.EmitNetwork(GCIdentityEvents.server.registerAccount, 35, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'register_3500',
        email = 'forged@example.test',
        accountId = 999,
        license = 'license:forged'
    })
    local response = IdentityTest.LastClientEvent()
    GCModuleTest.ExpectEqual(response.name, GCIdentityEvents.client.rejected, 'rejection event emitted')
    GCModuleTest.ExpectEqual(
        response.payload.code,
        'GC-IDENTITY-PAYLOAD-SCHEMA',
        'client accountId and license are rejected before domain logic'
    )
    GCModuleTest.ExpectEqual(
        GCIdentityRepository.TestAdapter().GetCounts().accounts,
        0,
        'forged payload creates no account'
    )
end)

GCModuleTest.Register('identity.disconnect_during_storage_result_is_stale', 'runtime', function()
    local memory = IdentityTest.Reset()
    GCIdentityService.Resolve(36)
    memory.SetBeforeOperation(function()
        GCIdentityService.Disconnect(36)
    end)
    local account, registrationError = GCIdentityService.RegisterAccount(36, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'register_3600',
        email = 'disconnect@example.test'
    })
    GCModuleTest.ExpectNil(account, 'stale registration result is not committed to runtime')
    GCModuleTest.ExpectEqual(
        registrationError,
        'GC-IDENTITY-SESSION-STALE',
        'disconnect invalidates async generation'
    )
    GCModuleTest.ExpectNil(GCIdentityStates.Get(36), 'disconnect leaves no runtime identity')
    local reconnect = GCIdentityService.Resolve(36)
    GCModuleTest.ExpectEqual(
        reconnect.state,
        'registration_required',
        'disconnect before challenge creation leaves a clean registration flow'
    )
    GCModuleTest.ExpectEqual(
        memory.GetCounts().accounts,
        0,
        'unverified registration never creates an account'
    )
end)

GCModuleTest.Register('identity.duplicate_email_across_players_is_rejected', 'security', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(37, 'shared@example.test', 'register_3700')
    GCIdentityService.Resolve(38)
    local account, registrationError = GCIdentityService.RegisterAccount(38, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'register_3800',
        email = 'shared@example.test'
    })
    GCModuleTest.ExpectNil(account, 'second account cannot claim same email')
    GCModuleTest.ExpectEqual(registrationError, 'GC-IDENTITY-EMAIL-TAKEN', 'email conflict stable')
end)

GCModuleTest.Register('identity.client_event_origin_guard', 'security', function()
    local executions = 0
    GCIdentityClientSecurity.RegisterServerEvent('gc_identity:test:serverOnly', function()
        executions = executions + 1
    end)
    IdentityTest.EmitNetwork('gc_identity:test:serverOnly', 0, {})
    GCModuleTest.ExpectEqual(executions, 0, 'local TriggerEvent spoof is rejected')
    IdentityTest.EmitNetwork('gc_identity:test:serverOnly', 65535, {})
    GCModuleTest.ExpectEqual(executions, 1, 'server-origin event is accepted')
end)
