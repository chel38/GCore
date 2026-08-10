local function createPayload(requestId, firstName, lastName)
    return {
        protocolVersion = 1,
        requestId = requestId,
        firstName = firstName or 'Anna',
        lastName = lastName or 'Smith'
    }
end

GCModuleTest.Register('identity.valid_identity_flow', 'integration', function()
    IdentityTest.Reset()
    local snapshot, resolveError = GCIdentityService.Resolve(21)
    GCModuleTest.ExpectNil(resolveError, 'account resolution succeeds')
    GCModuleTest.ExpectEqual(snapshot.state, 'character_required', 'new account needs character')
    GCModuleTest.ExpectNotNil(snapshot.account, 'public account exists')

    local character, createError = GCIdentityService.CreateCharacter(
        21,
        createPayload('request_1001')
    )
    GCModuleTest.ExpectNil(createError, 'character creation succeeds')
    GCModuleTest.ExpectEqual(character.firstName, 'Anna', 'character DTO returned')

    local selected, selectError = GCIdentityService.SelectCharacter(21, {
        protocolVersion = 1,
        requestId = 'request_1002',
        characterId = character.id
    })
    GCModuleTest.ExpectNil(selectError, 'character selection succeeds')
    GCModuleTest.ExpectEqual(selected.id, character.id, 'selected DTO returned')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsReady(21), 'identity reaches ready')
end)

GCModuleTest.Register('identity.duplicate_request_is_idempotent', 'integration', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(22)
    local payload = createPayload('request_2001')
    local first, firstError, firstReplay = GCIdentityService.CreateCharacter(22, payload)
    local second, secondError, secondReplay = GCIdentityService.CreateCharacter(22, payload)
    GCModuleTest.ExpectNil(firstError, 'first request succeeds')
    GCModuleTest.ExpectFalse(firstReplay, 'first request is not replay')
    GCModuleTest.ExpectNil(secondError, 'duplicate request succeeds idempotently')
    GCModuleTest.ExpectTrue(secondReplay, 'duplicate is marked replay')
    GCModuleTest.ExpectEqual(second.id, first.id, 'duplicate returns same character')
    GCModuleTest.ExpectEqual(#GCIdentityService.GetCharacters(22), 1, 'duplicate creates one character')
end)

GCModuleTest.Register('identity.character_limit_is_bounded', 'security', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(23)

    for index = 1, GCIdentityConfig.characters.maximum do
        local character = GCIdentityService.CreateCharacter(
            23,
            createPayload(('request_30%02d'):format(index), 'Name' .. index)
        )
        GCModuleTest.ExpectNotNil(character, 'character within limit is created')
        IdentityTest.Advance(61000)
    end

    local extra, extraError = GCIdentityService.CreateCharacter(
        23,
        createPayload('request_3999', 'Extra')
    )
    GCModuleTest.ExpectNil(extra, 'extra character rejected')
    GCModuleTest.ExpectEqual(extraError, 'GC-IDENTITY-CHARACTER-LIMIT', 'limit has stable code')
end)

GCModuleTest.Register('identity.storage_failure_rolls_back', 'integration', function()
    IdentityTest.Reset()
    IdentityTest.SetSaveFailure(true)
    local snapshot, resolveError = GCIdentityService.Resolve(24)
    GCModuleTest.ExpectNil(snapshot, 'failed account save creates no identity')
    GCModuleTest.ExpectEqual(resolveError, 'GC-IDENTITY-STORAGE-WRITE', 'storage failure returned')
    IdentityTest.SetSaveFailure(false)
    GCModuleTest.ExpectNil(
        GCIdentityRepository.FindAccountByIdentifier('license', 'license:test-24'),
        'failed save rolls account mutation back'
    )
end)
