GCEcosystemMetadata = {}

local moduleTypes = {
    reference = true,
    domain = true,
    infrastructure = true,
    integration = true,
    developer = true
}

local function values(resource, key)
    local result = {}
    local count = GetNumResourceMetadata(resource, key) or 0
    for index = 0, count - 1 do
        local value = GetResourceMetadata(resource, key, index)
        if type(value) == 'string' then result[#result + 1] = value end
    end
    return result
end

local function first(resource, key)
    local result = values(resource, key)
    return result[1], #result
end

local function validResourceName(value)
    return type(value) == 'string' and value:match('^[a-z0-9][a-z0-9_%-]*$') ~= nil
end

local function validSemver(value)
    if type(value) ~= 'string' then return false end
    return value:match('^%d+%.%d+%.%d+$') ~= nil
        or value:match('^%d+%.%d+%.%d+%-[0-9A-Za-z][0-9A-Za-z%.%-]*$') ~= nil
end

local function validCapability(value)
    return type(value) == 'string' and value:match('^[a-z0-9][a-z0-9%-]*$') ~= nil
end

local function parseDependencies(resource, key, descriptor)
    local result = {}
    for _, raw in ipairs(values(resource, key)) do
        local dependency = GCEcosystemUtils.ParseDependency(raw)
        if dependency then result[#result + 1] = dependency
        else
            GCEcosystemUtils.AddIssue(
                descriptor,
                'GC-ECOSYSTEM-METADATA-INVALID',
                ('%s=%s'):format(key, tostring(raw))
            )
        end
    end
    return result
end

function GCEcosystemMetadata.IsModule(resource)
    local marker = first(resource, 'gcore_module')
    return marker == 'yes'
end

function GCEcosystemMetadata.Read(resource, stateOverride)
    local marker, markerCount = first(resource, 'gcore_module')
    local name, nameCount = first(resource, 'name')
    local author, authorCount = first(resource, 'author')
    local description, descriptionCount = first(resource, 'description')
    local version, versionCount = first(resource, 'version')
    local contractRaw, contractCount = first(resource, 'gcore_contract')
    local typeValue, typeCount = first(resource, 'gcore_type')
    local apiRaw, apiCount = first(resource, 'gcore_api')
    local coreRaw, coreCount = first(resource, 'gcore_requires_core_api')
    local rawCapabilities = values(resource, 'gcore_capability')
    local descriptor = {
        resource = resource,
        name = name,
        author = author,
        description = description,
        version = version,
        type = typeValue,
        contractVersion = GCEcosystemUtils.PositiveInteger(contractRaw),
        apiVersion = GCEcosystemUtils.PositiveInteger(apiRaw),
        requiredCoreApi = GCEcosystemUtils.PositiveInteger(coreRaw),
        capabilities = GCEcosystemUtils.SortUnique(rawCapabilities),
        requiredModules = {},
        optionalModules = {},
        state = stateOverride or GetResourceState(resource),
        compatible = false,
        status = 'discovered',
        issues = {}
    }

    local requiredSingle = {
        gcore_module = markerCount,
        name = nameCount,
        author = authorCount,
        description = descriptionCount,
        version = versionCount,
        gcore_contract = contractCount,
        gcore_type = typeCount,
        gcore_requires_core_api = coreCount
    }
    for key, count in pairs(requiredSingle) do
        if count ~= 1 then
            GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-METADATA-INVALID', key)
        end
    end
    if apiCount > 1 then
        GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-METADATA-INVALID', 'gcore_api')
    end
    if marker ~= 'yes' or name ~= resource or not validResourceName(name)
        or type(author) ~= 'string' or author == ''
        or type(description) ~= 'string' or description == ''
        or not validSemver(version) or not moduleTypes[typeValue]
        or not descriptor.contractVersion or not descriptor.requiredCoreApi then
        GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-METADATA-INVALID', resource)
    end
    if apiRaw ~= nil and not descriptor.apiVersion then
        GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-METADATA-INVALID', 'gcore_api')
    end
    local seenCapabilities = {}
    for _, capability in ipairs(rawCapabilities) do
        if not validCapability(capability) or seenCapabilities[capability] then
            GCEcosystemUtils.AddIssue(
                descriptor,
                'GC-ECOSYSTEM-METADATA-INVALID',
                'gcore_capability=' .. tostring(capability)
            )
        end
        seenCapabilities[capability] = true
    end
    if descriptor.contractVersion ~= GCEcosystemVersion.contract then
        GCEcosystemUtils.AddIssue(
            descriptor,
            'GC-ECOSYSTEM-CONTRACT-UNSUPPORTED',
            tostring(descriptor.contractVersion)
        )
    end

    descriptor.requiredModules = parseDependencies(resource, 'gcore_requires', descriptor)
    descriptor.optionalModules = parseDependencies(resource, 'gcore_optional', descriptor)
    for _, dependency in ipairs(descriptor.requiredModules) do
        if dependency.resource == resource then
            GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-DEPENDENCY-SELF', resource)
        end
    end
    return descriptor
end
