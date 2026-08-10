-- EN: Standalone entry point for tests owned by independent GCore modules.
-- RU: Автономная точка входа для тестов независимых модулей GCore.

local repoRoot = arg[1] or '.'
local moduleName = arg[2]

if type(moduleName) ~= 'string' or not moduleName:match('^gc_[a-z0-9_]+$') then
    io.stderr:write('Usage: lua tools/module_test_harness.lua <repo-root> <gc_module>\n')
    os.exit(2)
end

local separator = package.config:sub(1, 1)
local resourceRoot = table.concat({
    repoRoot,
    'resources',
    '[greencore]',
    moduleName
}, separator) .. separator

GCModuleTest = {
    moduleName = moduleName,
    resourceRoot = resourceRoot,
    registered = {},
    assertions = 0,
    passed = 0,
    failed = 0
}

function GCModuleTest.Load(relativePath)
    local path = resourceRoot .. relativePath:gsub('/', separator)
    local file, openError = io.open(path, 'rb')

    if not file then
        error(('Unable to open %s: %s'):format(path, openError))
    end

    local source = file:read('*a')
    file:close()

    source = source:gsub('`([^`\r\n]+)`', '0')
    local chunk, loadError = load(source, '@' .. relativePath, 't', _ENV)

    if not chunk then
        error(('Unable to compile %s: %s'):format(relativePath, loadError))
    end

    return chunk()
end

function GCModuleTest.Register(name, category, fn)
    table.insert(GCModuleTest.registered, {
        name = name,
        category = category or 'unit',
        fn = fn
    })
end

function GCModuleTest.ExpectEqual(actual, expected, message)
    GCModuleTest.assertions = GCModuleTest.assertions + 1

    if actual == expected then
        GCModuleTest.passed = GCModuleTest.passed + 1
        print(('[PASS] %s'):format(message))
        return
    end

    GCModuleTest.failed = GCModuleTest.failed + 1
    print(('[FAIL] %s | expected=%s actual=%s'):format(
        message,
        tostring(expected),
        tostring(actual)
    ))
end

function GCModuleTest.ExpectTrue(value, message)
    GCModuleTest.ExpectEqual(value == true, true, message)
end

function GCModuleTest.ExpectFalse(value, message)
    GCModuleTest.ExpectEqual(value == false, true, message)
end

function GCModuleTest.ExpectNil(value, message)
    GCModuleTest.ExpectEqual(value == nil, true, message)
end

function GCModuleTest.ExpectNotNil(value, message)
    GCModuleTest.ExpectEqual(value ~= nil, true, message)
end

function GCModuleTest.Run()
    print(('=== GCore Module Test Runner: %s ==='):format(moduleName))

    for _, test in ipairs(GCModuleTest.registered) do
        print(('--- Running [%s]: %s ---'):format(test.category, test.name))
        local ok, runError = pcall(test.fn)

        if not ok then
            GCModuleTest.assertions = GCModuleTest.assertions + 1
            GCModuleTest.failed = GCModuleTest.failed + 1
            print(('[ERROR] %s | %s'):format(test.name, tostring(runError)))
        end
    end

    print(('Total: %d | Passed: %d | Failed: %d'):format(
        GCModuleTest.assertions,
        GCModuleTest.passed,
        GCModuleTest.failed
    ))

    return GCModuleTest.failed == 0
end

GCModuleTest.Load('tests/run.lua')

if not GCModuleTest.Run() then
    os.exit(1)
end
