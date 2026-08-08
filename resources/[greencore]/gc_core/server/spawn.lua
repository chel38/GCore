-- RU: Server-authoritative spawn decisions, verification and bounded retry.
-- EN: Server-authoritative spawn decisions, verification, and bounded retry.

GCSpawn = {}

local spawnDecisions = {}
local decisionTombstones = {}
local DECISION_TOMBSTONE_LIFETIME_SEC = 60

local function isReadyToSpawn(playerSource)
    return GCStates.Is(playerSource, 'client_ready') or GCStates.Is(playerSource, 'spawn_pending')
end

local function invalidateDecision(session, decision, status)
    if not decision then
        return
    end

    decision.consumed = true
    spawnDecisions[decision.id] = nil
    decisionTombstones[decision.id] = {
        source = decision.source,
        sessionId = decision.sessionId,
        status = status or 'consumed',
        expiresAt = GCUtils.NowSec() + DECISION_TOMBSTONE_LIFETIME_SEC
    }

    if session and session.spawnDecision == decision then
        session.spawnDecision = nil
    end
end

local function sendDecision(playerSource, decision)
    TriggerClientEvent(GCEvents.Client.spawnApproved, playerSource, {
        decisionId = decision.id,
        position = GCUtils.DeepCopy(decision.position),
        ped = GCUtils.DeepCopy(decision.ped),
        expiresAt = decision.expiresAt,
        attempt = decision.attempt
    })
end

function GCSpawn.CreateDecision(playerSource)
    if type(playerSource) ~= 'number' or not GCStates.Is(playerSource, 'spawn_pending') then
        return nil, 'GC-SPAWN-DECISION-001'
    end

    local session = GCSessions.Get(playerSource)

    if not session then
        return nil, 'GC-SESSION-001'
    end

    session.attemptedPedModels = session.attemptedPedModels or {}
    session.spawnAttempt = (session.spawnAttempt or 0) + 1

    local pedDefinition = session.nextSpawnPed and GCUtils.DeepCopy(session.nextSpawnPed) or nil
    local pedError = nil
    session.nextSpawnPed = nil

    if not pedDefinition then
        pedDefinition, pedError = GCPedProvider.Resolve(
            playerSource,
            session,
            session.attemptedPedModels
        )
    end

    if not pedDefinition then
        return nil, pedError or 'GC-SPAWN-PED-EXHAUSTED-001'
    end

    local position, positionError = GCSpawnLocationProvider.Resolve(playerSource, session)

    if not position then
        return nil, positionError or 'GC-SPAWN-001'
    end

    local now = GCUtils.NowSec()
    local decision = {
        id = GCIds.NewSpawnDecisionId(),
        sessionId = session.sessionId,
        source = playerSource,
        position = GCUtils.DeepCopy(position),
        ped = { name = pedDefinition.name, hash = pedDefinition.hash },
        attempt = session.spawnAttempt,
        createdAt = now,
        expiresAt = now + math.max(1, math.floor(GCConfig.Spawn.decisionLifetimeMs / 1000)),
        confirming = false,
        confirmed = false,
        consumed = false
    }

    spawnDecisions[decision.id] = decision
    session.spawnDecision = decision
    return decision
end

function GCSpawn.GetDecision(decisionId)
    return type(decisionId) == 'string' and spawnDecisions[decisionId] or nil
end

function GCSpawn.IsExpired(decision)
    return type(decision) ~= 'table'
        or not GCUtils.IsFiniteNumber(decision.expiresAt)
        or GCUtils.NowSec() > decision.expiresAt
end

function GCSpawn.Request(playerSource)
    if type(playerSource) ~= 'number' or not isReadyToSpawn(playerSource) then
        return nil, 'GC-SPAWN-DECISION-001'
    end

    local session = GCSessions.Get(playerSource)

    if not session then
        return nil, 'GC-SESSION-001'
    end

    if GCStates.Is(playerSource, 'client_ready') then
        local pendingOk, pendingError = GCStates.Set(playerSource, 'spawn_pending', 'spawn_requested')

        if not pendingOk then
            return nil, pendingError
        end
    end

    if session.spawnDecision then
        invalidateDecision(session, session.spawnDecision)
    end

    local decision, decisionError = GCSpawn.CreateDecision(playerSource)

    if not decision then
        return nil, decisionError
    end

    local spawningOk, spawningError = GCStates.Set(playerSource, 'spawning', 'spawn_approved')

    if not spawningOk then
        invalidateDecision(session, decision)
        return nil, spawningError
    end

    local confirmingOk, confirmingError = GCStates.Set(
        playerSource,
        'spawn_confirming',
        'client_executing_spawn'
    )

    if not confirmingOk then
        invalidateDecision(session, decision)
        return nil, confirmingError
    end

    -- RU: Сначала фиксируем внутреннее состояние, затем публикуем разрешение.
    -- EN: Commit the internal state before publishing the approval.
    sendDecision(playerSource, decision)

    return decision
end


function GCSpawn.ValidateSpawnSnapshot(decision, snapshot)
    if type(decision) ~= 'table' or type(snapshot) ~= 'table' then
        return false, 'GC-SPAWN-VERIFY-001'
    end

    if not snapshot.exists then
        return false, 'GC-SPAWN-ENTITY-MISSING'
    end

    if not snapshot.alive then
        return false, 'GC-SPAWN-ENTITY-DEAD'
    end

    if snapshot.owner ~= decision.source then
        return false, 'GC-SPAWN-OWNER-MISMATCH'
    end

    if decision.ped.hash ~= nil and snapshot.model ~= decision.ped.hash then
        return false, 'GC-SPAWN-MODEL-MISMATCH'
    end

    local actual = snapshot.position
    local expected = decision.position

    if type(actual) ~= 'table'
        or not GCUtils.IsFiniteNumber(actual.x)
        or not GCUtils.IsFiniteNumber(actual.y)
        or not GCUtils.IsFiniteNumber(actual.z) then
        return false, 'GC-SPAWN-POSITION-MISMATCH'
    end

    local dx = actual.x - expected.x
    local dy = actual.y - expected.y
    local dz = actual.z - expected.z
    local tolerance = GCConfig.Spawn.verification.positionTolerance or 8.0

    if dx * dx + dy * dy + dz * dz > tolerance * tolerance then
        return false, 'GC-SPAWN-POSITION-MISMATCH'
    end

    return true
end

local function verifyPlayerSpawn(playerSource, session, decision)
    local config = GCConfig.Spawn.verification or {}

    if config.enabled == false then
        return true
    end

    local startedAt = GCUtils.NowMs()
    local timeoutMs = math.max(0, config.timeoutMs or 3000)
    local intervalMs = math.max(1, config.intervalMs or 100)
    local maxAttempts = math.max(1, config.maxAttempts or 31)
    local lastError = 'GC-SPAWN-VERIFY-001'
    local attempt = 0

    repeat
        attempt = attempt + 1
        session.spawnVerificationAttempts = attempt
        local currentSession = GCSessions.Get(playerSource)

        if not currentSession then
            return false, 'GC-SESSION-001'
        end

        if currentSession ~= session
            or currentSession.sessionId ~= decision.sessionId
            or currentSession.spawnDecision ~= decision
            or not GCStates.Is(playerSource, 'spawn_confirming') then
            return false, 'GC-SPAWN-SESSION-CHANGED'
        end

        if GCServerRuntime.running == false or GCSecurity.IsResourceStopping() then
            return false, 'GC-SPAWN-SESSION-CHANGED'
        end

        if GCSpawn.IsExpired(decision) then
            return false, 'GC-SPAWN-DECISION-EXPIRED-001'
        end

        local snapshot = GCPlayers.GetEntitySnapshot(playerSource)
        local valid, verifyError = GCSpawn.ValidateSpawnSnapshot(decision, snapshot)

        -- RU: Natives/test boundary могли yield или изменить runtime state. Перед
        -- RU: commit повторно проверяем ту же session/decision transaction.
        -- EN: The native/test boundary may yield or change runtime state. Re-check
        -- EN: the same session/decision transaction before committing.
        local sessionAfterSnapshot = GCSessions.Get(playerSource)

        if not sessionAfterSnapshot then
            return false, 'GC-SESSION-001'
        end

        if sessionAfterSnapshot ~= session
            or sessionAfterSnapshot.sessionId ~= decision.sessionId
            or sessionAfterSnapshot.spawnDecision ~= decision
            or not GCStates.Is(playerSource, 'spawn_confirming') then
            return false, 'GC-SPAWN-SESSION-CHANGED'
        end

        if GCSpawn.IsExpired(decision) then
            return false, 'GC-SPAWN-DECISION-EXPIRED-001'
        end

        if valid then
            return true
        end

        lastError = verifyError or lastError

        if GCSpawnRetryPolicy.IsTerminalVerificationError(lastError) then
            return false, lastError
        end

        if attempt >= maxAttempts then
            return false, lastError
        end

        if GCUtils.NowMs() - startedAt >= timeoutMs then
            return false, 'GC-SPAWN-VERIFY-TIMEOUT'
        end

        Wait(intervalMs)
    until false

    return false, lastError
end

function GCSpawn.Confirm(playerSource, decisionId)
    if type(playerSource) ~= 'number' or type(decisionId) ~= 'string' then
        return false, 'GC-SPAWN-DECISION-UNKNOWN', false
    end

    local session = GCSessions.Get(playerSource)
    local decision = GCSpawn.GetDecision(decisionId)

    if not decision then
        local tombstone = decisionTombstones[decisionId]

        if not tombstone then
            return false, 'GC-SPAWN-DECISION-UNKNOWN', false
        end

        if tombstone.source ~= playerSource then
            return false, 'GC-SPAWN-DECISION-SOURCE-MISMATCH', false
        end

        if tombstone.status == 'expired' then
            return false, 'GC-SPAWN-DECISION-EXPIRED-001', false
        end

        return false, 'GC-SPAWN-DECISION-CONSUMED-001', false
    end

    if decision.source ~= playerSource then
        return false, 'GC-SPAWN-DECISION-SOURCE-MISMATCH', false
    end

    if not session then
        return false, 'GC-SESSION-001', false
    end

    if decision.sessionId ~= session.sessionId then
        return false, 'GC-SPAWN-DECISION-SESSION-MISMATCH', false
    end

    if decision.consumed or decision.confirmed or decision.confirming
        or session.spawnDecision ~= decision then
        return false, 'GC-SPAWN-DECISION-CONSUMED-001', false
    end

    if not GCStates.Is(playerSource, 'spawn_confirming') then
        return false, 'GC-SPAWN-STATE-001', false
    end

    if GCSpawn.IsExpired(decision) then
        invalidateDecision(session, decision, 'expired')
        GCStates.Set(playerSource, 'error', 'spawn_decision_expired')
        return false, 'GC-SPAWN-DECISION-EXPIRED-001', false
    end

    decision.confirming = true
    local verified, verifyError = verifyPlayerSpawn(playerSource, session, decision)

    if not verified then
        decision.confirming = false

        if verifyError == 'GC-SPAWN-DECISION-EXPIRED-001' then
            invalidateDecision(session, decision, 'expired')
            GCStates.Set(playerSource, 'error', 'spawn_decision_expired_during_verification')
            return false, verifyError, false
        end

        local retrying = GCSpawn.HandleSpawnFailure(playerSource, verifyError)
        return false, verifyError, retrying
    end

    local stateOk, stateError = GCStates.Set(playerSource, 'spawned', 'spawn_verified')

    if not stateOk then
        decision.confirming = false
        return false, stateError or 'GC-SPAWN-STATE-001', false
    end

    decision.confirmed = true
    session.spawnRetries = 0
    session.spawnSamePedRetries = 0
    session.spawnDifferentPedRetries = 0
    session.spawnVerificationAttempts = 0
    session.lastPed = decision.ped.name
    session.attemptedPedModels = {}
    session.spawnAttempt = 0
    invalidateDecision(session, decision)

    TriggerClientEvent(GCEvents.Client.spawnConfirmed, playerSource, {
        decisionId = decisionId,
        state = 'spawned'
    })

    return true
end

function GCSpawn.HandleSpawnFailure(playerSource, errorCode)
    if type(playerSource) ~= 'number' then
        return false
    end

    local session = GCSessions.Get(playerSource)

    if not session or (not GCStates.Is(playerSource, 'spawn_confirming')
        and not GCStates.Is(playerSource, 'spawning')) then
        return false
    end

    local retryConfig = GCConfig.Spawn.retry or {}
    local decision = session.spawnDecision
    local policy = GCSpawnRetryPolicy.Resolve(errorCode)
    local action = policy.action

    if action == GCSpawnRetryPolicy.Actions.NEW_PED
        and decision and decision.ped and decision.ped.name then
        session.attemptedPedModels = session.attemptedPedModels or {}
        session.attemptedPedModels[decision.ped.name] = true
        session.spawnDifferentPedRetries = (session.spawnDifferentPedRetries or 0) + 1
    elseif action == GCSpawnRetryPolicy.Actions.SAME_PED
        and decision and decision.ped then
        session.nextSpawnPed = GCUtils.DeepCopy(decision.ped)
        session.spawnSamePedRetries = (session.spawnSamePedRetries or 0) + 1
    end

    invalidateDecision(session, decision)
    session.spawnRetries = (session.spawnRetries or 0) + 1

    GCLogger.Warn(errorCode or 'GC-SPAWN-001', '[GC][SPAWN] Failure classified by retry policy', {
        source = playerSource,
        category = policy.category,
        action = action,
        attempt = session.spawnAttempt
    })

    if not retryConfig.enabled or action == GCSpawnRetryPolicy.Actions.REJECT then
        GCStates.Set(playerSource, 'error', 'spawn_failure_rejected_by_policy')
        return false
    end

    local totalLimit = math.max(1, retryConfig.maxTotalAttempts or 4)
    local samePedLimit = math.max(0, retryConfig.maxSamePedRetries or 1)
    local differentPedLimit = math.max(0, retryConfig.maxDifferentPedRetries or 2)

    if (session.spawnAttempt or 1) >= totalLimit
        or (session.spawnSamePedRetries or 0) > samePedLimit
        or (session.spawnDifferentPedRetries or 0) > differentPedLimit then
        session.nextSpawnPed = nil
        GCStates.Set(playerSource, 'error', 'spawn_failed_max_retries')
        return false
    end

    local pendingOk = GCStates.Set(playerSource, 'spawn_pending', 'spawn_retry_policy_' .. action:lower())

    if not pendingOk then
        GCStates.Set(playerSource, 'error', 'spawn_retry_state_failed')
        return false
    end

    local sessionId = session.sessionId

    SetTimeout(retryConfig.delayMs or 1000, function()
        local currentSession = GCSessions.Get(playerSource)

        if GCServerRuntime.running == false
            or not currentSession
            or currentSession.sessionId ~= sessionId
            or not GCStates.Is(playerSource, 'spawn_pending') then
            return
        end

        local nextDecision, requestError = GCSpawn.Request(playerSource)

        if not nextDecision then
            GCStates.Set(playerSource, 'error', 'spawn_retry_failed')
            TriggerClientEvent(GCEvents.Client.spawnRejected, playerSource, {
                errorCode = requestError or errorCode or 'GC-SPAWN-001',
                retryable = false
            })
        end
    end)

    return true
end

function GCSpawn.CleanupExpiredDecisions()
    local removedCount = 0

    for _, decision in pairs(GCUtils.ShallowCopy(spawnDecisions)) do
        if GCSpawn.IsExpired(decision) then
            local session = GCSessions.Get(decision.source)
            invalidateDecision(session, decision, 'expired')
            removedCount = removedCount + 1

            if session and GCStates.Is(decision.source, 'spawn_confirming') then
                GCStates.Set(decision.source, 'error', 'spawn_decision_expired')
            end
        end
    end


    for decisionId, tombstone in pairs(GCUtils.ShallowCopy(decisionTombstones)) do
        if GCUtils.NowSec() > tombstone.expiresAt then
            decisionTombstones[decisionId] = nil
        end
    end

    return removedCount
end

function GCSpawn.RemovePlayerDecisions(playerSource)
    if type(playerSource) ~= 'number' then
        return
    end

    local session = GCSessions.Get(playerSource)

    for _, decision in pairs(GCUtils.ShallowCopy(spawnDecisions)) do
        if decision.source == playerSource then
            invalidateDecision(session, decision)
        end
    end


    for decisionId, tombstone in pairs(GCUtils.ShallowCopy(decisionTombstones)) do
        if tombstone.source == playerSource then
            decisionTombstones[decisionId] = nil
        end
    end
end

function GCSpawn.RemoveAllDecisions()
    for decisionId in pairs(spawnDecisions) do
        spawnDecisions[decisionId] = nil
    end

    decisionTombstones = {}

    for _, session in pairs(GCSessions.GetAll()) do
        session.spawnDecision = nil
    end
end
