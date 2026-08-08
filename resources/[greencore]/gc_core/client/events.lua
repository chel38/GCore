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

    -- RU: Выполняем спавн.
    -- EN: Perform the spawn.
    GCClientSpawn.PerformSpawn(payload)
end)

-- RU: Обработчик отклонения спавна.
-- EN: Spawn rejection handler.
RegisterNetEvent('gc_core:client:spawnRejected', function(payload)
    -- RU: Записываем ошибку в лог.
    -- EN: Log the error.
    GCLogger.Warn('GC-CLIENT-SPAWN-002', 'Spawn rejected', {
        errorCode = payload and payload.errorCode
    })
end)

-- RU: Обработчик принудительной ресинхронизации.
-- EN: Force resync handler.
RegisterNetEvent('gc_core:client:forceResync', function()
    -- RU: Сбрасываем клиентское состояние.
    -- EN: Reset the client state.
    GCClientState.Reset()

    -- RU: Сбрасываем флаг отправки готовности.
    -- EN: Reset the readiness sent flag.
    GCClientReadiness.Reset()

    -- RU: Запускаем ожидание готовности заново.
    -- EN: Restart the readiness wait.
    GCClientReadiness.WaitForReadiness()
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