local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/discover_modules.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools'
package.path = scriptDirectory .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local Json = require('gcore_json')
local Discovery = require('gcore_discovery')

local root = '.'
local json = false
local nuiOnly = false

for index = 1, #arg do
    local value = arg[index]
    if value == '--json' then json = true
    elseif value == '--nui' then nuiOnly = true
    elseif value:sub(1, 2) == '--' then
        io.stderr:write('Unknown option: ' .. value .. '\n')
        os.exit(2)
    else root = value end
end

local modules, discoveryError = Discovery.Find(root)
if not modules then
    io.stderr:write(tostring(discoveryError) .. '\n')
    os.exit(1)
end

local output = {}
for _, module in ipairs(modules) do
    if not nuiOnly or module.hasNui then
        output[#output + 1] = json and {
            resource = module.descriptor.resource,
            path = module.path,
            hasNui = module.hasNui
        } or module.path
    end
end

if json then io.write(Json.Encode(output, true))
else for _, path in ipairs(output) do print(path) end end
