-- EN: This module evolves independently from gc_core resource patches.
-- RU: Этот модуль развивается независимо от patch-версий gc_core.

GCModuleVersion = {
    resource = {
        major = {{VERSION_MAJOR}},
        minor = {{VERSION_MINOR}},
        patch = {{VERSION_PATCH}},
        prerelease = '{{VERSION_PRERELEASE}}'
    },
{{VERSION_API}}}

function GCModuleVersion.GetString()
    local resource = GCModuleVersion.resource
    local value = ('%d.%d.%d'):format(resource.major, resource.minor, resource.patch)
    if resource.prerelease and resource.prerelease ~= '' then
        return ('%s-%s'):format(value, resource.prerelease)
    end
    return value
end
