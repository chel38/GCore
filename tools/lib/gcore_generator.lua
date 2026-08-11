local FS = require('gcore_fs')

local Generator = {}
local moduleTypes = {
    reference = true,
    domain = true,
    infrastructure = true,
    integration = true,
    developer = true
}

local function render(source, values)
    return (source:gsub('{{([A-Z0-9_]+)}}', function(key)
        return values[key] or ''
    end))
end

local function validName(name)
    return type(name) == 'string' and name:match('^[a-z0-9][a-z0-9_%-]*$') ~= nil
end

function Generator.Validate(options)
    if not validName(options.name) then return nil, 'GC-GENERATOR-NAME-INVALID' end
    if not moduleTypes[options.type or 'domain'] then return nil, 'GC-GENERATOR-TYPE-INVALID' end
    if options.thirdParty and options.name:match('^gc_') then
        return nil, 'GC-GENERATOR-OFFICIAL-PREFIX-RESERVED'
    end
    if not options.thirdParty and not options.name:match('^gc_') then
        return nil, 'GC-GENERATOR-THIRD-PARTY-FLAG-REQUIRED'
    end
    if options.api and (type(options.api) ~= 'number' or options.api < 1 or options.api % 1 ~= 0) then
        return nil, 'GC-GENERATOR-API-INVALID'
    end
    for _, value in ipairs({ options.author, options.description }) do
        if value and (type(value) ~= 'string' or value == '' or value:find("['\"\r\n]")) then
            return nil, 'GC-GENERATOR-METADATA-INVALID'
        end
    end
    return true
end

function Generator.BuildPlan(options, templateRoot)
    local valid, validationError = Generator.Validate(options)
    if not valid then return nil, validationError end
    local templateFiles = {
        ['fxmanifest.lua'] = 'fxmanifest.lua.tpl',
        ['README.md'] = 'README.md.tpl',
        ['README.ru.md'] = 'README.ru.md.tpl',
        ['shared/version.lua'] = 'shared/version.lua.tpl',
        ['server/main.lua'] = 'server/main.lua.tpl',
        ['tests/run.lua'] = 'tests/run.lua.tpl'
    }
    if options.client or options.nui then templateFiles['client/main.lua'] = 'client/main.lua.tpl' end
    if options.nui then
        templateFiles['web/index.html'] = 'web/index.html.tpl'
        templateFiles['web/package.json'] = 'web/package.json.tpl'
        templateFiles['web/tsconfig.json'] = 'web/tsconfig.json.tpl'
        templateFiles['web/vite.config.ts'] = 'web/vite.config.ts.tpl'
        templateFiles['web/src/main.ts'] = 'web/src/main.ts.tpl'
        templateFiles['web/src/style.css'] = 'web/src/style.css.tpl'
    end

    local api = options.api
    local values = {
        MODULE_NAME = options.name,
        MODULE_TYPE = options.type or 'domain',
        MODULE_DESCRIPTION = options.description or ('GCore module ' .. options.name),
        MODULE_AUTHOR = options.author or 'Module Author',
        VERSION = options.version or '0.1.0-alpha',
        VERSION_MAJOR = '0',
        VERSION_MINOR = '1',
        VERSION_PATCH = '0',
        VERSION_PRERELEASE = 'alpha',
        GCORE_API_METADATA = api and ("gcore_api '" .. api .. "'\n") or '',
        VERSION_API = api and ("    api = " .. api .. ",\n") or '',
        SDK_METADATA = options.sdk and "gcore_requires 'gc_sdk:api>=1'\n" or '',
        DEPENDENCIES = options.sdk and "dependency 'gc_core'\ndependency 'gc_sdk'"
            or "dependency 'gc_core'",
        CLIENT_MANIFEST = (options.client or options.nui) and "client_script 'client/main.lua'\n" or '',
        NUI_MANIFEST = options.nui and [[
ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}
]] or '',
        CORE_CHECK = options.sdk and [[
local compatible, compatibilityError = exports['gc_sdk']:RequireCoreApi(1)
if not compatible then
    error(('gc_core compatibility failed: %s'):format(tostring(compatibilityError)))
end
]] or [[
if GetResourceState('gc_core') ~= 'started' then
    error('gc_core is not started')
end

local apiVersion = exports['gc_core']:GetApiVersion()
if type(apiVersion) ~= 'number' or apiVersion < 1 then
    error('GCore Core API >= 1 is required')
end
]]
    }

    local plan = {}
    for destination, template in pairs(templateFiles) do
        local source, readError = FS.ReadFile(FS.Join(templateRoot, template))
        if not source then return nil, readError end
        plan[destination] = render(source, values)
    end
    return plan
end

function Generator.Generate(options, templateRoot, destinationRoot)
    local plan, planError = Generator.BuildPlan(options, templateRoot)
    if not plan then return nil, planError end
    local destination = FS.Join(destinationRoot, options.name)
    if FS.Exists(destination) then return nil, 'GC-GENERATOR-DESTINATION-EXISTS' end
    if not FS.MakeDir(destination) then return nil, 'GC-GENERATOR-DESTINATION-CREATE' end
    for relative, content in pairs(plan) do
        local written, writeError = FS.WriteFile(FS.Join(destination, relative), content)
        if not written then return nil, writeError end
    end
    return destination
end

return Generator
