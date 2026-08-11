local identityExports = {
    'GetIdentityVersion',
    'GetIdentityApiVersion',
    'GetIdentityProtocolVersion',
    'GetIdentityHealth',
    'IsAuthorized',
    'IsIdentityReady',
    'GetIdentityState',
    'GetAccount',
    'GetCharacters',
    'GetSelectedCharacter',
    'GetDisplayName'
}

GCModuleTest.Register('identity.api_v1_contract_exists', 'contract', function()
    for _, exportName in ipairs(identityExports) do
        GCModuleTest.ExpectEqual(
            type(IdentityTest.publicExports[exportName]),
            'function',
            exportName .. ' export exists'
        )
    end
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetIdentityVersion(), '0.4.0-alpha', 'resource version updated')
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetIdentityApiVersion(), 1, 'API version remains backward-compatible')
    GCModuleTest.ExpectEqual(GCIdentityAPI.GetIdentityProtocolVersion(), 3, 'pre-spawn protocol is v3')
end)

GCModuleTest.Register('identity.api_dto_isolation', 'contract', function()
    IdentityTest.Reset()
    IdentityTest.ResolveAndRegister(41, 'public@example.test', 'register_4100')
    local character = GCIdentityService.CreateCharacter(41, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'request_4101',
        firstName = 'Public',
        lastName = 'Copy'
    })
    GCIdentityService.SelectCharacter(41, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'request_4102',
        characterId = character.id
    })

    local accountDto = GCIdentityAPI.GetAccount(41)
    local characterDto = GCIdentityAPI.GetSelectedCharacter(41)
    local charactersDto = GCIdentityAPI.GetCharacters(41)
    local displayName = GCIdentityAPI.GetDisplayName(41)
    accountDto.id = 999
    accountDto.email = 'hack@example.test'
    characterDto.firstName = 'HACK'
    charactersDto[1].lastName = 'HACK'

    GCModuleTest.ExpectEqual(GCIdentityAPI.GetAccount(41).id, 1, 'account ID mutation is isolated')
    GCModuleTest.ExpectEqual(displayName, 'Test Player', 'registered account display name is public')
    GCModuleTest.ExpectEqual(
        GCIdentityAPI.GetAccount(41).email,
        'public@example.test',
        'account email mutation is isolated'
    )
    GCModuleTest.ExpectEqual(
        GCIdentityAPI.GetSelectedCharacter(41).firstName,
        'Public',
        'selected character mutation is isolated'
    )
    GCModuleTest.ExpectEqual(
        GCIdentityAPI.GetCharacters(41)[1].lastName,
        'Copy',
        'character list mutation is isolated'
    )
    GCModuleTest.ExpectNil(accountDto.identifier, 'account DTO excludes identifier')
    GCModuleTest.ExpectNil(accountDto.passwordHash, 'account DTO excludes credentials')
    GCModuleTest.ExpectNil(characterDto.accountId, 'character DTO excludes internal account id')
end)

GCModuleTest.Register('identity.api_health_dto_isolation', 'contract', function()
    IdentityTest.Reset()
    local health = GCIdentityAPI.GetIdentityHealth()
    GCModuleTest.ExpectEqual(health.status, 'ready', 'health reports ready repository')
    GCModuleTest.ExpectTrue(health.available, 'health reports service availability')
    GCModuleTest.ExpectEqual(health.storage, 'memory', 'test adapter is explicit')
    health.status = 'hacked'
    GCModuleTest.ExpectEqual(
        GCIdentityAPI.GetIdentityHealth().status,
        'ready',
        'health DTO mutation is isolated'
    )
end)

GCModuleTest.Register('identity.api_invalid_source_contract', 'contract', function()
    IdentityTest.Reset()
    GCModuleTest.ExpectFalse(GCIdentityAPI.IsAuthorized('41'), 'invalid source is not authorized')
    GCModuleTest.ExpectFalse(GCIdentityAPI.IsIdentityReady(-1), 'invalid source is not ready')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetIdentityState(0), 'invalid source state is nil')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetAccount(nil), 'invalid source account is nil')
    GCModuleTest.ExpectEqual(#GCIdentityAPI.GetCharacters(nil), 0, 'invalid source character list is empty')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetSelectedCharacter(nil), 'invalid selected character is nil')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetDisplayName(nil), 'invalid display name source is nil')
end)
