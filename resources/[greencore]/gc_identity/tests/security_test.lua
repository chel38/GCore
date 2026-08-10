GCModuleTest.Register('identity.foreign_character_is_rejected', 'security', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(31)
    GCIdentityService.Resolve(32)
    local foreign = GCIdentityService.CreateCharacter(32, {
        protocolVersion = 1,
        requestId = 'request_4001',
        firstName = 'Foreign',
        lastName = 'Owner'
    })
    local selected, selectError = GCIdentityService.SelectCharacter(31, {
        protocolVersion = 1,
        requestId = 'request_4002',
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

GCModuleTest.Register('identity.rate_limit_rejects_abuse', 'security', function()
    IdentityTest.Reset()
    local finalError

    for _ = 1, GCIdentityConfig.rateLimits.hello.maximum + 1 do
        local _, helloError = GCIdentityService.Hello(33)
        finalError = helloError
    end

    GCModuleTest.ExpectEqual(finalError, 'GC-IDENTITY-RATE-LIMIT', 'hello abuse is rate-limited')
end)

GCModuleTest.Register('identity.wrong_core_lifecycle_rejects', 'security', function()
    IdentityTest.Reset()
    IdentityTest.core.gameplay[34] = false
    GCIdentityService.Resolve(34)
    local character, createError = GCIdentityService.CreateCharacter(34, {
        protocolVersion = 1,
        requestId = 'request_5001',
        firstName = 'Wrong',
        lastName = 'State'
    })
    GCModuleTest.ExpectNil(character, 'non-gameplay player cannot create character')
    GCModuleTest.ExpectEqual(
        createError,
        'GC-IDENTITY-CORE-GAMEPLAY-NOT-READY',
        'core lifecycle error is stable'
    )
end)

GCModuleTest.Register('identity.server_event_rejects_malformed_payload', 'security', function()
    IdentityTest.Reset()
    IdentityTest.EmitNetwork(GCIdentityEvents.server.createCharacter, 35, {
        protocolVersion = 1,
        requestId = 'request_5002',
        firstName = 'Bad',
        lastName = 'Payload',
        authorized = true
    })
    local response = IdentityTest.LastClientEvent()
    GCModuleTest.ExpectEqual(response.name, GCIdentityEvents.client.rejected, 'rejection event emitted')
    GCModuleTest.ExpectEqual(
        response.payload.code,
        'GC-IDENTITY-PAYLOAD-SCHEMA',
        'forged field is rejected before domain logic'
    )
end)

GCModuleTest.Register('identity.client_event_origin_guard', 'security', function()
    local executions = 0
    GCIdentityClientSecurity.RegisterServerEvent('gc_identity:test:serverOnly', function()
        executions = executions + 1
    end)
    IdentityTest.EmitLocal('gc_identity:test:serverOnly', 0, {})
    GCModuleTest.ExpectEqual(executions, 0, 'local TriggerEvent spoof is rejected')
    IdentityTest.EmitLocal('gc_identity:test:serverOnly', 65535, {})
    GCModuleTest.ExpectEqual(executions, 1, 'server-origin event is accepted')
end)
