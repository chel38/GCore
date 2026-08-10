local function validateConfig()
    local adapter = GCIdentityConfig.storage.adapter

    return type(GCIdentityConfig.requiredCoreApi) == 'number'
        and GCIdentityConfig.requiredCoreApi >= 1
        and type(GCIdentityConfig.identifierTypes) == 'table'
        and #GCIdentityConfig.identifierTypes > 0
        and (adapter == 'oxmysql' or adapter == 'memory')
        and type(GCIdentityConfig.storage.legacyFile) == 'string'
        and GCIdentityConfig.storage.legacyFile ~= ''
        and type(GCIdentityConfig.database.healthAttempts) == 'number'
        and GCIdentityConfig.database.healthAttempts >= 1
        and type(GCIdentityConfig.database.healthRetryMs) == 'number'
        and GCIdentityConfig.database.healthRetryMs >= 100
        and type(GCIdentityConfig.characters.maximum) == 'number'
        and GCIdentityConfig.characters.maximum >= 1
end

local function startIdentity()
    GCIdentityService.SetAvailable(false)
    local databaseReady
    local databaseError

    for attempt = 1, GCIdentityConfig.database.healthAttempts do
        databaseReady, databaseError = GCIdentityDatabase.Initialize()

        if databaseReady then
            break
        end

        GCIdentityLogger.Warn(
            databaseError or 'GC-IDENTITY-DATABASE-UNAVAILABLE',
            'Database health check failed',
            { attempt = attempt, maximum = GCIdentityConfig.database.healthAttempts }
        )

        if attempt < GCIdentityConfig.database.healthAttempts then
            Wait(GCIdentityConfig.database.healthRetryMs)
        end
    end

    if not databaseReady then
        GCIdentityRepository.SetUnavailable()
        GCIdentityLogger.Error(
            databaseError or 'GC-IDENTITY-DATABASE-UNAVAILABLE',
            'gc_identity remains degraded; no fallback storage was activated'
        )
        return
    end

    local initialized, initializeError = GCIdentityRepository.Initialize()

    if not initialized then
        GCIdentityLogger.Error(
            initializeError or 'GC-IDENTITY-DATABASE-UNAVAILABLE',
            'Identity repository failed to initialize'
        )
        return
    end

    local importStats, importError = GCIdentityRepository.ImportLegacyJson()

    if not importStats then
        GCIdentityRepository.SetUnavailable()
        GCIdentityLogger.Error(importError, 'Legacy JSON import failed closed')
        return
    end

    if importStats.imported > 0 or importStats.skipped > 0 then
        GCIdentityLogger.Info(
            'GC-IDENTITY-LEGACY-IMPORT-COMPLETE',
            'Legacy JSON import completed',
            { imported = importStats.imported, skipped = importStats.skipped }
        )
    end

    GCIdentityService.SetAvailable(true)
    local databaseHealth = GCIdentityDatabase.GetHealth()
    GCIdentityLogger.Info(
        'GC-IDENTITY-STARTED',
        'gc_identity is ready',
        {
            version = GCIdentityVersion.GetString(),
            api = GCIdentityVersion.api,
            protocol = GCIdentityVersion.protocol,
            storage = GCIdentityRepository.GetAdapterName(),
            migrations = databaseHealth.appliedMigrations
        }
    )

    -- EN: One bounded recovery pass replaces permanent player polling.
    -- RU: Один bounded recovery pass заменяет постоянный polling игроков.
    Wait(0)
    local recovered = GCIdentityService.RecoverOnlinePlayers()

    if recovered > 0 then
        GCIdentityLogger.Info(
            'GC-IDENTITY-RECOVERY-COMPLETE',
            'Identity resource restart recovery completed',
            { recovered = recovered }
        )
    end
end

if not validateConfig() then
    GCIdentityLogger.Error(
        'GC-IDENTITY-CONFIG-INVALID',
        'Identity configuration is invalid'
    )
else
    CreateThread(startIdentity)
end
