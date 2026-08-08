-- RU: Тесты сессий GreenCore.
-- EN: GreenCore session tests.

-- RU: Тест генерации Session ID.
-- EN: Test of Session ID generation.
GCTest.Register('sessions.generate_id', function()
    local id1 = GCUtils.GenerateUuid(GCConstants.sessionPrefix)
    local id2 = GCUtils.GenerateUuid(GCConstants.sessionPrefix)

    GCTest.ExpectNotNil(id1, 'session id is generated')
    GCTest.ExpectNotNil(id2, 'second session id is generated')
    GCTest.ExpectFalse(id1 == id2, 'session ids are unique')
    GCTest.ExpectTrue(id1:find('^gc:session:') ~= nil, 'session id has correct prefix')
end)

-- RU: Тест создания pending connection.
-- EN: Test of pending connection creation.
GCTest.Register('sessions.create_pending', function()
    local identifiers = {
        license = 'license:test-license-123'
    }

    local pending, errorCode = GCSessions.CreatePendingConnection(60000, 'TestPlayer', identifiers, 'license:test-license-123', 'license')

    GCTest.ExpectNotNil(pending, 'pending connection is created')
    GCTest.ExpectNil(errorCode, 'no error on pending connection creation')
    GCTest.ExpectEqual(pending.temporarySource, 60000, 'pending temporary source is correct')
    GCTest.ExpectEqual(pending.state, 'connecting', 'pending state is connecting')
    GCTest.ExpectNotNil(pending.connectionId, 'pending connection id is generated')
    GCTest.ExpectTrue(pending.connectionId:find('^gc:connection:') ~= nil, 'pending connection id has correct prefix')

    GCSessions.RemovePendingConnection(60000)
end)

-- RU: Тест создания pending connection с невалидными данными.
-- EN: Test of pending connection creation with invalid data.
GCTest.Register('sessions.create_pending.invalid', function()
    local pending, errorCode = GCSessions.CreatePendingConnection('not-a-number', 'TestPlayer', {})

    GCTest.ExpectNil(pending, 'pending connection is not created with invalid source')
    GCTest.ExpectNotNil(errorCode, 'error code is returned for invalid source')
end)

-- RU: Тест миграции pending connection в активную сессию (playerJoining).
-- EN: Test of pending connection promotion to an active session (playerJoining).
GCTest.Register('sessions.promote', function()
    local identifiers = {
        license = 'license:test-license-456'
    }

    local pending, _ = GCSessions.CreatePendingConnection(60001, 'TestPlayer2', identifiers, 'license:test-license-456', 'license')

    GCTest.ExpectNotNil(pending, 'pending connection is created for promotion test')

    -- RU: Игрок вошёл, финальный source = 12.
    -- EN: The player joined, final source = 12.
    local session, promoteError = GCSessions.PromotePendingConnection(60001, 12)

    GCTest.ExpectNotNil(session, 'session is promoted')
    GCTest.ExpectNil(promoteError, 'no error on promotion')
    GCTest.ExpectEqual(session.source, 12, 'session source is the final source')
    GCTest.ExpectEqual(session.playerName, 'TestPlayer2', 'session player name is correct')
    GCTest.ExpectEqual(session.primaryIdentifier, 'license:test-license-456', 'primary identifier is correct')

    -- RU: Старая pending запись по temporary source удалена.
    -- EN: The old pending entry by temporary source is removed.
    local oldPending = GCSessions.GetPendingConnection(60001)
    GCTest.ExpectNil(oldPending, 'old pending connection is removed after promotion')

    -- RU: Активная сессия доступна по final source.
    -- EN: The active session is available by the final source.
    local activeSession = GCSessions.Get(12)
    GCTest.ExpectNotNil(activeSession, 'active session is retrieved by final source')

    GCSessions.Remove(12, 'test_cleanup')
end)

-- RU: Тест миграции без pending connection.
-- EN: Test of promotion without a pending connection.
GCTest.Register('sessions.promote_no_pending', function()
    local session, errorCode = GCSessions.PromotePendingConnection(60002, 13)

    GCTest.ExpectNil(session, 'no session promoted without a pending connection')
    GCTest.ExpectNotNil(errorCode, 'error code is returned without a pending connection')
end)

-- RU: Тест истечения pending connection.
-- EN: Test of pending connection expiration.
GCTest.Register('sessions.pending_expired', function()
    local identifiers = {
        license = 'license:test-license-567'
    }

    local pending, _ = GCSessions.CreatePendingConnection(60003, 'TestPlayer3', identifiers, 'license:test-license-567', 'license')

    -- RU: Устанавливаем прошедшее время истечения.
    -- EN: Set a past expiration time.
    pending.expiresAt = GCUtils.NowSec() - 10

    GCTest.ExpectTrue(GCSessions.IsPendingExpired(pending), 'expired pending connection is detected')

    GCSessions.RemovePendingConnection(60003)
end)

-- RU: Тест безопасного публичного DTO.
-- EN: Test of the safe public DTO.
GCTest.Register('sessions.public_dto', function()
    local identifiers = {
        license = 'license:test-license-678'
    }

    local pending, _ = GCSessions.CreatePendingConnection(60004, 'TestPlayer4', identifiers, 'license:test-license-678', 'license')
    local session, _ = GCSessions.PromotePendingConnection(60004, 14)

    GCTest.ExpectNotNil(session, 'session is created for DTO test')

    -- RU: Помечаем lastPed.
    -- EN: Mark the lastPed.
    session.lastPed = 'a_m_y_business_01'

    local dto = GCSessions.GetPublicDTO(14)

    GCTest.ExpectNotNil(dto, 'public DTO is returned')
    GCTest.ExpectEqual(dto.source, 14, 'DTO source is correct')
    GCTest.ExpectEqual(dto.state, 'connecting', 'DTO state is correct')
    GCTest.ExpectEqual(dto.lastPed, 'a_m_y_business_01', 'DTO lastPed is present')
    GCTest.ExpectNil(dto.identifiers, 'DTO does not expose identifiers')
    GCTest.ExpectNil(dto.primaryIdentifier, 'DTO does not expose primary identifier')
    GCTest.ExpectNil(dto.spawnDecision, 'DTO does not expose spawn decision')

    GCSessions.Remove(14, 'test_cleanup')
end)

-- RU: Тест существования сессии.
-- EN: Test of session existence.
GCTest.Register('sessions.exists', function()
    local identifiers = {
        license = 'license:test-license-202'
    }

    local pending, _ = GCSessions.CreatePendingConnection(60005, 'TestPlayer5', identifiers, 'license:test-license-202', 'license')
    GCSessions.PromotePendingConnection(60005, 15)

    GCTest.ExpectTrue(GCSessions.Exists(15), 'session exists')
    GCTest.ExpectFalse(GCSessions.Exists(999), 'non-existent session does not exist')

    GCSessions.Remove(15, 'test_cleanup')
end)

-- RU: Тест поиска сессии по идентификатору.
-- EN: Test of finding a session by identifier.
GCTest.Register('sessions.get_by_identifier', function()
    local identifiers = {
        license = 'license:test-license-303'
    }

    local pending, _ = GCSessions.CreatePendingConnection(60006, 'TestPlayer6', identifiers, 'license:test-license-303', 'license')
    GCSessions.PromotePendingConnection(60006, 16)

    local session = GCSessions.GetByIdentifier('license:test-license-303')

    GCTest.ExpectNotNil(session, 'session is found by identifier')
    GCTest.ExpectEqual(session.source, 16, 'found session source is correct')

    GCSessions.Remove(16, 'test_cleanup')
end)

-- RU: Тест создания восстановленной (recovered) сессии.
-- EN: Test of creating a recovered session.
GCTest.Register('sessions.create_recovered', function()
    local identifiers = {
        license = 'license:test-license-777'
    }

    local session, errorCode = GCSessions.CreateRecoveredSession(30, 'RecoveredPlayer', identifiers, 'license:test-license-777', 'license')

    GCTest.ExpectNotNil(session, 'recovered session is created')
    GCTest.ExpectNil(errorCode, 'no error on recovered session creation')
    GCTest.ExpectEqual(session.state, 'resyncing', 'recovered session starts in resyncing')
    GCTest.ExpectTrue(session.recovered, 'recovered flag is set')
    GCTest.ExpectEqual(session.source, 30, 'recovered session source is correct')

    GCSessions.Remove(30, 'test_cleanup')
end)

-- RU: Тест проверки использования идентификатора.
-- EN: Test of identifier-in-use check.
GCTest.Register('sessions.is_identifier_in_use', function()
    local identifiers = {
        license = 'license:test-license-888'
    }

    -- RU: Идентификатор ещё не используется.
    -- EN: The identifier is not yet in use.
    GCTest.ExpectFalse(GCSessions.IsIdentifierInUse('license:test-license-888'), 'identifier is not in use initially')

    local pending, _ = GCSessions.CreatePendingConnection(60007, 'TestPlayer7', identifiers, 'license:test-license-888', 'license')

    -- RU: Теперь идентификатор занят pending connection.
    -- EN: The identifier is now used by the pending connection.
    GCTest.ExpectTrue(GCSessions.IsIdentifierInUse('license:test-license-888'), 'identifier is in use after pending creation')

    GCSessions.RemovePendingConnection(60007)
end)

-- RU: FiveM передаёт oldID события playerJoining строкой.
-- EN: FiveM passes the playerJoining oldID as a string.
GCTest.Register('sessions.promote.string_temporary_source', function()
    local identifiers = {
        license = 'license:test-license-string-source'
    }

    GCSessions.CreatePendingConnection(60012, 'StringSourcePlayer', identifiers, identifiers.license, 'license')
    local session, errorCode = GCSessions.PromotePendingConnection('60012', '17')

    GCTest.ExpectNotNil(session, 'string temporary source is promoted')
    GCTest.ExpectNil(errorCode, 'string source promotion has no error')
    GCTest.ExpectEqual(session and session.source, 17, 'string final source is normalized')

    GCSessions.Remove(17, 'test_cleanup')
end)
