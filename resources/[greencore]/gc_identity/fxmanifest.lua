fx_version 'cerulean'
game 'gta5'

name 'gc_identity'
author 'GCore Project'
description 'Server-authoritative account and character identity module for GCore'
version '0.4.1-alpha'

dependency 'gc_core'
dependency 'oxmysql'

shared_scripts {
    'shared/version.lua',
    'shared/config.lua',
    'shared/events.lua',
    'shared/client_security.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logger.lua',
    'server/crypto.lua',
    'server/endpoint.lua',
    'server/security_config.lua',
    'server/mail_client.lua',
    'server/state.lua',
    'server/validation.lua',
    'server/rate_limit.lua',
    'server/migrations/registry.lua',
    'server/migrations/001_initial_identity.lua',
    'server/migrations/002_email_verification_security.lua',
    'server/migrations/003_pre_spawn_registration.lua',
    'server/database.lua',
    'server/repositories/memory.lua',
    'server/repositories/json_legacy.lua',
    'server/repositories/oxmysql.lua',
    'server/repository.lua',
    'server/service.lua',
    'server/api.lua',
    'server/events.lua',
    'server/exports.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}
