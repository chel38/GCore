fx_version 'cerulean'
game 'gta5'

name 'gc_example'
author 'GCore Project'
description 'Reference module demonstrating GCore Public API v1 usage'
version '0.1.0-alpha'

gcore_module 'yes'
gcore_contract '1'
gcore_type 'reference'
gcore_requires_core_api '1'
gcore_capability 'public-api-example'

dependency 'gc_core'

shared_scripts {
    'shared/version.lua',
    'shared/config.lua'
}
server_script 'server/main.lua'
