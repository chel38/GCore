-- RU: Точка входа для запуска тестов GreenCore.
-- EN: Entry point for running GreenCore tests.

-- RU: Этот файл загружается последним среди тестовых файлов.
-- EN: This file is loaded last among the test files.

-- RU: Запускаем тесты только в режиме разработки, чтобы не нагружать прод.
-- EN: Run tests only in development mode to avoid loading production.
if GCConfig.General.developmentMode then
    -- RU: Запускаем все зарегистрированные тесты.
    -- EN: Run all registered tests.
    GCTest.Run()
else
    GCLogger.Debug('GC-TEST-100', 'Tests skipped (developmentMode is disabled)')
end