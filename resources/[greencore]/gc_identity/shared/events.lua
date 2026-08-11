-- EN: One registry documents every network direction owned by gc_identity.
-- RU: Единый registry документирует направления network events gc_identity.

GCIdentityEvents = {
    server = {
        hello = 'gc_identity:server:hello',
        sendRegistrationCode = 'gc_identity:server:sendRegistrationCode',
        verifyEmail = 'gc_identity:server:verifyEmail',
        resendVerification = 'gc_identity:server:resendVerification',
        changeRegistrationEmail = 'gc_identity:server:changeRegistrationEmail',
        finalizeRegistration = 'gc_identity:server:finalizeRegistration',
        completeProfile = 'gc_identity:server:completeProfile',
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
    presented = 'presented',
    sendRegistrationCode = 'sendRegistrationCode',
    verifyEmail = 'verifyEmail',
    resendVerification = 'resendVerification',
    changeRegistrationEmail = 'changeRegistrationEmail',
    finalizeRegistration = 'finalizeRegistration',
    completeProfile = 'completeProfile',
    createCharacter = 'createCharacter',
    selectCharacter = 'selectCharacter',
    refresh = 'refresh',
    exit = 'exit'
}
