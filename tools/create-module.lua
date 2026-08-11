local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/create-module.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools'
package.path = scriptDirectory .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local FS = require('gcore_fs')
local Json = require('gcore_json')
local Generator = require('gcore_generator')

local options = { type = 'domain' }
local output = FS.Join(scriptDirectory, '..', 'resources', '[greencore]')
local dryRun, json = false, false

for index = 1, #arg do
    local value = arg[index]
    local key, item = value:match('^%-%-([%w%-]+)=(.+)$')
    if not options.name and value:sub(1, 2) ~= '--' then options.name = value
    elseif value == '--client' then options.client = true
    elseif value == '--nui' then options.nui = true
    elseif value == '--third-party' then options.thirdParty = true
    elseif value == '--sdk' then options.sdk = true
    elseif value == '--dry-run' then dryRun = true
    elseif value == '--json' then json = true
    elseif key == 'type' then options.type = item
    elseif key == 'output' then output = item
    elseif key == 'author' then options.author = item
    elseif key == 'description' then options.description = item
    elseif key == 'api' then
        options.api = tonumber(item)
        if not options.api then
            io.stderr:write('GC-GENERATOR-API-INVALID\n')
            os.exit(1)
        end
    else
        io.stderr:write('Usage: lua tools/create-module.lua <name> [--type=domain] [--api=1] [--client] [--nui] [--third-party] [--sdk] [--output=path] [--dry-run] [--json]\n')
        os.exit(2)
    end
end

if not options.name then
    io.stderr:write('Module name is required.\n')
    os.exit(2)
end

local templateRoot = FS.Join(scriptDirectory, 'templates', 'module')
local plan, planError = Generator.BuildPlan(options, templateRoot)
if not plan then
    io.stderr:write(tostring(planError) .. '\n')
    os.exit(1)
end

if dryRun then
    local files = {}
    for path in pairs(plan) do files[#files + 1] = path end
    table.sort(files)
    if json then io.write(Json.Encode({ module = options.name, files = files }, true))
    else
        print(('GCore module plan: %s'):format(options.name))
        for _, path in ipairs(files) do print('  ' .. path) end
    end
    os.exit(0)
end

local destination, generateError = Generator.Generate(options, templateRoot, output)
if not destination then
    io.stderr:write(tostring(generateError) .. '\n')
    os.exit(1)
end
print(('Created GCore module: %s'):format(destination))
