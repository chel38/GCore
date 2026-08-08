-- RU: Единый источник версий ресурса, публичного API и сетевого протокола.
-- EN: Single source of truth for resource, public API, and protocol versions.

GCVersion = {
    resource = {
        major = 0,
        minor = 1,
        patch = 3,
        prerelease = 'alpha'
    },
    api = 1,
    protocol = 1
}

function GCVersion.GetString()
    local version = GCVersion.resource
    local base = ('%d.%d.%d'):format(version.major, version.minor, version.patch)

    if version.prerelease and version.prerelease ~= '' then
        return ('%s-%s'):format(base, version.prerelease)
    end

    return base
end

function GCVersion.GetFullString()
    return GCVersion.GetString()
end

function GCVersion.GetApiVersion()
    return GCVersion.api
end

function GCVersion.GetProtocolVersion()
    return GCVersion.protocol
end

function GCVersion.GetPublicDto()
    return {
        version = GCVersion.GetString(),
        resource = {
            major = GCVersion.resource.major,
            minor = GCVersion.resource.minor,
            patch = GCVersion.resource.patch,
            prerelease = GCVersion.resource.prerelease
        },
        apiVersion = GCVersion.GetApiVersion(),
        protocolVersion = GCVersion.GetProtocolVersion()
    }
end
