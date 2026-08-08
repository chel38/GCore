-- RU: Сервис игроков GreenCore.
-- EN: GreenCore player service.

-- RU: Таблица сервиса игроков.
-- EN: Player service table.
GCPlayers = {}

--- Reads the authoritative OneSync entity state for a player's server ped.
--- Client-provided ped state is never used as proof of spawn or recovery.
function GCPlayers.GetEntitySnapshot(playerSource)
    local empty = {
        exists = false,
        alive = false,
        owner = nil,
        model = nil,
        position = nil
    }

    if type(playerSource) ~= 'number' or type(GetPlayerPed) ~= 'function' then
        return empty
    end

    local pedOk, ped = pcall(GetPlayerPed, playerSource)

    if not pedOk or type(ped) ~= 'number' or ped == 0 then
        return empty
    end

    local existsOk, exists = pcall(DoesEntityExist, ped)

    if not existsOk or not exists then
        return empty
    end

    local ownerOk, owner = pcall(NetworkGetEntityOwner, ped)
    local healthOk, health = pcall(GetEntityHealth, ped)
    local modelOk, model = pcall(GetEntityModel, ped)
    local coordsOk, coords = pcall(GetEntityCoords, ped)
    local minimumHealth = (GCConfig.Spawn.verification or {}).minimumHealth or 1

    return {
        exists = true,
        alive = healthOk and GCUtils.IsFiniteNumber(health) and health >= minimumHealth,
        owner = ownerOk and tonumber(owner) or nil,
        model = modelOk and model or nil,
        position = coordsOk and coords and {
            x = coords.x,
            y = coords.y,
            z = coords.z
        } or nil
    }
end

function GCPlayers.HasAuthoritativeLivePed(playerSource)
    local snapshot = GCPlayers.GetEntitySnapshot(playerSource)
    return snapshot.exists and snapshot.alive and snapshot.owner == playerSource
end

--- RU:
--- Выполняет полную очистку runtime-данных игрока.
--- Вызывается при отключении игрока из ЛЮБОГО состояния lifecycle.
--- Гарантирует отсутствие memory leak независимо от корректности state machine.
---
--- EN:
--- Performs a full cleanup of a player's runtime data.
--- Called when a player disconnects from ANY lifecycle state.
--- Guarantees no memory leak regardless of the state machine correctness.
---
--- @param playerSource number FiveM server player source
--- @param safeReason string Safe disconnection reason
local function cleanupPlayerRuntime(playerSource, safeReason)
    -- RU: Отменяем все решения о спавне.
    -- EN: Cancel all spawn decisions.
    GCSpawn.RemovePlayerDecisions(playerSource)

    -- RU: Удаляем данные rate limit.
    -- EN: Remove rate limit data.
    GCRateLimit.RemovePlayer(playerSource)

    -- RU: Удаляем активную сессию (вместе со всеми индексами).
    -- EN: Remove the active session (with all its indexes).
    GCSessions.Remove(playerSource, safeReason)

    -- RU: Удаляем pending connection, если она осталась (игрок отключился
    -- RU: до playerJoining).
    -- EN: Remove the pending connection if it remains (the player disconnected
    -- EN: before playerJoining).
    GCSessions.RemovePendingConnection(playerSource)
end

--- RU:
--- Обрабатывает отключение игрока.
--- Поток: найти сессию -> disconnecting -> отменить решения -> удалить
--- rate-limit -> удалить индексы -> disconnected -> полная очистка.
--- Если нормальный state transition невозможен, выполняется FORCED CLEANUP.
---
--- EN:
--- Handles a player disconnection.
--- Flow: find session -> disconnecting -> cancel decisions -> remove rate-limit
--- -> remove indexes -> disconnected -> full cleanup.
--- If a normal state transition is impossible, FORCED CLEANUP is executed.
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

    -- RU: Сохраняем безопасную причину отключения.
    -- EN: Save a safe disconnection reason.
    local safeReason = 'unknown'

    if type(reason) == 'string' and #reason > 0 then
        safeReason = GCUtils.Truncate(reason, 128)
    end

    -- RU: Находим сессию игрока.
    -- EN: Find the player session.
    local session = GCSessions.Get(playerSource)

    -- RU: Если активной сессии нет, возможно, осталась только pending connection.
    -- EN: If there is no active session, perhaps only a pending connection remains.
    local pending = GCSessions.GetPendingConnection(playerSource)

    if not session and pending then
        -- RU: Игрок отключился до playerJoining — очищаем pending connection.
        -- EN: The player disconnected before playerJoining — clean up the pending connection.
        GCSessions.RemovePendingConnection(playerSource)
        GCRateLimit.RemovePlayer(playerSource)
        return
    end

    if not session then
        return
    end

    -- RU: Устанавливаем состояние disconnecting.
    -- EN: Set the disconnecting state.
    local disconnectSuccess, disconnectError = GCStates.Set(playerSource, 'disconnecting', 'player_dropped')

    if not disconnectSuccess then
        -- RU: Нормальный переход невозможен — принудительная очистка.
        -- EN: A normal transition is impossible — forced cleanup.
        GCLogger.Warn('GC-PLAYER-101', 'Forced cleanup: failed to set disconnecting state', {
            source = playerSource,
            errorCode = disconnectError
        })
        cleanupPlayerRuntime(playerSource, safeReason)
        return
    end

    -- RU: Устанавливаем состояние disconnected.
    -- EN: Set the disconnected state.
    local disconnectedSuccess, disconnectedError = GCStates.Set(playerSource, 'disconnected', 'player_dropped')

    if not disconnectedSuccess then
        GCLogger.Warn('GC-PLAYER-101', 'Failed to set disconnected state, proceeding with cleanup', {
            source = playerSource,
            errorCode = disconnectedError
        })
    end

    -- RU: Выполняем полную очистку runtime-данных.
    -- EN: Perform the full runtime-data cleanup.
    cleanupPlayerRuntime(playerSource, safeReason)

    -- RU: Записываем лог.
    -- EN: Write a log.
    GCLogger.Info('GC-PLAYER-100', 'Player disconnected', {
        source = playerSource,
        reason = safeReason
    })
end

-- RU: forceResync повторяется ограниченно и остаётся лишь ускоряющей подсказкой:
-- RU: clientReady при старте клиента также завершает recovery.
-- EN: forceResync is retried a bounded number of times and remains only a prompt:
-- EN: clientReady on client start can also complete recovery.
local function sendRecoveryPrompt(playerSource, sessionId, attempt)
    local session = GCSessions.Get(playerSource)

    if not GCServerRuntime.running
        or not session
        or session.sessionId ~= sessionId
        or not GCStates.Is(playerSource, 'resyncing') then
        return
    end

    local maxAttempts = math.max(1, GCConfig.Connection.resyncForceMaxAttempts or 3)
    session.recoveryPromptAttempts = attempt
    TriggerClientEvent(GCEvents.Client.forceResync, playerSource)

    if attempt >= maxAttempts then
        return
    end

    SetTimeout(GCConfig.Connection.resyncForceIntervalMs or 1500, function()
        sendRecoveryPrompt(playerSource, sessionId, attempt + 1)
    end)
end

--- RU:
--- Восстанавливает сессии всех онлайн-игроков после рестарта gc_core.
--- ВАЖНО: рестарт gc_core НЕ должен уничтожать runtime-сессии и просить клиента
--- синхронизироваться с несуществующей сессией. Вместо этого для каждого
--- подключённого игрока создаётся recovered session (state = resyncing).
---
--- EN:
--- Recovers the sessions of all online players after a gc_core restart.
--- IMPORTANT: a gc_core restart must NOT destroy runtime sessions and then ask
--- the client to resync with a non-existent session. Instead, a recovered session
--- (state = resyncing) is created for every connected player.
---
--- @return number recoveredCount Number of recovered sessions
function GCPlayers.RecoverOnlinePlayers()
    local recoveredCount = 0

    -- RU: Получаем всех подключённых игроков.
    -- EN: Get all connected players.
    local players = GetPlayers()

    for _, rawPlayerSource in ipairs(players) do
        -- RU: GetPlayers возвращает строковые server ID в Lua runtime.
        -- EN: GetPlayers returns string server IDs in the Lua runtime.
        local playerSource = tonumber(rawPlayerSource)

        if playerSource then
            -- RU: Пропускаем игроков, у которых уже есть активная сессия.
            -- EN: Skip players who already have an active session.
            if not GCSessions.Exists(playerSource) then
                -- RU: Получаем имя и идентификаторы.
                -- EN: Get the name and identifiers.
                local playerName = GetPlayerName(playerSource) or 'Player'
                local identifiers = GCIdentifiers.GetAll(playerSource)
                local primaryIdentifier, primaryType = GCIdentifiers.GetPrimary(playerSource)

                -- RU: Создаём recovered session.
                -- EN: Create a recovered session.
                local session, sessionError = GCSessions.CreateRecoveredSession(
                    playerSource,
                    playerName,
                    identifiers,
                    primaryIdentifier,
                    primaryType
                )

                if session then
                    recoveredCount = recoveredCount + 1

                    local sessionId = session.sessionId
                    sendRecoveryPrompt(playerSource, sessionId, 1)

                    SetTimeout(GCConfig.Connection.resyncReadyTimeoutMs or 15000, function()
                        local currentSession = GCSessions.Get(playerSource)

                        if GCServerRuntime.running
                            and currentSession
                            and currentSession.sessionId == sessionId
                            and GCStates.Is(playerSource, 'resyncing') then
                            GCLogger.Warn('GC-RECOVERY-TIMEOUT', '[GC][RECOVERY] Handshake timed out', {
                                source = playerSource,
                                attempts = currentSession.recoveryPromptAttempts
                            })
                            GCStates.Set(playerSource, 'error', 'resync_timeout')
                            DropPlayer(
                                playerSource,
                                GC_T(GCConnection.GetPlayerLocale(playerSource), 'connection.timeout')
                            )
                        end
                    end)
                else
                    GCLogger.Warn('GC-RESYNC-001', 'Failed to recover player session', {
                        source = playerSource,
                        errorCode = sessionError
                    })
                end
            end
        end
    end

    return recoveredCount
end
