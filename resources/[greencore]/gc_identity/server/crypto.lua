GCIdentityCrypto = {}

local MASK = 0xffffffff
local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local function rotateRight(value, count)
    return ((value >> count) | (value << (32 - count))) & MASK
end

local function sha256Raw(message)
    local length = #message
    local bitLength = length * 8
    local padding = (56 - ((length + 1) % 64)) % 64
    message = message .. '\128' .. string.rep('\0', padding)
        .. string.pack('>I4I4', math.floor(bitLength / 0x100000000), bitLength & MASK)

    local hash = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    }

    for offset = 1, #message, 64 do
        local words = {}

        for index = 0, 15 do
            words[index + 1] = string.unpack('>I4', message, offset + index * 4)
        end

        for index = 17, 64 do
            local left = words[index - 15]
            local right = words[index - 2]
            local sigma0 = rotateRight(left, 7) ~ rotateRight(left, 18) ~ (left >> 3)
            local sigma1 = rotateRight(right, 17) ~ rotateRight(right, 19) ~ (right >> 10)
            words[index] = (words[index - 16] + sigma0 + words[index - 7] + sigma1) & MASK
        end

        local a, b, c, d = hash[1], hash[2], hash[3], hash[4]
        local e, f, g, h = hash[5], hash[6], hash[7], hash[8]

        for index = 1, 64 do
            local sum1 = rotateRight(e, 6) ~ rotateRight(e, 11) ~ rotateRight(e, 25)
            local choice = (e & f) ~ ((~e) & g)
            local temporary1 = (h + sum1 + choice + K[index] + words[index]) & MASK
            local sum0 = rotateRight(a, 2) ~ rotateRight(a, 13) ~ rotateRight(a, 22)
            local majority = (a & b) ~ (a & c) ~ (b & c)
            local temporary2 = (sum0 + majority) & MASK
            h, g, f, e = g, f, e, (d + temporary1) & MASK
            d, c, b, a = c, b, a, (temporary1 + temporary2) & MASK
        end

        hash[1] = (hash[1] + a) & MASK
        hash[2] = (hash[2] + b) & MASK
        hash[3] = (hash[3] + c) & MASK
        hash[4] = (hash[4] + d) & MASK
        hash[5] = (hash[5] + e) & MASK
        hash[6] = (hash[6] + f) & MASK
        hash[7] = (hash[7] + g) & MASK
        hash[8] = (hash[8] + h) & MASK
    end

    local parts = {}
    for index = 1, 8 do
        parts[index] = string.pack('>I4', hash[index])
    end
    return table.concat(parts)
end

local function hex(value)
    return (value:gsub('.', function(byte)
        return ('%02x'):format(byte:byte())
    end))
end

function GCIdentityCrypto.Sha256(value)
    if type(value) ~= 'string' then
        return nil
    end

    return hex(sha256Raw(value))
end

function GCIdentityCrypto.HmacSha256(secret, value)
    if type(secret) ~= 'string' or secret == '' or type(value) ~= 'string' then
        return nil
    end

    local key = #secret > 64 and sha256Raw(secret) or secret
    key = key .. string.rep('\0', 64 - #key)
    local outer, inner = {}, {}

    for index = 1, 64 do
        local byte = key:byte(index)
        outer[index] = string.char(byte ~ 0x5c)
        inner[index] = string.char(byte ~ 0x36)
    end

    return hex(sha256Raw(table.concat(outer) .. sha256Raw(table.concat(inner) .. value)))
end

function GCIdentityCrypto.ConstantTimeEquals(left, right)
    if type(left) ~= 'string' or type(right) ~= 'string' or #left ~= #right then
        return false
    end

    local difference = 0
    for index = 1, #left do
        difference = difference | (left:byte(index) ~ right:byte(index))
    end
    return difference == 0
end
