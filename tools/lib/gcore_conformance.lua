local FS = require('gcore_fs')
local Manifest = require('gcore_manifest')

local Conformance = {}

Conformance.ContractVersion = 1
Conformance.ModuleTypes = {
    reference = true,
    domain = true,
    infrastructure = true,
    integration = true,
    developer = true
}

Conformance.CoreApiV1 = {
    GetVersion = true,
    GetVersionString = true,
    GetApiVersion = true,
    GetProtocolVersion = true,
    GetSpawnMode = true,
    IsPlayerConnected = true,
    IsPlayerReady = true,
    IsPlayerSpawned = true,
    GetPlayerState = true,
    GetPlayerSession = true,
    GetPlayerIdentifier = true,
    CanUseGameplayFeatures = true,
    RequestPlayerSpawn = true,
    NotifyPlayer = true,
    NotifyAll = true
}

local function addIssue(result, code, message, path)
    result.issues[#result.issues + 1] = {
        code = code,
        message = message,
        path = path
    }
end

local function exactlyOne(metadata, key, result)
    local values = metadata[key] or {}
    if #values == 0 then
        addIssue(result, 'GC-CONFORMANCE-METADATA-MISSING', 'Missing metadata: ' .. key, 'fxmanifest.lua')
        return nil
    end
    if #values > 1 then
        addIssue(result, 'GC-CONFORMANCE-METADATA-DUPLICATE', 'Metadata must occur once: ' .. key, 'fxmanifest.lua')
    end
    return values[1]
end

local function validResourceName(value)
    return type(value) == 'string'
        and value:match('^[a-z0-9][a-z0-9_%-]*$') ~= nil
end

local function validCapability(value)
    return type(value) == 'string'
        and value:match('^[a-z0-9][a-z0-9%-]*$') ~= nil
end

local function set(values)
    local result = {}
    for _, value in ipairs(values or {}) do result[value] = true end
    return result
end

local function scanSource(modulePath, result, knownExports)
    local files = FS.ListFiles(modulePath) or {}

    for _, path in ipairs(files) do
        if path:match('%.lua$') then
            local source = FS.ReadFile(path) or ''
            local relative = FS.Relative(modulePath, path)

            if source:match('%f[%w](GCSessions)%f[%W]')
                or source:match('%f[%w](GCStates)%f[%W]')
                or source:match('%f[%w](GCSpawn)%f[%W]')
                or source:match('%f[%w](GCPlayers)%f[%W]') then
                addIssue(
                    result,
                    'GC-CONFORMANCE-CORE-INTERNAL',
                    'Module references a private gc_core global',
                    relative
                )
            end

            local normalized = source:gsub('\\', '/')
            if normalized:match('%.%./+gc_core')
                or normalized:match('@gc_core/')
                or normalized:match('gc_core/server/') then
                addIssue(
                    result,
                    'GC-CONFORMANCE-CORE-PRIVATE-PATH',
                    'Module imports a private gc_core path',
                    relative
                )
            end

            local patterns = {
                "exports%s*%[%s*['\"]gc_core['\"]%s*%]%s*:%s*([%w_]+)%s*%(",
                'exports%.gc_core%s*:%s*([%w_]+)%s*%('
            }
            for _, pattern in ipairs(patterns) do
                for method in source:gmatch(pattern) do
                    if not knownExports[method] then
                        addIssue(
                            result,
                            'GC-CONFORMANCE-CORE-EXPORT-UNKNOWN',
                            'Unknown gc_core export: ' .. method,
                            relative
                        )
                    end
                end
            end
        end
    end
end

local function validateManifestFiles(modulePath, metadata, result)
    local fileKeys = {
        'shared_script', 'shared_scripts',
        'server_script', 'server_scripts',
        'client_script', 'client_scripts',
        'ui_page'
    }

    for _, key in ipairs(fileKeys) do
        for _, declaredPath in ipairs(metadata[key] or {}) do
            local external = declaredPath:sub(1, 1) == '@'
            local normalized = declaredPath:gsub('\\', '/')
            local unsafe = normalized:sub(1, 1) == '/'
                or normalized:match('^%a:/') ~= nil
                or normalized:match('^%.%./') ~= nil
                or normalized:match('/%.%./') ~= nil
            if not external and unsafe then
                addIssue(
                    result,
                    'GC-CONFORMANCE-MANIFEST-PATH-UNSAFE',
                    ('Manifest %s contains an unsafe resource path: %s'):format(key, declaredPath),
                    'fxmanifest.lua'
                )
            end
            local wildcard = declaredPath:find('*', 1, true) or declaredPath:find('?', 1, true)
            if not external and not unsafe and not wildcard
                and not FS.IsFile(FS.Join(modulePath, declaredPath)) then
                addIssue(
                    result,
                    'GC-CONFORMANCE-MANIFEST-FILE-MISSING',
                    ('Manifest %s points to a missing file: %s'):format(key, declaredPath),
                    'fxmanifest.lua'
                )
            end
        end
    end
end

function Conformance.Validate(modulePath, options)
    options = options or {}
    local resource = FS.Basename(modulePath)
    local result = {
        ok = false,
        module = resource,
        path = FS.Normalize(modulePath),
        issues = {},
        descriptor = nil
    }
    local manifestPath = FS.Join(modulePath, 'fxmanifest.lua')
    local source, readError = FS.ReadFile(manifestPath)

    if not source then
        addIssue(result, 'GC-CONFORMANCE-MANIFEST-MISSING', readError or 'fxmanifest.lua is missing', 'fxmanifest.lua')
        return result
    end

    local metadata = Manifest.Parse(source)
    local requiredKeys = {
        'name', 'author', 'description', 'version', 'gcore_module',
        'gcore_contract', 'gcore_type', 'gcore_requires_core_api'
    }
    for _, key in ipairs(requiredKeys) do exactlyOne(metadata, key, result) end

    for key in pairs(metadata) do
        if key:match('^gcore_') and not Manifest.KnownGCoreKeys[key] then
            addIssue(result, 'GC-CONFORMANCE-METADATA-RESERVED', 'Unknown reserved metadata: ' .. key, 'fxmanifest.lua')
        end
    end

    local descriptor = Manifest.Descriptor(metadata, resource)
    result.descriptor = descriptor

    if Manifest.First(metadata, 'gcore_module') ~= 'yes' then
        addIssue(result, 'GC-CONFORMANCE-MODULE-MARKER', "gcore_module must be 'yes'", 'fxmanifest.lua')
    end
    if descriptor.name ~= resource or not validResourceName(descriptor.name) then
        addIssue(result, 'GC-CONFORMANCE-NAME-INVALID', 'Manifest name must match the resource directory', 'fxmanifest.lua')
    end
    if not Manifest.IsSemver(descriptor.version) then
        addIssue(result, 'GC-CONFORMANCE-VERSION-INVALID', 'version must be SemVer', 'fxmanifest.lua')
    end
    if descriptor.contractVersion ~= Conformance.ContractVersion then
        addIssue(result, 'GC-CONFORMANCE-CONTRACT-UNSUPPORTED', 'Unsupported Module Contract version', 'fxmanifest.lua')
    end
    if not Conformance.ModuleTypes[descriptor.type] then
        addIssue(result, 'GC-CONFORMANCE-TYPE-INVALID', 'Unknown gcore_type', 'fxmanifest.lua')
    end
    if not descriptor.requiredCoreApi then
        addIssue(result, 'GC-CONFORMANCE-CORE-API-INVALID', 'gcore_requires_core_api must be a positive integer', 'fxmanifest.lua')
    end

    local dependencies = set(descriptor.fiveMDependencies)
    if not dependencies.gc_core then
        addIssue(result, 'GC-CONFORMANCE-CORE-DEPENDENCY-MISSING', "dependency 'gc_core' is required", 'fxmanifest.lua')
    end

    local capabilitySet = {}
    for _, capability in ipairs(descriptor.capabilities) do
        if not validCapability(capability) then
            addIssue(result, 'GC-CONFORMANCE-CAPABILITY-INVALID', 'Invalid capability: ' .. tostring(capability), 'fxmanifest.lua')
        elseif capabilitySet[capability] then
            addIssue(result, 'GC-CONFORMANCE-CAPABILITY-DUPLICATE', 'Duplicate capability: ' .. capability, 'fxmanifest.lua')
        end
        capabilitySet[capability] = true
    end

    for _, dependency in ipairs(descriptor.requiredModules) do
        if not dependency.resource then
            addIssue(result, 'GC-CONFORMANCE-DEPENDENCY-GRAMMAR', 'Invalid gcore_requires grammar: ' .. tostring(dependency.raw), 'fxmanifest.lua')
        elseif dependency.resource == resource then
            addIssue(result, 'GC-CONFORMANCE-DEPENDENCY-SELF', 'A module cannot require itself', 'fxmanifest.lua')
        elseif not dependencies[dependency.resource] then
            addIssue(result, 'GC-CONFORMANCE-DEPENDENCY-DECLARATION', 'Required module lacks FiveM dependency: ' .. dependency.resource, 'fxmanifest.lua')
        end
    end
    for _, dependency in ipairs(descriptor.optionalModules) do
        if not dependency.resource then
            addIssue(result, 'GC-CONFORMANCE-OPTIONAL-GRAMMAR', 'Invalid gcore_optional grammar: ' .. tostring(dependency.raw), 'fxmanifest.lua')
        end
    end

    for _, requiredPath in ipairs({ 'README.md', 'README.ru.md', 'shared/version.lua', 'tests/run.lua' }) do
        if not FS.IsFile(FS.Join(modulePath, requiredPath)) then
            addIssue(result, 'GC-CONFORMANCE-FILE-MISSING', 'Required file is missing: ' .. requiredPath, requiredPath)
        end
    end

    local versionSource = FS.ReadFile(FS.Join(modulePath, 'shared/version.lua'))
    if versionSource then
        local sourceVersion, sourceApi = Manifest.VersionFromSource(versionSource)
        if sourceVersion ~= descriptor.version then
            addIssue(result, 'GC-CONFORMANCE-VERSION-MISMATCH', 'shared/version.lua does not match manifest version', 'shared/version.lua')
        end
        if descriptor.apiVersion and sourceApi ~= descriptor.apiVersion then
            addIssue(result, 'GC-CONFORMANCE-API-MISMATCH', 'shared/version.lua does not match gcore_api', 'shared/version.lua')
        end
    end

    validateManifestFiles(modulePath, metadata, result)
    scanSource(modulePath, result, options.knownCoreExports or Conformance.CoreApiV1)
    result.ok = #result.issues == 0
    return result
end

return Conformance
