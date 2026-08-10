fx_version 'cerulean'
game 'gta5'

name 'gc_identity'
author 'GCore Project'
description 'Server-authoritative account and character identity module for GCore'
version '0.1.0-alpha'

dependency 'gc_core'

shared_scripts {
    'shared/version.lua',
    'shared/config.lua',
    'shared/events.lua',
    'shared/client_security.lua'
}

server_scripts {
    'server/logger.lua',
    'server/state.lua',
    'server/validation.lua',
    'server/rate_limit.lua',
    'server/repository.lua',
    'server/service.lua',
    'server/api.lua',
    'server/events.lua',
    'server/exports.lua',
    'server/main.lua'
}

client_script 'client/main.lua'
