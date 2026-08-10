local identityExports = {
    'GetIdentityVersion',
    'GetIdentityApiVersion',
    'GetIdentityProtocolVersion',
    'IsAuthorized',
    'IsIdentityReady',
    'GetIdentityState',
    'GetAccount',
    'GetCharacters',
    'GetSelectedCharacter'
}

GCModuleTest.Register('identity.api_v1_contract_exists', 'contract', function()
    for _, exportName in ipairs(identityExports) do
        GCModuleTest.ExpectEqual(
            type(IdentityTest.publicExports[exportName]),
            'function',
            exportName .. ' export exists'
        )
    end
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetIdentityVersion(), '0.1.0-alpha', 'resource version stable')
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetIdentityApiVersion(), 1, 'API version stable')
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetIdentityProtocolVersion(), 1, 'protocol stable')
end)

GCModuleTest.Register('identity.api_dto_isolation', 'contract', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(41)
    local character = GCIdentityService.CreateCharacter(41, {
        protocolVersion = 1,
        requestId = 'request_6001',
        firstName = 'Public',
        lastName = 'Copy'
    })
    GCIdentityService.SelectCharacter(41, {
        protocolVersion = 1,
        requestId = 'request_6002',
        characterId = character.id
    })

    local accountDto = GCIdentityAPI.GetAccount(41)
    local characterDto = GCIdentityAPI.GetSelectedCharacter(41)
    accountDto.id = 999
    characterDto.firstName = 'HACK'

    GCModuleTest.ExpectNotNil(GCIdentityAPI.GetAccount(41), 'account DTO exists')
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetAccount(41).id, 1, 'account DTO mutation is isolated')
    GCModuleTest.ExpectEqual(
        GCIdentityAPI.GetSelectedCharacter(41).firstName,
        'Public',
        'character DTO mutation is isolated'
    )
    GCModuleTest.ExpectNil(accountDto.identifier, 'account DTO excludes identifier')
    GCModuleTest.ExpectNil(characterDto.accountId, 'character DTO excludes internal account id')
end)

GCModuleTest.Register('identity.api_invalid_source_contract', 'contract', function()
    IdentityTest.Reset()
    GCModuleTest.ExpectFalse(GCIdentityAPI.IsAuthorized('41'), 'invalid source is not authorized')
    GCModuleTest.ExpectFalse(GCIdentityAPI.IsIdentityReady(-1), 'invalid source is not ready')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetIdentityState(0), 'invalid source state is nil')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetAccount(nil), 'invalid source account is nil')
    GCModuleTest.ExpectEqual(#GCIdentityAPI.GetCharacters(nil), 0, 'invalid source character list is empty')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetSelectedCharacter(nil), 'invalid selected character is nil')
end)
