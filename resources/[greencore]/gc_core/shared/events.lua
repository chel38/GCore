-- RU: Реестр публичных сетевых событий протокола v2 и server-local hooks.
-- EN: Registry of public protocol v2 network events and server-local hooks.

GCEvents = {
    Server = {
        clientReady = 'gc_core:server:clientReady',
        requestSpawn = 'gc_core:server:requestSpawn',
        confirmSpawn = 'gc_core:server:confirmSpawn',
        reportClientError = 'gc_core:server:reportClientError',
        resyncReady = 'gc_core:server:resyncReady'
    },
    Client = {
        connectionAccepted = 'gc_core:client:connectionAccepted',
        spawnApproved = 'gc_core:client:spawnApproved',
        spawnRejected = 'gc_core:client:spawnRejected',
        spawnConfirmed = 'gc_core:client:spawnConfirmed',
        forceResync = 'gc_core:client:forceResync',
        notify = 'gc_core:client:notify'
    },
    Hooks = {
        playerSpawned = 'gc_core:hook:playerSpawned'
    }
}
