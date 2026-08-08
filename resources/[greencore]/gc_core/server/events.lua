-- RU: Регистрация сетевых событий GreenCore.
-- EN: GreenCore network event registration.

-- RU: Обработчик события готовности клиента.
-- EN: Client readiness event handler.
RegisterNetEvent('gc_core:server:clientReady', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed = GCRateLimit.Check(playerSource, 'clientReady')

    if not allowed then
        local shouldKick = GCRateLimit.RegisterViolation(playerSource)

        if shouldKick then
            DropPlayer(playerSource, GC_T(GCConnection.GetPlayerLocale(playerSource), 'error.rate_limited'))
        end

        return
    end

    -- RU: Записываем факт выполнения действия.
    -- EN: Record the action.
    GCRateLimit.Record(playerSource, 'clientReady')

    -- RU: Проверяем payload.
    -- EN: Validate the payload.
    local isValid, errorCode = GCValidation.ClientReady(payload)

    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    -- RU: Обрабатываем готовность клиента (включая строгую проверку протокола).
    -- EN: Handle the client readiness (including the strict protocol check).
    GCConnection.HandleClientReady(playerSource, payload)
end)

-- RU: Обработчик запроса спавна.
-- EN: Spawn request event handler.
RegisterNetEvent('gc_core:server:requestSpawn', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed = GCRateLimit.Check(playerSource, 'requestSpawn')

    if not allowed then
        local shouldKick = GCRateLimit.RegisterViolation(playerSource)

        if shouldKick then
            DropPlayer(playerSource, GC_T(GCConnection.GetPlayerLocale(playerSource), 'error.rate_limited'))
        end

        return
    end

    -- RU: Записываем факт выполнения действия.
    -- EN: Record the action.
    GCRateLimit.Record(playerSource, 'requestSpawn')

    -- RU: Проверяем payload.
    -- EN: Validate the payload.
    local isValid, errorCode = GCValidation.RequestSpawn(payload)

    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    -- RU: Запрашиваем спавн.
    -- EN: Request the spawn.
    local decision, spawnError = GCSpawn.Request(playerSource)

    if not decision then
        TriggerClientEvent('gc_core:client:spawnRejected', playerSource, {
            errorCode = spawnError,
            retryable = false
        })
    end
end)

-- RU: Обработчик подтверждения спавна.
-- RU: Используется атомарный GCSpawn.Confirm: решение потребляется только
-- RU: после успешного перехода состояния в spawned.
-- EN: Spawn confirmation event handler.
-- EN: Uses the atomic GCSpawn.Confirm: the decision is consumed only after a
-- EN: successful state transition to spawned.
RegisterNetEvent('gc_core:server:confirmSpawn', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed = GCRateLimit.Check(playerSource, 'confirmSpawn')

    if not allowed then
        local shouldKick = GCRateLimit.RegisterViolation(playerSource)

        if shouldKick then
            DropPlayer(playerSource, GC_T(GCConnection.GetPlayerLocale(playerSource), 'error.rate_limited'))
        end

        return
    end

    -- RU: Записываем факт выполнения действия.
    -- EN: Record the action.
    GCRateLimit.Record(playerSource, 'confirmSpawn')

    -- RU: Проверяем payload.
    -- EN: Validate the payload.
    local isValid, errorCode = GCValidation.ConfirmSpawn(payload)

    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    -- RU: Подтверждаем спавн (атомарно).
    -- EN: Confirm the spawn (atomically).
    local success, confirmError = GCSpawn.Confirm(playerSource, payload.decisionId)

    if not success then
        -- RU: Отклоняем; клиент не должен оставаться в состоянии spawned.
        -- EN: Reject; the client must not remain in the spawned state.
        TriggerClientEvent('gc_core:client:spawnRejected', playerSource, {
            errorCode = confirmError,
            retryable = false
        })
    end
end)

-- RU: Обработчик сообщения об ошибке клиента.
-- RU: Ошибки спавна обрабатываются сервером через ограниченный retry flow.
-- EN: Client error report event handler.
-- EN: Spawn errors are handled by the server through the limited retry flow.
RegisterNetEvent('gc_core:server:reportClientError', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed = GCRateLimit.Check(playerSource, 'reportClientError')

    if not allowed then
        local shouldKick = GCRateLimit.RegisterViolation(playerSource)

        if shouldKick then
            DropPlayer(playerSource, GC_T(GCConnection.GetPlayerLocale(playerSource), 'error.rate_limited'))
        end

        return
    end

    -- RU: Записываем факт выполнения действия.
    -- EN: Record the action.
    GCRateLimit.Record(playerSource, 'reportClientError')

    -- RU: Проверяем payload.
    -- EN: Validate the payload.
    local isValid, errorCode = GCValidation.ReportClientError(payload)

    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    -- RU: Записываем ошибку клиента в лог.
    -- EN: Log the client error.
    GCLogger.Warn('GC-CLIENT-100', 'Client reported an error', {
        source = playerSource,
        errorCode = payload.errorCode
    })

    -- RU: Если это ошибка спавна, запускаем серверный retry flow.
    -- EN: If this is a spawn error, start the server-controlled retry flow.
    local errorCode = payload.errorCode

    if type(errorCode) == 'string' and errorCode:sub(1, 7) == 'GC-SPAWN' then
        GCSpawn.HandleSpawnFailure(playerSource, errorCode)
    end
end)

-- RU: Обработчик ответа о готовности к resync после рестарта.
-- EN: Resync-ready response handler after a restart.
RegisterNetEvent('gc_core:server:resyncReady', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed = GCRateLimit.Check(playerSource, 'resyncReady')

    if not allowed then
        local shouldKick = GCRateLimit.RegisterViolation(playerSource)

        if shouldKick then
            DropPlayer(playerSource, GC_T(GCConnection.GetPlayerLocale(playerSource), 'error.rate_limited'))
        end

        return
    end

    -- RU: Записываем факт выполнения действия.
    -- EN: Record the action.
    GCRateLimit.Record(playerSource, 'resyncReady')

    -- RU: Проверяем payload.
    -- EN: Validate the payload.
    local isValid, errorCode = GCValidation.ResyncReady(payload)

    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    -- RU: Проверяем строгое совпадение версии протокола.
    -- EN: Verify strict protocol version match.
    local protocolMatches, protocolError = GCValidation.ProtocolMatches(payload.protocolVersion)

    if not protocolMatches then
        GCLogger.Warn('GC-PROTOCOL-MISMATCH-001', 'Client protocol incompatible during resync', {
            source = playerSource,
            clientProtocol = payload.protocolVersion
        })
        return
    end

    -- RU: Обрабатываем resync.
    -- EN: Handle the resync.
    GCConnection.HandleResyncReady(playerSource, payload)
end)
