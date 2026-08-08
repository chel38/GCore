-- RU: Тесты rate limit GreenCore.
-- EN: GreenCore rate limit tests.

-- RU: Тест разрешённого действия без превышения лимита.
-- EN: Test of an allowed action without exceeding the limit.
GCTest.Register('rate_limit.allowed', function()
    local playerSource = 40

    GCRateLimit.RemovePlayer(playerSource)

    -- RU: Первый запрос всегда разрешён.
    -- EN: The first request is always allowed.
    local allowed, errorCode = GCRateLimit.Check(playerSource, 'requestSpawn')

    GCTest.ExpectTrue(allowed, 'first request is allowed')
    GCTest.ExpectNil(errorCode, 'no error code for allowed request')
end)

-- RU: Тест превышения лимита по количеству попыток.
-- EN: Test of exceeding the limit by the number of attempts.
GCTest.Register('rate_limit.max_attempts', function()
    local playerSource = 41
    local actionName = 'requestSpawn'

    GCRateLimit.RemovePlayer(playerSource)

    -- RU: Заполняем окно попытками до предела.
    -- EN: Fill the window with attempts up to the limit.
    local limitConfig = GCConfig.Security.rateLimits[actionName]

    for _ = 1, limitConfig.maxAttempts do
        GCRateLimit.Record(playerSource, actionName)
    end

    -- RU: Следующий запрос должен быть отклонён.
    -- EN: The next request must be rejected.
    local allowed = GCRateLimit.Check(playerSource, actionName)

    GCTest.ExpectFalse(allowed, 'request beyond max attempts is rejected')
end)

-- RU: Тест запрещённого действия с невалидными аргументами.
-- EN: Test of a disallowed action with invalid arguments.
GCTest.Register('rate_limit.invalid_args', function()
    local allowed, errorCode = GCRateLimit.Check('not-a-number', 'requestSpawn')

    GCTest.ExpectFalse(allowed, 'invalid source is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-RATE-LIMIT-001', 'invalid source returns GC-RATE-LIMIT-001')
end)

-- RU: Тест сброса данных rate limit игрока.
-- EN: Test of resetting a player rate limit data.
GCTest.Register('rate_limit.reset', function()
    local playerSource = 42
    local actionName = 'clientReady'

    GCRateLimit.RemovePlayer(playerSource)

    GCRateLimit.Record(playerSource, actionName)
    GCRateLimit.Record(playerSource, actionName)

    GCRateLimit.Reset(playerSource, actionName)

    -- RU: После сброса запрос снова разрешён.
    -- EN: After a reset the request is allowed again.
    local allowed = GCRateLimit.Check(playerSource, actionName)

    GCTest.ExpectTrue(allowed, 'request is allowed after reset')
end)

-- RU: Тест регистрации нарушений и кика.
-- EN: Test of registering violations and kicking.
GCTest.Register('rate_limit.violations', function()
    local playerSource = 43

    GCRateLimit.RemovePlayer(playerSource)

    -- RU: Достигаем порога нарушений.
    -- EN: Reach the violation threshold.
    local shouldKick = false

    for _ = 1, (GCConfig.Security.maxViolationsBeforeKick or 10) do
        shouldKick = GCRateLimit.RegisterViolation(playerSource)
    end

    GCTest.ExpectTrue(shouldKick, 'player should be kicked after many violations')

    GCRateLimit.RemovePlayer(playerSource)
end)

-- RU: Тест удаления всех данных rate limit.
-- EN: Test of clearing all rate limit data.
GCTest.Register('rate_limit.clear_all', function()
    local playerSource = 44

    GCRateLimit.RemovePlayer(playerSource)
    GCRateLimit.Record(playerSource, 'clientReady')
    GCRateLimit.Record(playerSource, 'requestSpawn')

    GCRateLimit.ClearAll()

    -- RU: После полной очистки первый запрос разрешён.
    -- EN: After a full clear the first request is allowed.
    local allowed = GCRateLimit.Check(playerSource, 'clientReady')

    GCTest.ExpectTrue(allowed, 'request is allowed after clear all')
end)