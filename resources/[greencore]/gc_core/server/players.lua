-- RU: Сервис игроков GreenCore.
-- EN: GreenCore player service.

-- RU: Таблица сервиса игроков.
-- EN: Player service table.
GCPlayers = {}

--- RU:
--- Обрабатывает отключение игрока.
---
--- EN:
--- Handles a player disconnection.
---
--- @param reason string|nil Disconnection reason
--- @param resourceName string|nil Resource name
--- @param clientDropReason string|nil Client drop reason
function GCPlayers.HandleDropped(reason, resourceName, clientDropReason)
    -- RU: Получаем source игрока.
    -- EN: Get the player source.
    local playerSource = source

    -- RU: Проверяем корректность source.
    -- EN: Validate the source.
    if type(playerSource) ~= 'number' then
        return
    end

    -- RU: Находим сессию игрока.
    -- EN: Find the player session.
    local session = GCSessions.Get(playerSource)

    if not session then
        return
    end

    -- RU: Устанавливаем состояние disconnecting.
    -- EN: Set the disconnecting state.
    GCStates.Set(playerSource, 'disconnecting', 'player_dropped')

    -- RU: Сохраняем безопасную причину отключения.
    -- EN: Save a safe disconnection reason.
    local safeReason = 'unknown'

    if type(reason) == 'string' and #reason > 0 then
        safeReason = GCUtils.Truncate(reason, 128)
    end

    -- RU: Удаляем решения о спавне.
    -- EN: Remove spawn decisions.
    GCSpawn.RemovePlayerDecisions(playerSource)

    -- RU: Удаляем данные rate limit.
    -- EN: Remove rate limit data.
    GCRateLimit.RemovePlayer(playerSource)

    -- RU: Устанавливаем состояние disconnected.
    -- EN: Set the disconnected state.
    GCStates.Set(playerSource, 'disconnected', 'player_dropped')

    -- RU: Удаляем серверную сессию.
    -- EN: Remove the server session.
    GCSessions.Remove(playerSource, safeReason)

    -- RU: Записываем лог.
    -- EN: Write a log.
    GCLogger.Info('GC-PLAYER-100', 'Player disconnected', {
        source = playerSource,
        reason = safeReason
    })
end