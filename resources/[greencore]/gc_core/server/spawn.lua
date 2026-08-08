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
--- Проверяет, что игрок готов к созданию решения о спавне.
--- Разрешены входные состояния client_ready (обычный поток) и spawn_pending
--- (восстановленный после рестарта поток).
---
--- EN:
--- Checks that the player is ready to create a spawn decision.
--- Allowed entry states are client_ready (normal flow) and spawn_pending
--- (flow recovered after a restart).
---
--- @param playerSource number FiveM server player source
--- @return boolean ready Whether the player is ready
local function isReadyToSpawn(playerSource)
    return GCStates.Is(playerSource, 'client_ready')
        or GCStates.Is(playerSource, 'spawn_pending')
end

--- RU:
--- Создаёт решение о спавне для игрока.
--- Модель педа выбирает СЕРВЕР через GCPedProvider, точку — через
--- GCSpawnLocationProvider. Решение неизменно после создания.
---
--- EN:
--- Creates a spawn decision for a player.
--- The ped model is chosen by the SERVER via GCPedProvider, and the location via
--- GCSpawnLocationProvider. The decision is immutable after creation.
---
--- @param playerSource number FiveM server player source
--- @return table|nil decision Spawn decision
--- @return string|nil errorCode Error code
function GCSpawn.CreateDecision(playerSource)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SPAWN-DECISION-001'
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
        return nil, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Разрешаем модель педа через провайдер (сервер выбирает).
    -- EN: Resolve the ped model through the provider (the server chooses).
    local pedDefinition, pedError = GCPedProvider.Resolve(playerSource, session)

    if not pedDefinition then
        -- RU: Если пед не выбран, используем fallback ped.
        -- EN: If no ped was resolved, use the fallback ped.
        pedDefinition = GCPedProvider.ResolveFallback()
    end

    -- RU: Разрешаем точку спавна через провайдер.
    -- EN: Resolve the spawn location through the provider.
    local position, positionError = GCSpawnLocationProvider.Resolve(playerSource, session)

    if not position then
        return nil, positionError or 'GC-SPAWN-001'
    end

    -- RU: Создаём решение о спавне.
    -- EN: Create the spawn decision.
    local now = GCUtils.NowSec()
    local decision = {
        id = createSpawnDecisionId(),
        sessionId = session.sessionId,
        source = playerSource,

        position = position,

        -- RU: Модель педа передаётся клиенту как имя и (если доступен) hash.
        -- EN: The ped model is sent to the client as a name and (if available) a hash.
        ped = {
            name = pedDefinition.name,
            hash = pedDefinition.hash
        },

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
            decisionId = decision.id,
            ped = decision.ped.name
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

    if type(decision.expiresAt) ~= 'number' then
        return true
    end

    return GCUtils.NowSec() > decision.expiresAt
end

--- RU:
--- Запрашивает спавн игрока.
--- Обычный поток: client_ready -> spawn_pending -> spawning -> spawn_confirming.
--- Восстановленный поток: spawn_pending (уже установлен) -> spawning -> spawn_confirming.
---
--- EN:
--- Requests a player spawn.
--- Normal flow: client_ready -> spawn_pending -> spawning -> spawn_confirming.
--- Recovered flow: spawn_pending (already set) -> spawning -> spawn_confirming.
---
--- @param playerSource number FiveM server player source
--- @return table|nil decision Spawn decision
--- @return string|nil errorCode Error code
function GCSpawn.Request(playerSource)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Проверяем готовность к спавну.
    -- EN: Verify readiness to spawn.
    if not isReadyToSpawn(playerSource) then
        return nil, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Если игрок ещё в client_ready, переводим в spawn_pending.
    -- EN: If the player is still in client_ready, move to spawn_pending.
    if GCStates.Is(playerSource, 'client_ready') then
        local success, errorCode = GCStates.Set(playerSource, 'spawn_pending', 'spawn_requested')

        if not success then
            return nil, errorCode
        end
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
        ped = decision.ped,
        expiresAt = decision.expiresAt
    })

    -- RU: Переводим игрока в состояние spawn_confirming (клиент выполняет спавн).
    -- EN: Move the player to the spawn_confirming state (the client is performing the spawn).
    local confirmStateSuccess, confirmStateError = GCStates.Set(playerSource, 'spawn_confirming', 'client_executing_spawn')

    if not confirmStateSuccess then
        GCLogger.Warn('GC-SPAWN-001', 'Failed to set spawn_confirming state', {
            source = playerSource,
            errorCode = confirmStateError
        })
    end

    return decision
end

--- RU:
--- Подтверждает завершение спавна игрока.
--- АТОМАРНАЯ операция: сначала валидация, затем переход состояния, и только
--- после успешного перехода решение помечается confirmed/consumed и удаляется.
--- Если переход состояния не удался, решение остаётся активным для retry/timeout.
---
--- EN:
--- Confirms the completion of a player spawn.
--- ATOMIC operation: first validation, then the state transition, and only after
--- a successful transition is the decision marked confirmed/consumed and removed.
--- If the state transition fails, the decision stays active for retry/timeout.
---
--- @param playerSource number FiveM server player source
--- @param decisionId string Spawn decision ID
--- @return boolean success Whether the confirmation succeeded
--- @return string|nil errorCode Error code
function GCSpawn.Confirm(playerSource, decisionId)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return false, 'GC-SPAWN-DECISION-001'
    end

    if type(decisionId) ~= 'string' then
        return false, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return false, 'GC-SPAWN-001'
    end

    -- RU: Проверяем, что игрок находится в состоянии spawn_confirming.
    -- EN: Verify that the player is in the spawn_confirming state.
    if not GCStates.Is(playerSource, 'spawn_confirming') then
        return false, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Получаем решение о спавне.
    -- EN: Get the spawn decision.
    local decision = GCSpawn.GetDecision(decisionId)

    if not decision then
        return false, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Проверяем, что решение принадлежит текущему source.
    -- EN: Verify that the decision belongs to the current source.
    if decision.source ~= playerSource then
        return false, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Проверяем, что решение принадлежит текущей сессии.
    -- EN: Verify that the decision belongs to the current session.
    if decision.sessionId ~= session.sessionId then
        return false, 'GC-SPAWN-DECISION-001'
    end

    -- RU: Проверяем, что решение не истекло.
    -- EN: Verify that the decision has not expired.
    if GCSpawn.IsExpired(decision) then
        spawnDecisions[decisionId] = nil

        if session.spawnDecision == decision then
            session.spawnDecision = nil
        end

        GCStates.Set(playerSource, 'error', 'spawn_decision_expired')
        return false, 'GC-SPAWN-DECISION-EXPIRED-001'
    end

    -- RU: Проверяем, что решение не было использовано.
    -- EN: Verify that the decision has not been consumed.
    if decision.consumed then
        return false, 'GC-SPAWN-DECISION-CONSUMED-001'
    end

    -- RU: Проверяем, что подтверждение ещё не было принято.
    -- EN: Verify that the confirmation has not already been accepted.
    if decision.confirmed then
        return false, 'GC-SPAWN-DECISION-CONSUMED-001'
    end

    -- RU: ШАГ "STATE TRANSITION": переводим игрока в spawned.
    -- RU: Только после успешного перехода решение будет потреблено.
    -- EN: "STATE TRANSITION" step: move the player to spawned.
    -- EN: Only after a successful transition will the decision be consumed.
    local success, errorCode = GCStates.Set(playerSource, 'spawned', 'spawn_confirmed')

    if not success then
        -- RU: Решение остаётся активным; вызывающий решит (retry/timeout).
        -- EN: The decision stays active; the caller decides (retry/timeout).
        return false, errorCode or 'GC-SPAWN-DECISION-001'
    end

    -- RU: Помечаем решение как подтверждённое и использованное.
    -- EN: Mark the decision as confirmed and consumed.
    decision.confirmed = true
    decision.consumed = true
    session.spawnRetries = 0

    -- RU: Сохраняем выбранную модель педа в сессии (для avoidImmediateRepeat).
    -- EN: Save the chosen ped model in the session (for avoidImmediateRepeat).
    session.lastPed = decision.ped.name

    -- RU: Удаляем решение из хранилища.
    -- EN: Remove the decision from storage.
    spawnDecisions[decisionId] = nil

    -- RU: Очищаем решение в сессии.
    -- EN: Clear the decision in the session.
    session.spawnDecision = nil

    -- RU: Отправляем клиенту подтверждение спавна (SERVER = source of truth).
    -- EN: Send the spawn confirmation to the client (SERVER = source of truth).
    TriggerClientEvent('gc_core:client:spawnConfirmed', playerSource, {
        decisionId = decisionId,
        state = 'spawned'
    })

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseSpawn then
        GCLogger.Debug('GC-SPAWN-101', 'Spawn confirmed', {
            source = playerSource,
            decisionId = decisionId,
            ped = session.lastPed
        })
    end

    return true
end

--- RU:
--- Обрабатывает неудачный спавн (клиент сообщил ошибку).
--- Повторная попытка выполняется ТОЛЬКО по решению сервера и ограничена.
--- После исчерпания попыток игрок переводится в состояние error.
---
--- EN:
--- Handles a failed spawn (the client reported an error).
--- A retry is executed ONLY on server decision and is limited.
--- After the attempts are exhausted the player moves to the error state.
---
--- @param playerSource number FiveM server player source
--- @param errorCode string Client-reported error code
function GCSpawn.HandleSpawnFailure(playerSource, errorCode)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return
    end

    local session = GCSessions.Get(playerSource)

    if not session then
        return
    end

    -- RU: Проверяем, что игрок в состоянии spawn_confirming или spawning.
    -- EN: Verify that the player is in spawn_confirming or spawning.
    if not GCStates.Is(playerSource, 'spawn_confirming')
        and not GCStates.Is(playerSource, 'spawning') then
        return
    end

    -- RU: Проверяем настройки retry.
    -- EN: Check the retry settings.
    local retryConfig = GCConfig.Spawn.retry

    if type(retryConfig) ~= 'table' or not retryConfig.enabled then
        -- RU: Retry отключён — переводим в error.
        -- EN: Retry disabled — move to error.
        GCStates.Set(playerSource, 'error', 'spawn_failed')
        return
    end

    -- RU: Считаем количество попыток.
    -- EN: Count the number of attempts.
    session.spawnRetries = (session.spawnRetries or 0) + 1

    -- RU: Если попытки не исчерпаны, повторяем с тем же решением (тот же ped).
    -- EN: If attempts remain, retry with the same decision (same ped).
    if session.spawnRetries < (retryConfig.maxAttempts or 2) then
        local decision = session.spawnDecision

        if decision then
            if GCSpawn.IsExpired(decision) then
                spawnDecisions[decision.id] = nil
                session.spawnDecision = nil
                GCStates.Set(playerSource, 'error', 'spawn_retry_decision_expired')
                return
            end

            -- RU: Возвращаемся в spawn_confirming и повторно отправляем решение.
            -- EN: Return to spawn_confirming and resend the decision.
            local currentState = GCStates.Get(playerSource)
            local success = currentState == 'spawn_confirming'

            if currentState == 'spawning' then
                success = GCStates.Set(playerSource, 'spawn_confirming', 'spawn_retry')
            end

            if success then
                local sessionId = session.sessionId

                SetTimeout(retryConfig.delayMs or 1000, function()
                    local currentSession = GCSessions.Get(playerSource)

                    if currentSession
                        and currentSession.sessionId == sessionId
                        and currentSession.spawnDecision == decision
                        and not GCSpawn.IsExpired(decision) then
                        TriggerClientEvent('gc_core:client:spawnApproved', playerSource, {
                            decisionId = decision.id,
                            position = decision.position,
                            ped = decision.ped,
                            expiresAt = decision.expiresAt
                        })
                    end
                end)
                return
            end
        end
    end

    -- RU: Попытки исчерпаны или решение отсутствует — переводим в error.
    -- EN: Attempts exhausted or no decision — move to error.
    GCStates.Set(playerSource, 'error', 'spawn_failed_max_retries')
end

--- RU:
--- Удаляет истёкшие spawn decision и переводит зависшие сессии в error.
---
--- EN:
--- Removes expired spawn decisions and moves stuck sessions to error.
---
--- @return number removedCount Number of removed decisions
function GCSpawn.CleanupExpiredDecisions()
    local removedCount = 0

    for decisionId, decision in pairs(spawnDecisions) do
        if GCSpawn.IsExpired(decision) then
            spawnDecisions[decisionId] = nil
            removedCount = removedCount + 1

            local session = GCSessions.Get(decision.source)

            if session and session.spawnDecision == decision then
                session.spawnDecision = nil

                if GCStates.Is(decision.source, 'spawn_pending')
                    or GCStates.Is(decision.source, 'spawning')
                    or GCStates.Is(decision.source, 'spawn_confirming') then
                    GCStates.Set(decision.source, 'error', 'spawn_decision_expired')
                end
            end
        end
    end

    return removedCount
end

--- RU:
--- Удаляет все решения о спавне игрока.
--- Используется при отключении игрока.
---
--- EN:
--- Removes all spawn decisions for a player.
--- Used when a player disconnects.
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
