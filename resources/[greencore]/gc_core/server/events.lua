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
    local allowed, rateError = GCRateLimit.Check(playerSource, 'clientReady')

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

    -- RU: Обрабатываем готовность клиента.
    -- EN: Handle the client readiness.
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
    local allowed, rateError = GCRateLimit.Check(playerSource, 'requestSpawn')

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
            errorCode = spawnError
        })
    end
end)

-- RU: Обработчик подтверждения спавна.
-- EN: Spawn confirmation event handler.
RegisterNetEvent('gc_core:server:confirmSpawn', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed, rateError = GCRateLimit.Check(playerSource, 'confirmSpawn')

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

    -- RU: Подтверждаем спавн.
    -- EN: Confirm the spawn.
    local success, confirmError = GCSpawn.Confirm(playerSource, payload.decisionId)

    if not success then
        TriggerClientEvent('gc_core:client:spawnRejected', playerSource, {
            errorCode = confirmError
        })
    end
end)

-- RU: Обработчик сообщения об ошибке клиента.
-- EN: Client error report event handler.
RegisterNetEvent('gc_core:server:reportClientError', function(payload)
    -- RU: Получаем source игрока из контекста события.
    -- EN: Get the player source from the event context.
    local playerSource = source

    -- RU: Проверяем rate limit.
    -- EN: Check the rate limit.
    local allowed, rateError = GCRateLimit.Check(playerSource, 'reportClientError')

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
end)