-- RU: Главный серверный файл GreenCore.
-- EN: GreenCore main server file.

-- RU: Обработчик подключения игрока.
-- EN: Player connection handler.
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    GCConnection.HandleConnecting(playerName, setKickReason, deferrals)
end)

-- RU: Обработчик отключения игрока.
-- EN: Player disconnection handler.
AddEventHandler('playerDropped', function(reason, resourceName, clientDropReason)
    GCPlayers.HandleDropped(reason, resourceName, clientDropReason)
end)

-- RU: Обработчик запуска ресурса.
-- EN: Resource start handler.
AddEventHandler('onResourceStart', function(resourceName)
    -- RU: Проверяем, что это наш ресурс.
    -- EN: Verify that this is our resource.
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    -- RU: Инициализируем генератор случайных чисел.
    -- EN: Initialize the random number generator.
    math.randomseed(os.time())

    -- RU: Очищаем старые runtime-таблицы.
    -- EN: Clear old runtime tables.
    GCSessions.Clear()
    GCRateLimit.ClearAll()

    -- RU: Разблокируем подключения.
    -- EN: Unblock connections.
    GCSecurity.UnblockConnections()

    -- RU: Запрашиваем повторную синхронизацию у всех онлайн-игроков.
    -- EN: Request a resync from all online players.
    for _, playerSource in ipairs(GetPlayers()) do
        TriggerClientEvent('gc_core:client:forceResync', playerSource)
    end

    -- RU: Выводим сообщение о запуске.
    -- EN: Print the startup message.
    GCLogger.Info('GC-BOOT-100', ('gc_core %s started successfully'):format(GCVersion.GetString()))
end)

-- RU: Обработчик остановки ресурса.
-- EN: Resource stop handler.
AddEventHandler('onResourceStop', function(resourceName)
    -- RU: Проверяем, что это наш ресурс.
    -- EN: Verify that this is our resource.
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    -- RU: Блокируем новые подключения.
    -- EN: Block new connections.
    GCSecurity.BlockConnections('resource_stopping')

    -- RU: Очищаем все сессии.
    -- EN: Clear all sessions.
    GCSessions.Clear()

    -- RU: Выводим сообщение об остановке.
    -- EN: Print the stop message.
    GCLogger.Info('GC-BOOT-101', 'gc_core stopped')
end)