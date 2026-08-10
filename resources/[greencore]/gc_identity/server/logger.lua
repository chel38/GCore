GCIdentityLogger = {}

local function write(level, code, message, data)
    local suffix = ''

    if type(data) == 'table' then
        local fields = {}

        for key, value in pairs(data) do
            local normalizedKey = tostring(key):lower()

            if normalizedKey ~= 'identifier'
                and normalizedKey ~= 'email'
                and not normalizedKey:find('password', 1, true)
                and not normalizedKey:find('secret', 1, true)
                and not normalizedKey:find('token', 1, true) then
                table.insert(fields, ('%s=%s'):format(tostring(key), tostring(value)))
            end
        end

        table.sort(fields)

        if #fields > 0 then
            suffix = ' | ' .. table.concat(fields, ', ')
        end
    end

    print(('[GC][IDENTITY][%s] [%s] %s%s'):format(level, code, message, suffix))
end

function GCIdentityLogger.Info(code, message, data)
    write('INFO', code, message, data)
end

function GCIdentityLogger.Warn(code, message, data)
    write('WARN', code, message, data)
end

function GCIdentityLogger.Error(code, message, data)
    write('ERROR', code, message, data)
end
