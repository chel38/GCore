-- EN: gc_identity versions evolve independently from gc_core.
-- RU: Версии gc_identity развиваются независимо от gc_core.

GCIdentityVersion = {
    resource = {
        major = 0,
        minor = 2,
        patch = 0,
        prerelease = 'alpha'
    },
    api = 1,
    protocol = 1
}

function GCIdentityVersion.GetString()
    local resource = GCIdentityVersion.resource
    local version = ('%d.%d.%d'):format(resource.major, resource.minor, resource.patch)

    if resource.prerelease and resource.prerelease ~= '' then
        return ('%s-%s'):format(version, resource.prerelease)
    end

    return version
end
