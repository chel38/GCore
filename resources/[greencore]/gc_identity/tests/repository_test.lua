GCModuleTest.Register('identity.repository_account_contract', 'repository', function()
    local memory = IdentityTest.Reset()
    local account, createError = GCIdentityRepository.RegisterAccount(
        'owner@example.test',
        'license',
        'license:repository-owner'
    )
    GCModuleTest.ExpectNil(createError, 'account transaction succeeds')
    GCModuleTest.ExpectEqual(account.email, 'owner@example.test', 'email is persisted')
    GCModuleTest.ExpectEqual(account.status, 'active', 'new account is active')

    local byIdentifier = GCIdentityRepository.FindAccountByIdentifier(
        'license',
        'license:repository-owner'
    )
    local byEmail = GCIdentityRepository.FindAccountByEmail('owner@example.test')
    GCModuleTest.ExpectEqual(byIdentifier.id, account.id, 'identifier lookup resolves account')
    GCModuleTest.ExpectEqual(byEmail.id, account.id, 'email lookup resolves account')

    local _, emailError = GCIdentityRepository.RegisterAccount(
        'owner@example.test',
        'license',
        'license:repository-other'
    )
    local _, identifierError = GCIdentityRepository.RegisterAccount(
        'other@example.test',
        'license',
        'license:repository-owner'
    )
    GCModuleTest.ExpectEqual(emailError, 'GC-IDENTITY-EMAIL-TAKEN', 'unique email enforced')
    GCModuleTest.ExpectEqual(
        identifierError,
        'GC-IDENTITY-REGISTRATION-CONFLICT',
        'unique trusted identifier enforced'
    )

    local counts = memory.GetCounts()
    GCModuleTest.ExpectEqual(counts.accounts, 1, 'conflicts create no partial account')
    GCModuleTest.ExpectEqual(counts.identifiers, 1, 'conflicts create no partial identifier')
end)

GCModuleTest.Register('identity.repository_character_contract', 'repository', function()
    IdentityTest.Reset()
    local owner = GCIdentityRepository.RegisterAccount(
        'owner@example.test',
        'license',
        'license:character-owner'
    )
    local foreign = GCIdentityRepository.RegisterAccount(
        'foreign@example.test',
        'license',
        'license:character-foreign'
    )
    local character = GCIdentityRepository.CreateCharacter(
        owner.id,
        'Anna',
        'Smith',
        2
    )
    GCModuleTest.ExpectNotNil(character, 'first character persists')
    GCModuleTest.ExpectEqual(
        #GCIdentityRepository.GetCharacters(owner.id),
        1,
        'character list is account-scoped'
    )

    local selected, selectionError = GCIdentityRepository.SelectCharacter(
        owner.id,
        character.id
    )
    GCModuleTest.ExpectNil(selectionError, 'own character can be selected')
    GCModuleTest.ExpectEqual(selected.id, character.id, 'selection returns character')

    local _, foreignError = GCIdentityRepository.SelectCharacter(
        foreign.id,
        character.id
    )
    GCModuleTest.ExpectEqual(
        foreignError,
        'GC-IDENTITY-CHARACTER-NOT-OWNED',
        'foreign ownership is rejected'
    )

    GCIdentityRepository.CreateCharacter(owner.id, 'Ben', 'Smith', 2)
    local _, limitError = GCIdentityRepository.CreateCharacter(
        owner.id,
        'Cara',
        'Smith',
        2
    )
    GCModuleTest.ExpectEqual(limitError, 'GC-IDENTITY-CHARACTER-LIMIT', 'repository limit is atomic')
end)

GCModuleTest.Register('identity.repository_storage_error_not_not_found', 'repository', function()
    local memory = IdentityTest.Reset()
    memory.SetFailure('GC-IDENTITY-DATABASE-QUERY-FAILED')
    local account, accountError = GCIdentityRepository.FindAccountByIdentifier(
        'license',
        'license:missing'
    )
    GCModuleTest.ExpectNil(account, 'failed storage returns no account')
    GCModuleTest.ExpectEqual(
        accountError,
        'GC-IDENTITY-DATABASE-QUERY-FAILED',
        'storage failure is distinct from NOT_FOUND'
    )
    local counts = memory.GetCounts()
    GCModuleTest.ExpectEqual(counts.accounts, 0, 'storage error creates no account')
end)

GCModuleTest.Register('identity.repository_legacy_import_is_explicit_and_idempotent', 'migration', function()
    local memory = IdentityTest.Reset()
    IdentityTest.SetLegacyData({
        nextAccountId = 2,
        nextCharacterId = 2,
        accounts = {
            {
                id = 1,
                identifierType = 'license',
                identifier = 'license:legacy-one',
                selectedCharacterId = 1,
                createdAt = 100,
                updatedAt = 200
            }
        },
        characters = {
            {
                id = 1,
                accountId = 1,
                firstName = 'Legacy',
                lastName = 'Player',
                createdAt = 100,
                updatedAt = 200
            }
        }
    })
    GCIdentityConfig.storage.importLegacyJson = true
    local first, firstError = GCIdentityRepository.ImportLegacyJson()
    local second, secondError = GCIdentityRepository.ImportLegacyJson()
    GCIdentityConfig.storage.importLegacyJson = false
    GCModuleTest.ExpectNil(firstError, 'legacy import succeeds')
    GCModuleTest.ExpectEqual(first.imported, 1, 'legacy account imported once')
    GCModuleTest.ExpectNil(secondError, 'legacy replay succeeds')
    GCModuleTest.ExpectEqual(second.skipped, 1, 'legacy replay is idempotent')
    local account = GCIdentityRepository.FindAccountByIdentifier(
        'license',
        'license:legacy-one'
    )
    GCModuleTest.ExpectNil(account.email, 'legacy account requires email completion')
    GCModuleTest.ExpectNotNil(account.selectedCharacterId, 'legacy selection is mapped')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 1, 'legacy replay creates one account')
end)
