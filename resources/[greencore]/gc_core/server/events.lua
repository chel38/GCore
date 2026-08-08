-- RU: Network ingress. Every action is rate-limited and schema-validated here.
-- EN: Network ingress. Every action is rate-limited and schema-validated here.

local function registerViolation(playerSource)
    if GCRateLimit.RegisterViolation(playerSource) then
        DropPlayer(playerSource, GC_T(GCConnection.GetPlayerLocale(playerSource), 'error.rate_limited'))
    end
end

local function guard(playerSource, actionName, validator, payload)
    if not GCRateLimit.Check(playerSource, actionName) then
        registerViolation(playerSource)
        return false
    end

    GCRateLimit.Record(playerSource, actionName)
    local valid, errorCode = validator(payload)

    if not valid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        registerViolation(playerSource)
        return false
    end

    return true
end

RegisterNetEvent(GCEvents.Server.clientReady, function(payload)
    local playerSource = source

    if guard(playerSource, 'clientReady', GCValidation.ClientReady, payload) then
        GCConnection.HandleClientReady(playerSource, payload)
    end
end)

RegisterNetEvent(GCEvents.Server.requestSpawn, function(payload)
    local playerSource = source

    if not guard(playerSource, 'requestSpawn', GCValidation.RequestSpawn, payload) then
        return
    end

    local decision, errorCode = GCSpawn.Request(playerSource)

    if not decision then
        TriggerClientEvent(GCEvents.Client.spawnRejected, playerSource, {
            errorCode = errorCode,
            retryable = false
        })
    end
end)

RegisterNetEvent(GCEvents.Server.confirmSpawn, function(payload)
    local playerSource = source

    if not guard(playerSource, 'confirmSpawn', GCValidation.ConfirmSpawn, payload) then
        return
    end

    local success, errorCode, retrying = GCSpawn.Confirm(playerSource, payload.decisionId)

    if not success then
        TriggerClientEvent(GCEvents.Client.spawnRejected, playerSource, {
            errorCode = errorCode,
            retryable = retrying == true
        })
    end
end)

RegisterNetEvent(GCEvents.Server.reportClientError, function(payload)
    local playerSource = source

    if not guard(playerSource, 'reportClientError', GCValidation.ReportClientError, payload) then
        return
    end

    GCLogger.Warn('GC-CLIENT-100', 'Client reported an error', {
        source = playerSource,
        errorCode = payload.errorCode
    })

    if payload.errorCode:sub(1, 8) == 'GC-SPAWN' then
        GCSpawn.HandleSpawnFailure(playerSource, payload.errorCode)
    end
end)

RegisterNetEvent(GCEvents.Server.resyncReady, function(payload)
    local playerSource = source

    if guard(playerSource, 'resyncReady', GCValidation.ResyncReady, payload) then
        GCConnection.HandleResyncReady(playerSource, payload)
    end
end)
