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
            if options and options.silentWhileStarting
                and serviceError == 'GC-IDENTITY-DATABASE-UNAVAILABLE' then
                return
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
    { silentWhileStarting = true }
)

registerIngress(
    GCIdentityEvents.server.registerAccount,
    'registration',
    GCIdentityValidation.ValidateRegistration,
    GCIdentityService.RegisterAccount
)

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
