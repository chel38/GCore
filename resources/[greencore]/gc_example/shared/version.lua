-- EN: gc_example resource metadata is independent from the gc_core patch version.
-- RU: Метаданные ресурса gc_example не зависят от patch-версии gc_core.

GCExampleVersion = {
    resource = {
        major = 0,
        minor = 1,
        patch = 0,
        prerelease = 'alpha'
    }
}

function GCExampleVersion.GetString()
    local resource = GCExampleVersion.resource
    local value = ('%d.%d.%d'):format(resource.major, resource.minor, resource.patch)

    if resource.prerelease and resource.prerelease ~= '' then
        return ('%s-%s'):format(value, resource.prerelease)
    end

    return value
end
