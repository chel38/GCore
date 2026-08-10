-- RU: Регистрация клиентских сетевых событий GreenCore.
-- EN: GreenCore client network event registration.

-- RU: Обработчик подтверждения подключения.
-- EN: Connection acceptance handler.
GCClientSecurity.RegisterServerEvent(GCEvents.Client.connectionAccepted, function(payload)
    local valid, errorCode = GCValidation.ConnectionAccepted(payload)

    if not valid then
        GCClientDiagnostics.Report(errorCode)
        return
    end

    GCClientReadiness.Acknowledge()

    if GCClientState.IsConnectionAccepted() then
        return
    end

    -- RU: Устанавливаем флаг подтверждения подключения.
    -- EN: Set the connection acceptance flag.
    GCClientState.SetConnectionAccepted(true)

    -- RU: Запрашиваем спавн у сервера.
    -- EN: Request a spawn from the server.
    TriggerServerEvent(GCEvents.Server.requestSpawn, {})
end)

-- RU: Обработчик одобрения спавна.
-- EN: Spawn approval handler.
GCClientSecurity.RegisterServerEvent(GCEvents.Client.spawnApproved, function(payload)
    local valid, errorCode = GCValidation.SpawnApproved(payload)

    if not valid then
        GCClientDiagnostics.Report(errorCode)
        return
    end

    GCClientReadiness.Acknowledge()

    -- RU: Проверяем, что спавн ещё не выполняется.
    -- EN: Verify that a spawn is not already in progress.
    if GCClientState.IsSpawning()
        or GCClientState.IsSpawnConfirming()
        or GCClientState.IsSpawned()
        or GCClientState.IsSpawnDecisionReceived() then
        return
    end

    GCClientState.SetSpawnDecisionReceived(true)
    GCClientState.SetSpawnError(false)

    -- RU: Выполняем спавн (клиент переходит в spawn_confirming).
    -- EN: Perform the spawn (the client moves to spawn_confirming).
    GCClientSpawn.PerformSpawn(payload)
end)

-- RU: Обработчик отклонения спавна.
-- RU: Клиент не должен оставаться в состоянии spawned после отклонения.
-- EN: Spawn rejection handler.
-- EN: The client must not remain in the spawned state after a rejection.
GCClientSecurity.RegisterServerEvent(GCEvents.Client.spawnRejected, function(payload)
    local valid = GCValidation.SpawnRejected(payload)

    if not valid then
        return
    end

    GCClientReadiness.Acknowledge()

    -- RU: Старый reject не может сбросить уже подтверждённый spawned state.
    -- EN: A stale rejection cannot reset an already confirmed spawned state.
    if GCClientState.IsSpawned() then
        return
    end

    -- RU: Записываем ошибку в лог.
    -- EN: Log the error.
    GCLogger.Warn('GC-CLIENT-SPAWN-002', 'Spawn rejected', {
        errorCode = payload and payload.errorCode,
        retryable = payload and payload.retryable
    })

    -- RU: Сбрасываем подтверждение спавна и помечаем ошибку.
    -- EN: Reset the spawn confirmation and mark the error.
    GCClientState.SetSpawnConfirming(false)
    GCClientState.SetSpawning(false)
    GCClientState.SetSpawnDecisionReceived(false)
    GCClientState.SetSpawned(false)
    GCClientState.SetSpawnError(true)
end)

-- RU: Обработчик подтверждения спавна.
-- RU: ТОЛЬКО после этого события клиент устанавливает spawned=true.
-- RU: Сервер остаётся единственным источником истины.
-- EN: Spawn confirmation handler.
-- EN: ONLY after this event does the client set spawned=true.
-- EN: The server remains the single source of truth.
GCClientSecurity.RegisterServerEvent(GCEvents.Client.spawnConfirmed, function(payload)
    local valid = GCValidation.SpawnConfirmed(payload)

    if not valid then
        return
    end

    GCClientReadiness.Acknowledge()

    -- RU: Проверяем, что клиент действительно ожидал подтверждения.
    -- EN: Verify that the client was actually waiting for confirmation.
    if not GCClientState.IsSpawnConfirming() then
        -- RU: Восстановленный после рестарта игрок может получить spawnConfirmed
        -- RU: без spawn_confirming (он уже в мире). Принимаем и это.
        -- EN: A player recovered after a restart may receive spawnConfirmed without
        -- EN: spawn_confirming (already in the world). Accept this too.
        if payload and payload.state == 'spawned' then
            GCClientState.SetSpawnError(false)
            GCClientState.SetSpawning(false)
            GCClientState.SetSpawnDecisionReceived(false)
            GCClientState.SetSpawned(true)
            GCClientLoadingScreen.Complete()
        end
        return
    end

    -- RU: Сбрасываем флаг ошибки и подтверждаем завершение спавна.
    -- EN: Clear the error flag and confirm the spawn completion.
    GCClientState.SetSpawnError(false)
    GCClientState.SetSpawnConfirming(false)
    GCClientState.SetSpawnDecisionReceived(false)
    GCClientState.SetSpawned(true)
    GCClientLoadingScreen.Complete()
end)

-- RU: Обработчик принудительной ресинхронизации после рестарта gc_core.
-- RU: Клиент НЕ спавнит игрока заново автоматически. Он сообщает серверу о своей
-- RU: готовности (resyncReady), а сервер решает, что делать дальше.
-- EN: Force resync handler after a gc_core restart.
-- EN: The client does NOT automatically re-spawn the player. It reports its
-- EN: readiness (resyncReady) to the server, and the server decides what to do.
GCClientSecurity.RegisterServerEvent(GCEvents.Client.forceResync, function()
    -- RU: Сбрасываем клиентское состояние.
    -- EN: Reset the client state.
    GCClientState.Reset()
    GCClientReadiness.Reset()

    -- RU: Ответ отправляется только после реальной готовности клиента. Если
    -- RU: параллельно уже идёт обычный clientReady, он сам завершит recovery.
    -- EN: Reply only after the client is actually ready. If the normal clientReady
    -- EN: wait is already active, that handshake will complete recovery itself.
    GCClientReadiness.WaitForReadiness('resync')
end)

-- RU: Обработчик уведомления.
-- EN: Notification handler.
GCClientSecurity.RegisterServerEvent(GCEvents.Client.notify, function(payload)
    local valid = GCValidation.Notification(payload)

    if not valid then
        return
    end

    -- RU: Определяем тип уведомления.
    -- EN: Determine the notification type.
    local notificationType = payload.type

    -- RU: Выводим уведомление с типом.
    -- EN: Show the notification with its type.
    print(('[GreenCore][%s] %s'):format(notificationType, payload.message))
end)
