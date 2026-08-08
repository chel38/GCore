-- RU: Единственная точка определения server/client runtime.
-- EN: The single source of truth for server/client runtime detection.

GCRuntime = {}

function GCRuntime.Context()
    if type(IsDuplicityVersion) ~= 'function' then
        return 'unknown'
    end

    local ok, isServer = pcall(IsDuplicityVersion)

    if not ok then
        return 'unknown'
    end

    return isServer and 'server' or 'client'
end

function GCRuntime.IsServer()
    return GCRuntime.Context() == 'server'
end

function GCRuntime.IsClient()
    return GCRuntime.Context() == 'client'
end

function GCRuntime.AssertServer(origin)
    if not GCRuntime.IsServer() then
        error(('%s must only run on the server'):format(origin or 'gc_core'), 2)
    end
end

function GCRuntime.AssertClient(origin)
    if not GCRuntime.IsClient() then
        error(('%s must only run on the client'):format(origin or 'gc_core'), 2)
    end
end
