local function safeRequestId(payload)
    if type(payload) == 'table'
        and type(payload.requestId) == 'string'
        and #payload.requestId <= 64 then
        return payload.requestId
    end

    return nil
end

local function reject(playerSource, payload, code)
    GCIdentityLogger.Warn(code, 'Request rejected', { source = playerSource })
    TriggerClientEvent(GCIdentityEvents.client.rejected, playerSource, {
        requestId = safeRequestId(payload),
        code = code
    })
end

local function registerIngress(eventName, action, validator, handler, options)
    RegisterNetEvent(eventName, function(payload)
        local playerSource = source
        local allowed, rateError = GCIdentityRateLimit.Check(playerSource, action)

        if not allowed then
            reject(playerSource, payload, rateError)
            return
        end

        local validated, validationError = validator(payload)

        if not validated then
            reject(playerSource, payload, validationError)
            return
        end

        local result, serviceError = handler(playerSource, validated)

        if not result then
            -- EN: A hello may race the bounded database bootstrap after a
            -- resource restart. The client already retries, and startup
            -- recovery sends the authoritative snapshot once storage is ready.
            -- RU: Hello может обогнать bounded запуск БД после рестарта.
            -- Клиент уже делает retry, а recovery отправит snapshot после ready.
            if options and options.silentTransient then
                local transientErrors = {
                    ['GC-IDENTITY-CORE-UNAVAILABLE'] = true,
                    ['GC-IDENTITY-CORE-PLAYER-NOT-CONNECTED'] = true,
                    ['GC-IDENTITY-CORE-PLAYER-NOT-READY'] = true,
                    ['GC-IDENTITY-OPERATION-IN-PROGRESS'] = true
                }

                if transientErrors[serviceError] then
                    return
                end

                if serviceError == 'GC-IDENTITY-DATABASE-UNAVAILABLE' then
                    local health = GCIdentityDatabase.GetHealth()

                    if health.status ~= 'degraded' then
                        return
                    end
                end
            end

            reject(playerSource, validated, serviceError)
            return
        end

        GCIdentityService.SendSnapshot(playerSource)
    end)
end

registerIngress(
    GCIdentityEvents.server.hello,
    'hello',
    GCIdentityValidation.ValidateHello,
    function(playerSource)
        return GCIdentityService.Hello(playerSource)
    end,
    { silentTransient = true }
)

registerIngress(
    GCIdentityEvents.server.sendRegistrationCode,
    'registration',
    GCIdentityValidation.ValidateRegistration,
    GCIdentityService.SendRegistrationCode
)

registerIngress(
    GCIdentityEvents.server.verifyEmail,
    'verifyEmail',
    GCIdentityValidation.ValidateVerificationCode,
    GCIdentityService.VerifyEmailCode
)

registerIngress(
    GCIdentityEvents.server.resendVerification,
    'resendVerification',
    GCIdentityValidation.ValidateResendVerification,
    GCIdentityService.ResendVerification
)

registerIngress(
    GCIdentityEvents.server.changeRegistrationEmail,
    'changeRegistrationEmail',
    GCIdentityValidation.ValidateChangeRegistrationEmail,
    GCIdentityService.ChangeRegistrationEmail
)

registerIngress(
    GCIdentityEvents.server.finalizeRegistration,
    'finalizeRegistration',
    GCIdentityValidation.ValidateFinalizeRegistration,
    GCIdentityService.FinalizeRegistration
)

registerIngress(
    GCIdentityEvents.server.completeProfile,
    'completeProfile',
    GCIdentityValidation.ValidateCompleteProfile,
    GCIdentityService.CompleteProfile
)

RegisterNetEvent(GCIdentityEvents.server.clientFailure, function(payload)
    local playerSource = source
    local allowed, rateError = GCIdentityRateLimit.Check(playerSource, 'clientFailure')

    if not allowed then
        reject(playerSource, payload, rateError)
        return
    end

    local validated, validationError = GCIdentityValidation.ValidateClientFailure(payload)

    if not validated then
        reject(playerSource, payload, validationError)
        return
    end

    GCIdentityLogger.Error(
        validated.code,
        'Client identity lifecycle failed; disconnecting safely',
        { source = playerSource }
    )
    DropPlayer(playerSource, ('GCore Identity unavailable (%s)'):format(validated.code))
end)

registerIngress(
    GCIdentityEvents.server.createCharacter,
    'createCharacter',
    GCIdentityValidation.ValidateCreateCharacter,
    GCIdentityService.CreateCharacter
)

registerIngress(
    GCIdentityEvents.server.selectCharacter,
    'selectCharacter',
    GCIdentityValidation.ValidateSelectCharacter,
    GCIdentityService.SelectCharacter
)

RegisterNetEvent(GCIdentityEvents.server.exit, function(payload)
    local playerSource = source
    local allowed, rateError = GCIdentityRateLimit.Check(playerSource, 'exit')

    if not allowed then
        reject(playerSource, payload, rateError)
        return
    end

    local validated, validationError = GCIdentityValidation.ValidateExit(payload)

    if not validated then
        reject(playerSource, payload, validationError)
        return
    end

    DropPlayer(playerSource, 'Exited identity setup')
end)

AddEventHandler('playerDropped', function()
    GCIdentityService.Disconnect(source)
end)

AddEventHandler('gc_core:hook:playerSpawned', function(playerSource)
    GCIdentityService.HandleCoreSpawned(playerSource)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= 'gc_core' then
        return
    end

    GCIdentityStates.ClearAll()
    GCIdentityRateLimit.ClearAll()
    GCIdentityLogger.Warn(
        'GC-IDENTITY-CORE-UNAVAILABLE',
        'gc_core stopped; runtime identity state cleared'
    )
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'gc_core' or not GCIdentityService.IsAvailable() then
        return
    end

    local recovered = GCIdentityService.RecoverOnlinePlayers()
    GCIdentityLogger.Info(
        'GC-IDENTITY-RECOVERY-COMPLETE',
        'gc_core restart recovery completed',
        { recovered = recovered }
    )
end)
