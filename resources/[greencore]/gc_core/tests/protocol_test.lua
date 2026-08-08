-- RU: Тесты проверки версии протокола GreenCore.
-- EN: GreenCore protocol version validation tests.

-- RU: Тест совпадения версии протокола.
-- EN: Test of protocol version match.
GCTest.Register('protocol.same_version', function()
    local serverProtocol = GCConfig.General.protocolVersion

    local matches, errorCode = GCValidation.ProtocolMatches(serverProtocol)

    GCTest.ExpectTrue(matches, 'same version is accepted')
    GCTest.ExpectNil(errorCode, 'no error for same version')
end)

-- RU: Тест несовпадающей версии протокола.
-- EN: Test of a mismatched protocol version.
GCTest.Register('protocol.wrong_version', function()
    local serverProtocol = GCConfig.General.protocolVersion

    -- RU: Берём заведомо другую версию.
    -- EN: Take a guaranteed different version.
    local wrongVersion = serverProtocol + 1

    local matches, errorCode = GCValidation.ProtocolMatches(wrongVersion)

    GCTest.ExpectFalse(matches, 'wrong version is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PROTOCOL-MISMATCH-001', 'mismatch error code is returned')
end)

-- RU: Тест отсутствующей версии протокола.
-- EN: Test of a missing protocol version.
GCTest.Register('protocol.missing_version', function()
    local matches, errorCode = GCValidation.ProtocolMatches(nil)

    GCTest.ExpectFalse(matches, 'missing version is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PROTOCOL-MISMATCH-001', 'mismatch error code is returned')
end)

-- RU: Тест неверного типа версии протокола.
-- EN: Test of an invalid protocol version type.
GCTest.Register('protocol.wrong_type', function()
    local matches, errorCode = GCValidation.ProtocolMatches('1')

    GCTest.ExpectFalse(matches, 'string version is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PROTOCOL-MISMATCH-001', 'mismatch error code is returned')
end)

-- RU: Тест нецелой версии протокола.
-- EN: Test of a non-integer protocol version.
GCTest.Register('protocol.float_version', function()
    local matches, errorCode = GCValidation.ProtocolMatches(1.5)

    GCTest.ExpectFalse(matches, 'float version is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PROTOCOL-MISMATCH-001', 'mismatch error code is returned')
end)

-- RU: Тест валидации payload resync-ready.
-- EN: Test of resync-ready payload validation.
GCTest.Register('protocol.resync_ready.valid', function()
    local payload = {
        protocolVersion = GCConfig.General.protocolVersion,
        clientVersion = '0.1.0',
        isPedAlive = true
    }

    local isValid, errorCode = GCValidation.ResyncReady(payload)

    GCTest.ExpectTrue(isValid, 'valid resyncReady payload is accepted')
    GCTest.ExpectNil(errorCode, 'no error for valid resyncReady')
end)

-- RU: Тест невалидного payload resync-ready.
-- EN: Test of an invalid resync-ready payload.
GCTest.Register('protocol.resync_ready.invalid', function()
    local payload = {
        protocolVersion = GCConfig.General.protocolVersion,
        clientVersion = 123
    }

    local isValid, errorCode = GCValidation.ResyncReady(payload)

    GCTest.ExpectFalse(isValid, 'invalid resyncReady payload is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-VERSION-001', 'correct error code for resyncReady')
end)