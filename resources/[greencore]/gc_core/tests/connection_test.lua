-- RU: Тесты подключения GreenCore.
-- EN: GreenCore connection tests.

-- RU: Тест маскировки идентификатора.
-- EN: Test of identifier masking.
GCTest.Register('connection.mask_identifier', function()
    local masked = GCIdentifiers.Mask('license:12ab34cd56ef7890')

    GCTest.ExpectNotNil(masked, 'identifier is masked')
    GCTest.ExpectTrue(masked:find('^license:'), 'masked identifier keeps type prefix')
    GCTest.ExpectFalse(masked:find('12ab34cd56ef7890'), 'masked identifier hides full value')
end)

-- RU: Тест маскировки короткого идентификатора.
-- EN: Test of masking a short identifier.
GCTest.Register('connection.mask_short_identifier', function()
    local masked = GCIdentifiers.Mask('license:abc')

    GCTest.ExpectNotNil(masked, 'short identifier is masked')
    GCTest.ExpectTrue(masked:find('^license:'), 'short masked identifier keeps type prefix')
end)

-- RU: Тест маскировки невалидного идентификатора.
-- EN: Test of masking an invalid identifier.
GCTest.Register('connection.mask_invalid_identifier', function()
    local masked = GCIdentifiers.Mask(123)

    GCTest.ExpectEqual(masked, '<invalid>', 'invalid identifier returns <invalid>')
end)

-- RU: Тест сравнения идентификаторов.
-- EN: Test of identifier comparison.
GCTest.Register('connection.compare_identifiers', function()
    GCTest.ExpectTrue(GCIdentifiers.Compare('license:abc', 'license:abc'), 'equal identifiers match')
    GCTest.ExpectFalse(GCIdentifiers.Compare('license:abc', 'license:def'), 'different identifiers do not match')
    GCTest.ExpectFalse(GCIdentifiers.Compare(nil, 'license:abc'), 'nil identifier does not match')
end)

-- RU: Тест получения основного идентификатора.
-- EN: Test of getting the primary identifier.
GCTest.Register('connection.get_primary', function()
    -- RU: Создаём тестовую сессию с license.
    -- EN: Create a test session with license.
    local identifiers = {
        license = 'license:test-primary-1'
    }

    GCSessions.Create(10, 'TestPlayer10', identifiers)

    local session = GCSessions.Get(10)

    GCTest.ExpectNotNil(session, 'session is created')
    GCTest.ExpectEqual(session.primaryIdentifierType, 'license', 'primary type is license')
    GCTest.ExpectEqual(session.primaryIdentifier, 'license:test-primary-1', 'primary identifier is correct')

    GCSessions.Remove(10, 'test_cleanup')
end)

-- RU: Тест получения запасного идентификатора.
-- EN: Test of getting the fallback identifier.
GCTest.Register('connection.get_fallback', function()
    -- RU: Создаём тестовую сессию только с license2.
    -- EN: Create a test session with only license2.
    local identifiers = {
        license2 = 'license2:test-fallback-1'
    }

    GCSessions.Create(11, 'TestPlayer11', identifiers)

    local session = GCSessions.Get(11)

    GCTest.ExpectNotNil(session, 'session is created')
    GCTest.ExpectEqual(session.primaryIdentifierType, 'license2', 'primary type is license2')
    GCTest.ExpectEqual(session.primaryIdentifier, 'license2:test-fallback-1', 'fallback identifier is correct')

    GCSessions.Remove(11, 'test_cleanup')
end)