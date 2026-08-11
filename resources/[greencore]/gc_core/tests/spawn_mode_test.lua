local function createManualModeSession(playerSource)
    local temporarySource = 91000 + playerSource
    local identifier = 'license:spawn-mode-' .. tostring(playerSource)
    GCSessions.CreatePendingConnection(
        temporarySource,
        'SpawnModePlayer',
        { license = identifier },
        identifier,
        'license'
    )
    local session = GCSessions.PromotePendingConnection(temporarySource, playerSource)
    GCStates.Set(playerSource, 'validated', 'spawn_mode_test')
    GCStates.Set(playerSource, 'joining', 'spawn_mode_test')
    GCStates.Set(playerSource, 'client_ready', 'spawn_mode_test')
    return session
end

GCTest.Register('spawn_mode.manual_rejects_client_but_allows_server_api', function()
    local previousMode = GCConfig.Spawn.mode
    GCConfig.Spawn.mode = 'manual'
    local session = createManualModeSession(151)

    GCTestHarness.EmitNetworkEvent(GCEvents.Server.requestSpawn, 151, {})
    GCTest.ExpectEqual(session.state, 'client_ready', 'client request cannot cross manual spawn gate')
    GCTest.ExpectNil(session.spawnDecision, 'client request creates no decision in manual mode')

    local decision, decisionError = GCAPI.RequestPlayerSpawn(151)
    GCTest.ExpectNotNil(decision, 'trusted server API can release manual spawn')
    GCTest.ExpectNil(decisionError, 'trusted server release has no error')
    GCTest.ExpectEqual(session.state, 'spawn_confirming', 'server API follows the normal state machine')

    GCSpawn.RemovePlayerDecisions(151)
    GCSessions.Remove(151, 'spawn_mode_test_cleanup')
    GCConfig.Spawn.mode = previousMode
end, 'security')
