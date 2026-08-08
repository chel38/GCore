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
    GCTest.ExpectTrue(id1:find('^gc:session:'), 'session id has correct prefix')
end)

-- RU: Тест создания сессии.
-- EN: Test of session creation.
GCTest.Register('sessions.create', function()
    local identifiers = {
        license = 'license:test-license-123'
    }

    local session, errorCode = GCSessions.Create(1, 'TestPlayer', identifiers)

    GCTest.ExpectNotNil(session, 'session is created')
    GCTest.ExpectNil(errorCode, 'no error on session creation')
    GCTest.ExpectEqual(session.source, 1, 'session source is correct')
    GCTest.ExpectEqual(session.playerName, 'TestPlayer', 'session player name is correct')
    GCTest.ExpectEqual(session.state, 'connecting', 'session initial state is connecting')
    GCTest.ExpectEqual(session.primaryIdentifier, 'license:test-license-123', 'primary identifier is correct')

    GCSessions.Remove(1, 'test_cleanup')
end)

-- RU: Тест создания сессии с невалидными данными.
-- EN: Test of session creation with invalid data.
GCTest.Register('sessions.create.invalid', function()
    local session, errorCode = GCSessions.Create('not-a-number', 'TestPlayer', {})

    GCTest.ExpectNil(session, 'session is not created with invalid source')
    GCTest.ExpectNotNil(errorCode, 'error code is returned for invalid source')
end)

-- RU: Тест получения сессии.
-- EN: Test of getting a session.
GCTest.Register('sessions.get', function()
    local identifiers = {
        license = 'license:test-license-456'
    }

    GCSessions.Create(2, 'TestPlayer2', identifiers)

    local session = GCSessions.Get(2)

    GCTest.ExpectNotNil(session, 'session is retrieved by source')
    GCTest.ExpectEqual(session.source, 2, 'retrieved session source is correct')

    GCSessions.Remove(2, 'test_cleanup')
end)

-- RU: Тест копирования сессии.
-- EN: Test of session cloning.
GCTest.Register('sessions.clone', function()
    local identifiers = {
        license = 'license:test-license-789'
    }

    GCSessions.Create(3, 'TestPlayer3', identifiers)

    local clone = GCSessions.Clone(3)

    GCTest.ExpectNotNil(clone, 'session clone is returned')
    GCTest.ExpectEqual(clone.source, 3, 'clone source is correct')

    -- RU: Изменение копии не должно влиять на настоящую сессию.
    -- EN: Modifying the copy must not affect the real session.
    clone.state = 'spawned'

    local realSession = GCSessions.Get(3)

    GCTest.ExpectEqual(realSession.state, 'connecting', 'modifying clone does not affect real session')

    GCSessions.Remove(3, 'test_cleanup')
end)

-- RU: Тест удаления сессии.
-- EN: Test of session removal.
GCTest.Register('sessions.remove', function()
    local identifiers = {
        license = 'license:test-license-101'
    }

    GCSessions.Create(4, 'TestPlayer4', identifiers)

    local removed = GCSessions.Remove(4, 'test_cleanup')

    GCTest.ExpectTrue(removed, 'session is removed')

    local session = GCSessions.Get(4)

    GCTest.ExpectNil(session, 'session no longer exists after removal')
end)

-- RU: Тест существования сессии.
-- EN: Test of session existence.
GCTest.Register('sessions.exists', function()
    local identifiers = {
        license = 'license:test-license-202'
    }

    GCSessions.Create(5, 'TestPlayer5', identifiers)

    GCTest.ExpectTrue(GCSessions.Exists(5), 'session exists')
    GCTest.ExpectFalse(GCSessions.Exists(999), 'non-existent session does not exist')

    GCSessions.Remove(5, 'test_cleanup')
end)

-- RU: Тест поиска сессии по идентификатору.
-- EN: Test of finding a session by identifier.
GCTest.Register('sessions.get_by_identifier', function()
    local identifiers = {
        license = 'license:test-license-303'
    }

    GCSessions.Create(6, 'TestPlayer6', identifiers)

    local session = GCSessions.GetByIdentifier('license:test-license-303')

    GCTest.ExpectNotNil(session, 'session is found by identifier')
    GCTest.ExpectEqual(session.source, 6, 'found session source is correct')

    GCSessions.Remove(6, 'test_cleanup')
end)