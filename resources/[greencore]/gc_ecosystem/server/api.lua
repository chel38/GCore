GCEcosystemAPI = {}

function GCEcosystemAPI.GetVersion()
    return GCEcosystemVersion.GetPublicDto()
end

function GCEcosystemAPI.GetApiVersion()
    return GCEcosystemVersion.api
end

function GCEcosystemAPI.ListModules()
    return GCEcosystemRegistry.List()
end

function GCEcosystemAPI.GetModule(resource)
    if type(resource) ~= 'string' or resource == '' then return nil end
    return GCEcosystemRegistry.Get(resource)
end

function GCEcosystemAPI.IsModuleCompatible(resource)
    local descriptor = GCEcosystemAPI.GetModule(resource)
    if not descriptor then return false, 'GC-ECOSYSTEM-MODULE-NOT-FOUND' end
    return descriptor.compatible, nil
end

function GCEcosystemAPI.GetDependencyGraph()
    return GCEcosystemRegistry.Graph()
end

function GCEcosystemAPI.GetCapabilityProviders(capability)
    return GCEcosystemRegistry.CapabilityProviders(capability)
end

function GCEcosystemAPI.Refresh()
    return GCEcosystemRegistry.Refresh()
end
