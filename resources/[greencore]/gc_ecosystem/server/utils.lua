GCEcosystemUtils = {}

function GCEcosystemUtils.DeepCopy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do
        copy[GCEcosystemUtils.DeepCopy(key, seen)] = GCEcosystemUtils.DeepCopy(item, seen)
    end
    return copy
end

function GCEcosystemUtils.PositiveInteger(value)
    if type(value) ~= 'string' or not value:match('^%d+$') then return nil end
    local parsed = tonumber(value)
    if not parsed or parsed < 1 or parsed % 1 ~= 0 then return nil end
    return parsed
end

function GCEcosystemUtils.ParseDependency(value)
    if type(value) ~= 'string' then return nil end
    local resource, api = value:match('^([a-z0-9][a-z0-9_%-]*):api>=(%d+)$')
    api = tonumber(api)
    if not resource or not api or api < 1 then return nil end
    return { resource = resource, minimumApi = api, raw = value }
end

function GCEcosystemUtils.AddIssue(descriptor, code, details)
    descriptor.issues[#descriptor.issues + 1] = {
        code = code,
        details = details
    }
end

function GCEcosystemUtils.SortUnique(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end
