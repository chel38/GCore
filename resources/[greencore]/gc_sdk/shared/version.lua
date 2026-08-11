GCSDKVersion = {
    resource = {
        major = 0,
        minor = 1,
        patch = 0,
        prerelease = 'alpha'
    },
    api = 1
}

function GCSDKVersion.GetString()
    local resource = GCSDKVersion.resource
    local value = ('%d.%d.%d'):format(resource.major, resource.minor, resource.patch)
    if resource.prerelease and resource.prerelease ~= '' then
        return ('%s-%s'):format(value, resource.prerelease)
    end
    return value
end

function GCSDKVersion.GetPublicDto()
    return {
        version = GCSDKVersion.GetString(),
        apiVersion = GCSDKVersion.api
    }
end
