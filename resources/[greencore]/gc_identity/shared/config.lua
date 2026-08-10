-- EN: Module-owned configuration. Identity settings never enter gc_core config.
-- RU: Конфигурация принадлежит модулю. Identity settings не входят в gc_core.

GCIdentityConfig = {
    requiredCoreApi = 1,
    identifierTypes = { 'license', 'license2' },
    storage = {
        file = 'data/identities.json'
    },
    characters = {
        maximum = 3,
        nameMinBytes = 2,
        nameMaxBytes = 32
    },
    rateLimits = {
        hello = { maximum = 5, windowMs = 30000 },
        createCharacter = { maximum = 3, windowMs = 60000 },
        selectCharacter = { maximum = 10, windowMs = 60000 }
    },
    replayCacheSize = 32,
    clientHello = {
        maximumAttempts = 5,
        retryIntervalMs = 3000
    }
}
