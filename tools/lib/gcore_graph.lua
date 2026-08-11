local Graph = {}

function Graph.FindCycles(descriptors)
    local byName = {}
    for _, descriptor in ipairs(descriptors or {}) do
        byName[descriptor.resource] = descriptor
    end

    local state = {}
    local stack = {}
    local stackIndex = {}
    local cycles = {}
    local seenCycles = {}

    local function visit(resource)
        state[resource] = 'visiting'
        stack[#stack + 1] = resource
        stackIndex[resource] = #stack

        for _, dependency in ipairs((byName[resource] or {}).requiredModules or {}) do
            local target = dependency.resource
            if target and byName[target] then
                if state[target] == 'visiting' then
                    local cycle = {}
                    for index = stackIndex[target], #stack do cycle[#cycle + 1] = stack[index] end
                    cycle[#cycle + 1] = target
                    local key = table.concat(cycle, '->')
                    if not seenCycles[key] then
                        cycles[#cycles + 1] = cycle
                        seenCycles[key] = true
                    end
                elseif not state[target] then
                    visit(target)
                end
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

function Graph.ToDto(descriptors)
    local nodes = {}
    local edges = {}

    for _, descriptor in ipairs(descriptors or {}) do
        nodes[#nodes + 1] = descriptor.resource
        edges[#edges + 1] = {
            from = descriptor.resource,
            to = 'gc_core',
            kind = 'core-api',
            minimumApi = descriptor.requiredCoreApi
        }
        for _, dependency in ipairs(descriptor.requiredModules or {}) do
            if dependency.resource then
                edges[#edges + 1] = {
                    from = descriptor.resource,
                    to = dependency.resource,
                    kind = 'required',
                    minimumApi = dependency.minimumApi
                }
            end
        end
        for _, dependency in ipairs(descriptor.optionalModules or {}) do
            if dependency.resource then
                edges[#edges + 1] = {
                    from = descriptor.resource,
                    to = dependency.resource,
                    kind = 'optional',
                    minimumApi = dependency.minimumApi
                }
            end
        end
    end

    table.sort(nodes)
    table.sort(edges, function(left, right)
        local a = left.from .. '\0' .. left.to .. '\0' .. left.kind
        local b = right.from .. '\0' .. right.to .. '\0' .. right.kind
        return a < b
    end)
    return { nodes = nodes, edges = edges }
end

return Graph
