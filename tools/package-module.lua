local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/package-module.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools'
package.path = scriptDirectory .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local FS = require('gcore_fs')
local Package = require('gcore_package')

local modulePath
local repoRoot = FS.Normalize(FS.Join(scriptDirectory, '..'))
local output = FS.Join(repoRoot, 'build', 'releases')

for index = 1, #arg do
    local value = arg[index]
    local customOutput = value:match('^%-%-output=(.+)$')
    if customOutput then output = customOutput
    elseif not modulePath then modulePath = value
    else
        io.stderr:write('Usage: lua tools/package-module.lua <module-path> [--output=path]\n')
        os.exit(2)
    end
end

if not modulePath or not FS.Exists(modulePath) then
    io.stderr:write('Module path does not exist.\n')
    os.exit(2)
end

local result, packageError, details = Package.Build(modulePath, output, {
    repoRoot = repoRoot,
    harness = FS.Join(scriptDirectory, 'module_test_harness.lua')
})
if not result then
    io.stderr:write(tostring(packageError) .. '\n')
    if details and details.issues then
        for _, issue in ipairs(details.issues) do io.stderr:write(issue.code .. ': ' .. issue.message .. '\n') end
    end
    os.exit(1)
end

print(('Packaged %d files: %s'):format(result.files, result.archive))
print(('SHA-256: %s'):format(result.checksum))
