# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore runtime is 100% Lua.**
> **GreenCore runtime полностью написан на Lua.**
>
> Server, client, shared, config, locales and tests of `gc_core` — all in Lua.
> Module NUI uses **TypeScript + Tailwind CSS** and other modern FiveM-supported
> technologies. **C# will not be used.**

---

## Purpose

GreenCore is a minimal modular engine for FiveM written entirely in Lua 5.4.
It handles the secure player lifecycle:

```text
Connection → Validation → Session → Client readiness → Pre-spawn identity →
Server authorization → Spawn → Confirmation → Disconnection
```

## Development status

**0.1.5-alpha** — secure pre-spawn authorization and manual spawn gate.

Core Resource Version: `0.1.5-alpha`

Core API Version: `1`

Network Protocol Version: `2`

Core API Status: **Stable for module development**

Module ecosystem: Module Standard v1, `gc_example 0.1.0-alpha`, `gc_identity 0.4.1-alpha`,
optional `gc_sdk 0.1.0-alpha`, optional `gc_ecosystem 0.1.0-alpha`, and local
`mail-service 0.1.0-alpha`.

## Version features

- Connection validation via deferrals
- Identifier validation
- In-memory Lua sessions
- Player state management
- Network event rate limiting
- Server-side spawn decision
- Server-side OneSync ped, ownership, model, and position verification
- Recovery without trusting the client's `isPedAlive` hint
- Client spawn with Lua natives
- Public API v1
- RU|EN localization
- Diagnostics mode
- Public-API-only reference module
- Persistent MariaDB-backed identity/character module with NUI

## Version limitations

The first version does **not** include:

- Identity inside `gc_core` (the independent `gc_identity` resource owns it)
- A general database/ORM inside `gc_core`
- Money, inventory, vehicles
- Chat, HUD, admin panel
- C# (not planned) / C# (не планируется)

> **The `gc_identity` NUI is built with TypeScript + Tailwind CSS.**
> **NUI модуля `gc_identity` написан на TypeScript + Tailwind CSS.**

## Requirements

- FXServer (current version)
- Windows or Linux
- OneSync
- Lua 5.4 (runtime is entirely Lua / runtime полностью на Lua)
- MariaDB and `oxmysql` when `gc_identity` is enabled

## Installation

1. Open your FiveM server resources folder.
2. Create a `[greencore]` folder.
3. Place the required `gc_*` resources into this folder.
4. Open `server.cfg`.
5. Add:

```cfg
set mysql_connection_string "mysql://USER:PASSWORD@127.0.0.1:3306/gcore?charset=utf8mb4"
set gcore_spawn_mode manual
ensure oxmysql
ensure gc_core
ensure gc_sdk
ensure gc_ecosystem
ensure gc_example
ensure gc_identity
```

6. Save `server.cfg`.
7. Start FXServer.
8. Look for the message:

```text
[GreenCore] [INFO] gc_core 0.1.5-alpha started successfully
```

## Configuration

All configuration is stored in Lua files under `resources/[greencore]/gc_core/config/`.

## Structure

```text
resources/[greencore]/
├── gc_core/       # lifecycle foundation
├── gc_sdk/        # optional compatibility helpers
├── gc_ecosystem/  # optional local registry/diagnostics
├── gc_example/    # direct Public API reference
└── gc_identity/   # account and character identity domain
```

`gc_core` does not depend on SDK or ecosystem. Modules may use Core API directly.

## GCore Ecosystem

- [Introduction](docs/en/ecosystem/00-introduction.md)
- [Module Standard v1](docs/en/ecosystem/module-standard.md)
- [Creating a module](docs/en/ecosystem/creating-module.md)
- [Metadata](docs/en/ecosystem/metadata.md) and [dependencies](docs/en/ecosystem/dependencies.md)
- [Registry](docs/en/ecosystem/registry.md) and [optional SDK](docs/en/ecosystem/sdk.md)
- [Testing](docs/en/ecosystem/testing.md), [packaging](docs/en/ecosystem/packaging.md), and [third-party modules](docs/en/ecosystem/third-party-modules.md)
- [Ecosystem v0.1 implementation report](docs/en/ecosystem/ecosystem-v0.1-report.md)

## API

Server exports:

| Export                   | Returns        | Purpose                   |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | API version               |
| `GetProtocolVersion`     | number         | Protocol version          |
| `GetSpawnMode`           | string         | `automatic` or `manual`   |
| `GetVersion`             | table          | `gc_core` version         |
| `GetVersionString`       | string         | `0.1.5-alpha`             |
| `IsPlayerConnected`      | boolean        | Checks session            |
| `IsPlayerReady`          | boolean        | Checks readiness          |
| `IsPlayerSpawned`        | boolean        | Checks spawn              |
| `GetPlayerState`         | string or nil  | Returns state             |
| `GetPlayerSession`       | table or nil   | Returns session copy      |
| `GetPlayerIdentifier`    | string or nil  | Returns identifier        |
| `CanUseGameplayFeatures` | boolean        | Allows gameplay features  |
| `RequestPlayerSpawn`     | table or nil   | Requests spawn            |
| `NotifyPlayer`           | boolean        | Sends a notification      |
| `NotifyAll`              | boolean        | Sends a notification to all |

## Documentation

- [Documentation EN](docs/en/00-introduction.md)
- [Документация RU](docs/ru/00-introduction.md)
- [Diagrams](docs/diagrams/architecture.md)
- [Runtime and txAdmin](docs/en/18-runtime-txadmin.md)
- [Migration 0.1.1 → 0.1.2](docs/en/migration/0.1.1-to-0.1.2.md)
- [Module Contract v1](docs/en/module-contract.md)
- [Module dependency graph](docs/en/module-dependencies.md)
- [gc_identity design](docs/en/modules/gc_identity/design.md)
- [Pre-spawn registration and secure authorization](docs/en/modules/gc_identity/pre-spawn-registration.md)
- [gc_identity NUI lifecycle audit](docs/en/modules/gc_identity/nui-lifecycle-audit.md)
- [Persistent identity implementation report](docs/en/modules/gc_identity/implementation-report.md)
- [Module ecosystem stage report](docs/en/module-ecosystem-report.md)
- [API compatibility policy](docs/en/20-api-compatibility.md)

## Testing

All tests are written in Lua and are loaded only after explicit `gc_runTests 1` opt-in:

```text
resources/[greencore]/gc_core/tests/
```

Independent module suites:

```text
lua tools/module_test_harness.lua . gc_example
lua tools/module_test_harness.lua . gc_identity
lua tools/run-module-suite.lua .
lua tools/tests/run.lua .
lua tools/module_conformance.lua path/to/module
lua tools/package-module.lua path/to/module
```

## Security

- Server is the source of truth
- Client is never trusted
- All payloads are validated
- Identifiers are masked
- Rate limit on all events

## License

See [LICENSE.txt](LICENSE.txt).
