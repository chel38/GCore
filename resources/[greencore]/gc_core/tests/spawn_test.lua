-- RU: Тесты спавна GreenCore.
-- EN: GreenCore spawn tests.

-- RU: Тест создания решения о спавне.
-- EN: Test of spawn decision creation.
GCTest.Register('spawn.create_decision', function()
    -- RU: Создаём сессию и переводим в spawn_pending.
    -- EN: Create a session and move to spawn_pending.
    local identifiers = {
        license = 'license:test-spawn-1'
    }

    GCSessions.Create(20, 'TestPlayer20', identifiers)
    GCStates.Set(20, 'validated', 'test')
    GCStates.Set(20, 'joining', 'test')
    GCStates.Set(20, 'client_ready', 'test')
    GCStates.Set(20, 'spawn_pending', 'test')

    local decision, errorCode = GCSpawn.CreateDecision(20)

    GCTest.ExpectNotNil(decision, 'spawn decision is created')
    GCTest.ExpectNil(errorCode, 'no error on decision creation')
    GCTest.ExpectTrue(decision.id:find('^gc:spawn:'), 'decision id has correct prefix')
    GCTest.ExpectEqual(decision.source, 20, 'decision source is correct')
    GCTest.ExpectEqual(decision.confirmed, false, 'decision is not confirmed initially')
    GCTest.ExpectEqual(decision.consumed, false, 'decision is not consumed initially')

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

-- RU: Тест подтверждения спавна.
-- EN: Test of spawn confirmation.
GCTest.Register('spawn.confirm', function()
    -- RU: Создаём сессию и переводим в spawn_pending.
    -- EN: Create a session and move to spawn_pending.
    local identifiers = {
        license = 'license:test-spawn-2'
    }

    GCSessions.Create(21, 'TestPlayer21', identifiers)
    GCStates.Set(21, 'validated', 'test')
    GCStates.Set(21, 'joining', 'test')
    GCStates.Set(21, 'client_ready', 'test')
    GCStates.Set(21, 'spawn_pending', 'test')

    local decision, errorCode = GCSpawn.CreateDecision(21)

    GCTest.ExpectNotNil(decision, 'decision is created for confirmation test')

    -- RU: Переводим в spawning перед подтверждением.
    -- EN: Move to spawning before confirming.
    GCStates.Set(21, 'spawning', 'test')

    local success, confirmError = GCSpawn.Confirm(21, decision.id)

    GCTest.ExpectTrue(success, 'spawn confirmation succeeds')
    GCTest.ExpectNil(confirmError, 'no error on confirmation')

    GCTest.ExpectTrue(GCStates.Is(21, 'spawned'), 'player is in spawned state after confirmation')

    GCSpawn.RemovePlayerDecisions(21)
    GCSessions.Remove(21, 'test_cleanup')
end)

-- RU: Тест повторного подтверждения.
-- EN: Test of duplicate confirmation.
GCTest.Register('spawn.confirm_duplicate', function()
    -- RU: Создаём сессию и переводим в spawn_pending.
    -- EN: Create a session and move to spawn_pending.
    local identifiers = {
        license = 'license:test-spawn-3'
    }

    GCSessions.Create(22, 'TestPlayer22', identifiers)
    GCStates.Set(22, 'validated', 'test')
    GCStates.Set(22, 'joining', 'test')
    GCStates.Set(22, 'client_ready', 'test')
    GCStates.Set(22, 'spawn_pending', 'test')

    local decision, errorCode = GCSpawn.CreateDecision(22)

    GCTest.ExpectNotNil(decision, 'decision is created for duplicate test')

    -- RU: Переводим в spawning перед подтверждением.
    -- EN: Move to spawning before confirming.
    GCStates.Set(22, 'spawning', 'test')

    local success1 = GCSpawn.Confirm(22, decision.id)
    GCTest.ExpectTrue(success1, 'first confirmation succeeds')

    -- RU: Повторное подтверждение должно быть отклонено.
    -- EN: Duplicate confirmation must be rejected.
    local success2, confirmError2 = GCSpawn.Confirm(22, decision.id)
    GCTest.ExpectFalse(success2, 'duplicate confirmation is rejected')
    GCTest.ExpectNotNil(confirmError2, 'error code is returned for duplicate confirmation')

    GCSpawn.RemovePlayerDecisions(22)
    GCSessions.Remove(22, 'test_cleanup')
end)

-- RU: Тест подтверждения с поддельным Decision ID.
-- EN: Test of confirmation with a fake Decision ID.
GCTest.Register('spawn.confirm_fake_decision', function()
    -- RU: Создаём сессию и переводим в spawning.
    -- EN: Create a session and move to spawning.
    local identifiers = {
        license = 'license:test-spawn-4'
    }

    GCSessions.Create(23, 'TestPlayer23', identifiers)
    GCStates.Set(23, 'validated', 'test')
    GCStates.Set(23, 'joining', 'test')
    GCStates.Set(23, 'client_ready', 'test')
    GCStates.Set(23, 'spawn_pending', 'test')
    GCStates.Set(23, 'spawning', 'test')

    local success, confirmError = GCSpawn.Confirm(23, 'gc:spawn:fake-id')

    GCTest.ExpectFalse(success, 'fake decision id is rejected')
    GCTest.ExpectNotNil(confirmError, 'error code is returned for fake decision')

    GCSpawn.RemovePlayerDecisions(23)
    GCSessions.Remove(23, 'test_cleanup')
end)