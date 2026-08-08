-- RU: Интеграционные тесты вызывают реальный GCSpawn.Confirm с включённой
-- RU: server-side verification; заменяется только FiveM native snapshot boundary.
-- EN: Integration tests call the real GCSpawn.Confirm with server-side
-- EN: verification enabled; only the FiveM native snapshot boundary is mocked.

local function setupVerificationSession(playerSource)
    local temporarySource = 70000 + playerSource
    local license = 'license:spawn-verification-' .. tostring(playerSource)
    GCSessions.CreatePendingConnection(temporarySource, 'Verify' .. tostring(playerSource), {
        license = license
    }, license, 'license')
    local session = GCSessions.PromotePendingConnection(temporarySource, playerSource)
    GCStates.Set(playerSource, 'validated', 'test')
    GCStates.Set(playerSource, 'joining', 'test')
    GCStates.Set(playerSource, 'client_ready', 'test')
    local decision = GCSpawn.Request(playerSource)
    return session, decision
end

local function matchingSnapshot(decision)
    return {
        exists = true,
        alive = true,
        owner = decision.source,
        model = decision.ped.hash,
        position = {
            x = decision.position.x,
            y = decision.position.y,
            z = decision.position.z
        }
    }
end

local function withVerification(options, snapshotProvider, body)
    local config = GCConfig.Spawn.verification
    local original = {
        enabled = config.enabled,
        timeoutMs = config.timeoutMs,
        intervalMs = config.intervalMs,
        maxAttempts = config.maxAttempts
    }
    local originalProvider = GCPlayers.GetEntitySnapshot

    config.enabled = true
    config.timeoutMs = options.timeoutMs or 1000
    config.intervalMs = options.intervalMs or 1
    config.maxAttempts = options.maxAttempts or 3
    GCPlayers.GetEntitySnapshot = snapshotProvider

    local ok, result = pcall(body)

    GCPlayers.GetEntitySnapshot = originalProvider
    config.enabled = original.enabled
    config.timeoutMs = original.timeoutMs
    config.intervalMs = original.intervalMs
    config.maxAttempts = original.maxAttempts

    if not ok then
        error(result)
    end
end

local function cleanupVerificationSession(playerSource)
    GCSpawn.RemovePlayerDecisions(playerSource)
    GCSessions.Remove(playerSource, 'test_cleanup')
end

GCTest.Register('spawn.confirm_with_server_verification_success', function()
    local session, decision = setupVerificationSession(101)
    local snapshots = 0

    withVerification({}, function()
        snapshots = snapshots + 1
        return matchingSnapshot(decision)
    end, function()
        local success, errorCode = GCSpawn.Confirm(101, decision.id)
        GCTest.ExpectTrue(success, 'production Confirm succeeds after authoritative snapshot')
        GCTest.ExpectNil(errorCode, 'verified success has no error')
    end)

    GCTest.ExpectEqual(snapshots, 1, 'real verification loop reads server entity state')
    GCTest.ExpectTrue(GCStates.Is(101, 'spawned'), 'verified transaction commits spawned')
    GCTest.ExpectNil(session.spawnDecision, 'verified transaction consumes decision')
    cleanupVerificationSession(101)
end, 'integration')

GCTest.Register('spawn.confirm_entity_missing', function()
    local _, decision = setupVerificationSession(102)
    withVerification({ maxAttempts = 1 }, function()
        return { exists = false, alive = false }
    end, function()
        local success, errorCode, retrying = GCSpawn.Confirm(102, decision.id)
        GCTest.ExpectFalse(success, 'missing server entity is rejected')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-ENTITY-MISSING', 'entity error is classified')
        GCTest.ExpectTrue(retrying, 'entity failure may retry the same ped within limits')
    end)
    cleanupVerificationSession(102)
end, 'integration')

GCTest.Register('spawn.confirm_dead_ped', function()
    local _, decision = setupVerificationSession(103)
    local snapshot = matchingSnapshot(decision)
    snapshot.alive = false
    withVerification({ maxAttempts = 1 }, function() return snapshot end, function()
        local success, errorCode = GCSpawn.Confirm(103, decision.id)
        GCTest.ExpectFalse(success, 'dead authoritative ped is rejected')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-ENTITY-DEAD', 'dead ped error is classified')
    end)
    cleanupVerificationSession(103)
end, 'integration')

GCTest.Register('spawn.confirm_wrong_owner', function()
    local session, decision = setupVerificationSession(104)
    local snapshot = matchingSnapshot(decision)
    snapshot.owner = 999
    withVerification({}, function() return snapshot end, function()
        local success, errorCode, retrying = GCSpawn.Confirm(104, decision.id)
        GCTest.ExpectFalse(success, 'wrong network owner is rejected')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-OWNER-MISMATCH', 'ownership has a security code')
        GCTest.ExpectFalse(retrying, 'ownership mismatch is never a model retry')
    end)
    GCTest.ExpectNil(session.attemptedPedModels[decision.ped.name], 'ownership does not blacklist ped')
    cleanupVerificationSession(104)
end, 'security')

GCTest.Register('spawn.confirm_model_mismatch', function()
    local session, decision = setupVerificationSession(105)
    local snapshot = matchingSnapshot(decision)
    snapshot.model = (decision.ped.hash or 0) + 1
    withVerification({}, function() return snapshot end, function()
        local success, errorCode, retrying = GCSpawn.Confirm(105, decision.id)
        GCTest.ExpectFalse(success, 'wrong model is rejected')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-MODEL-MISMATCH', 'model error is classified')
        GCTest.ExpectTrue(retrying, 'model mismatch creates a bounded new-ped retry')
    end)
    GCTest.ExpectTrue(session.attemptedPedModels[decision.ped.name], 'only model failure blacklists ped')
    cleanupVerificationSession(105)
end, 'integration')

GCTest.Register('spawn.confirm_position_mismatch', function()
    local session, decision = setupVerificationSession(106)
    local snapshot = matchingSnapshot(decision)
    snapshot.position.x = snapshot.position.x + 1000.0
    withVerification({ maxAttempts = 1 }, function() return snapshot end, function()
        local success, errorCode, retrying = GCSpawn.Confirm(106, decision.id)
        GCTest.ExpectFalse(success, 'persistent position mismatch is rejected')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-POSITION-MISMATCH', 'position error is classified')
        GCTest.ExpectTrue(retrying, 'one bounded same-ped retry is allowed')
    end)
    GCTest.ExpectNil(session.attemptedPedModels[decision.ped.name], 'position does not blacklist ped')
    cleanupVerificationSession(106)
end, 'integration')

GCTest.Register('spawn.confirm_verification_timeout', function()
    local _, decision = setupVerificationSession(107)
    withVerification({ timeoutMs = 0, maxAttempts = 3 }, function()
        return { exists = false, alive = false }
    end, function()
        local success, errorCode = GCSpawn.Confirm(107, decision.id)
        GCTest.ExpectFalse(success, 'verification timeout rejects confirmation')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-VERIFY-TIMEOUT', 'timeout has a stable diagnostic code')
    end)
    cleanupVerificationSession(107)
end, 'integration')

GCTest.Register('spawn.confirm_expired_decision', function()
    local _, decision = setupVerificationSession(108)
    decision.expiresAt = GCUtils.NowSec() - 1
    local success, errorCode, retrying = GCSpawn.Confirm(108, decision.id)
    GCTest.ExpectFalse(success, 'expired transaction is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-SPAWN-DECISION-EXPIRED-001', 'expired code is stable')
    GCTest.ExpectFalse(retrying, 'expired transaction never enters spawn retry')
    cleanupVerificationSession(108)
end, 'integration')

GCTest.Register('spawn.confirm_consumed_decision', function()
    local _, decision = setupVerificationSession(109)
    decision.consumed = true
    local success, errorCode = GCSpawn.Confirm(109, decision.id)
    GCTest.ExpectFalse(success, 'consumed transaction is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-SPAWN-DECISION-CONSUMED-001', 'consumed code is stable')
    cleanupVerificationSession(109)
end, 'security')

GCTest.Register('spawn.confirm_source_mismatch', function()
    local _, decision = setupVerificationSession(110)
    local success, errorCode = GCSpawn.Confirm(1110, decision.id)
    GCTest.ExpectFalse(success, 'foreign source cannot confirm decision')
    GCTest.ExpectEqual(errorCode, 'GC-SPAWN-DECISION-SOURCE-MISMATCH', 'source mismatch is explicit')
    cleanupVerificationSession(110)
end, 'security')

GCTest.Register('spawn.confirm_session_mismatch', function()
    local _, decision = setupVerificationSession(111)
    decision.sessionId = 'gc:session:stale'
    local success, errorCode = GCSpawn.Confirm(111, decision.id)
    GCTest.ExpectFalse(success, 'foreign session cannot confirm decision')
    GCTest.ExpectEqual(errorCode, 'GC-SPAWN-DECISION-SESSION-MISMATCH', 'session mismatch is explicit')
    cleanupVerificationSession(111)
end, 'security')

GCTest.Register('spawn.confirm_session_changed_during_verification', function()
    local _, decision = setupVerificationSession(112)
    withVerification({}, function()
        GCSessions.Remove(112, 'test_session_replaced')
        GCSessions.CreateRecoveredSession(112, 'Replacement112', {
            license = 'license:replacement-112'
        }, 'license:replacement-112', 'license')
        return matchingSnapshot(decision)
    end, function()
        local success, errorCode, retrying = GCSpawn.Confirm(112, decision.id)
        GCTest.ExpectFalse(success, 'session replacement cancels verification')
        GCTest.ExpectEqual(errorCode, 'GC-SPAWN-SESSION-CHANGED', 'session change has stable code')
        GCTest.ExpectFalse(retrying, 'session change cannot create a retry')
    end)
    cleanupVerificationSession(112)
end, 'security')

GCTest.Register('spawn.confirm_disconnect_during_verification', function()
    local _, decision = setupVerificationSession(113)
    withVerification({}, function()
        GCSessions.Remove(113, 'test_disconnect')
        return matchingSnapshot(decision)
    end, function()
        local success, errorCode, retrying = GCSpawn.Confirm(113, decision.id)
        GCTest.ExpectFalse(success, 'disconnect cancels verification')
        GCTest.ExpectEqual(errorCode, 'GC-SESSION-001', 'disconnect returns session error')
        GCTest.ExpectFalse(retrying, 'disconnect cannot create a retry')
    end)
    cleanupVerificationSession(113)
end, 'integration')

GCTest.Register('spawn.retry_policy_table', function()
    GCTest.ExpectEqual(GCSpawnRetryPolicy.Resolve('GC-SPAWN-PED-LOAD-001').action, 'NEW_PED', 'model selects new ped')
    GCTest.ExpectEqual(GCSpawnRetryPolicy.Resolve('GC-SPAWN-COLLISION-001').action, 'SAME_PED', 'collision keeps ped')
    GCTest.ExpectEqual(GCSpawnRetryPolicy.Resolve('GC-SPAWN-POSITION-MISMATCH').category, 'POSITION', 'position is classified')
    GCTest.ExpectEqual(GCSpawnRetryPolicy.Resolve('GC-SPAWN-OWNER-MISMATCH').action, 'REJECT', 'ownership rejects')
    GCTest.ExpectEqual(GCSpawnRetryPolicy.Resolve('unregistered-error').category, 'UNKNOWN', 'unknown is fail-closed')
end)

GCTest.Register('spawn.retry_collision_reuses_ped', function()
    local session, decision = setupVerificationSession(114)
    local retrying = GCSpawn.HandleSpawnFailure(114, 'GC-SPAWN-COLLISION-001')
    local nextDecision = GCSpawn.Request(114)

    GCTest.ExpectTrue(retrying, 'collision allows bounded retry')
    GCTest.ExpectNotNil(nextDecision, 'same-ped retry creates a new decision')
    GCTest.ExpectEqual(nextDecision.ped.name, decision.ped.name, 'collision reuses the ped model')
    GCTest.ExpectNil(session.attemptedPedModels[decision.ped.name], 'collision never blacklists ped')
    cleanupVerificationSession(114)
end, 'integration')

GCTest.Register('spawn.retry_limits_are_terminal', function()
    local _, decision = setupVerificationSession(115)
    local retryConfig = GCConfig.Spawn.retry
    local originalLimit = retryConfig.maxSamePedRetries
    retryConfig.maxSamePedRetries = 0
    local retrying = GCSpawn.HandleSpawnFailure(115, 'GC-SPAWN-COLLISION-001')
    retryConfig.maxSamePedRetries = originalLimit

    GCTest.ExpectFalse(retrying, 'same-ped retry cannot exceed configured limit')
    GCTest.ExpectTrue(GCStates.Is(115, 'error'), 'retry exhaustion enters terminal error state')
    GCTest.ExpectNil(GCSessions.Get(115).attemptedPedModels[decision.ped.name], 'limit exhaustion still does not blacklist ped')
    cleanupVerificationSession(115)
end, 'integration')
