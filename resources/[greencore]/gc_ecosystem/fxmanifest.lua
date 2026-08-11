fx_version 'cerulean'
game 'gta5'

name 'gc_ecosystem'
author 'GCore Project'
description 'Optional local module registry and compatibility diagnostics for GCore'
version '0.1.0-alpha'

gcore_module 'yes'
gcore_contract '1'
gcore_type 'infrastructure'
gcore_api '1'
gcore_requires_core_api '1'
gcore_capability 'module-registry'
gcore_capability 'compatibility-diagnostics'
gcore_capability 'dependency-graph'

server_only 'yes'
dependency 'gc_core'

server_scripts {
    'shared/version.lua',
    'server/utils.lua',
    'server/metadata.lua',
    'server/graph.lua',
    'server/registry.lua',
    'server/api.lua',
    'server/exports.lua',
    'server/main.lua'
}
