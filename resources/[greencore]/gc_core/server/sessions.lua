-- RU: Сервис сессий игрока GreenCore.
-- EN: GreenCore player session service.

-- RU: Таблица сервиса сессий.
-- EN: Session service table.
GCSessions = {}

-- RU: Внутреннее хранилище сессий. Недоступно сторонним ресурсам.
-- EN: Internal session storage. Not accessible to third-party resources.
local sessions = {}

-- RU: Индекс сессий по основному идентификатору.
-- EN: Session index by primary identifier.
local sessionsByIdentifier = {}

--- RU:
--- Создаёт новую временную сессию подключившегося игрока.
--- Данные хранятся только в оперативной памяти сервера.
---
--- EN:
--- Creates a new temporary session for the connected player.
--- The data is stored only in the server memory.
---
--- @param playerSource number FiveM server player source
--- @param playerName string Player display name
--- @param identifiers table Player identifiers
--- @return table|nil session Created session
--- @return string|nil errorCode Error code
function GCSessions.Create(playerSource, playerName, identifiers)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SESSION-002'
    end

    if type(playerName) ~= 'string' then
        return nil, 'GC-SESSION-002'
    end

    if type(identifiers) ~= 'table' then
        return nil, 'GC-SESSION-002'
    end

    -- RU: Проверяем, что сессия для этого source ещё не существует.
    -- EN: Verify that a session for this source does not already exist.
    if sessions[playerSource] then
        return nil, 'GC-SESSION-002'
    end

    -- RU: Получаем основной идентификатор.
    -- EN: Get the primary identifier.
    local primaryIdentifier = identifiers[GCConstants.primaryIdentifierType]
    local primaryType = GCConstants.primaryIdentifierType

    if not primaryIdentifier and GCConfig.Connection.allowLicense2Fallback then
        primaryIdentifier = identifiers[GCConstants.fallbackIdentifierType]
        primaryType = GCConstants.fallbackIdentifierType
    end

    -- RU: Генерируем уникальный Session ID.
    -- EN: Generate a unique Session ID.
    local sessionId = GCUtils.GenerateUuid(GCConstants.sessionPrefix)

    -- RU: Создаём структуру сессии.
    -- EN: Create the session structure.
    local session = {
        sessionId = sessionId,
        source = playerSource,
        playerName = playerName,

        identifiers = GCUtils.DeepCopy(identifiers),

        primaryIdentifierType = primaryType,
        primaryIdentifier = primaryIdentifier,

        state = 'connecting',
        previousState = nil,
        stateReason = 'player_connecting',

        connectedAt = GCUtils.NowSec(),
        validatedAt = nil,
        clientReadyAt = nil,
        spawnedAt = nil,
        disconnectedAt = nil,

        spawnDecision = nil,

        metadata = {
            locale = GCConfig.General.locale,
            clientVersion = nil,
            protocolVersion = nil
        }
    }

    -- RU: Сохраняем сессию.
    -- EN: Store the session.
    sessions[playerSource] = session

    -- RU: Индексируем по основному идентификатору.
    -- EN: Index by primary identifier.
    if primaryIdentifier then
        sessionsByIdentifier[primaryIdentifier] = session
    end

    return session
end

--- RU:
--- Возвращает сессию игрока по source.
---
--- EN:
--- Returns a player session by source.
---
--- @param playerSource number FiveM server player source
--- @return table|nil session Session
function GCSessions.Get(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    return sessions[playerSource]
end

--- RU:
--- Возвращает сессию по основному идентификатору.
---
--- EN:
--- Returns a session by primary identifier.
---
--- @param identifier string Primary identifier
--- @return table|nil session Session
function GCSessions.GetByIdentifier(identifier)
    if type(identifier) ~= 'string' then
        return nil
    end

    return sessionsByIdentifier[identifier]
end

--- RU:
--- Проверяет, существует ли сессия для игрока.
---
--- EN:
--- Checks whether a session exists for a player.
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
--- Возвращает безопасную копию сессии игрока.
--- Изменение копии не влияет на настоящую сессию.
---
--- EN:
--- Returns a safe copy of a player session.
--- Modifying the copy does not affect the real session.
---
--- @param playerSource number FiveM server player source
--- @return table|nil sessionCopy Safe session copy
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
--- Удаляет сессию игрока.
---
--- EN:
--- Removes a player session.
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
--- Очищает все сессии.
---
--- EN:
--- Clears all sessions.
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