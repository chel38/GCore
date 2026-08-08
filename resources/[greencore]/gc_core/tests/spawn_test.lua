-- RU: Тесты спавна GreenCore.
-- EN: GreenCore spawn tests.

-- RU: Локальный helper: создаёт сессию и переводит её в заданное состояние.
-- RU: Используется для установки предусловий тестов.
-- EN: Local helper: creates a session and moves it to the given state.
-- EN: Used to set up test preconditions.
local function setupSession(tempSource, finalSource, state)
    local identifiers = {
        license = 'license:test-spawn-' .. tostring(finalSource)
    }

    local pending, _ = GCSessions.CreatePendingConnection(tempSource, 'TestPlayer' .. tostring(finalSource), identifiers, identifiers.license, 'license')
    local session, _ = GCSessions.PromotePendingConnection(tempSource, finalSource)

    -- RU: Двигаемся по lifecycle до требуемого состояния.
    -- EN: Walk the lifecycle up to the required state.
    GCStates.Set(finalSource, 'validated', 'test')
    GCStates.Set(finalSource, 'joining', 'test')

    if state == 'joining' then
        return session
    end

    GCStates.Set(finalSource, 'client_ready', 'test')

    if state == 'client_ready' then
        return session
    end

    GCStates.Set(finalSource, 'spawn_pending', 'test')

    if state == 'spawn_pending' then
        return session
    end

    GCStates.Set(finalSource, 'spawning', 'test')

    if state == 'spawning' then
        return session
    end

    GCStates.Set(finalSource, 'spawn_confirming', 'test')

    return session
end

-- RU: Тест создания решения о спавне (содержит случайный ped).
-- EN: Test of spawn decision creation (contains a random ped).
GCTest.Register('spawn.create_decision', function()
    setupSession(60020, 20, 'spawn_pending')

    local decision, errorCode = GCSpawn.CreateDecision(20)

    GCTest.ExpectNotNil(decision, 'spawn decision is created')
    GCTest.ExpectNil(errorCode, 'no error on decision creation')
    GCTest.ExpectTrue(decision.id:find('^gc:spawn:') ~= nil, 'decision id has correct prefix')
    GCTest.ExpectEqual(decision.source, 20, 'decision source is correct')
    GCTest.ExpectEqual(decision.confirmed, false, 'decision is not confirmed initially')
    GCTest.ExpectEqual(decision.consumed, false, 'decision is not consumed initially')

    -- RU: Решение содержит ped из белого списка.
    -- EN: The decision contains a ped from the whitelist.
    GCTest.ExpectNotNil(decision.ped, 'decision contains ped')
    GCTest.ExpectNotNil(decision.ped.name, 'decision contains ped name')
    GCTest.ExpectTrue(type(decision.ped.name) == 'string' and #decision.ped.name > 0, 'ped name is a non-empty string')

    GCSpawn.RemovePlayerDecisions(20)
    GCSessions.Remove(20, 'test_cleanup')
end)

-- RU: Тест создания решения без сессии.
-- EN: Test of decision creation without a session.
GCTest.Register('spawn.create_decision_no_session', function()
    local decision, errorCode = GCSpawn.CreateDecision(999)

    GCTest.ExpectNil(decision, 'no decision without a session')
    GCTest.ExpectNotNil(errorCode, 'error code is returned without a session')
end)

-- RU: Тест истечения решения.
-- EN: Test of decision expiration.
GCTest.Register('spawn.decision_expired', function()
    local decision = {
        id = 'gc:spawn:test-expired',
        expiresAt = GCUtils.NowSec() - 10
    }

    GCTest.ExpectTrue(GCSpawn.IsExpired(decision), 'expired decision is detected')
end)

-- RU: Тест неистёкшего решения.
-- EN: Test of a non-expired decision.
GCTest.Register('spawn.decision_not_expired', function()
    local decision = {
        id = 'gc:spawn:test-valid',
        expiresAt = GCUtils.NowSec() + 100
    }

    GCTest.ExpectFalse(GCSpawn.IsExpired(decision), 'valid decision is not expired')
end)

-- RU: Тест подтверждения спавна (атомарный).
-- EN: Test of spawn confirmation (atomic).
GCTest.Register('spawn.confirm', function()
    setupSession(60021, 21, 'client_ready')

    local decision, _ = GCSpawn.Request(21)

    GCTest.ExpectNotNil(decision, 'decision is created for confirmation test')

    local verificationEnabled = GCConfig.Spawn.verification.enabled
    GCConfig.Spawn.verification.enabled = false
    local success, confirmError = GCSpawn.Confirm(21, decision.id)
    GCConfig.Spawn.verification.enabled = verificationEnabled

    GCTest.ExpectTrue(success, 'spawn confirmation succeeds')
    GCTest.ExpectNil(confirmError, 'no error on confirmation')
    GCTest.ExpectTrue(GCStates.Is(21, 'spawned'), 'player is in spawned state after confirmation')

    -- RU: Решение должно быть очищено из сессии после подтверждения.
    -- EN: The decision must be cleared from the session after confirmation.
    local session = GCSessions.Get(21)
    GCTest.ExpectNil(session.spawnDecision, 'spawn decision is cleared after confirmation')

    -- RU: lastPed должен быть установлен.
    -- EN: lastPed must be set.
    GCTest.ExpectNotNil(session.lastPed, 'lastPed is set after confirmation')

    GCSpawn.RemovePlayerDecisions(21)
    GCSessions.Remove(21, 'test_cleanup')
end)

-- RU: Тест повторного подтверждения отклоняется.
-- EN: Test that duplicate confirmation is rejected.
GCTest.Register('spawn.confirm_duplicate', function()
    setupSession(60022, 22, 'client_ready')

    local decision, _ = GCSpawn.Request(22)

    local verificationEnabled = GCConfig.Spawn.verification.enabled
    GCConfig.Spawn.verification.enabled = false
    local success1 = GCSpawn.Confirm(22, decision.id)
    GCConfig.Spawn.verification.enabled = verificationEnabled
    GCTest.ExpectTrue(success1, 'first confirmation succeeds')

    -- RU: Повторное подтверждение должно быть отклонено, т.к. решение потреблено.
    -- EN: Duplicate confirmation must be rejected because the decision is consumed.
    local success2, confirmError2 = GCSpawn.Confirm(22, decision.id)
    GCTest.ExpectFalse(success2, 'duplicate confirmation is rejected')
    GCTest.ExpectNotNil(confirmError2, 'error code is returned for duplicate confirmation')

    GCSpawn.RemovePlayerDecisions(22)
    GCSessions.Remove(22, 'test_cleanup')
end)

-- RU: Тест подтверждения с поддельным Decision ID.
-- EN: Test of confirmation with a fake Decision ID.
GCTest.Register('spawn.confirm_fake_decision', function()
    setupSession(60023, 23, 'client_ready')

    local decision, _ = GCSpawn.Request(23)

    local success, confirmError = GCSpawn.Confirm(23, 'gc:spawn:fake-id')

    GCTest.ExpectFalse(success, 'fake decision id is rejected')
    GCTest.ExpectNotNil(confirmError, 'error code is returned for fake decision')
    GCTest.ExpectFalse(GCStates.Is(23, 'spawned'), 'player is not spawned after fake decision')

    GCSpawn.RemovePlayerDecisions(23)
    GCSessions.Remove(23, 'test_cleanup')
end)

-- RU: Тест истёкшего решения отклоняется.
-- EN: Test that an expired decision is rejected.
GCTest.Register('spawn.confirm_expired', function()
    setupSession(60024, 24, 'client_ready')

    local decision, _ = GCSpawn.Request(24)

    -- RU: Искусственно старим решение.
    -- EN: Artificially age the decision.
    decision.expiresAt = GCUtils.NowSec() - 5

    local success, confirmError = GCSpawn.Confirm(24, decision.id)

    GCTest.ExpectFalse(success, 'expired decision is rejected')
    GCTest.ExpectEqual(confirmError, 'GC-SPAWN-DECISION-EXPIRED-001', 'expired error code is returned')
    GCTest.ExpectFalse(GCStates.Is(24, 'spawned'), 'player is not spawned after expired decision')

    GCSpawn.RemovePlayerDecisions(24)
    GCSessions.Remove(24, 'test_cleanup')
end)

-- RU: Тест: неудачный переход состояния не потребляет решение.
-- RU: Если переход невозможен, решение остаётся активным.
-- EN: Test: a failed state transition does not consume the decision.
-- EN: If the transition is impossible, the decision stays active.
GCTest.Register('spawn.confirm_failed_transition_keeps_decision', function()
    setupSession(60025, 25, 'client_ready')

    -- RU: Создаём решение и сбрасываем состояние обратно в connecting
    -- RU: (из connecting переход в spawned невозможен).
    -- EN: Create a decision and reset the state back to connecting
    -- EN: (from connecting a transition to spawned is impossible).
    local decision, _ = GCSpawn.Request(25)

    -- RU: Принудительно ломаем состояние сессии.
    -- EN: Forcefully break the session state.
    local session = GCSessions.Get(25)
    session.state = 'disconnected'

    local success, confirmError = GCSpawn.Confirm(25, decision.id)

    GCTest.ExpectFalse(success, 'confirmation fails when state transition is invalid')
    GCTest.ExpectNotNil(confirmError, 'error code is returned for failed transition')

    -- RU: Решение должно остаться доступным (не потреблено).
    -- EN: The decision must remain available (not consumed).
    GCTest.ExpectFalse(decision.consumed, 'decision is not consumed after failed transition')

    -- RU: Восстанавливаем состояние для очистки.
    -- EN: Restore the state for cleanup.
    session.state = 'spawn_confirming'

    GCSpawn.RemovePlayerDecisions(25)
    GCSessions.Remove(25, 'test_cleanup')
end)

-- RU: Retry из spawn_confirming не должен выполнять запрещённый self-transition.
-- EN: A retry from spawn_confirming must not attempt a forbidden self-transition.
GCTest.Register('spawn.retry_from_confirming', function()
    setupSession(60026, 26, 'client_ready')

    local decision, _ = GCSpawn.Request(26)
    GCSpawn.HandleSpawnFailure(26, 'GC-SPAWN-PED-TIMEOUT-001')

    local session = GCSessions.Get(26)

    GCTest.ExpectNotNil(decision, 'initial decision exists')
    GCTest.ExpectTrue(GCStates.Is(26, 'spawn_pending'), 'retry returns to spawn_pending')
    GCTest.ExpectEqual(session and session.spawnRetries, 1, 'retry counter is incremented')
    GCTest.ExpectTrue(decision.consumed, 'old decision is invalidated before retry')
    GCTest.ExpectNil(session.spawnDecision, 'old decision is detached from the session')

    local nextDecision, nextError = GCSpawn.Request(26)
    GCTest.ExpectNotNil(nextDecision, 'retry creates a new decision')
    GCTest.ExpectNil(nextError, 'new retry decision has no error')
    GCTest.ExpectFalse(nextDecision.id == decision.id, 'retry decision id is new')
    GCTest.ExpectFalse(nextDecision.ped.name == decision.ped.name, 'failed ped model is not reused')

    GCSpawn.RemovePlayerDecisions(26)
    GCSessions.Remove(26, 'test_cleanup')
end)

GCTest.Register('spawn.server_snapshot_validation', function()
    local decision = {
        source = 27,
        ped = { hash = 1234 },
        position = { x = 10.0, y = 20.0, z = 30.0 }
    }
    local snapshot = {
        exists = true,
        alive = true,
        owner = 27,
        model = 1234,
        position = { x = 11.0, y = 20.0, z = 30.0 }
    }

    local valid = GCSpawn.ValidateSpawnSnapshot(decision, snapshot)
    GCTest.ExpectTrue(valid, 'matching authoritative ped snapshot is accepted')

    snapshot.owner = 99
    valid = GCSpawn.ValidateSpawnSnapshot(decision, snapshot)
    GCTest.ExpectFalse(valid, 'foreign entity ownership is rejected')

    snapshot.owner = 27
    snapshot.position.x = 1000.0
    valid = GCSpawn.ValidateSpawnSnapshot(decision, snapshot)
    GCTest.ExpectFalse(valid, 'out-of-range position is rejected')
end, 'security')
