GCModuleTest.Register('identity.validation_valid_payloads', 'unit', function()
    IdentityTest.Reset()
    local hello = GCIdentityValidation.ValidateHello({ protocolVersion = 1 })
    local registration = GCIdentityValidation.ValidateRegistration({
        protocolVersion = 1,
        requestId = 'request_0000',
        email = '  Player.Name@Example.COM '
    })
    local create = GCIdentityValidation.ValidateCreateCharacter({
        protocolVersion = 1,
        requestId = 'request_0001',
        firstName = '  Anna ',
        lastName = " O'Neil "
    })
    local select = GCIdentityValidation.ValidateSelectCharacter({
        protocolVersion = 1,
        requestId = 'request_0002',
        characterId = 1
    })
    GCModuleTest.ExpectNotNil(hello, 'hello schema accepted')
    GCModuleTest.ExpectEqual(
        registration.email,
        'player.name@example.com',
        'email normalized deterministically'
    )
    GCModuleTest.ExpectEqual(create.firstName, 'Anna', 'first name normalized')
    GCModuleTest.ExpectEqual(create.lastName, "O'Neil", 'apostrophe name accepted')
    GCModuleTest.ExpectEqual(select.characterId, 1, 'character id accepted')
end)

GCModuleTest.Register('identity.validation_rejects_malformed', 'security', function()
    IdentityTest.Reset()
    local _, unknownError = GCIdentityValidation.ValidateHello({
        protocolVersion = 1,
        forged = true
    })
    local _, protocolError = GCIdentityValidation.ValidateHello({ protocolVersion = 99 })
    local _, emailError = GCIdentityValidation.ValidateRegistration({
        protocolVersion = 1,
        requestId = 'request_0003',
        email = "victim@example.com' OR 1=1"
    })
    local _, nameError = GCIdentityValidation.ValidateCreateCharacter({
        protocolVersion = 1,
        requestId = 'request_0004',
        firstName = string.rep('A', 33),
        lastName = 'Smith'
    })
    local _, idError = GCIdentityValidation.ValidateSelectCharacter({
        protocolVersion = 1,
        requestId = '../unsafe',
        characterId = 1
    })
    GCModuleTest.ExpectEqual(unknownError, 'GC-IDENTITY-PAYLOAD-SCHEMA', 'unknown key rejected')
    GCModuleTest.ExpectEqual(protocolError, 'GC-IDENTITY-PROTOCOL-MISMATCH', 'protocol rejected')
    GCModuleTest.ExpectEqual(emailError, 'GC-IDENTITY-REGISTRATION-INVALID', 'SQL fragment email rejected')
    GCModuleTest.ExpectEqual(nameError, 'GC-IDENTITY-CHARACTER-INVALID', 'oversized name rejected')
    GCModuleTest.ExpectEqual(idError, 'GC-IDENTITY-PAYLOAD-REQUEST-ID', 'unsafe request id rejected')
end)

GCModuleTest.Register('identity.validation_email_policy', 'unit', function()
    IdentityTest.Reset()
    local valid = {
        'simple@example.com',
        "o'reilly@example.com",
        'user+tag@sub.example.com'
    }
    local invalid = {
        'missing-at.example.com',
        '@example.com',
        'user@localhost',
        'user..dots@example.com',
        'user@example..com',
        'user name@example.com'
    }

    for _, email in ipairs(valid) do
        GCModuleTest.ExpectNotNil(
            GCIdentityValidation.NormalizeEmail(email),
            email .. ' accepted by basic email policy'
        )
    end

    for _, email in ipairs(invalid) do
        GCModuleTest.ExpectNil(
            GCIdentityValidation.NormalizeEmail(email),
            email .. ' rejected by basic email policy'
        )
    end
end)

GCModuleTest.Register('identity.validation_client_failure_allowlist', 'security', function()
    local valid, validError = GCIdentityValidation.ValidateClientFailure({
        protocolVersion = 1,
        code = 'GC-IDENTITY-NUI-NOT-READY'
    })
    GCModuleTest.ExpectNotNil(valid, 'known client lifecycle failure is accepted')
    GCModuleTest.ExpectNil(validError, 'known client lifecycle failure has no validation error')

    local forged, forgedError = GCIdentityValidation.ValidateClientFailure({
        protocolVersion = 1,
        code = 'GC-IDENTITY-FORGED-DROP'
    })
    GCModuleTest.ExpectNil(forged, 'unknown client failure cannot request a disconnect')
    GCModuleTest.ExpectEqual(
        forgedError,
        'GC-IDENTITY-CLIENT-FAILURE-INVALID',
        'unknown client failure has a stable validation code'
    )
end)
