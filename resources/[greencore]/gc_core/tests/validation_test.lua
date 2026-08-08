-- RU: Тесты валидации payload GreenCore.
-- EN: GreenCore payload validation tests.

-- RU: Тест валидного payload готовности клиента.
-- EN: Test of a valid client readiness payload.
GCTest.Register('validation.client_ready.valid', function()
    local payload = {
        clientVersion = '0.1.0',
        protocolVersion = 1,
        locale = 'ru'
    }

    local isValid, errorCode = GCValidation.ClientReady(payload)

    GCTest.ExpectTrue(isValid, 'valid clientReady payload is accepted')
    GCTest.ExpectNil(errorCode, 'no error code for valid payload')
end)

-- RU: Тест невалидного типа payload.
-- EN: Test of an invalid payload type.
GCTest.Register('validation.client_ready.invalid_type', function()
    local isValid, errorCode = GCValidation.ClientReady('not-a-table')

    GCTest.ExpectFalse(isValid, 'non-table payload is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-TYPE-001', 'correct error code for non-table')
end)

-- RU: Тест невалидного clientVersion.
-- EN: Test of an invalid clientVersion.
GCTest.Register('validation.client_ready.invalid_version', function()
    local payload = {
        clientVersion = 123,
        protocolVersion = 1
    }

    local isValid, errorCode = GCValidation.ClientReady(payload)

    GCTest.ExpectFalse(isValid, 'non-string clientVersion is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-VERSION-001', 'correct error code for version')
end)

-- RU: Тест слишком длинного clientVersion.
-- EN: Test of an overly long clientVersion.
GCTest.Register('validation.client_ready.long_version', function()
    local payload = {
        clientVersion = string.rep('a', 33),
        protocolVersion = 1
    }

    local isValid, errorCode = GCValidation.ClientReady(payload)

    GCTest.ExpectFalse(isValid, 'overly long clientVersion is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-VERSION-002', 'correct error code for long version')
end)

-- RU: Тест невалидного protocolVersion.
-- EN: Test of an invalid protocolVersion.
GCTest.Register('validation.client_ready.invalid_protocol', function()
    local payload = {
        clientVersion = '0.1.0',
        protocolVersion = 'one'
    }

    local isValid, errorCode = GCValidation.ClientReady(payload)

    GCTest.ExpectFalse(isValid, 'non-number protocolVersion is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-PROTOCOL-001', 'correct error code for protocol')
end)

-- RU: Тест невалидного locale.
-- EN: Test of an invalid locale.
GCTest.Register('validation.client_ready.invalid_locale', function()
    local payload = {
        clientVersion = '0.1.0',
        protocolVersion = 1,
        locale = 42
    }

    local isValid, errorCode = GCValidation.ClientReady(payload)

    GCTest.ExpectFalse(isValid, 'non-string locale is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-LOCALE-001', 'correct error code for locale')
end)

-- RU: Тест валидного payload подтверждения спавна.
-- EN: Test of a valid spawn confirmation payload.
GCTest.Register('validation.confirm_spawn.valid', function()
    local payload = {
        decisionId = 'gc:spawn:test-id'
    }

    local isValid, errorCode = GCValidation.ConfirmSpawn(payload)

    GCTest.ExpectTrue(isValid, 'valid confirmSpawn payload is accepted')
    GCTest.ExpectNil(errorCode, 'no error code for valid confirmSpawn')
end)

-- RU: Тест невалидного decisionId.
-- EN: Test of an invalid decisionId.
GCTest.Register('validation.confirm_spawn.invalid_decision', function()
    local payload = {
        decisionId = 123
    }

    local isValid, errorCode = GCValidation.ConfirmSpawn(payload)

    GCTest.ExpectFalse(isValid, 'non-string decisionId is rejected')
    GCTest.ExpectEqual(errorCode, 'GC-PAYLOAD-DECISION-001', 'correct error code for decision')
end)

GCTest.Register('validation.rejects_unknown_fields', function()
    local valid = GCValidation.ClientReady({
        clientVersion = GCVersion.GetString(),
        protocolVersion = GCVersion.GetProtocolVersion(),
        injected = true
    })

    GCTest.ExpectFalse(valid, 'unknown handshake fields are rejected')
end, 'security')

GCTest.Register('validation.rejects_non_finite_coordinates', function()
    local valid = GCValidation.SpawnApproved({
        decisionId = 'gc:spawn:test',
        position = { x = 0 / 0, y = 0.0, z = 0.0, heading = 0.0 },
        ped = { name = 'mp_m_freemode_01' }
    })

    GCTest.ExpectFalse(valid, 'NaN coordinates are rejected')
end, 'security')
