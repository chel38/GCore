local function printStatus()
    local modules = GCEcosystemRegistry.List()
    local compatible = 0
    local issues = 0
    for _, descriptor in ipairs(modules) do
        if descriptor.compatible then compatible = compatible + 1 end
        issues = issues + #descriptor.issues
    end
    print(('[GC][ECOSYSTEM] %d modules discovered, %d compatible, %d issues'):format(
        #modules,
        compatible,
        issues
    ))
end

GCEcosystemRegistry.Refresh()
printStatus()

AddEventHandler('onResourceStart', function(resource)
    GCEcosystemRegistry.Refresh({ resource = resource, state = 'started' })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then return end
    GCEcosystemRegistry.Refresh({ resource = resource, state = 'stopped' })
end)

RegisterCommand('gcore:modules', function(playerSource)
    if playerSource ~= 0 then return end
    print(('GCore Ecosystem %s / API %d'):format(
        GCEcosystemVersion.GetString(),
        GCEcosystemVersion.api
    ))
    for _, descriptor in ipairs(GCEcosystemRegistry.List()) do
        print(('[%s] %s version=%s api=%s state=%s status=%s'):format(
            descriptor.compatible and 'OK' or '!!',
            descriptor.resource,
            tostring(descriptor.version),
            tostring(descriptor.apiVersion or '-'),
            tostring(descriptor.state),
            descriptor.status
        ))
        for _, issue in ipairs(descriptor.issues) do
            print(('  %s: %s'):format(issue.code, tostring(issue.details or '')))
        end
    end
end, true)
