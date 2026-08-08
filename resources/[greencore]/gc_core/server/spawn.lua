-- RU: Сервис спавна игрока GreenCore.
-- EN: GreenCore player spawn service.

-- RU: Таблица сервиса спавна.
-- EN: Spawn service table.
GCSpawn = {}

-- RU: Внутреннее хранилище решений о спавне.
-- EN: Internal spawn decision storage.
local spawnDecisions = {}

--- RU:
--- Создаёт идентификатор решения о спавне.
---
--- EN:
--- Creates a spawn decision identifier.
---
--- @return string decisionId Spawn decision identifier
local function createSpawnDecisionId()
    return GCUtils.GenerateUuid(GCConstants.spawnPrefix)
end

--- RU:
--- Проверяет корректность конфигурации спавна.
---
--- EN:
--- Validates the spawn configuration.
---
--- @return boolean valid Whether the configuration is valid
local function validateSpawnConfiguration()
    local default = GCConfig.Spawn.default

    if type(default) ~= 'table' then
        return false
    end

    if type(default.x) ~= 'number' then
        return false
    end

    if type(default.y) ~= 'number' then
        return false
    end

    if type(default.z) ~= 'number' then
        return false
    end

    if type(default.heading) ~= 'number' then
        return false
    end

    if type(default.model) ~= 'number' then
        return false
    end

    return true
end

--- RU:
--- Создаёт решение о спавне для игрока.
---
--- EN:
--- Creates a spawn decision for a player.
---
--- @param playerSource number FiveM server player source
--- @return table|nil decision Spawn decision
--- @return string|nil errorCode Error code
function GCSpawn.CreateDecision(playerSource)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что игрок находится в состоянии spawn_pending.
    -- EN: Verify that the player is in the spawn_pending state.
    if not GCStates.Is(playerSource, 'spawn_pending') then
        return nil, 'GC-SPAWN-002'
    end

    -- RU: Проверяем корректность конфигурации спавна.
    -- EN: Validate the spawn configuration.
    if not validateSpawnConfiguration() then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Получаем точку спавна из конфигурации.
    -- EN: Get the spawn point from the configuration.
    local default = GCConfig.Spawn.default

    -- RU: Создаём решение о спавне.
    -- EN: Create the spawn decision.
    local now = GCUtils.NowSec()
    local decision = {
        id = createSpawnDecisionId(),
        sessionId = session.sessionId,
        source = playerSource,

        position = {
            x = default.x,
            y = default.y,
            z = default.z,
            heading = default.heading
        },

        model = default.model,

        createdAt = now,
        expiresAt = now + math.floor(GCConfig.Spawn.decisionLifetimeMs / 1000),

        confirmed = false,
        consumed = false
    }

    -- RU: Сохраняем решение.
    -- EN: Store the decision.
    spawnDecisions[decision.id] = decision

    -- RU: Сохраняем решение в сессии.
    -- EN: Store the decision in the session.
    session.spawnDecision = decision

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseSpawn then
        GCLogger.Debug('GC-SPAWN-100', 'Spawn decision created', {
            source = playerSource,
            decisionId = decision.id
        })
    end

    return decision
end

--- RU:
--- Возвращает решение о спавне по его ID.
---
--- EN:
--- Returns a spawn decision by its ID.
---
--- @param decisionId string Spawn decision ID
--- @return table|nil decision Spawn decision
function GCSpawn.GetDecision(decisionId)
    if type(decisionId) ~= 'string' then
        return nil
    end

    return spawnDecisions[decisionId]
end

--- RU:
--- Проверяет, истекло ли решение о спавне.
---
--- EN:
--- Checks whether a spawn decision has expired.
---
--- @param decision table Spawn decision
--- @return boolean expired Whether the decision has expired
function GCSpawn.IsExpired(decision)
    if type(decision) ~= 'table' then
        return true
    end

    return GCUtils.NowSec() > decision.expiresAt
end

--- RU:
--- Запрашивает спавн игрока.
---
--- EN:
--- Requests a player spawn.
---
--- @param playerSource number FiveM server player source
--- @return table|nil decision Spawn decision
--- @return string|nil errorCode Error code
function GCSpawn.Request(playerSource)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что игрок находится в состоянии client_ready.
    -- EN: Verify that the player is in the client_ready state.
    if not GCStates.Is(playerSource, 'client_ready') then
        return nil, 'GC-SPAWN-002'
    end

    -- RU: Переводим игрока в состояние spawn_pending.
    -- EN: Move the player to the spawn_pending state.
    local success, errorCode = GCStates.Set(playerSource, 'spawn_pending', 'spawn_requested')

    if not success then
        return nil, errorCode
    end

    -- RU: Создаём решение о спавне.
    -- EN: Create the spawn decision.
    local decision, decisionError = GCSpawn.CreateDecision(playerSource)

    if not decision then
        return nil, decisionError
    end

    -- RU: Переводим игрока в состояние spawning.
    -- EN: Move the player to the spawning state.
    local spawnSuccess, spawnError = GCStates.Set(playerSource, 'spawning', 'spawn_approved')

    if not spawnSuccess then
        return nil, spawnError
    end

    -- RU: Отправляем решение клиенту.
    -- EN: Send the decision to the client.
    TriggerClientEvent('gc_core:client:spawnApproved', playerSource, {
        decisionId = decision.id,
        position = decision.position,
        model = decision.model,
        expiresAt = decision.expiresAt
    })

    return decision
end

--- RU:
--- Подтверждает завершение спавна игрока.
---
--- EN:
--- Confirms the completion of a player spawn.
---
--- @param playerSource number FiveM server player source
--- @param decisionId string Spawn decision ID
--- @return boolean success Whether the confirmation succeeded
--- @return string|nil errorCode Error code
function GCSpawn.Confirm(playerSource, decisionId)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return false, 'GC-SPAWN-001'
    end

    if type(decisionId) ~= 'string' then
        return false, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return false, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что игрок находится в состоянии spawning.
    -- EN: Verify that the player is in the spawning state.
    if not GCStates.Is(playerSource, 'spawning') then
        return false, 'GC-SPAWN-002'
    end

    -- RU: Получаем решение о спавне.
    -- EN: Get the spawn decision.
    local decision = GCSpawn.GetDecision(decisionId)

    if not decision then
        return false, 'GC-SPAWN-002'
    end

    -- RU: Проверяем, что решение принадлежит текущей сессии.
    -- EN: Verify that the decision belongs to the current session.
    if decision.sessionId ~= session.sessionId then
        return false, 'GC-SPAWN-002'
    end

    -- RU: Проверяем, что решение не истекло.
    -- EN: Verify that the decision has not expired.
    if GCSpawn.IsExpired(decision) then
        return false, 'GC-SPAWN-003'
    end

    -- RU: Проверяем, что решение не было использовано.
    -- EN: Verify that the decision has not been consumed.
    if decision.consumed then
        return false, 'GC-SPAWN-002'
    end

    -- RU: Проверяем, что подтверждение ещё не было принято.
    -- EN: Verify that the confirmation has not already been accepted.
    if decision.confirmed then
        return false, 'GC-SPAWN-002'
    end

    -- RU: Помечаем решение как подтверждённое и использованное.
    -- EN: Mark the decision as confirmed and consumed.
    decision.confirmed = true
    decision.consumed = true

    -- RU: Переводим игрока в состояние spawned.
    -- EN: Move the player to the spawned state.
    local success, errorCode = GCStates.Set(playerSource, 'spawned', 'spawn_confirmed')

    if not success then
        return false, errorCode
    end

    -- RU: Удаляем решение из хранилища.
    -- EN: Remove the decision from storage.
    spawnDecisions[decisionId] = nil

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseSpawn then
        GCLogger.Debug('GC-SPAWN-101', 'Spawn confirmed', {
            source = playerSource,
            decisionId = decisionId
        })
    end

    return true
end

--- RU:
--- Удаляет все решения о спавне игрока.
---
--- EN:
--- Removes all spawn decisions for a player.
---
--- @param playerSource number FiveM server player source
function GCSpawn.RemovePlayerDecisions(playerSource)
    if type(playerSource) ~= 'number' then
        return
    end

    -- RU: Удаляем решения, принадлежащие игроку.
    -- EN: Remove decisions belonging to the player.
    for decisionId, decision in pairs(spawnDecisions) do
        if decision.source == playerSource then
            spawnDecisions[decisionId] = nil
        end
    end

    -- RU: Очищаем решение в сессии.
    -- EN: Clear the decision in the session.
    local session = GCSessions.Get(playerSource)

    if session then
        session.spawnDecision = nil
    end
end