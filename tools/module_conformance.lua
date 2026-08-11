local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/module_conformance.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools'
package.path = scriptDirectory .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local FS = require('gcore_fs')
local Json = require('gcore_json')
local Conformance = require('gcore_conformance')

local modulePath
local json = false
local quiet = false

for index = 1, #arg do
    local value = arg[index]
    if value == '--json' then json = true
    elseif value == '--quiet' then quiet = true
    elseif not modulePath then modulePath = value
    else
        io.stderr:write('Usage: lua tools/module_conformance.lua <module-path> [--json] [--quiet]\n')
        os.exit(2)
    end
end

if not modulePath or not FS.Exists(modulePath) then
    io.stderr:write('Module path does not exist.\n')
    os.exit(2)
end

local knownCoreExports
local coreExportsSource = FS.ReadFile(FS.Join(
    scriptDirectory,
    '..',
    'resources',
    '[greencore]',
    'gc_core',
    'server',
    'exports.lua'
))
if coreExportsSource then
    knownCoreExports = {}
    for name in coreExportsSource:gmatch("exports%s*%(%s*'([^']+)'") do
        knownCoreExports[name] = true
    end
end

local result = Conformance.Validate(modulePath, { knownCoreExports = knownCoreExports })

if json then
    io.write(Json.Encode(result, true))
elseif not quiet then
    print('GCore Module Conformance')
    print(('Module .......... %s'):format(result.module))
    print(('Manifest ........ %s'):format(FS.IsFile(FS.Join(modulePath, 'fxmanifest.lua')) and 'PASS' or 'FAIL'))
    print(('Metadata ........ %s'):format(result.descriptor and 'CHECKED' or 'FAIL'))
    print(('Issues .......... %d'):format(#result.issues))
    for _, issue in ipairs(result.issues) do
        print(('  [%s] %s (%s)'):format(issue.code, issue.message, issue.path or '-'))
    end
    print(('RESULT: %s'):format(result.ok and 'PASS' or 'FAIL'))
end

os.exit(result.ok and 0 or 1)
