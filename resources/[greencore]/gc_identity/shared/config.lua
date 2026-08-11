-- EN: Module-owned configuration. Identity settings never enter gc_core config.
-- RU: Конфигурация принадлежит модулю. Identity settings не входят в gc_core.

GCIdentityConfig = {
    requiredCoreApi = 1,
    identifierTypes = { 'license', 'license2' },
    storage = {
        adapter = 'oxmysql',
        legacyFile = 'data/identities.json',
        importLegacyJson = true
    },
    database = {
        healthAttempts = 5,
        healthRetryMs = 2000
    },
    mail = {
        requestTimeoutMs = 8000,
        healthCheckOnStart = true
    },
    verification = {
        codeDigits = 6,
        ttlSeconds = 600,
        maximumAttempts = 5,
        resendCooldownSeconds = 60
    },
    accounts = {
        emailMinBytes = 5,
        emailMaxBytes = 254,
        firstNameMinBytes = 2,
        firstNameMaxBytes = 32,
        lastNameMinBytes = 2,
        lastNameMaxBytes = 32
    },
    characters = {
        maximum = 3,
        nameMinBytes = 2,
        nameMaxBytes = 32
    },
    rateLimits = {
        hello = { maximum = 5, windowMs = 30000 },
        registration = { maximum = 3, windowMs = 60000 },
        verifyEmail = { maximum = 8, windowMs = 60000 },
        resendVerification = { maximum = 3, windowMs = 60000 },
        changeRegistrationEmail = { maximum = 3, windowMs = 60000 },
        finalizeRegistration = { maximum = 3, windowMs = 60000 },
        completeProfile = { maximum = 3, windowMs = 60000 },
        createCharacter = { maximum = 3, windowMs = 60000 },
        selectCharacter = { maximum = 10, windowMs = 60000 },
        clientFailure = { maximum = 2, windowMs = 30000 },
        exit = { maximum = 2, windowMs = 30000 }
    },
    replayCacheSize = 32,
    clientHello = {
        maximumAttempts = 5,
        retryIntervalMs = 3000
    },
    client = {
        nuiReadyTimeoutMs = 10000,
        restrictControls = true,
        debug = false
    }
}
