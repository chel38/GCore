GCEcosystemGraph = {}

function GCEcosystemGraph.FindCycles(descriptors)
    local byName = {}
    for _, descriptor in ipairs(descriptors) do byName[descriptor.resource] = descriptor end
    local state, stack, stackIndex, cycles = {}, {}, {}, {}

    local function visit(resource)
        state[resource] = 'visiting'
        stack[#stack + 1] = resource
        stackIndex[resource] = #stack
        for _, dependency in ipairs(byName[resource].requiredModules) do
            local target = dependency.resource
            if byName[target] then
                if state[target] == 'visiting' then
                    local cycle = {}
                    for index = stackIndex[target], #stack do cycle[#cycle + 1] = stack[index] end
                    cycle[#cycle + 1] = target
                    cycles[#cycles + 1] = cycle
                elseif not state[target] then visit(target) end
            end
        end
        stackIndex[resource] = nil
        stack[#stack] = nil
        state[resource] = 'done'
    end

    local names = {}
    for name in pairs(byName) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do if not state[name] then visit(name) end end
    return cycles
end

function GCEcosystemGraph.Build(descriptors)
    local nodes, edges = {}, {}
    for _, descriptor in ipairs(descriptors) do
        nodes[#nodes + 1] = descriptor.resource
        edges[#edges + 1] = {
            from = descriptor.resource,
            to = 'gc_core',
            kind = 'core-api',
            minimumApi = descriptor.requiredCoreApi
        }
        for _, dependency in ipairs(descriptor.requiredModules) do
            edges[#edges + 1] = {
                from = descriptor.resource,
                to = dependency.resource,
                kind = 'required',
                minimumApi = dependency.minimumApi
            }
        end
        for _, dependency in ipairs(descriptor.optionalModules) do
            edges[#edges + 1] = {
                from = descriptor.resource,
                to = dependency.resource,
                kind = 'optional',
                minimumApi = dependency.minimumApi
            }
        end
    end
    table.sort(nodes)
    table.sort(edges, function(a, b)
        return (a.from .. '\0' .. a.to .. '\0' .. a.kind)
            < (b.from .. '\0' .. b.to .. '\0' .. b.kind)
    end)
    return { nodes = nodes, edges = edges }
end
