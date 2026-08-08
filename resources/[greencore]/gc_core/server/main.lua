-- RU: Главный серверный файл GreenCore.
-- EN: GreenCore main server file.

-- RU: Обработчик подключения игрока.
-- RU: Здесь создаётся pending connection, а не активная сессия.
-- EN: Player connection handler.
-- EN: A pending connection is created here, not an active session.
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    GCConnection.HandleConnecting(playerName, setKickReason, deferrals)
end)

-- RU: Обработчик завершения входа игрока.
-- RU: FiveM передаёт oldSource (временный source), а source в контексте события
-- RU: является финальным runtime source. Здесь pending connection мигрируется
-- RU: в активную сессию.
-- EN: Player joining handler.
-- EN: FiveM passes oldSource (the temporary source), while the source in the event
-- EN: context is the final runtime source. Here the pending connection migrates
-- EN: into an active session.
AddEventHandler('playerJoining', function(oldSource)
    GCConnection.HandleJoining(oldSource)
end)

-- RU: Обработчик отключения игрока.
-- EN: Player disconnection handler.
AddEventHandler('playerDropped', function(reason, resourceName, clientDropReason)
    GCPlayers.HandleDropped(reason, resourceName, clientDropReason)
end)

-- RU: Обработчик запуска ресурса.
-- RU: Использует recovery flow: не очищает runtime-сессии, а восстанавливает
-- RU: сессии уже подключённых игроков и просит их о resync.
-- EN: Resource start handler.
-- EN: Uses the recovery flow: does not clear runtime sessions, but recovers the
-- EN: sessions of already-connected players and asks them to resync.
AddEventHandler('onResourceStart', function(resourceName)
    -- RU: Проверяем, что это наш ресурс.
    -- EN: Verify that this is our resource.
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    -- RU: Инициализируем генератор случайных чисел.
    -- EN: Initialize the random number generator.
    math.randomseed(os.time())

    -- RU: Валидируем конфигурацию только после загрузки провайдеров.
    -- EN: Validate configuration only after the providers have been loaded.
    GCPedProvider.ValidateConfig()

    if not GCSpawnLocationProvider.ValidateConfig() then
        GCLogger.Warn('GC-SPAWN-001', 'Default spawn location configuration is invalid')
    end

    -- RU: Очищаем только pending connection (их temporary source недействителен
    -- RU: после рестарта). Активные сессии восстанавливаются заново.
    -- EN: Clear only pending connections (their temporary sources are invalid
    -- EN: after a restart). Active sessions are recovered anew.
    GCSessions.ClearPending()

    -- RU: Сбрасываем данные rate limit (рестарт ресурса).
    -- EN: Reset rate limit data (resource restart).
    GCRateLimit.ClearAll()

    -- RU: Разблокируем подключения.
    -- EN: Unblock connections.
    GCSecurity.UnblockConnections()

    -- RU: Восстанавливаем сессии всех онлайн-игроков.
    -- EN: Recover the sessions of all online players.
    local recovered = GCPlayers.RecoverOnlinePlayers()

    -- RU: Запускаем обслуживание временных подключений и spawn decision.
    -- EN: Start maintenance for pending connections and spawn decisions.
    CreateThread(function()
        while true do
            for temporarySource, pending in pairs(GCSessions.GetAllPending()) do
                if GCSessions.IsPendingExpired(pending) then
                    GCLogger.Debug('GC-CONNECTION-PENDING-002', 'Pending connection expired', {
                        source = temporarySource,
                        connectionId = pending.connectionId
                    })
                    GCSessions.RemovePendingConnection(temporarySource)
                end
            end

            GCSpawn.CleanupExpiredDecisions()
            Wait(5000)
        end
    end)

    -- RU: Выводим сообщение о запуске.
    -- EN: Print the startup message.
    GCLogger.Info('GC-BOOT-100', ('gc_core %s started successfully (recovered %d players)'):format(
        GCVersion.GetString(),
        recovered
    ))
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

    -- RU: Очищаем pending connection и активные сессии.
    -- EN: Clear pending connections and active sessions.
    GCSessions.ClearPending()
    GCSessions.Clear()

    -- RU: Выводим сообщение об остановке.
    -- EN: Print the stop message.
    GCLogger.Info('GC-BOOT-101', 'gc_core stopped')
end)
