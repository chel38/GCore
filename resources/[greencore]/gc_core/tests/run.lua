-- RU: Точка входа для запуска тестов GreenCore.
-- EN: Entry point for running GreenCore tests.

-- RU: Этот файл загружается последним среди тестовых файлов.
-- EN: This file is loaded last among the test files.

-- RU: Тесты НЕ запускаются автоматически при обычном запуске gc_core.
-- RU: Они запускаются ТОЛЬКО если явно включены: config GCConfig.Tests.enabled
-- RU: или серверный convar gc_runTests (например, set gc_runTests 1).
-- EN: Tests do NOT run automatically on a normal gc_core startup.
-- EN: They run ONLY if explicitly enabled: config GCConfig.Tests.enabled or the
-- EN: server convar gc_runTests (e.g., set gc_runTests 1).

-- RU: Определяем, включены ли тесты.
-- EN: Determine whether tests are enabled.
local testsEnabled = false

-- RU: Проверяем конфигурацию.
-- EN: Check the configuration.
if GCConfig.Tests and GCConfig.Tests.enabled then
    testsEnabled = true
end

-- RU: Проверяем convar (gc_runTests).
-- EN: Check the convar (gc_runTests).
local convarName = 'gc_runTests'

if GCConfig.Tests and type(GCConfig.Tests.convar) == 'string' then
    convarName = GCConfig.Tests.convar
end

if GetConvarInt(convarName, 0) == 1 then
    testsEnabled = true
end

-- RU: Запускаем тесты, только если они явно включены.
-- EN: Run tests only if they are explicitly enabled.
if testsEnabled then
    GCTest.Run()
else
    GCLogger.Debug('GC-TEST-100', 'Tests skipped (not explicitly enabled)')
end