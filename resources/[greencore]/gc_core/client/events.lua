-- RU: Регистрация клиентских сетевых событий GreenCore.
-- EN: GreenCore client network event registration.

-- RU: Обработчик подтверждения подключения.
-- EN: Connection acceptance handler.
RegisterNetEvent('gc_core:client:connectionAccepted', function(payload)
    -- RU: Устанавливаем флаг подтверждения подключения.
    -- EN: Set the connection acceptance flag.
    GCClientState.SetConnectionAccepted(true)

    -- RU: Запрашиваем спавн у сервера.
    -- EN: Request a spawn from the server.
    TriggerServerEvent('gc_core:server:requestSpawn', {})
end)

-- RU: Обработчик одобрения спавна.
-- EN: Spawn approval handler.
RegisterNetEvent('gc_core:client:spawnApproved', function(payload)
    -- RU: Проверяем, что спавн ещё не выполняется.
    -- EN: Verify that a spawn is not already in progress.
    if GCClientState.IsSpawning() then
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
RegisterNetEvent('gc_core:client:spawnRejected', function(payload)
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
RegisterNetEvent('gc_core:client:spawnConfirmed', function(payload)
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
        end
        return
    end

    -- RU: Сбрасываем флаг ошибки и подтверждаем завершение спавна.
    -- EN: Clear the error flag and confirm the spawn completion.
    GCClientState.SetSpawnError(false)
    GCClientState.SetSpawnConfirming(false)
    GCClientState.SetSpawnDecisionReceived(false)
    GCClientState.SetSpawned(true)
end)

-- RU: Обработчик принудительной ресинхронизации после рестарта gc_core.
-- RU: Клиент НЕ спавнит игрока заново автоматически. Он сообщает серверу о своей
-- RU: готовности (resyncReady), а сервер решает, что делать дальше.
-- EN: Force resync handler after a gc_core restart.
-- EN: The client does NOT automatically re-spawn the player. It reports its
-- EN: readiness (resyncReady) to the server, and the server decides what to do.
RegisterNetEvent('gc_core:client:forceResync', function()
    -- RU: Сбрасываем клиентское состояние.
    -- EN: Reset the client state.
    GCClientState.Reset()

    -- RU: Определяем, жив ли ped игрока (информация для сервера, не доверять целиком).
    -- EN: Determine whether the player ped is alive (information for the server, not fully trusted).
    local ped = PlayerPedId()
    local isPedAlive = ped ~= 0 and DoesEntityExist(ped) and IsPedAlive(ped)

    -- RU: Отправляем серверу ответ о готовности к resync.
    -- EN: Send the resync-ready response to the server.
    TriggerServerEvent('gc_core:server:resyncReady', {
        protocolVersion = GCConfig.General.protocolVersion,
        clientVersion = GCVersion.GetString(),
        isPedAlive = isPedAlive
    })
end)

-- RU: Обработчик уведомления.
-- EN: Notification handler.
RegisterNetEvent('gc_core:client:notify', function(payload)
    -- RU: Проверяем payload.
    -- EN: Validate the payload.
    if type(payload) ~= 'table' then
        return
    end

    -- RU: Проверяем сообщение.
    -- EN: Validate the message.
    if type(payload.message) ~= 'string' or #payload.message == 0 then
        return
    end

    -- RU: Определяем тип уведомления.
    -- EN: Determine the notification type.
    local notificationType = 'info'

    if type(payload.type) == 'string' and #payload.type > 0 then
        notificationType = payload.type
    end

    -- RU: Выводим уведомление с типом.
    -- EN: Show the notification with its type.
    print(('[GreenCore][%s] %s'):format(notificationType, payload.message))
end)
