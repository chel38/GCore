GCEcosystemVersion = {
    resource = {
        major = 0,
        minor = 1,
        patch = 0,
        prerelease = 'alpha'
    },
    api = 1,
    contract = 1
}

function GCEcosystemVersion.GetString()
    local resource = GCEcosystemVersion.resource
    local value = ('%d.%d.%d'):format(resource.major, resource.minor, resource.patch)
    if resource.prerelease and resource.prerelease ~= '' then
        return ('%s-%s'):format(value, resource.prerelease)
    end
    return value
end

function GCEcosystemVersion.GetPublicDto()
    return {
        version = GCEcosystemVersion.GetString(),
        apiVersion = GCEcosystemVersion.api,
        contractVersion = GCEcosystemVersion.contract
    }
end
