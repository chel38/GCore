GCSDK = {}

local function validPositiveInteger(value)
    return type(value) == 'number' and value >= 1 and value % 1 == 0
end

local function validResourceName(value)
    return type(value) == 'string'
        and value:match('^[a-z0-9][a-z0-9_%-]*$') ~= nil
end

function GCSDK.GetVersion()
    return GCSDKVersion.GetPublicDto()
end

function GCSDK.GetApiVersion()
    return GCSDKVersion.api
end

function GCSDK.GetCoreApiVersion()
    if GetResourceState('gc_core') ~= 'started' then
        return nil, 'GC-SDK-CORE-UNAVAILABLE'
    end

    local ok, apiVersion = pcall(function()
        return exports['gc_core']:GetApiVersion()
    end)
    if not ok or not validPositiveInteger(apiVersion) then
        return nil, 'GC-SDK-CORE-UNAVAILABLE'
    end
    return apiVersion, nil
end

function GCSDK.IsCoreAvailable()
    return GCSDK.GetCoreApiVersion() ~= nil
end

function GCSDK.RequireCoreApi(minimumApi)
    if not validPositiveInteger(minimumApi) then
        return false, 'GC-SDK-ARGUMENT-INVALID'
    end
    local apiVersion, apiError = GCSDK.GetCoreApiVersion()
    if not apiVersion then return false, apiError end
    if apiVersion < minimumApi then
        return false, 'GC-SDK-CORE-API-INCOMPATIBLE', {
            required = minimumApi,
            actual = apiVersion
        }
    end
    return true, nil, { required = minimumApi, actual = apiVersion }
end

function GCSDK.RequireResource(resource)
    if not validResourceName(resource) then
        return false, 'GC-SDK-ARGUMENT-INVALID'
    end
    local state = GetResourceState(resource)
    if state ~= 'started' then
        return false, 'GC-SDK-MODULE-UNAVAILABLE', {
            resource = resource,
            state = state
        }
    end
    return true, nil, { resource = resource, state = state }
end
