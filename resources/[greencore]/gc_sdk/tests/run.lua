local states = { gc_core = 'started', dependency = 'started' }
local coreApi = 1

function GetResourceState(resource) return states[resource] or 'missing' end
exports = {
    gc_core = {
        GetApiVersion = function() return coreApi end
    }
}

GCModuleTest.Load('shared/version.lua')
GCModuleTest.Load('server/api.lua')

GCModuleTest.Register('sdk.version_contract', 'contract', function()
    local version = GCSDK.GetVersion()
    GCModuleTest.ExpectEqual(version.version, '0.1.0-alpha', 'SDK version returned')
    GCModuleTest.ExpectEqual(GCSDK.GetApiVersion(), 1, 'SDK API v1 returned')
    version.apiVersion = 999
    GCModuleTest.ExpectEqual(GCSDK.GetApiVersion(), 1, 'version DTO is detached')
end)

GCModuleTest.Register('sdk.core_available', 'contract', function()
    states.gc_core = 'started'
    coreApi = 1
    local ok, code, details = GCSDK.RequireCoreApi(1)
    GCModuleTest.ExpectTrue(GCSDK.IsCoreAvailable(), 'started core is available')
    GCModuleTest.ExpectTrue(ok, 'sufficient Core API accepted')
    GCModuleTest.ExpectNil(code, 'compatible core has no error')
    GCModuleTest.ExpectEqual(details.actual, 1, 'actual API is reported')
end)

GCModuleTest.Register('sdk.core_stopped_fails_closed', 'runtime', function()
    states.gc_core = 'stopped'
    local ok, code = GCSDK.RequireCoreApi(1)
    GCModuleTest.ExpectFalse(GCSDK.IsCoreAvailable(), 'stopped core is unavailable')
    GCModuleTest.ExpectFalse(ok, 'stopped core is rejected')
    GCModuleTest.ExpectEqual(code, 'GC-SDK-CORE-UNAVAILABLE', 'stopped core has stable code')
end)

GCModuleTest.Register('sdk.core_api_too_old', 'contract', function()
    states.gc_core = 'started'
    coreApi = 1
    local ok, code, details = GCSDK.RequireCoreApi(2)
    GCModuleTest.ExpectFalse(ok, 'old Core API is rejected')
    GCModuleTest.ExpectEqual(code, 'GC-SDK-CORE-API-INCOMPATIBLE', 'old API has stable code')
    GCModuleTest.ExpectEqual(details.required, 2, 'minimum API is reported')
end)

GCModuleTest.Register('sdk.invalid_input_and_resource_requirement', 'security', function()
    local ok, code = GCSDK.RequireCoreApi('1')
    GCModuleTest.ExpectFalse(ok, 'non-integer API rejected')
    GCModuleTest.ExpectEqual(code, 'GC-SDK-ARGUMENT-INVALID', 'invalid API has stable code')
    ok, code = GCSDK.RequireResource('..' .. '/gc_core')
    GCModuleTest.ExpectFalse(ok, 'path traversal resource rejected')
    GCModuleTest.ExpectEqual(code, 'GC-SDK-ARGUMENT-INVALID', 'invalid resource has stable code')
    local details
    ok, code, details = GCSDK.RequireResource('dependency')
    GCModuleTest.ExpectTrue(ok, 'started generic resource accepted')
    GCModuleTest.ExpectNil(code, 'started resource has no error')
    GCModuleTest.ExpectEqual(details.state, 'started', 'resource state reported')
    states.dependency = 'stopped'
    ok, code = GCSDK.RequireResource('dependency')
    GCModuleTest.ExpectFalse(ok, 'stopped generic resource rejected')
    GCModuleTest.ExpectEqual(code, 'GC-SDK-MODULE-UNAVAILABLE', 'stopped resource has stable code')
end)
