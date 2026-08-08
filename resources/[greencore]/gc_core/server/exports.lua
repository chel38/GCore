-- RU: Публичный API GreenCore (серверные exports).
-- EN: GreenCore public API (server exports).

-- RU: Возвращает версию API.
-- EN: Returns the API version.
exports('GetApiVersion', function()
    return GCConfig.General.apiVersion
end)

-- RU: Возвращает версию gc_core.
-- EN: Returns the gc_core version.
exports('GetVersion', function()
    return GCVersion.GetString()
end)

-- RU: Проверяет, подключён ли игрок (существует ли сессия).
-- EN: Checks whether a player is connected (session exists).
exports('IsPlayerConnected', function(playerSource)
    if type(playerSource) ~= 'number' then
        return false
    end

    return GCSessions.Exists(playerSource)
end)

-- RU: Проверяет, готов ли игрок к игровым действиям.
-- EN: Checks whether a player is ready for gameplay actions.
exports('IsPlayerReady', function(playerSource)
    if type(playerSource) ~= 'number' then
        return false
    end

    return GCStates.Is(playerSource, 'client_ready')
        or GCStates.Is(playerSource, 'spawn_pending')
        or GCStates.Is(playerSource, 'spawning')
        or GCStates.Is(playerSource, 'spawned')
end)

-- RU: Проверяет, появился ли игрок.
-- EN: Checks whether a player has spawned.
exports('IsPlayerSpawned', function(playerSource)
    if type(playerSource) ~= 'number' then
        return false
    end

    return GCStates.Is(playerSource, 'spawned')
end)

-- RU: Возвращает текущее состояние игрока.
-- EN: Returns the current state of a player.
exports('GetPlayerState', function(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    return GCStates.Get(playerSource)
end)

-- RU: Возвращает безопасную копию сессии игрока.
-- EN: Returns a safe copy of a player session.
exports('GetPlayerSession', function(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    return GCSessions.Clone(playerSource)
end)

-- RU: Возвращает идентификатор игрока по типу.
-- EN: Returns a player identifier by type.
exports('GetPlayerIdentifier', function(playerSource, identifierType)
    if type(playerSource) ~= 'number' then
        return nil
    end

    if type(identifierType) ~= 'string' then
        return nil
    end

    return GCIdentifiers.GetByType(playerSource, identifierType)
end)

-- RU: Проверяет, может ли игрок использовать игровые функции.
-- EN: Checks whether a player can use gameplay features.
exports('CanUseGameplayFeatures', function(playerSource)
    if type(playerSource) ~= 'number' then
        return false
    end

    return GCStates.Is(playerSource, 'spawned')
end)

-- RU: Запрашивает спавн игрока.
-- EN: Requests a player spawn.
exports('RequestPlayerSpawn', function(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    return GCSpawn.Request(playerSource)
end)

-- RU: Отправляет уведомление игроку.
-- EN: Sends a notification to a player.
exports('NotifyPlayer', function(playerSource, message, notificationType)
    if type(playerSource) ~= 'number' then
        return false
    end

    if type(message) ~= 'string' then
        return false
    end

    local success, errorCode = GCNotifications.SendToPlayer(playerSource, message, notificationType)

    if not success then
        GCLogger.Warn('GC-NOTIFY-100', 'Failed to send notification', {
            source = playerSource,
            errorCode = errorCode
        })
    end

    return success
end)

-- RU: Отправляет уведомление всем игрокам.
-- EN: Sends a notification to all players.
exports('NotifyAll', function(message, notificationType)
    if type(message) ~= 'string' then
        return false
    end

    local success, errorCode = GCNotifications.SendToAll(message, notificationType)

    if not success then
        GCLogger.Warn('GC-NOTIFY-101', 'Failed to send notification to all', {
            errorCode = errorCode
        })
    end

    return success
end)