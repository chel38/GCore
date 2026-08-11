# GCore Module Standard v1

The Module Standard describes an ordinary FiveM resource that integrates with
GCore through public contracts. It is structural and compatibility metadata; it
is not a security review, package signature, or permission system.

## Required layout

```text
module/
├── fxmanifest.lua
├── README.md
├── README.ru.md
├── shared/version.lua
├── server/                 # required for production modules
└── tests/run.lua
```

Create `client/` only for client runtime and `web/` only for a real NUI. A
server-only module must not add dummy client code.

## Required manifest metadata

```lua
fx_version 'cerulean'
game 'gta5'

name 'example_resource'
author 'Example Author'
description 'Short, factual description'
version '0.1.0-alpha'

gcore_module 'yes'
gcore_contract '1'
gcore_type 'domain'
gcore_requires_core_api '1'

dependency 'gc_core'
```

Allowed `gcore_type` values in contract v1 are `reference`, `domain`,
`infrastructure`, `integration`, and `developer`.

## Optional metadata

- `gcore_api '1'` when the module exposes a documented public API.
- Repeated `gcore_capability 'value'` entries for catalog/diagnostics.
- Repeated `gcore_requires 'resource:api>=1'` entries for required GCore modules.
- Repeated `gcore_optional 'resource:api>=1'` entries for optional integration.
- `gcore_repository` and `gcore_license` when publishing information is useful.

Required `gcore_requires` edges must also have a FiveM `dependency`. Optional
edges must not be converted into required FiveM dependencies. Core compatibility
uses `gcore_requires_core_api`, never the private Core network protocol or an
exact `gc_core` resource patch.

## Naming and third-party resources

`gc_*` is reserved for official GCore resources. Discovery is based on
`gcore_module 'yes'`, so a third-party module may use another valid FiveM name.
Claiming the metadata does not make third-party code trusted or safe.

## Public boundary

- Use documented exports or documented local server events.
- Never import `gc_core/server/*` or read `GCSessions`, `GCStates`, `GCSpawn`, or
  any other internal table.
- Return detached, minimal DTOs without secrets.
- Treat every client/NUI payload as untrusted and validate it server-side.
- Re-check state after asynchronous DB/HTTP work and on dependency restart.
- Keep module-specific state, security, rate limits, and domain logic in the module.

## Compatibility

Module Contract version, resource version, public API version, and network
protocol version are separate values. Contract v1 accepts additive compatible
metadata. A breaking standard change requires a new contract version.

Run conformance before tests and packaging:

```text
lua tools/module_conformance.lua path/to/module
```
