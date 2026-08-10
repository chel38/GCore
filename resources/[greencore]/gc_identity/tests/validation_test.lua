GCModuleTest.Register('identity.validation_valid_payloads', 'unit', function()
    IdentityTest.Reset()
    local hello = GCIdentityValidation.ValidateHello({ protocolVersion = 1 })
    local create = GCIdentityValidation.ValidateCreateCharacter({
        protocolVersion = 1,
        requestId = 'request_0001',
        firstName = '  Anna ',
        lastName = ' Smith '
    })
    local select = GCIdentityValidation.ValidateSelectCharacter({
        protocolVersion = 1,
        requestId = 'request_0002',
        characterId = 1
    })
    GCModuleTest.ExpectNotNil(hello, 'hello schema accepted')
    GCModuleTest.ExpectEqual(create.firstName, 'Anna', 'first name normalized')
    GCModuleTest.ExpectEqual(create.lastName, 'Smith', 'last name normalized')
    GCModuleTest.ExpectEqual(select.characterId, 1, 'character id accepted')
end)

GCModuleTest.Register('identity.validation_rejects_malformed', 'security', function()
    IdentityTest.Reset()
    local _, unknownError = GCIdentityValidation.ValidateHello({
        protocolVersion = 1,
        forged = true
    })
    local _, protocolError = GCIdentityValidation.ValidateHello({ protocolVersion = 99 })
    local _, nameError = GCIdentityValidation.ValidateCreateCharacter({
        protocolVersion = 1,
        requestId = 'request_0003',
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
    GCModuleTest.ExpectEqual(nameError, 'GC-IDENTITY-PAYLOAD-NAME', 'oversized name rejected')
    GCModuleTest.ExpectEqual(idError, 'GC-IDENTITY-PAYLOAD-REQUEST-ID', 'unsafe request id rejected')
end)
