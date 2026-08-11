GCIdentityEndpoint = {}

local function normalizeIpv4(value)
    local parts = {}
    for part in value:gmatch('[^.]+') do
        if not part:match('^%d+$') then
            return nil
        end

        local number = tonumber(part)
        if not number or number < 0 or number > 255 then
            return nil
        end
        table.insert(parts, tostring(number))
    end

    return #parts == 4 and table.concat(parts, '.') or nil
end

local function ipv4Words(value)
    local normalized = normalizeIpv4(value)
    if not normalized then
        return nil
    end

    local octets = {}
    for part in normalized:gmatch('[^.]+') do
        table.insert(octets, tonumber(part))
    end
    return {
        octets[1] * 256 + octets[2],
        octets[3] * 256 + octets[4]
    }
end

local function splitIpv6Part(value, output)
    if value == '' then
        return true
    end

    for part in value:gmatch('[^:]+') do
        if part:find('.', 1, true) then
            local words = ipv4Words(part)
            if not words then
                return false
            end
            table.insert(output, words[1])
            table.insert(output, words[2])
        elseif #part > 4 or not part:match('^[0-9a-f]+$') then
            return false
        else
            table.insert(output, tonumber(part, 16))
        end
    end
    return true
end

local function normalizeIpv6(value)
    value = value:lower()
    if value:find('%%', 1, true) or value:find('::', 1, true) ~= value:match('^.*()::') then
        return nil
    end

    local compression = value:find('::', 1, true)
    local words = {}

    if compression then
        local left, right = value:sub(1, compression - 1), value:sub(compression + 2)
        local leftWords, rightWords = {}, {}
        if not splitIpv6Part(left, leftWords) or not splitIpv6Part(right, rightWords) then
            return nil
        end
        local missing = 8 - #leftWords - #rightWords
        if missing < 1 then
            return nil
        end
        for _, word in ipairs(leftWords) do table.insert(words, word) end
        for _ = 1, missing do table.insert(words, 0) end
        for _, word in ipairs(rightWords) do table.insert(words, word) end
    else
        if not splitIpv6Part(value, words) or #words ~= 8 then
            return nil
        end
    end

    if #words ~= 8 then
        return nil
    end

    -- EN: IPv4-mapped IPv6 is canonicalized to IPv4 so equivalent endpoints
    -- cannot create different trust fingerprints.
    -- RU: IPv4-mapped IPv6 приводится к IPv4, чтобы эквивалентные endpoints
    -- не создавали разные trust fingerprints.
    if words[1] == 0 and words[2] == 0 and words[3] == 0 and words[4] == 0
        and words[5] == 0 and words[6] == 0xffff then
        return ('%d.%d.%d.%d'):format(
            words[7] >> 8, words[7] & 0xff,
            words[8] >> 8, words[8] & 0xff
        )
    end

    local result = {}
    for index, word in ipairs(words) do
        result[index] = ('%04x'):format(word)
    end
    return table.concat(result, ':')
end

function GCIdentityEndpoint.Normalize(value)
    if type(value) ~= 'string' or value == '' then
        return nil
    end

    local endpoint = value:match('^%[([^%]]+)%]:%d+$')
        or value:match('^(%d+%.%d+%.%d+%.%d+):%d+$')
        or value

    if endpoint:find(':', 1, true) then
        return normalizeIpv6(endpoint)
    end
    return normalizeIpv4(endpoint)
end

function GCIdentityEndpoint.ForPlayer(playerSource)
    local endpoint = GetPlayerEndpoint(playerSource)
    local normalized = GCIdentityEndpoint.Normalize(endpoint)
    if not normalized then
        return nil, 'GC-IDENTITY-ENDPOINT-UNAVAILABLE'
    end
    return normalized
end
