local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/run-module-suite.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools'
package.path = scriptDirectory .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local FS = require('gcore_fs')
local Discovery = require('gcore_discovery')

local root = arg[1] or '.'
local modules, discoveryError = Discovery.Find(root)
if not modules then
    io.stderr:write(tostring(discoveryError) .. '\n')
    os.exit(1)
end

local function run(script, ...)
    local command = 'lua ' .. FS.ShellQuote(FS.Join(scriptDirectory, script))
    for _, value in ipairs({ ... }) do command = command .. ' ' .. FS.ShellQuote(value) end
    local ok, _, code = os.execute(command)
    return ok == true or ok == 0 or code == 0
end

for _, module in ipairs(modules) do
    print(('=== Conformance + tests: %s ==='):format(module.descriptor.resource))
    if not run('module_conformance.lua', module.path, '--quiet')
        or not run('module_test_harness.lua', root, module.path) then
        os.exit(1)
    end
end

print(('All %d discovered module suites passed.'):format(#modules))
