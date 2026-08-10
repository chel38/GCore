local function validateConfig()
    return type(GCIdentityConfig.requiredCoreApi) == 'number'
        and GCIdentityConfig.requiredCoreApi >= 1
        and type(GCIdentityConfig.identifierTypes) == 'table'
        and #GCIdentityConfig.identifierTypes > 0
        and type(GCIdentityConfig.storage.file) == 'string'
        and GCIdentityConfig.storage.file ~= ''
        and type(GCIdentityConfig.characters.maximum) == 'number'
        and GCIdentityConfig.characters.maximum >= 1
end

if not validateConfig() then
    GCIdentityLogger.Error(
        'GC-IDENTITY-CONFIG-INVALID',
        'Identity configuration is invalid'
    )
else
    local loaded, loadError = GCIdentityRepository.Load()

    if not loaded then
        GCIdentityLogger.Error(loadError, 'Identity repository failed to load')
    else
        GCIdentityService.SetAvailable(true)
        GCIdentityLogger.Info(
            'GC-IDENTITY-STARTED',
            'gc_identity is ready',
            {
                version = GCIdentityVersion.GetString(),
                api = GCIdentityVersion.api,
                protocol = GCIdentityVersion.protocol
            }
        )

        -- EN: One bounded recovery pass replaces permanent player polling.
        -- RU: Один bounded recovery pass заменяет постоянный polling игроков.
        CreateThread(function()
            Wait(0)
            local recovered = GCIdentityService.RecoverOnlinePlayers()

            if recovered > 0 then
                GCIdentityLogger.Info(
                    'GC-IDENTITY-RECOVERY-COMPLETE',
                    'Identity resource restart recovery completed',
                    { recovered = recovered }
                )
            end
        end)
    end
end
