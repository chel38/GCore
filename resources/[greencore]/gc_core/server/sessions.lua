-- RU: Сервис сессий игрока GreenCore.
-- EN: GreenCore player session service.

-- RU: Таблица сервиса сессий.
-- EN: Session service table.
GCSessions = {}

-- RU: Внутреннее хранилище активных сессий. Недоступно сторонним ресурсам.
-- EN: Internal active session storage. Not accessible to third-party resources.
local sessions = {}

-- RU: Индекс активных сессий по основному идентификатору.
-- EN: Active session index by primary identifier.
local sessionsByIdentifier = {}

-- RU: Хранилище pending connection.
-- RU: ВАЖНО: во время playerConnecting source ещё не является окончательным
-- RU: runtime Player ID. Пока не произошёл playerJoining, соединение считается
-- RU: только ожидающим (pending), а не полноценной активной сессией.
-- EN: Pending connection storage.
-- EN: IMPORTANT: during playerConnecting the source is not yet the final runtime
-- EN: Player ID. Until playerJoining occurs, the connection is considered pending,
-- EN: not a full active session.
local pendingConnections = {}

-- RU: Индекс pending connection по основному идентификатору.
-- EN: Pending connection index by primary identifier.
local pendingByIdentifier = {}

-- RU: Счётчик последовательных идентификаторов pending connection.
-- EN: Sequential counter for pending connection identifiers.
local pendingCounter = 0

--- RU:
--- Создаёт pending connection для подключающегося игрока.
--- Пока playerJoining не произошёл, это НЕ активная сессия, а только
--- временное представление подключения, привязанное к temporary source.
---
--- EN:
--- Creates a pending connection for a connecting player.
--- Until playerJoining occurs this is NOT an active session, only a temporary
--- representation of the connection tied to the temporary source.
---
--- @param temporarySource number Temporary FiveM server player source
--- @param playerName string Player display name
--- @param identifiers table Player identifiers
--- @param primaryIdentifier string|nil Primary identifier
--- @param primaryIdentifierType string|nil Primary identifier type
--- @return table pending Pending connection
--- @return string|nil errorCode Error code
function GCSessions.CreatePendingConnection(temporarySource, playerName, identifiers, primaryIdentifier, primaryIdentifierType)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(temporarySource) ~= 'number' then
        return nil, 'GC-CONNECTION-PENDING-001'
    end

    if type(playerName) ~= 'string' then
        return nil, 'GC-CONNECTION-PENDING-001'
    end

    if type(identifiers) ~= 'table' then
        return nil, 'GC-CONNECTION-PENDING-001'
    end

    -- RU: Генерируем уникальный идентификатор pending connection.
    -- EN: Generate a unique pending connection identifier.
    pendingCounter = pendingCounter + 1
    local connectionId = GCIds.NewCorrelationId(('gc:connection:%d'):format(pendingCounter))

    local nowSec = GCUtils.NowSec()
    local lifetimeMs = GCConfig.Connection.pendingConnectionLifetimeMs or 60000

    -- RU: Создаём структуру pending connection.
    -- EN: Create the pending connection structure.
    local pending = {
        connectionId = connectionId,
        temporarySource = temporarySource,
        playerName = playerName,
        identifiers = GCUtils.DeepCopy(identifiers),
        primaryIdentifier = primaryIdentifier,
        primaryIdentifierType = primaryIdentifierType,
        state = 'connecting',
        connectedAt = nowSec,
        expiresAt = nowSec + math.floor(lifetimeMs / 1000)
    }

    -- RU: Сохраняем pending connection по temporary source.
    -- EN: Store the pending connection by temporary source.
    pendingConnections[temporarySource] = pending

    -- RU: Индексируем по основному идентификатору.
    -- EN: Index by primary identifier.
    if primaryIdentifier then
        pendingByIdentifier[primaryIdentifier] = pending
    end

    return pending
end

--- RU:
--- Возвращает pending connection по temporary source.
---
--- EN:
--- Returns a pending connection by temporary source.
---
--- @param temporarySource number Temporary source
--- @return table|nil pending Pending connection
function GCSessions.GetPendingConnection(temporarySource)
    if type(temporarySource) ~= 'number' then
        return nil
    end

    return pendingConnections[temporarySource]
end

--- RU:
--- Проверяет, истекла ли pending connection.
---
--- EN:
--- Checks whether a pending connection has expired.
---
--- @param pending table Pending connection
--- @return boolean expired Whether the pending connection has expired
function GCSessions.IsPendingExpired(pending)
    if type(pending) ~= 'table' then
        return true
    end

    return GCUtils.NowSec() > pending.expiresAt
end

--- RU:
--- Удаляет pending connection (по temporary source или по connectionId).
--- Полностью очищает связанные с ней данные.
---
--- EN:
--- Removes a pending connection (by temporary source or connectionId).
--- Fully clears its associated data.
---
--- @param temporarySource number|string Temporary source or connectionId
--- @return boolean removed Whether the pending connection was removed
function GCSessions.RemovePendingConnection(temporarySource)
    local pending = nil

    -- RU: Разрешаем поиск как по source, так и по connectionId.
    -- EN: Allow lookup by source or connectionId.
    if type(temporarySource) == 'number' then
        pending = pendingConnections[temporarySource]
    elseif type(temporarySource) == 'string' then
        for _, candidate in pairs(pendingConnections) do
            if candidate.connectionId == temporarySource then
                pending = candidate
                break
            end
        end
    end

    if not pending then
        return false
    end

    -- RU: Удаляем индекс по идентификатору.
    -- EN: Remove the identifier index.
    if pending.primaryIdentifier then
        pendingByIdentifier[pending.primaryIdentifier] = nil
    end

    -- RU: Удаляем запись по source.
    -- EN: Remove the entry by source.
    if type(temporarySource) == 'number' then
        pendingConnections[temporarySource] = nil
    else
        for key, candidate in pairs(pendingConnections) do
            if candidate.connectionId == temporarySource then
                pendingConnections[key] = nil
                break
            end
        end
    end

    return true
end

--- RU:
--- Мигрирует pending connection в полноценную активную сессию.
--- playerJoining предоставляет окончательный runtime source, которым заменяются
--- все внутренние ссылки на temporary source. Старая pending запись удаляется.
---
--- EN:
--- Promotes a pending connection to a full active session.
--- playerJoining provides the final runtime source, which replaces all internal
--- references to the temporary source. The old pending entry is removed.
---
--- @param temporarySource number|string Temporary source from playerConnecting
--- @param finalSource number|string Final runtime source from playerJoining
--- @return table|nil session Created active session
--- @return string|nil errorCode Error code
function GCSessions.PromotePendingConnection(temporarySource, finalSource)
    -- RU: playerJoining передаёт oldID строкой; нормализуем оба source.
    -- EN: playerJoining passes oldID as a string; normalize both sources.
    temporarySource = tonumber(temporarySource)
    finalSource = tonumber(finalSource)

    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(temporarySource) ~= 'number' then
        return nil, 'GC-JOIN-001'
    end

    if type(finalSource) ~= 'number' then
        return nil, 'GC-JOIN-001'
    end

    -- RU: Получаем pending connection.
    -- EN: Get the pending connection.
    local pending = pendingConnections[temporarySource]

    if not pending then
        return nil, 'GC-JOIN-001'
    end

    -- RU: Проверяем, что не существует активной сессии с final source.
    -- EN: Verify that no active session exists with the final source.
    if sessions[finalSource] then
        return nil, 'GC-JOIN-002'
    end

    -- RU: Генерируем Session ID.
    -- EN: Generate a Session ID.
    local sessionId = GCIds.NewSessionId()

    -- RU: Создаём активную сессию, перенося данные из pending connection.
    -- EN: Create the active session, carrying data from the pending connection.
    local session = {
        sessionId = sessionId,
        source = finalSource,
        playerName = pending.playerName,

        identifiers = GCUtils.DeepCopy(pending.identifiers),

        primaryIdentifierType = pending.primaryIdentifierType,
        primaryIdentifier = pending.primaryIdentifier,

        -- RU: Начинаем с состояния connecting; playerConnecting ещё валидирует.
        -- EN: Start in the connecting state; playerConnecting still validates.
        state = 'connecting',
        previousState = nil,
        stateReason = 'player_joined',

        connectedAt = pending.connectedAt,
        validatedAt = nil,
        clientReadyAt = nil,
        spawnedAt = nil,
        disconnectedAt = nil,

        spawnDecision = nil,
        lastPed = nil,
        spawnAttempt = 0,
        spawnRetries = 0,
        spawnSamePedRetries = 0,
        spawnDifferentPedRetries = 0,
        spawnVerificationAttempts = 0,
        nextSpawnPed = nil,
        attemptedPedModels = {},

        -- RU: Флаг восстановленной сессии после рестарта gc_core.
        -- EN: Flag of a recovered session after a gc_core restart.
        recovered = false,
        recoveryStartedAt = nil,
        recoveryCompletedAt = nil,
        recoveryPromptAttempts = 0,

        metadata = {
            locale = GCConfig.General.locale,
            clientVersion = nil,
            protocolVersion = nil
        }
    }

    -- RU: Сохраняем сессию по final source.
    -- EN: Store the session by final source.
    sessions[finalSource] = session

    -- RU: Индексируем по основному идентификатору.
    -- EN: Index by primary identifier.
    if session.primaryIdentifier then
        sessionsByIdentifier[session.primaryIdentifier] = session
    end

    -- RU: Удаляем pending connection (вместе со всеми индексами).
    -- EN: Remove the pending connection (with all its indexes).
    pendingConnections[temporarySource] = nil

    if pending.primaryIdentifier then
        pendingByIdentifier[pending.primaryIdentifier] = nil
    end

    -- RU: Записываем диагностический лог о миграции source.
    -- EN: Write a diagnostic log about the source migration.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseConnection then
        GCLogger.Debug('GC-JOIN-100', 'Pending connection promoted to active session', {
            temporarySource = temporarySource,
            finalSource = finalSource
        })
    end

    return session
end

--- RU:
--- Создаёт восстановленную (recovered) сессию для уже подключённого игрока
--- после рестарта gc_core. Такой игрок уже находится в мире, поэтому повторный
--- spawn не требуется; сессия начинается в состоянии resyncing.
---
--- EN:
--- Creates a recovered session for an already-connected player after a gc_core
--- restart. Such a player is already in the world, so no re-spawn is required;
--- the session starts in the resyncing state.
---
--- @param finalSource number|string Final runtime player source
--- @param playerName string Player display name
--- @param identifiers table Player identifiers
--- @param primaryIdentifier string|nil Primary identifier
--- @param primaryIdentifierType string|nil Primary identifier type
--- @return table session Recovered session
function GCSessions.CreateRecoveredSession(finalSource, playerName, identifiers, primaryIdentifier, primaryIdentifierType)
    finalSource = tonumber(finalSource)

    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(finalSource) ~= 'number' then
        return nil, 'GC-RESYNC-001'
    end

    -- RU: Генерируем Session ID.
    -- EN: Generate a Session ID.
    local sessionId = GCIds.NewSessionId()

    -- RU: Создаём восстановленную сессию.
    -- EN: Create the recovered session.
    local session = {
        sessionId = sessionId,
        source = finalSource,
        playerName = playerName,

        identifiers = GCUtils.DeepCopy(identifiers),

        primaryIdentifierType = primaryIdentifierType,
        primaryIdentifier = primaryIdentifier,

        -- RU: Восстановленная сессия начинается с resyncing, а не со spawn.
        -- EN: A recovered session starts with resyncing, not spawning.
        state = 'resyncing',
        previousState = nil,
        stateReason = 'resource_restart_recovery',

        connectedAt = GCUtils.NowSec(),
        validatedAt = nil,
        clientReadyAt = nil,
        spawnedAt = nil,
        disconnectedAt = nil,

        spawnDecision = nil,
        lastPed = nil,
        spawnAttempt = 0,
        spawnRetries = 0,
        spawnSamePedRetries = 0,
        spawnDifferentPedRetries = 0,
        spawnVerificationAttempts = 0,
        nextSpawnPed = nil,
        attemptedPedModels = {},

        -- RU: Флаг восстановленной сессии после рестарта.
        -- EN: Flag of a session recovered after a restart.
        recovered = true,
        recoveryStartedAt = GCUtils.NowSec(),
        recoveryCompletedAt = nil,
        recoveryPromptAttempts = 0,

        metadata = {
            locale = GCConfig.General.locale,
            clientVersion = nil,
            protocolVersion = nil
        }
    }

    -- RU: Сохраняем сессию.
    -- EN: Store the session.
    sessions[finalSource] = session

    -- RU: Индексируем по основному идентификатору.
    -- EN: Index by primary identifier.
    if primaryIdentifier then
        sessionsByIdentifier[primaryIdentifier] = session
    end

    return session
end

--- RU:
--- Возвращает активную сессию игрока по source.
---
--- EN:
--- Returns an active player session by source.
---
--- @param playerSource number FiveM server player source
--- @return table|nil session Active session
function GCSessions.Get(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    return sessions[playerSource]
end

--- RU:
--- Возвращает активную сессию по основному идентификатору.
---
--- EN:
--- Returns an active session by primary identifier.
---
--- @param identifier string Primary identifier
--- @return table|nil session Active session
function GCSessions.GetByIdentifier(identifier)
    if type(identifier) ~= 'string' then
        return nil
    end

    return sessionsByIdentifier[identifier]
end

--- RU:
--- Проверяет, используется ли идентификатор в активной или pending сессии.
--- Используется для отклонения дублирующих подключений ещё на стадии playerConnecting.
---
--- EN:
--- Checks whether an identifier is in use by an active or pending session.
--- Used to reject duplicate connections already at the playerConnecting stage.
---
--- @param identifier string Identifier to check
--- @return boolean inUse Whether the identifier is in use
function GCSessions.IsIdentifierInUse(identifier)
    if type(identifier) ~= 'string' then
        return false
    end

    -- RU: Проверяем активные сессии.
    -- EN: Check active sessions.
    if sessionsByIdentifier[identifier] then
        return true
    end

    -- RU: Проверяем pending connection.
    -- EN: Check pending connections.
    if pendingByIdentifier[identifier] then
        return true
    end

    return false
end

--- RU:
--- Проверяет, существует ли активная сессия для игрока.
---
--- EN:
--- Checks whether an active session exists for a player.
---
--- @param playerSource number FiveM server player source
--- @return boolean exists Whether the session exists
function GCSessions.Exists(playerSource)
    if type(playerSource) ~= 'number' then
        return false
    end

    return sessions[playerSource] ~= nil
end

--- RU:
--- Возвращает безопасный публичный DTO сессии.
--- RU: НЕ возвращает внутренние identifiers, spawn decision, security или
--- RU: rate-limit данные. Для identifiers существует отдельный API.
---
--- EN:
--- Returns a safe public session DTO.
--- EN: Does NOT return internal identifiers, spawn decision, security, or
--- EN: rate-limit data. A separate API exists for identifiers.
---
--- @param playerSource number FiveM server player source
--- @return table|nil dto Safe session DTO
function GCSessions.GetPublicDTO(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    local session = sessions[playerSource]

    if not session then
        return nil
    end

    -- RU: Явно перечисляем только безопасные поля.
    -- EN: Explicitly list only safe fields.
    local dto = {
        source = session.source,
        state = session.state,
        playerName = session.playerName,

        connectedAt = session.connectedAt,
        clientReadyAt = session.clientReadyAt,
        spawnedAt = session.spawnedAt,

        lastPed = session.lastPed
    }

    -- RU: Локаль является нечувствительной метаданной.
    -- EN: The locale is non-sensitive metadata.
    if session.metadata and session.metadata.locale then
        dto.locale = session.metadata.locale
    end

    return dto
end

--- RU: Возвращает один захваченный при подключении identifier для внутреннего
--- RU: server-side API. Таблица identifiers наружу не передаётся.
--- EN: Returns one identifier captured at connection time for the internal
--- EN: server-side API. The identifiers table is never exposed.
--- @param playerSource number
--- @param identifierType string
--- @return string|nil identifier
function GCSessions.GetIdentifier(playerSource, identifierType)
    if type(playerSource) ~= 'number' or type(identifierType) ~= 'string' then
        return nil
    end

    local session = sessions[playerSource]

    if not session or type(session.identifiers) ~= 'table' then
        return nil
    end

    local identifier = session.identifiers[identifierType]
    return type(identifier) == 'string' and identifier or nil
end

--- RU:
--- Возвращает полную копию сессии (только для внутреннего использования и тестов).
--- Изменение копии не влияет на настоящую сессию.
--- Этот метод НЕ используется публичным API, чтобы не раскрывать чувствительные данные.
---
--- EN:
--- Returns a full copy of a session (internal use and tests only).
--- Modifying the copy does not affect the real session.
--- This method is NOT used by the public API to avoid exposing sensitive data.
---
--- @param playerSource number FiveM server player source
--- @return table|nil sessionCopy Session copy
function GCSessions.Clone(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    local session = sessions[playerSource]

    if not session then
        return nil
    end

    return GCUtils.DeepCopy(session)
end

--- RU:
--- Удаляет активную сессию игрока.
---
--- EN:
--- Removes an active player session.
---
--- @param playerSource number FiveM server player source
--- @param reason string|nil Reason for removal
--- @return boolean removed Whether the session was removed
function GCSessions.Remove(playerSource, reason)
    if type(playerSource) ~= 'number' then
        return false
    end

    local session = sessions[playerSource]

    if not session then
        return false
    end

    -- RU: Удаляем индекс по идентификатору.
    -- EN: Remove the identifier index.
    if session.primaryIdentifier then
        sessionsByIdentifier[session.primaryIdentifier] = nil
    end

    -- RU: Удаляем сессию.
    -- EN: Remove the session.
    sessions[playerSource] = nil

    return true
end

--- RU:
--- Возвращает количество активных сессий.
---
--- EN:
--- Returns the number of active sessions.
---
--- @return number count Number of sessions
function GCSessions.Count()
    local count = 0

    for _ in pairs(sessions) do
        count = count + 1
    end

    return count
end

--- RU:
--- Возвращает количество pending connection.
---
--- EN:
--- Returns the number of pending connections.
---
--- @return number count Number of pending connections
function GCSessions.PendingCount()
    local count = 0

    for _ in pairs(pendingConnections) do
        count = count + 1
    end

    return count
end

--- RU:
--- Возвращает список активных сессий в виде итератора (для перебора в main.lua).
---
--- EN:
--- Returns a list of active sessions for iteration.
---
--- @return table sessionList Array of sessions
function GCSessions.GetAll()
    local result = {}

    for _, session in pairs(sessions) do
        table.insert(result, session)
    end

    return result
end

--- RU:
--- Возвращает таблицу всех pending connection (по temporary source).
--- Используется периодической очисткой истёкших pending connection.
---
--- EN:
--- Returns a table of all pending connections (by temporary source).
--- Used by the periodic cleanup of expired pending connections.
---
--- @return table pendingTable Map of temporary source -> pending connection
function GCSessions.GetAllPending()
    return pendingConnections
end

--- RU:
--- Очищает все активные сессии.
---
--- EN:
--- Clears all active sessions.
---
--- @return number cleared Number of cleared sessions
function GCSessions.Clear()
    local count = 0

    for playerSource in pairs(sessions) do
        sessions[playerSource] = nil
        count = count + 1
    end

    sessionsByIdentifier = {}

    return count
end

--- RU:
--- Очищает все pending connection.
---
--- EN:
--- Clears all pending connections.
---
--- @return number cleared Number of cleared pending connections
function GCSessions.ClearPending()
    local count = 0

    for temporarySource in pairs(pendingConnections) do
        pendingConnections[temporarySource] = nil
        count = count + 1
    end

    pendingByIdentifier = {}

    return count
end
