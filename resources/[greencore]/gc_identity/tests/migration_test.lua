local function method(awaitHandler)
    return { await = awaitHandler }
end

local function restoreMemoryDatabase()
    GCIdentityConfig.storage.adapter = 'memory'
    MySQL = {}
    GCIdentityDatabase.Initialize()
    GCIdentityRepository.Initialize('memory')
    GCIdentityService.SetAvailable(true)
end

GCModuleTest.Register('identity.migrations_fresh_database_applies_in_order', 'migration', function()
    IdentityTest.Reset()
    local inserts = 0
    local ddlStatements = 0
    GCIdentityConfig.storage.adapter = 'oxmysql'
    MySQL = {
        scalar = method(function() return 1 end),
        query = method(function(sql)
            if sql:find('SELECT `version`', 1, true) then
                return {}
            end

            ddlStatements = ddlStatements + 1
            return {}
        end),
        insert = method(function(_, values)
            inserts = inserts + 1
            GCModuleTest.ExpectEqual(values[1], '001_initial_identity', 'migration version recorded')
            return inserts
        end)
    }
    local initialized, initializeError = GCIdentityDatabase.Initialize()
    GCModuleTest.ExpectTrue(initialized, 'fresh database initializes')
    GCModuleTest.ExpectNil(initializeError, 'fresh migration has no error')
    GCModuleTest.ExpectTrue(ddlStatements >= 5, 'migration table and schema statements execute')
    GCModuleTest.ExpectEqual(inserts, 1, 'one pending migration is recorded')
    GCModuleTest.ExpectEqual(
        GCIdentityDatabase.GetHealth().appliedMigrations,
        1,
        'health reports applied migration count'
    )
    restoreMemoryDatabase()
end)

GCModuleTest.Register('identity.migrations_existing_database_is_idempotent', 'migration', function()
    IdentityTest.Reset()
    local migrationInserts = 0
    local schemaStatements = 0
    GCIdentityConfig.storage.adapter = 'oxmysql'
    MySQL = {
        scalar = method(function() return 1 end),
        query = method(function(sql)
            if sql:find('SELECT `version`', 1, true) then
                return { { version = '001_initial_identity' } }
            end

            if sql:find('gc_identity_schema_migrations', 1, true) then
                return {}
            end

            if sql:find('CREATE TABLE IF NOT EXISTS `gc_', 1, true)
                and not sql:find('gc_identity_schema_migrations', 1, true) then
                schemaStatements = schemaStatements + 1
            end
            return {}
        end),
        insert = method(function()
            migrationInserts = migrationInserts + 1
            return 1
        end)
    }
    local initialized = GCIdentityDatabase.Initialize()
    GCModuleTest.ExpectTrue(initialized, 'existing database initializes')
    GCModuleTest.ExpectEqual(schemaStatements, 0, 'applied schema does not rerun')
    GCModuleTest.ExpectEqual(migrationInserts, 0, 'applied migration is not recorded twice')
    restoreMemoryDatabase()
end)

GCModuleTest.Register('identity.migrations_failure_keeps_module_degraded', 'migration', function()
    IdentityTest.Reset()
    GCIdentityConfig.storage.adapter = 'oxmysql'
    MySQL = {
        scalar = method(function() return 1 end),
        query = method(function(sql)
            if sql:find('SELECT `version`', 1, true) then
                return {}
            end

            if sql:find('CREATE TABLE IF NOT EXISTS `gc_accounts`', 1, true) then
                error('simulated migration failure')
            end

            return {}
        end),
        insert = method(function() return 1 end)
    }
    local initialized = GCIdentityDatabase.Initialize()
    GCModuleTest.ExpectFalse(initialized, 'failed migration rejects initialization')
    GCModuleTest.ExpectEqual(
        GCIdentityDatabase.GetHealth().code,
        'GC-IDENTITY-MIGRATION-FAILED',
        'migration failure has stable health code'
    )
    GCModuleTest.ExpectFalse(GCIdentityDatabase.IsReady(), 'failed migration never reports ready')
    restoreMemoryDatabase()
end)

GCModuleTest.Register('identity.oxmysql_runtime_values_are_parameterized', 'security', function()
    IdentityTest.Reset()
    local captured = {}
    local injectedEmail = "o'reilly@example.test"
    local injectedIdentifier = "license:value' OR 1=1"
    MySQL = {
        startTransaction = function(handler)
            return handler(function(sql, values)
                table.insert(captured, { sql = sql, values = values })

                if sql:find('INSERT INTO `gc_accounts`', 1, true) then
                    return { insertId = 77, affectedRows = 1 }
                end

                if sql:find('INSERT INTO `gc_account_identifiers`', 1, true) then
                    return { affectedRows = 1 }
                end

                return {}
            end)
        end,
        single = method(function()
            return {
                id = 77,
                email = injectedEmail,
                status = 'active',
                createdAt = 1,
                updatedAt = 1
            }
        end)
    }

    local account, accountError = GCIdentityRepositories.oxmysql.RegisterAccount(
        injectedEmail,
        'license',
        injectedIdentifier
    )
    GCModuleTest.ExpectNil(accountError, 'parameterized registration succeeds in boundary mock')
    GCModuleTest.ExpectEqual(account.id, 77, 'transaction result maps to account')

    for _, query in ipairs(captured) do
        GCModuleTest.ExpectNil(
            query.sql:find(injectedEmail, 1, true),
            'email never concatenated into SQL'
        )
        GCModuleTest.ExpectNil(
            query.sql:find(injectedIdentifier, 1, true),
            'identifier never concatenated into SQL'
        )
        GCModuleTest.ExpectNotNil(query.values, 'runtime query uses parameter array')
    end

    restoreMemoryDatabase()
end)
