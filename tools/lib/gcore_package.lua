local FS = require('gcore_fs')
local Json = require('gcore_json')
local Manifest = require('gcore_manifest')
local Conformance = require('gcore_conformance')
local Sha256 = require('gcore_sha256')

local Package = {}
local excludedDirectories = {
    ['.git'] = true,
    ['.idea'] = true,
    ['.vscode'] = true,
    node_modules = true,
    coverage = true,
    ['test-results'] = true,
    build = true
}

function Package.ShouldInclude(relative)
    local normalized = relative:gsub('\\', '/')
    -- EN: Top-level data is runtime-owned state and must never cross the release boundary.
    -- RU: Корневой data содержит runtime-состояние и не должен попадать в релиз.
    if normalized == 'data' or normalized:match('^data/') then return false end
    for component in normalized:gmatch('[^/]+') do
        if excludedDirectories[component] then return false end
    end
    local name = normalized:match('([^/]+)$') or normalized
    if name == '.env' or (name:match('^%.env%.') and name ~= '.env.example') then return false end
    if name:match('%.log$') or name:match('%.tmp$') or name:match('~$') then return false end
    if name:match('%.sqlite3?$') or name:match('%.db$')
        or name == 'secrets.json' or name == 'credentials.json'
        or name:match('%.pem$') or name:match('%.key$') then return false end
    return true
end

local function pad(value, width)
    assert(#value <= width, 'tar path field is too long')
    return value .. string.rep('\0', width - #value)
end

local function octal(value, width)
    local encoded = string.format('%0' .. tostring(width - 1) .. 'o', value)
    assert(#encoded < width, 'tar numeric field overflow')
    return encoded .. '\0'
end

local function tarName(path)
    if #path <= 100 then return path, '' end
    for index = #path, 1, -1 do
        if path:sub(index, index) == '/' then
            local prefix, name = path:sub(1, index - 1), path:sub(index + 1)
            if #prefix <= 155 and #name <= 100 then return name, prefix end
        end
    end
    error('tar path is too long: ' .. path)
end

local function tarHeader(path, size, timestamp)
    local name, prefix = tarName(path)
    local header = pad(name, 100)
        .. octal(420, 8) .. octal(0, 8) .. octal(0, 8)
        .. octal(size, 12) .. octal(timestamp, 12)
        .. '        ' .. '0' .. pad('', 100)
        .. 'ustar\0' .. '00' .. pad('gcore', 32) .. pad('gcore', 32)
        .. octal(0, 8) .. octal(0, 8) .. pad(prefix, 155) .. string.rep('\0', 12)
    local checksum = 0
    for index = 1, #header do checksum = checksum + header:byte(index) end
    local encoded = string.format('%06o\0 ', checksum)
    return header:sub(1, 148) .. encoded .. header:sub(157)
end

function Package.CreateTar(modulePath, resource, files, destination, timestamp)
    local output, openError = io.open(destination, 'wb')
    if not output then return nil, openError end
    for _, path in ipairs(files) do
        local relative = FS.Relative(modulePath, path)
        local content = assert(FS.ReadFile(path))
        output:write(tarHeader(resource .. '/' .. relative, #content, timestamp))
        output:write(content)
        local remainder = #content % 512
        if remainder ~= 0 then output:write(string.rep('\0', 512 - remainder)) end
    end
    output:write(string.rep('\0', 1024))
    output:close()
    return true
end

function Package.Build(modulePath, outputRoot, options)
    options = options or {}
    local conformance = Conformance.Validate(modulePath)
    if not conformance.ok then return nil, 'GC-PACKAGE-CONFORMANCE-FAILED', conformance end
    local descriptor = conformance.descriptor
    local manifest = Manifest.Parse(assert(FS.ReadFile(FS.Join(modulePath, 'fxmanifest.lua'))))
    if Manifest.First(manifest, 'ui_page')
        and not FS.IsFile(FS.Join(modulePath, 'web', 'dist', 'index.html')) then
        return nil, 'GC-PACKAGE-NUI-DIST-MISSING'
    end

    if not options.skipTests then
        local command = 'lua ' .. FS.ShellQuote(options.harness)
            .. ' ' .. FS.ShellQuote(options.repoRoot or '.')
            .. ' ' .. FS.ShellQuote(modulePath)
        local ok, _, code = os.execute(command)
        if not (ok == true or ok == 0 or code == 0) then return nil, 'GC-PACKAGE-TESTS-FAILED' end
    end

    local releaseRoot = FS.Join(outputRoot, descriptor.resource .. '-' .. descriptor.version)
    if FS.Exists(releaseRoot) then return nil, 'GC-PACKAGE-DESTINATION-EXISTS' end
    if not FS.MakeDir(releaseRoot) then return nil, 'GC-PACKAGE-DESTINATION-CREATE' end
    local files = FS.ListFiles(modulePath) or {}
    local allowed = {}
    for _, path in ipairs(files) do
        local relative = FS.Relative(modulePath, path)
        if Package.ShouldInclude(relative) then
            allowed[#allowed + 1] = path
            assert(FS.CopyFile(path, FS.Join(releaseRoot, 'resource', relative)))
        end
    end
    table.sort(allowed)

    local timestamp = os.time()
    local archive = FS.Join(releaseRoot, descriptor.resource .. '-' .. descriptor.version .. '.tar')
    local created, archiveError = Package.CreateTar(modulePath, descriptor.resource, allowed, archive, timestamp)
    if not created then return nil, archiveError end
    local archiveContent = assert(FS.ReadFile(archive))
    local checksum = Sha256.Sum(archiveContent)
    assert(FS.WriteFile(archive .. '.sha256', checksum .. '  ' .. FS.Basename(archive) .. '\n'))
    local releaseManifest = {
        module = descriptor.resource,
        version = descriptor.version,
        contract = descriptor.contractVersion,
        api = descriptor.apiVersion,
        checksum = { algorithm = 'SHA-256', value = checksum },
        builtAt = os.date('!%Y-%m-%dT%H:%M:%SZ', timestamp)
    }
    assert(FS.WriteFile(
        FS.Join(releaseRoot, 'release-manifest.json'),
        Json.Encode(releaseManifest, true)
    ))
    return {
        root = releaseRoot,
        archive = archive,
        checksum = checksum,
        files = #allowed
    }
end

return Package
