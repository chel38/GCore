-- RU: Тесты логгера GreenCore.
-- EN: GreenCore logger tests.

-- RU: Тест: логирование с чувствительными данными не вызывает ошибок.
-- RU: Логгер автоматически маскирует license/ip/discord, поэтому вызов не должен
-- RU: падать и не должен выбрасывать исключение.
-- EN: Test: logging with sensitive data does not raise errors.
-- EN: The logger automatically masks license/ip/discord, so the call must not
-- EN: crash or throw an exception.
GCTest.Register('logger.sensitive_data_no_error', function()
    local ok, err = pcall(function()
        GCLogger.Debug('GC-TEST-200', 'Sensitive data log test', {
            source = 1,
            license = 'license:abcdef1234567890abcdef1234567890',
            license2 = 'license2:1234567890abcdef1234567890abcdef',
            ip = '192.168.1.1',
            discord = 'discord:123456789012345678',
            primaryIdentifier = 'license:abcdef1234567890'
        })
    end)

    GCTest.ExpectTrue(ok, 'logging with sensitive data does not raise an error')
    GCTest.ExpectNil(err, 'no error message from sensitive-data logging')
end)

-- RU: Тест: логирование со вложенными таблицами с чувствительными данными.
-- EN: Test: logging with nested tables containing sensitive data.
GCTest.Register('logger.nested_sensitive_data_no_error', function()
    local ok, err = pcall(function()
        GCLogger.Info('GC-TEST-201', 'Nested sensitive data log test', {
            session = {
                identifiers = {
                    license = 'license:abcdef1234567890'
                }
            },
            source = 2
        })
    end)

    GCTest.ExpectTrue(ok, 'logging with nested sensitive data does not raise an error')
    GCTest.ExpectNil(err, 'no error message from nested sensitive-data logging')
end)

-- RU: Тест: логирование без данных.
-- EN: Test: logging without data.
GCTest.Register('logger.no_data_no_error', function()
    local ok, err = pcall(function()
        GCLogger.Info('GC-TEST-202', 'No data log test')
    end)

    GCTest.ExpectTrue(ok, 'logging without data does not raise an error')
    GCTest.ExpectNil(err, 'no error message from no-data logging')
end)

-- RU: Тест: список уровней доступен.
-- EN: Test: the level list is available.
GCTest.Register('logger.levels_available', function()
    GCTest.ExpectNotNil(GCLogger.LEVELS, 'logger levels are exported')
    GCTest.ExpectTrue(GCUtils.Contains(GCLogger.LEVELS, 'DEBUG'), 'DEBUG level is present')
    GCTest.ExpectTrue(GCUtils.Contains(GCLogger.LEVELS, 'ERROR'), 'ERROR level is present')
end)