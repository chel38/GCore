local resources = {}
local metadata = {}
local states = { gc_core = 'started' }
local handlers = {}
local commands = {}
local coreApi = 1

local function add(resource, options)
    options = options or {}
    resources[#resources + 1] = resource
    states[resource] = options.state or 'started'
    metadata[resource] = {
        name = { options.name or resource },
        author = { 'Test Author' },
        description = { 'Test module' },
        version = { options.version or '0.1.0-alpha' }
    }
    if options.module ~= false then
        metadata[resource].gcore_module = { 'yes' }
        metadata[resource].gcore_contract = options.contract == false and {} or { tostring(options.contract or 1) }
        metadata[resource].gcore_type = { options.type or 'domain' }
        metadata[resource].gcore_requires_core_api = { tostring(options.coreApi or 1) }
        if options.api then metadata[resource].gcore_api = { tostring(options.api) } end
        if options.capabilities then metadata[resource].gcore_capability = options.capabilities end
        if options.required then metadata[resource].gcore_requires = options.required end
        if options.optional then metadata[resource].gcore_optional = options.optional end
    end
end

local function reset()
    resources = {}
    metadata = {}
    states = { gc_core = 'started' }
    coreApi = 1
end

function GetNumResources() return #resources end
function GetResourceByFindIndex(index) return resources[index + 1] end
function GetResourceState(resource) return states[resource] or 'missing' end
function GetNumResourceMetadata(resource, key)
    return #(metadata[resource] and metadata[resource][key] or {})
end
function GetResourceMetadata(resource, key, index)
    return metadata[resource] and metadata[resource][key]
        and metadata[resource][key][index + 1] or nil
end
function GetCurrentResourceName() return 'gc_ecosystem' end
function AddEventHandler(name, callback) handlers[name] = callback end
function RegisterCommand(name, callback) commands[name] = callback end

exports = {
    gc_core = {
        GetApiVersion = function() return coreApi end
    }
}

reset()
add('gc_ecosystem', { type = 'infrastructure', api = 1, capabilities = { 'module-registry' } })
add('gc_example', { type = 'reference', capabilities = { 'public-api-example' } })
add('vendor_identity', { api = 1, capabilities = { 'identity' } })
add('ordinary_resource', { module = false })

GCModuleTest.Load('shared/version.lua')
GCModuleTest.Load('server/utils.lua')
GCModuleTest.Load('server/metadata.lua')
GCModuleTest.Load('server/graph.lua')
GCModuleTest.Load('server/registry.lua')
GCModuleTest.Load('server/api.lua')
GCModuleTest.Load('server/main.lua')

local function issueCode(descriptor, code)
    for _, issue in ipairs(descriptor and descriptor.issues or {}) do
        if issue.code == code then return true end
    end
    return false
end

GCModuleTest.Register('ecosystem.discovery_and_third_party', 'integration', function()
    local modules = GCEcosystemAPI.ListModules()
    GCModuleTest.ExpectEqual(#modules, 3, 'ordinary FiveM resource is ignored')
    GCModuleTest.ExpectNotNil(GCEcosystemAPI.GetModule('gc_example'), 'official module discovered')
    GCModuleTest.ExpectNotNil(GCEcosystemAPI.GetModule('vendor_identity'), 'third-party module discovered by metadata')
    GCModuleTest.ExpectNil(GCEcosystemAPI.GetModule('ordinary_resource'), 'normal resource absent from registry')
end)

GCModuleTest.Register('ecosystem.public_api_contract', 'contract', function()
    GCModuleTest.ExpectEqual(GCEcosystemAPI.GetVersion().version, '0.1.0-alpha', 'version DTO returned')
    GCModuleTest.ExpectEqual(GCEcosystemAPI.GetApiVersion(), 1, 'Ecosystem API v1 returned')
    local compatible, compatibleError = GCEcosystemAPI.IsModuleCompatible('gc_example')
    GCModuleTest.ExpectTrue(compatible, 'compatible module reports true')
    GCModuleTest.ExpectNil(compatibleError, 'compatible module has no error')
    local missing, missingError = GCEcosystemAPI.IsModuleCompatible('missing')
    GCModuleTest.ExpectFalse(missing, 'missing module reports false')
    GCModuleTest.ExpectEqual(missingError, 'GC-ECOSYSTEM-MODULE-NOT-FOUND', 'missing module has stable code')
end)

GCModuleTest.Register('ecosystem.registry_dto_is_detached', 'security', function()
    local list = GCEcosystemAPI.ListModules()
    list[1].compatible = false
    list[1].capabilities[1] = 'forged'
    list[1].issues[1] = { code = 'forged' }
    GCModuleTest.ExpectTrue(GCEcosystemAPI.GetModule('gc_ecosystem').compatible, 'top-level DTO mutation is isolated')
    GCModuleTest.ExpectEqual(GCEcosystemAPI.GetCapabilityProviders('module-registry')[1], 'gc_ecosystem', 'capability array mutation is isolated')
    GCModuleTest.ExpectEqual(#GCEcosystemAPI.GetModule('gc_ecosystem').issues, 0, 'issue array mutation is isolated')
    local graph = GCEcosystemAPI.GetDependencyGraph()
    graph.nodes[1] = 'forged'
    GCModuleTest.ExpectFalse(GCEcosystemAPI.GetDependencyGraph().nodes[1] == 'forged', 'graph DTO is detached')
end)

GCModuleTest.Register('ecosystem.malformed_metadata_fails_closed', 'security', function()
    reset()
    add('broken_module', { contract = false, capabilities = { 'broken-provider' } })
    GCEcosystemAPI.Refresh()
    local descriptor = GCEcosystemAPI.GetModule('broken_module')
    GCModuleTest.ExpectFalse(descriptor.compatible, 'malformed descriptor is incompatible')
    GCModuleTest.ExpectTrue(issueCode(descriptor, 'GC-ECOSYSTEM-METADATA-INVALID'), 'malformed descriptor has metadata code')
    GCModuleTest.ExpectEqual(#GCEcosystemAPI.GetCapabilityProviders('broken-provider'), 0, 'incompatible provider is never advertised')
end)

GCModuleTest.Register('ecosystem.invalid_semver_and_capability_fail_closed', 'security', function()
    reset()
    add('broken_shape', {
        version = 'latest',
        api = 1,
        capabilities = { 'Valid_But_Unsafe', 'duplicate', 'duplicate' }
    })
    GCEcosystemAPI.Refresh()
    local descriptor = GCEcosystemAPI.GetModule('broken_shape')
    GCModuleTest.ExpectFalse(descriptor.compatible, 'invalid runtime metadata is incompatible')
    GCModuleTest.ExpectTrue(issueCode(descriptor, 'GC-ECOSYSTEM-METADATA-INVALID'), 'invalid runtime metadata has stable code')
    GCModuleTest.ExpectEqual(#GCEcosystemAPI.GetCapabilityProviders('duplicate'), 0, 'duplicate capability provider is hidden')
end)

GCModuleTest.Register('ecosystem.required_and_optional_dependencies', 'integration', function()
    reset()
    add('consumer', {
        required = { 'missing_required:api>=1' },
        optional = { 'missing_optional:api>=1' }
    })
    GCEcosystemAPI.Refresh()
    local descriptor = GCEcosystemAPI.GetModule('consumer')
    GCModuleTest.ExpectFalse(descriptor.compatible, 'missing required dependency rejects compatibility')
    GCModuleTest.ExpectEqual(descriptor.status, 'missing_dependency', 'missing required status is explicit')
    GCModuleTest.ExpectTrue(issueCode(descriptor, 'GC-ECOSYSTEM-DEPENDENCY-MISSING'), 'missing required dependency has stable code')

    reset()
    add('optional_consumer', { optional = { 'missing_optional:api>=1' } })
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectTrue(GCEcosystemAPI.GetModule('optional_consumer').compatible, 'missing optional dependency is allowed')
end)

GCModuleTest.Register('ecosystem.module_api_and_state_compatibility', 'integration', function()
    reset()
    add('provider', { api = 1 })
    add('consumer', { required = { 'provider:api>=2' } })
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('consumer'), 'GC-ECOSYSTEM-MODULE-API-INCOMPATIBLE'), 'old module API rejected')

    states.provider = 'stopped'
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('consumer'), 'GC-ECOSYSTEM-DEPENDENCY-STOPPED'), 'stopped required module rejected')
end)

GCModuleTest.Register('ecosystem.core_api_compatibility', 'integration', function()
    reset()
    add('future_module', { coreApi = 999 })
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('future_module'), 'GC-ECOSYSTEM-CORE-API-INCOMPATIBLE'), 'old Core API rejected')
    states.gc_core = 'stopped'
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('future_module'), 'GC-ECOSYSTEM-CORE-UNAVAILABLE'), 'stopped core fails closed')
end)

GCModuleTest.Register('ecosystem_cycle_and_self_dependency', 'security', function()
    reset()
    add('module_a', { api = 1, required = { 'module_b:api>=1' } })
    add('module_b', { api = 1, required = { 'module_a:api>=1' } })
    add('self_module', { api = 1, required = { 'self_module:api>=1' } })
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('module_a'), 'GC-ECOSYSTEM-DEPENDENCY-CYCLE'), 'cycle A is rejected')
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('module_b'), 'GC-ECOSYSTEM-DEPENDENCY-CYCLE'), 'cycle B is rejected')
    GCModuleTest.ExpectTrue(issueCode(GCEcosystemAPI.GetModule('self_module'), 'GC-ECOSYSTEM-DEPENDENCY-SELF'), 'self dependency is rejected')
end)

GCModuleTest.Register('ecosystem_resource_start_stop_refresh', 'runtime', function()
    reset()
    add('tracked_module', { state = 'started' })
    GCEcosystemAPI.Refresh()
    GCModuleTest.ExpectNotNil(handlers.onResourceStart, 'resource start handler registered')
    GCModuleTest.ExpectNotNil(handlers.onResourceStop, 'resource stop handler registered')
    handlers.onResourceStop('tracked_module')
    GCModuleTest.ExpectEqual(GCEcosystemAPI.GetModule('tracked_module').state, 'stopped', 'stop event updates registry state')
    GCModuleTest.ExpectFalse(GCEcosystemAPI.GetModule('tracked_module').compatible, 'stopped module is not runtime-compatible')
    handlers.onResourceStart('tracked_module')
    GCModuleTest.ExpectEqual(GCEcosystemAPI.GetModule('tracked_module').state, 'started', 'start event updates registry state')
    GCModuleTest.ExpectNotNil(commands['gcore:modules'], 'console diagnostics command registered')
end)
