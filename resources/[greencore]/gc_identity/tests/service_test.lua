local function createPayload(requestId, firstName, lastName)
    return {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = requestId,
        firstName = firstName or 'Anna',
        lastName = lastName or 'Smith'
    }
end

GCModuleTest.Register('identity.new_identifier_requires_registration', 'integration', function()
    IdentityTest.Reset()
    local snapshot, resolveError = GCIdentityService.Resolve(21)
    GCModuleTest.ExpectNil(resolveError, 'unknown identifier lookup succeeds')
    GCModuleTest.ExpectEqual(
        snapshot.state,
        'registration_required',
        'unknown identifier does not auto-create account'
    )
    GCModuleTest.ExpectNil(snapshot.account, 'unregistered snapshot exposes no account')
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(21), 'unregistered player is not authorized')
    GCModuleTest.ExpectEqual(
        GCIdentityRepository.TestAdapter().GetCounts().accounts,
        0,
        'lookup alone creates no persistent account'
    )
end)

GCModuleTest.Register('identity.valid_persistent_identity_flow', 'integration', function()
    IdentityTest.Reset()
    local snapshot, registrationError = IdentityTest.ResolveAndRegister(
        22,
        'anna@example.test',
        'register_2200'
    )
    GCModuleTest.ExpectNil(registrationError, 'registration transaction succeeds')
    GCModuleTest.ExpectEqual(snapshot.state, 'character_required', 'registered account needs character')
    GCModuleTest.ExpectEqual(snapshot.account.email, 'anna@example.test', 'public account email returned')

    local character, createError = GCIdentityService.CreateCharacter(
        22,
        createPayload('request_2201')
    )
    GCModuleTest.ExpectNil(createError, 'character creation succeeds')
    GCModuleTest.ExpectEqual(character.firstName, 'Anna', 'character DTO returned')

    local selected, selectError = GCIdentityService.SelectCharacter(22, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'request_2202',
        characterId = character.id
    })
    GCModuleTest.ExpectNil(selectError, 'character selection succeeds')
    GCModuleTest.ExpectEqual(selected.id, character.id, 'selected DTO returned')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsReady(22), 'identity reaches ready')
end)

GCModuleTest.Register('identity.returning_identifier_auto_authorizes', 'integration', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(23, 'returning@example.test', 'register_2300')
    GCIdentityService.Disconnect(23)
    local snapshot, resolveError = GCIdentityService.Resolve(23)
    GCModuleTest.ExpectNil(resolveError, 'returning identifier lookup succeeds')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(23), 'trusted identifier auto-authorizes')
    GCModuleTest.ExpectEqual(snapshot.account.email, 'returning@example.test', 'same account is restored')
    GCModuleTest.ExpectEqual(
        GCIdentityRepository.TestAdapter().GetCounts().accounts,
        1,
        'reconnect creates no duplicate account'
    )
end)

GCModuleTest.Register('identity.duplicate_requests_are_idempotent', 'integration', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(24)
    local registration = {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'register_2400',
        firstName = 'Duplicate',
        lastName = 'Player',
        email = 'duplicate@example.test'
    }
    local firstAccount, firstError, firstReplay = GCIdentityService.SendRegistrationCode(24, registration)
    local secondAccount, secondError, secondReplay = GCIdentityService.SendRegistrationCode(24, registration)
    GCModuleTest.ExpectNil(firstError, 'first registration succeeds')
    GCModuleTest.ExpectFalse(firstReplay, 'first registration is not replay')
    GCModuleTest.ExpectNil(secondError, 'duplicate registration is safe')
    GCModuleTest.ExpectTrue(secondReplay, 'duplicate registration is replay')
    GCModuleTest.ExpectTrue(firstAccount.pending, 'first request creates a pending challenge')
    GCModuleTest.ExpectTrue(secondAccount.pending, 'duplicate returns the same pending result')

    local delivered = IdentityTest.LastMailPayload()
    local verified, verificationError = GCIdentityService.VerifyEmailCode(24, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'verify_2400',
        code = delivered.code
    })
    GCModuleTest.ExpectNil(verificationError, 'verification marks email verified')
    GCModuleTest.ExpectTrue(verified.verified, 'verification does not create an account')
    local finalized, finalizeError = GCIdentityService.FinalizeRegistration(24, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'finalize_2400'
    })
    GCModuleTest.ExpectNil(finalizeError, 'explicit finalization creates the account')
    GCModuleTest.ExpectEqual(finalized.displayName, 'Duplicate Player', 'finalization returns public account DTO')
    GCModuleTest.ExpectEqual(
        GCIdentityService.GetSnapshot(24).state,
        'spawn_releasing',
        'finalization releases one spawn'
    )
    IdentityTest.CompleteCoreSpawn(24)

    local payload = createPayload('request_2401')
    local first, createError, firstCreateReplay = GCIdentityService.CreateCharacter(24, payload)
    local second, replayError, secondCreateReplay = GCIdentityService.CreateCharacter(24, payload)
    GCModuleTest.ExpectNil(createError, 'first character request succeeds')
    GCModuleTest.ExpectFalse(firstCreateReplay, 'first character request is not replay')
    GCModuleTest.ExpectNil(replayError, 'duplicate character request succeeds idempotently')
    GCModuleTest.ExpectTrue(secondCreateReplay, 'duplicate character request is replay')
    GCModuleTest.ExpectEqual(second.id, first.id, 'duplicate returns same character')
    GCModuleTest.ExpectEqual(#GCIdentityService.GetCharacters(24), 1, 'duplicate creates one character')
end)

GCModuleTest.Register('identity.character_limit_is_bounded', 'security', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(25, 'limit@example.test', 'register_2500')

    for index = 1, GCIdentityConfig.characters.maximum do
        local character = GCIdentityService.CreateCharacter(
            25,
            createPayload(('request_25%02d'):format(index), 'Name' .. string.char(64 + index))
        )
        GCModuleTest.ExpectNotNil(character, 'character within limit is created')
    end

    local extra, extraError = GCIdentityService.CreateCharacter(
        25,
        createPayload('request_2599', 'Extra')
    )
    GCModuleTest.ExpectNil(extra, 'extra character rejected')
    GCModuleTest.ExpectEqual(extraError, 'GC-IDENTITY-CHARACTER-LIMIT', 'limit has stable code')
end)

GCModuleTest.Register('identity.disabled_account_fails_closed', 'security', function()
    local memory = IdentityTest.Reset()
    local snapshot = IdentityTest.ResolveAndRegister(26, 'disabled@example.test', 'register_2600')
    memory.SetAccountStatus(snapshot.account.id, 'disabled')
    GCIdentityService.Disconnect(26)
    local resolved, resolveError = GCIdentityService.Resolve(26)
    GCModuleTest.ExpectNil(resolved, 'disabled account is not authorized')
    GCModuleTest.ExpectEqual(resolveError, 'GC-IDENTITY-ACCOUNT-DISABLED', 'disabled code is stable')
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(26), 'disabled identity stays unauthorized')
end)

GCModuleTest.Register('identity.two_player_sessions_are_isolated', 'integration', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(27, 'player-a@example.test', 'register_2700')
    IdentityTest.ResolveAndRegister(28, 'player-b@example.test', 'register_2800')
    local characterA = GCIdentityService.CreateCharacter(27, createPayload('request_2701', 'Alice', 'One'))
    local characterB = GCIdentityService.CreateCharacter(28, createPayload('request_2801', 'Bob', 'Two'))
    GCModuleTest.ExpectEqual(#GCIdentityService.GetCharacters(27), 1, 'player A owns one character')
    GCModuleTest.ExpectEqual(#GCIdentityService.GetCharacters(28), 1, 'player B owns one character')
    GCModuleTest.ExpectEqual(GCIdentityService.GetCharacters(27)[1].id, characterA.id, 'A DTO isolated')
    GCModuleTest.ExpectEqual(GCIdentityService.GetCharacters(28)[1].id, characterB.id, 'B DTO isolated')
end)
