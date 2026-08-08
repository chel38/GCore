-- RU: Tests are loaded only after explicit opt-in; production does not execute them.
-- EN: Tests are loaded only after explicit opt-in; production does not execute them.

local convarName = (GCConfig.Tests and GCConfig.Tests.convar) or 'gc_runTests'
local testsEnabled = GCConfig.Tests and GCConfig.Tests.enabled == true
    or GetConvarInt(convarName, 0) == 1

if testsEnabled then
    local testFiles = {
        'tests/test_runner.lua',
        'tests/validation_test.lua',
        'tests/states_test.lua',
        'tests/sessions_test.lua',
        'tests/connection_test.lua',
        'tests/spawn_test.lua',
        'tests/protocol_test.lua',
        'tests/ped_provider_test.lua',
        'tests/logger_test.lua',
        'tests/rate_limit_test.lua',
        'tests/notifications_test.lua',
        'tests/runtime_test.lua',
        'tests/api_test.lua',
        'tests/run.lua'
    }

    for _, fileName in ipairs(testFiles) do
        local sourceCode = LoadResourceFile(GetCurrentResourceName(), fileName)

        if type(sourceCode) ~= 'string' then
            error(('Unable to load test file %s'):format(fileName))
        end

        local chunk, loadError = load(sourceCode, ('@%s'):format(fileName), 't', _ENV)

        if not chunk then
            error(('Unable to compile test file %s: %s'):format(fileName, loadError))
        end

        chunk()
    end
end
