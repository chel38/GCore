local FS = require('gcore_fs')
local Manifest = require('gcore_manifest')

local Discovery = {}

function Discovery.Find(root)
    local scanRoot = FS.Join(root, 'resources')
    if not FS.Exists(scanRoot) then scanRoot = root end
    local files, listError = FS.ListFiles(scanRoot)
    if not files then return nil, listError end
    local modules = {}

    for _, path in ipairs(files) do
        if FS.Basename(path) == 'fxmanifest.lua' then
            local source = FS.ReadFile(path)
            local metadata = source and Manifest.Parse(source) or {}

            if Manifest.First(metadata, 'gcore_module') == 'yes' then
                local modulePath = FS.Dirname(path)
                local descriptor = Manifest.Descriptor(metadata, FS.Basename(modulePath))
                modules[#modules + 1] = {
                    path = modulePath,
                    manifestPath = path,
                    metadata = metadata,
                    descriptor = descriptor,
                    hasNui = Manifest.First(metadata, 'ui_page') ~= nil
                        and FS.IsFile(FS.Join(modulePath, 'web', 'package.json'))
                }
            end
        end
    end

    table.sort(modules, function(left, right)
        return left.descriptor.resource < right.descriptor.resource
    end)
    return modules
end

return Discovery
