-- EN: Declarative fxmanifest parser. It never executes third-party Lua.
-- RU: Declarative fxmanifest parser. Он никогда не выполняет сторонний Lua-код.

local Manifest = {}

Manifest.KnownGCoreKeys = {
    gcore_module = true,
    gcore_contract = true,
    gcore_type = true,
    gcore_api = true,
    gcore_requires_core_api = true,
    gcore_capability = true,
    gcore_requires = true,
    gcore_optional = true,
    gcore_repository = true,
    gcore_license = true
}

local function append(metadata, key, value)
    metadata[key] = metadata[key] or {}
    metadata[key][#metadata[key] + 1] = value
end

local function quotedValue(line)
    return line:match("^%s*[%w_]+%s+'([^']*)'%s*$")
        or line:match('^%s*[%w_]+%s+"([^"]*)"%s*$')
end

function Manifest.Parse(source)
    assert(type(source) == 'string', 'manifest source must be a string')
    local metadata = {}
    local blockKey

    for rawLine in (source .. '\n'):gmatch('(.-)\r?\n') do
        local line = rawLine:gsub('%s+%-%-.*$', '')

        if blockKey then
            for quote, value in line:gmatch("(['\"])(.-)%1") do
                if quote and value ~= '' then append(metadata, blockKey, value) end
            end
            if line:find('}', 1, true) then blockKey = nil end
        else
            local key = line:match('^%s*([%w_]+)%s*{')
            if key then
                blockKey = key
                for quote, value in line:gmatch("(['\"])(.-)%1") do
                    if quote and value ~= '' then append(metadata, blockKey, value) end
                end
                if line:find('}', 1, true) then blockKey = nil end
            else
                key = line:match("^%s*([%w_]+)%s+['\"]")
                local value = key and quotedValue(line) or nil
                if key and value then append(metadata, key, value) end
            end
        end
    end

    return metadata
end


function Manifest.First(metadata, key)
    return metadata[key] and metadata[key][1] or nil
end

function Manifest.Values(metadata, key)
    local result = {}
    for index, value in ipairs(metadata[key] or {}) do result[index] = value end
    return result
end

function Manifest.ParsePositiveInteger(value)
    if type(value) ~= 'string' or not value:match('^%d+$') then return nil end
    local parsed = tonumber(value)
    if not parsed or parsed < 1 or parsed % 1 ~= 0 then return nil end
    return parsed
end

function Manifest.IsSemver(value)
    if type(value) ~= 'string' then return false end
    return value:match('^%d+%.%d+%.%d+$') ~= nil
        or value:match('^%d+%.%d+%.%d+%-[0-9A-Za-z][0-9A-Za-z%.%-]*$') ~= nil
end

function Manifest.ParseDependency(value)
    if type(value) ~= 'string' then return nil end
    local resource, api = value:match('^([a-z0-9][a-z0-9_%-]*):api>=(%d+)$')
    api = tonumber(api)
    if not resource or not api or api < 1 then return nil end
    return { resource = resource, minimumApi = api, raw = value }
end

function Manifest.VersionFromSource(source)
    if type(source) ~= 'string' then return nil, nil end
    local major = tonumber(source:match('major%s*=%s*(%d+)'))
    local minor = tonumber(source:match('minor%s*=%s*(%d+)'))
    local patch = tonumber(source:match('patch%s*=%s*(%d+)'))
    local prerelease = source:match("prerelease%s*=%s*'([^']*)'")
        or source:match('prerelease%s*=%s*"([^"]*)"')
    local api = tonumber(source:match('[^%w_]api%s*=%s*(%d+)'))

    if not major or not minor or not patch then return nil, api end
    local version = ('%d.%d.%d'):format(major, minor, patch)
    if prerelease and prerelease ~= '' then version = version .. '-' .. prerelease end
    return version, api
end

function Manifest.Descriptor(metadata, resourceName)
    local required = {}
    local optional = {}

    for _, raw in ipairs(Manifest.Values(metadata, 'gcore_requires')) do
        required[#required + 1] = Manifest.ParseDependency(raw) or { raw = raw }
    end
    for _, raw in ipairs(Manifest.Values(metadata, 'gcore_optional')) do
        optional[#optional + 1] = Manifest.ParseDependency(raw) or { raw = raw }
    end

    local fiveMDependencies = Manifest.Values(metadata, 'dependency')
    for _, value in ipairs(Manifest.Values(metadata, 'dependencies')) do
        fiveMDependencies[#fiveMDependencies + 1] = value
    end

    return {
        resource = resourceName,
        name = Manifest.First(metadata, 'name'),
        author = Manifest.First(metadata, 'author'),
        description = Manifest.First(metadata, 'description'),
        version = Manifest.First(metadata, 'version'),
        contractVersion = Manifest.ParsePositiveInteger(Manifest.First(metadata, 'gcore_contract')),
        type = Manifest.First(metadata, 'gcore_type'),
        apiVersion = Manifest.ParsePositiveInteger(Manifest.First(metadata, 'gcore_api')),
        requiredCoreApi = Manifest.ParsePositiveInteger(
            Manifest.First(metadata, 'gcore_requires_core_api')
        ),
        capabilities = Manifest.Values(metadata, 'gcore_capability'),
        requiredModules = required,
        optionalModules = optional,
        fiveMDependencies = fiveMDependencies,
        repository = Manifest.First(metadata, 'gcore_repository'),
        license = Manifest.First(metadata, 'gcore_license')
    }
end

return Manifest
