-- EN: One registry documents every network direction owned by gc_identity.
-- RU: Единый registry документирует направления network events gc_identity.

GCIdentityEvents = {
    server = {
        hello = 'gc_identity:server:hello',
        registerAccount = 'gc_identity:server:registerAccount',
        createCharacter = 'gc_identity:server:createCharacter',
        selectCharacter = 'gc_identity:server:selectCharacter',
        clientFailure = 'gc_identity:server:clientFailure',
        exit = 'gc_identity:server:exit'
    },
    client = {
        snapshot = 'gc_identity:client:snapshot',
        rejected = 'gc_identity:client:rejected'
    }
}

GCIdentityNuiCallbacks = {
    ready = 'ready',
    registerAccount = 'registerAccount',
    createCharacter = 'createCharacter',
    selectCharacter = 'selectCharacter',
    refresh = 'refresh',
    exit = 'exit'
}
