-- Deterministic JSON encoder used by catalog and machine-readable diagnostics.

local Json = {}

local function escape(value)
    local replacements = {
        ['"'] = '\\"',
        ['\\'] = '\\\\',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    }

    return value:gsub('[%z\1-\31\\"]', function(character)
        return replacements[character] or ('\\u%04x'):format(character:byte())
    end)
end

local function isArray(value)
    local count = 0

    for key in pairs(value) do
        if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then return false end
        count = math.max(count, key)
    end

    for index = 1, count do
        if value[index] == nil then return false end
    end

    return true, count
end

local function encode(value, pretty, depth, seen)
    local valueType = type(value)
    if value == nil then return 'null' end
    if valueType == 'boolean' or valueType == 'number' then return tostring(value) end
    if valueType == 'string' then return '"' .. escape(value) .. '"' end
    assert(valueType == 'table', 'unsupported JSON type: ' .. valueType)
    assert(not seen[value], 'cyclic JSON value')
    seen[value] = true

    local indent = pretty and string.rep('  ', depth) or ''
    local childIndent = pretty and string.rep('  ', depth + 1) or ''
    local separator = pretty and ',\n' or ','
    local array, count = isArray(value)
    local items = {}

    if array then
        for index = 1, count do
            items[#items + 1] = childIndent .. encode(value[index], pretty, depth + 1, seen)
        end
        seen[value] = nil
        if #items == 0 then return '[]' end
        return '[' .. (pretty and '\n' or '') .. table.concat(items, separator)
            .. (pretty and '\n' .. indent or '') .. ']'
    end

    local keys = {}
    for key in pairs(value) do
        assert(type(key) == 'string', 'JSON object keys must be strings')
        keys[#keys + 1] = key
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        local colon = pretty and ': ' or ':'
        items[#items + 1] = childIndent .. '"' .. escape(key) .. '"' .. colon
            .. encode(value[key], pretty, depth + 1, seen)
    end

    seen[value] = nil
    if #items == 0 then return '{}' end
    return '{' .. (pretty and '\n' or '') .. table.concat(items, separator)
        .. (pretty and '\n' .. indent or '') .. '}'
end

function Json.Encode(value, pretty)
    return encode(value, pretty == true, 0, {}) .. (pretty and '\n' or '')
end

return Json
