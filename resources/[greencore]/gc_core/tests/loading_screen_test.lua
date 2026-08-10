-- EN: The system loading screen may close only after a server-origin
-- spawnConfirmed event commits the authoritative spawned state.
-- RU: Системный loading screen можно закрыть только после server-origin события
-- spawnConfirmed, которое фиксирует authoritative state spawned.

GCTest.Register('loading_screen.closes_after_authoritative_spawn_confirmation', function()
    GCClientState.Reset()
    GCClientState.SetSpawnConfirming(true)

    local accepted = GCTestHarness.EmitServerClientEvent(
        GCEvents.Client.spawnConfirmed,
        {
            decisionId = 'decision_loading_1',
            state = 'spawned'
        }
    )
    local shutdowns = GCTestHarness.GetLoadingScreenShutdowns()

    GCTest.ExpectTrue(accepted, 'server spawn confirmation is accepted')
    GCTest.ExpectTrue(GCClientState.IsSpawned(), 'client commits confirmed spawned state')
    GCTest.ExpectTrue(GCClientLoadingScreen.IsComplete(), 'loading screen completion is recorded')
    GCTest.ExpectEqual(shutdowns.nui, 1, 'NUI loading screen closes once')
    GCTest.ExpectEqual(shutdowns.game, 1, 'FiveM loading screen closes once')

    GCTestHarness.EmitServerClientEvent(
        GCEvents.Client.spawnConfirmed,
        {
            decisionId = 'decision_loading_1',
            state = 'spawned'
        }
    )
    shutdowns = GCTestHarness.GetLoadingScreenShutdowns()

    GCTest.ExpectEqual(shutdowns.nui, 1, 'duplicate confirmation cannot close NUI twice')
    GCTest.ExpectEqual(shutdowns.game, 1, 'duplicate confirmation cannot close FiveM screen twice')
end, 'runtime')
