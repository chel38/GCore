-- EN: Small cross-platform filesystem boundary for offline developer tooling.
-- RU: Небольшая cross-platform filesystem boundary для offline tooling.

local FS = {}
local separator = package.config:sub(1, 1)
local windows = separator == '\\'

local function commandSucceeded(ok, _, code)
    return ok == true or ok == 0 or code == 0
end

local function shellQuote(value)
    assert(type(value) == 'string' and not value:find('[\r\n\0]'), 'unsafe path')

    if windows then
        assert(not value:find('"', 1, true), 'double quote is not allowed in a tooling path')
        return '"' .. value .. '"'
    end

    return "'" .. value:gsub("'", "'\\''") .. "'"
end

function FS.IsWindows()
    return windows
end

function FS.ShellQuote(value)
    return shellQuote(value)
end

function FS.Separator()
    return separator
end

function FS.Normalize(path)
    assert(type(path) == 'string', 'path must be a string')
    local normalized = path:gsub('[\\/]+', separator)

    if #normalized > 1 then
        normalized = normalized:gsub('[\\/]+$', '')
    end

    return normalized
end


function FS.Join(...)
    local parts = { ... }
    local result = ''

    for _, part in ipairs(parts) do
        if type(part) == 'string' and part ~= '' then
            part = FS.Normalize(part)
            if result == '' then
                result = part
            else
                result = result:gsub('[\\/]+$', '')
                    .. separator
                    .. part:gsub('^[\\/]+', '')
            end
        end
    end

    return result
end

function FS.Basename(path)
    local normalized = FS.Normalize(path)
    return normalized:match('([^\\/]+)$') or normalized
end

function FS.Dirname(path)
    local normalized = FS.Normalize(path)
    return normalized:match('^(.*)[\\/][^\\/]+$') or '.'
end

function FS.ReadFile(path)
    local file, openError = io.open(path, 'rb')
    if not file then return nil, openError end
    local content = file:read('*a')
    file:close()
    return content
end

function FS.IsFile(path)
    local file = io.open(path, 'rb')
    if not file then return false end
    file:close()
    return true
end

function FS.Exists(path)
    if FS.IsFile(path) then return true end
    local ok, _, code = os.rename(path, path)
    return ok == true or code == 13
end

function FS.MakeDir(path)
    if FS.Exists(path) then return true end
    local command

    if windows then
        command = 'mkdir ' .. shellQuote(path) .. ' >NUL 2>&1'
    else
        command = 'mkdir -p ' .. shellQuote(path) .. ' >/dev/null 2>&1'
    end

    return commandSucceeded(os.execute(command)) and FS.Exists(path)
end

function FS.WriteFile(path, content)
    local parent = FS.Dirname(path)
    if parent ~= '.' and not FS.MakeDir(parent) then
        return nil, 'unable to create directory: ' .. parent
    end

    local file, openError = io.open(path, 'wb')
    if not file then return nil, openError end
    file:write(content)
    file:close()
    return true
end

function FS.CopyFile(source, destination)
    local content, readError = FS.ReadFile(source)
    if not content then return nil, readError end
    return FS.WriteFile(destination, content)
end

function FS.Relative(root, path)
    local normalizedRoot = FS.Normalize(root):gsub('\\', '/')
    local normalizedPath = FS.Normalize(path):gsub('\\', '/')
    local prefix = normalizedRoot .. '/'

    if normalizedPath:sub(1, #prefix):lower() == prefix:lower() then
        return normalizedPath:sub(#prefix + 1)
    end

    local relativeRoot = normalizedRoot:gsub('^%./', ''):gsub('^/', '')
    local marker = '/' .. relativeRoot .. '/'
    local markerStart = normalizedPath:lower():find(marker:lower(), 1, true)
    if markerStart then
        return normalizedPath:sub(markerStart + #marker)
    end

    return normalizedPath
end


function FS.ListFiles(root)
    if not FS.Exists(root) then return {} end
    local command

    if windows then
        command = 'dir /s /b /a-d ' .. shellQuote(root) .. ' 2>NUL'
    else
        command = 'find ' .. shellQuote(root) .. ' -type f 2>/dev/null'
    end

    local pipe = io.popen(command, 'r')
    if not pipe then return nil, 'unable to enumerate files' end
    local result = {}

    for line in pipe:lines() do
        if line ~= '' then result[#result + 1] = FS.Normalize(line) end
    end

    pipe:close()
    table.sort(result)
    return result
end

function FS.ScriptRoot(scriptPath)
    local directory = FS.Dirname(scriptPath)
    return FS.Normalize(FS.Join(directory, '..'))
end

return FS
