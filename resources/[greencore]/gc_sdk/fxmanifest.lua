fx_version 'cerulean'
game 'gta5'

name 'gc_sdk'
author 'GCore Project'
description 'Optional minimal compatibility helpers for GCore module authors'
version '0.1.0-alpha'

gcore_module 'yes'
gcore_contract '1'
gcore_type 'developer'
gcore_api '1'
gcore_requires_core_api '1'
gcore_capability 'core-compatibility-helpers'

server_only 'yes'
dependency 'gc_core'

server_scripts {
    'shared/version.lua',
    'server/api.lua',
    'server/exports.lua',
    'server/main.lua'
}
