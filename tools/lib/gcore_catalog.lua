local Json = require('gcore_json')
local Graph = require('gcore_graph')

local Catalog = {}

function Catalog.Entries(modules)
    local entries = {}
    for _, module in ipairs(modules) do
        local descriptor = module.descriptor
        entries[#entries + 1] = {
            resource = descriptor.resource,
            name = descriptor.name,
            version = descriptor.version,
            type = descriptor.type,
            contract = descriptor.contractVersion,
            api = descriptor.apiVersion,
            requiresCoreApi = descriptor.requiredCoreApi,
            capabilities = descriptor.capabilities,
            requiredModules = descriptor.requiredModules,
            optionalModules = descriptor.optionalModules
        }
    end
    table.sort(entries, function(a, b) return a.resource < b.resource end)
    return entries
end

function Catalog.ValidateGraph(entries)
    local byName = {}
    local counts = {}
    local issues = {}
    for _, entry in ipairs(entries) do
        byName[entry.resource] = entry
        counts[entry.resource] = (counts[entry.resource] or 0) + 1
    end
    for resource, count in pairs(counts) do
        if count > 1 then
            issues[#issues + 1] = {
                code = 'GC-CATALOG-MODULE-DUPLICATE',
                module = resource
            }
        end
    end
    for _, entry in ipairs(entries) do
        for _, dependency in ipairs(entry.requiredModules or {}) do
            if dependency.resource and not byName[dependency.resource] then
                issues[#issues + 1] = {
                    code = 'GC-CATALOG-DEPENDENCY-MISSING',
                    module = entry.resource,
                    dependency = dependency.resource
                }
            end
        end
    end
    for _, cycle in ipairs(Graph.FindCycles(entries)) do
        issues[#issues + 1] = {
            code = 'GC-CATALOG-DEPENDENCY-CYCLE',
            cycle = cycle
        }
    end
    return issues
end

function Catalog.Json(entries)
    return Json.Encode({
        contractVersion = 1,
        generatedFrom = 'fxmanifest.lua',
        modules = entries
    }, true)
end

local function moduleRows(entries)
    local rows = {}
    for _, entry in ipairs(entries) do
        local capabilities = #entry.capabilities > 0 and table.concat(entry.capabilities, ', ') or '-'
        rows[#rows + 1] = ('| `%s` | `%s` | %s | %s | %d | %s |'):format(
            entry.resource,
            entry.version,
            entry.type,
            entry.api and tostring(entry.api) or '-',
            entry.requiresCoreApi,
            capabilities
        )
    end
    return table.concat(rows, '\n')
end

function Catalog.EnglishModules(entries)
    return [[<!-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY. -->
# Installed GCore modules

Source of truth: Module Standard metadata in each `fxmanifest.lua`.

| Resource | Version | Type | API | Core API >= | Capabilities |
| --- | --- | --- | ---: | ---: | --- |
]] .. moduleRows(entries) .. '\n'
end

function Catalog.RussianModules(entries)
    return [[<!-- ЭТОТ ФАЙЛ СГЕНЕРИРОВАН. НЕ РЕДАКТИРУЙТЕ ВРУЧНУЮ. -->
# Установленные GCore modules

Source of truth: metadata Module Standard в каждом `fxmanifest.lua`.

| Resource | Версия | Тип | API | Core API >= | Capabilities |
| --- | --- | --- | ---: | ---: | --- |
]] .. moduleRows(entries) .. '\n'
end

function Catalog.Diagram(entries)
    local lines = {
        '<!-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY. -->',
        '# GCore module dependency graph',
        '',
        '```mermaid',
        'flowchart BT',
        '    gc_core["gc_core / Public API v1"]'
    }
    for _, entry in ipairs(entries) do
        lines[#lines + 1] = ('    %s["%s %s"]'):format(
            entry.resource:gsub('[^%w_]', '_'),
            entry.resource,
            entry.version
        )
        lines[#lines + 1] = ('    %s -->|"Core API >= %d"| gc_core'):format(
            entry.resource:gsub('[^%w_]', '_'),
            entry.requiresCoreApi
        )
        for _, dependency in ipairs(entry.requiredModules or {}) do
            lines[#lines + 1] = ('    %s -->|"API >= %d"| %s'):format(
                entry.resource:gsub('[^%w_]', '_'),
                dependency.minimumApi,
                dependency.resource:gsub('[^%w_]', '_')
            )
        end
        for _, dependency in ipairs(entry.optionalModules or {}) do
            lines[#lines + 1] = ('    %s -.->|"optional API >= %d"| %s'):format(
                entry.resource:gsub('[^%w_]', '_'),
                dependency.minimumApi,
                dependency.resource:gsub('[^%w_]', '_')
            )
        end
    end
    lines[#lines + 1] = '```'
    lines[#lines + 1] = ''
    return table.concat(lines, '\n')
end

return Catalog
