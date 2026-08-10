-- EN: One registry documents every network direction owned by gc_identity.
-- RU: Единый registry документирует направления network events gc_identity.

GCIdentityEvents = {
    server = {
        hello = 'gc_identity:server:hello',
        createCharacter = 'gc_identity:server:createCharacter',
        selectCharacter = 'gc_identity:server:selectCharacter'
    },
    client = {
        snapshot = 'gc_identity:client:snapshot',
        rejected = 'gc_identity:client:rejected'
    }
}
