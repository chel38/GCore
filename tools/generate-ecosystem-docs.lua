local separator = package.config:sub(1, 1)
local scriptDirectory = (arg[0] or 'tools/generate-ecosystem-docs.lua'):match('^(.*)[\\/][^\\/]+$') or 'tools'
package.path = scriptDirectory .. separator .. 'lib' .. separator .. '?.lua;' .. package.path

local FS = require('gcore_fs')
local Discovery = require('gcore_discovery')
local Catalog = require('gcore_catalog')

local root = '.'
local check = false
for index = 1, #arg do
    if arg[index] == '--check' then check = true else root = arg[index] end
end

local modules, discoveryError = Discovery.Find(root)
if not modules then io.stderr:write(tostring(discoveryError) .. '\n'); os.exit(1) end
local entries = Catalog.Entries(modules)
local graphIssues = Catalog.ValidateGraph(entries)
if #graphIssues > 0 then
    for _, issue in ipairs(graphIssues) do
        io.stderr:write(issue.code .. ': ' .. tostring(issue.module or table.concat(issue.cycle, ' -> ')) .. '\n')
    end
    os.exit(1)
end

local outputs = {
    [FS.Join(root, 'docs', 'generated', 'modules.json')] = Catalog.Json(entries),
    [FS.Join(root, 'docs', 'en', 'ecosystem', 'modules.md')] = Catalog.EnglishModules(entries),
    [FS.Join(root, 'docs', 'ru', 'ecosystem', 'modules.md')] = Catalog.RussianModules(entries),
    [FS.Join(root, 'docs', 'diagrams', 'module-graph.md')] = Catalog.Diagram(entries)
}

local stale = {}
for path, content in pairs(outputs) do
    if check then
        if FS.ReadFile(path) ~= content then stale[#stale + 1] = path end
    else
        local written, writeError = FS.WriteFile(path, content)
        if not written then io.stderr:write(tostring(writeError) .. '\n'); os.exit(1) end
    end
end

if #stale > 0 then
    table.sort(stale)
    for _, path in ipairs(stale) do io.stderr:write('Generated ecosystem file is stale: ' .. path .. '\n') end
    os.exit(1)
end

print(('Ecosystem catalog: %d modules, %s'):format(#entries, check and 'current' or 'generated'))
