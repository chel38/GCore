fx_version 'cerulean'
game 'gta5'

name '{{MODULE_NAME}}'
author '{{MODULE_AUTHOR}}'
description '{{MODULE_DESCRIPTION}}'
version '{{VERSION}}'

gcore_module 'yes'
gcore_contract '1'
gcore_type '{{MODULE_TYPE}}'
{{GCORE_API_METADATA}}gcore_requires_core_api '1'
{{SDK_METADATA}}
{{DEPENDENCIES}}

shared_script 'shared/version.lua'
server_script 'server/main.lua'
{{CLIENT_MANIFEST}}{{NUI_MANIFEST}}
