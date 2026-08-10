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

RegisterNetEvent(GCIdentityEvents.server.hello, function(payload)
    local playerSource = source
    local validated, validationError = GCIdentityValidation.ValidateHello(payload)

    if not validated then
        reject(playerSource, payload, validationError)
        return
    end

    local snapshot, helloError = GCIdentityService.Hello(playerSource)

    if not snapshot then
        reject(playerSource, payload, helloError)
        return
    end

    GCIdentityService.SendSnapshot(playerSource)
end)

RegisterNetEvent(GCIdentityEvents.server.createCharacter, function(payload)
    local playerSource = source
    local validated, validationError = GCIdentityValidation.ValidateCreateCharacter(payload)

    if not validated then
        reject(playerSource, payload, validationError)
        return
    end

    local character, createError = GCIdentityService.CreateCharacter(playerSource, validated)

    if not character then
        reject(playerSource, validated, createError)
        return
    end

    GCIdentityService.SendSnapshot(playerSource)
end)

RegisterNetEvent(GCIdentityEvents.server.selectCharacter, function(payload)
    local playerSource = source
    local validated, validationError = GCIdentityValidation.ValidateSelectCharacter(payload)

    if not validated then
        reject(playerSource, payload, validationError)
        return
    end

    local character, selectError = GCIdentityService.SelectCharacter(playerSource, validated)

    if not character then
        reject(playerSource, validated, selectError)
        return
    end

    GCIdentityService.SendSnapshot(playerSource)
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
    if resourceName ~= 'gc_core' then
        return
    end

    local recovered = GCIdentityService.RecoverOnlinePlayers()
    GCIdentityLogger.Info(
        'GC-IDENTITY-RECOVERY-COMPLETE',
        'gc_core restart recovery completed',
        { recovered = recovered }
    )
end)
