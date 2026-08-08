-- RU: Встроенный тестовый раннер GreenCore.
-- EN: GreenCore built-in test runner.

-- RU: Таблица тестового раннера.
-- EN: Test runner table.
GCTest = {}

-- RU: Счётчики результатов тестов.
-- EN: Test result counters.
local passed = 0
local failed = 0
local total = 0

-- RU: Список зарегистрированных тестов.
-- EN: List of registered tests.
local registeredTests = {}

--- RU:
--- Проверяет, что два значения равны.
---
--- EN:
--- Checks that two values are equal.
---
--- @param actual any Actual value
--- @param expected any Expected value
--- @param testName string Test name
function GCTest.ExpectEqual(actual, expected, testName)
    total = total + 1

    if actual == expected then
        passed = passed + 1
        print(('[PASS] %s'):format(testName))
    else
        failed = failed + 1
        print(('[FAIL] %s | expected=%s actual=%s'):format(
            testName,
            tostring(expected),
            tostring(actual)
        ))
    end
end

--- RU:
--- Проверяет, что значение истинно.
---
--- EN:
--- Checks that a value is true.
---
--- @param value any Value to check
--- @param testName string Test name
function GCTest.ExpectTrue(value, testName)
    GCTest.ExpectEqual(value == true, true, testName)
end

--- RU:
--- Проверяет, что значение ложно.
---
--- EN:
--- Checks that a value is false.
---
--- @param value any Value to check
--- @param testName string Test name
function GCTest.ExpectFalse(value, testName)
    GCTest.ExpectEqual(value == false, true, testName)
end

--- RU:
--- Проверяет, что значение равно nil.
---
--- EN:
--- Checks that a value is nil.
---
--- @param value any Value to check
--- @param testName string Test name
function GCTest.ExpectNil(value, testName)
    GCTest.ExpectEqual(value == nil, true, testName)
end

--- RU:
--- Проверяет, что значение не равно nil.
---
--- EN:
--- Checks that a value is not nil.
---
--- @param value any Value to check
--- @param testName string Test name
function GCTest.ExpectNotNil(value, testName)
    GCTest.ExpectEqual(value ~= nil, true, testName)
end

--- RU:
--- Регистрирует тестовую функцию.
---
--- EN:
--- Registers a test function.
---
--- @param testName string Test name
--- @param testFunction function Test function
function GCTest.Register(testName, testFunction)
    table.insert(registeredTests, {
        name = testName,
        fn = testFunction
    })
end

--- RU:
--- Запускает все зарегистрированные тесты.
---
--- EN:
--- Runs all registered tests.
function GCTest.Run()
    print('=== GreenCore Test Runner ===')

    for _, test in ipairs(registeredTests) do
        print(('--- Running: %s ---'):format(test.name))

        local ok, err = pcall(test.fn)

        if not ok then
            failed = failed + 1
            total = total + 1
            print(('[ERROR] %s | %s'):format(test.name, tostring(err)))
        end
    end

    print('=== Results ===')
    print(('Total: %d | Passed: %d | Failed: %d'):format(total, passed, failed))

    if failed == 0 then
        print('ALL TESTS PASSED')
    else
        print('SOME TESTS FAILED')
    end
end