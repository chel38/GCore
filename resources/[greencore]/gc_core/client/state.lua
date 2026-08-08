-- RU: Клиентский сервис состояния GreenCore.
-- EN: GreenCore client state service.

-- RU: Таблица клиентского сервиса состояния.
-- EN: Client state service table.
GCClientState = {}

-- RU: Внутреннее состояние клиента.
-- EN: Internal client state.
local clientState = {
    -- RU: Готов ли клиент сообщить о готовности.
    -- EN: Whether the client is ready to report readiness.
    ready = false,

    -- RU: Получено ли подтверждение подключения от сервера.
    -- EN: Whether the connection acceptance was received from the server.
    connectionAccepted = false,

    -- RU: Получено ли решение о спавне.
    -- EN: Whether a spawn decision was received.
    spawnDecisionReceived = false,

    -- RU: Выполняется ли спавн.
    -- EN: Whether a spawn is in progress.
    spawning = false,

    -- RU: Завершён ли спавн.
    -- EN: Whether the spawn is complete.
    spawned = false
}

--- RU:
--- Устанавливает флаг готовности клиента.
---
--- EN:
--- Sets the client readiness flag.
---
--- @param value boolean Readiness value
function GCClientState.SetReady(value)
    clientState.ready = value == true
end

--- RU:
--- Проверяет, готов ли клиент.
---
--- EN:
--- Checks whether the client is ready.
---
--- @return boolean ready Whether the client is ready
function GCClientState.IsReady()
    return clientState.ready
end

--- RU:
--- Устанавливает флаг подтверждения подключения.
---
--- EN:
--- Sets the connection acceptance flag.
---
--- @param value boolean Acceptance value
function GCClientState.SetConnectionAccepted(value)
    clientState.connectionAccepted = value == true
end

--- RU:
--- Проверяет, получено ли подтверждение подключения.
---
--- EN:
--- Checks whether the connection acceptance was received.
---
--- @return boolean accepted Whether the connection was accepted
function GCClientState.IsConnectionAccepted()
    return clientState.connectionAccepted
end

--- RU:
--- Устанавливает флаг получения решения о спавне.
---
--- EN:
--- Sets the spawn decision received flag.
---
--- @param value boolean Received value
function GCClientState.SetSpawnDecisionReceived(value)
    clientState.spawnDecisionReceived = value == true
end

--- RU:
--- Проверяет, получено ли решение о спавне.
---
--- EN:
--- Checks whether a spawn decision was received.
---
--- @return boolean received Whether the decision was received
function GCClientState.IsSpawnDecisionReceived()
    return clientState.spawnDecisionReceived
end

--- RU:
--- Устанавливает флаг выполнения спавна.
---
--- EN:
--- Sets the spawning flag.
---
--- @param value boolean Spawning value
function GCClientState.SetSpawning(value)
    clientState.spawning = value == true
end

--- RU:
--- Проверяет, выполняется ли спавн.
---
--- EN:
--- Checks whether a spawn is in progress.
---
--- @return boolean spawning Whether a spawn is in progress
function GCClientState.IsSpawning()
    return clientState.spawning
end

--- RU:
--- Устанавливает флаг завершения спавна.
---
--- EN:
--- Sets the spawned flag.
---
--- @param value boolean Spawned value
function GCClientState.SetSpawned(value)
    clientState.spawned = value == true
end

--- RU:
--- Проверяет, завершён ли спавн.
---
--- EN:
--- Checks whether the spawn is complete.
---
--- @return boolean spawned Whether the spawn is complete
function GCClientState.IsSpawned()
    return clientState.spawned
end

--- RU:
--- Сбрасывает клиентское состояние.
---
--- EN:
--- Resets the client state.
function GCClientState.Reset()
    clientState.ready = false
    clientState.connectionAccepted = false
    clientState.spawnDecisionReceived = false
    clientState.spawning = false
    clientState.spawned = false
end