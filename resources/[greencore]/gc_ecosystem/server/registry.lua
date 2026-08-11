GCEcosystemRegistry = {}

local registry = {}
local graph = { nodes = {}, edges = {} }

local function coreApiVersion()
    if GetResourceState('gc_core') ~= 'started' then return nil end
    local ok, value = pcall(function() return exports['gc_core']:GetApiVersion() end)
    if not ok or type(value) ~= 'number' or value % 1 ~= 0 then return nil end
    return value
end

local function discover(override)
    local descriptors = {}
    local count = GetNumResources() or 0
    for index = 0, count - 1 do
        local resource = GetResourceByFindIndex(index)
        if resource and GCEcosystemMetadata.IsModule(resource) then
            local state = override and override.resource == resource and override.state or nil
            descriptors[#descriptors + 1] = GCEcosystemMetadata.Read(resource, state)
        end
    end
    table.sort(descriptors, function(a, b) return a.resource < b.resource end)
    return descriptors
end

local function evaluate(descriptors)
    local byName = {}
    for _, descriptor in ipairs(descriptors) do byName[descriptor.resource] = descriptor end
    local coreApi = coreApiVersion()

    for _, descriptor in ipairs(descriptors) do
        if descriptor.state == 'stopped' or descriptor.state == 'stopping' then
            GCEcosystemUtils.AddIssue(
                descriptor,
                'GC-ECOSYSTEM-MODULE-STOPPED',
                descriptor.resource
            )
        end

        if not coreApi then
            GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-CORE-UNAVAILABLE')
        elseif descriptor.requiredCoreApi and coreApi < descriptor.requiredCoreApi then
            GCEcosystemUtils.AddIssue(
                descriptor,
                'GC-ECOSYSTEM-CORE-API-INCOMPATIBLE',
                ('required=%d actual=%d'):format(descriptor.requiredCoreApi, coreApi)
            )
        end

        for _, dependency in ipairs(descriptor.requiredModules) do
            local target = byName[dependency.resource]
            if not target then
                GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-DEPENDENCY-MISSING', dependency.resource)
            elseif target.state ~= 'started' then
                GCEcosystemUtils.AddIssue(descriptor, 'GC-ECOSYSTEM-DEPENDENCY-STOPPED', dependency.resource)
            elseif not target.apiVersion or target.apiVersion < dependency.minimumApi then
                GCEcosystemUtils.AddIssue(
                    descriptor,
                    'GC-ECOSYSTEM-MODULE-API-INCOMPATIBLE',
                    dependency.raw
                )
            end
        end
    end

    for _, cycle in ipairs(GCEcosystemGraph.FindCycles(descriptors)) do
        local details = table.concat(cycle, ' -> ')
        local touched = {}
        for _, resource in ipairs(cycle) do
            if byName[resource] and not touched[resource] then
                GCEcosystemUtils.AddIssue(byName[resource], 'GC-ECOSYSTEM-DEPENDENCY-CYCLE', details)
                touched[resource] = true
            end
        end
    end

    for _, descriptor in ipairs(descriptors) do
        descriptor.compatible = #descriptor.issues == 0
        if descriptor.state == 'stopped' or descriptor.state == 'stopping' then
            descriptor.status = 'stopped'
        elseif not descriptor.compatible then
            local missing = false
            for _, issue in ipairs(descriptor.issues) do
                if issue.code == 'GC-ECOSYSTEM-DEPENDENCY-MISSING' then missing = true end
            end
            descriptor.status = missing and 'missing_dependency' or 'incompatible'
        elseif descriptor.state == 'started' then descriptor.status = 'compatible'
        else descriptor.status = 'discovered' end
    end
end

function GCEcosystemRegistry.Refresh(override)
    local descriptors = discover(override)
    evaluate(descriptors)
    registry = {}
    for _, descriptor in ipairs(descriptors) do registry[descriptor.resource] = descriptor end
    graph = GCEcosystemGraph.Build(descriptors)
    return GCEcosystemRegistry.List()
end

function GCEcosystemRegistry.List()
    local result = {}
    for _, descriptor in pairs(registry) do result[#result + 1] = descriptor end
    table.sort(result, function(a, b) return a.resource < b.resource end)
    return GCEcosystemUtils.DeepCopy(result)
end

function GCEcosystemRegistry.Get(resource)
    return GCEcosystemUtils.DeepCopy(registry[resource])
end

function GCEcosystemRegistry.Graph()
    return GCEcosystemUtils.DeepCopy(graph)
end

function GCEcosystemRegistry.CapabilityProviders(capability)
    if type(capability) ~= 'string' or capability == '' then return {} end
    local providers = {}
    for resource, descriptor in pairs(registry) do
        if descriptor.compatible then
            for _, value in ipairs(descriptor.capabilities) do
                if value == capability then providers[#providers + 1] = resource break end
            end
        end
    end
    table.sort(providers)
    return providers
end
