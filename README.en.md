# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore runtime is 100% Lua.**
> **GreenCore runtime полностью написан на Lua.**
>
> Server, client, shared, config, locales and tests of `gc_core` — all in Lua.
> Further development and adding **NUI** will use **TypeScript + Tailwind CSS**
> and other modern FiveM-supported technologies. **C# will not be used.**

---

## Purpose

GreenCore is a minimal modular engine for FiveM written entirely in Lua 5.4.
It handles the secure player lifecycle:

```text
Connection → Validation → Session → Client readiness → Spawn → Confirmation → Disconnection
```

## Development status

**0.1.2-alpha** — stabilized early-alpha release.

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

## Version limitations

The first version does **not** include:

- Registration, accounts, characters
- Database
- Money, inventory, vehicles
- Chat, HUD, admin panel
- NUI (will be added later) / NUI (будет добавлен позже)
- C# (not planned) / C# (не планируется)

> **When NUI is added, it will be written with TypeScript + Tailwind CSS**
> **and other modern FiveM technologies. C# will not be used.**
> **NUI, когда будет добавлен, будет написан на TypeScript + Tailwind CSS**
> **и других современных технологиях FiveM. C# не будет использоваться.**

## Requirements

- FXServer (current version)
- Windows or Linux
- OneSync
- Lua 5.4 (runtime is entirely Lua / runtime полностью на Lua)

## Installation

1. Open your FiveM server resources folder.
2. Create a `[greencore]` folder.
3. Place `gc_core` into this folder.
4. Open `server.cfg`.
5. Add:

```cfg
ensure gc_core
```

6. Save `server.cfg`.
7. Start FXServer.
8. Look for the message:

```text
[GreenCore] [INFO] gc_core 0.1.2-alpha started successfully
```

## Configuration

All configuration is stored in Lua files under `resources/[greencore]/gc_core/config/`.

## Structure

```text
resources/[greencore]/gc_core/
├── fxmanifest.lua
├── config/       # Lua configuration
├── locales/      # Lua localization
├── shared/       # Shared code
├── server/       # Server logic
├── client/       # Client logic
└── tests/        # Lua tests
```

## API

Server exports:

| Export                   | Returns        | Purpose                   |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | API version               |
| `GetProtocolVersion`     | number         | Protocol version          |
| `GetVersion`             | table          | `gc_core` version         |
| `GetVersionString`       | string         | `0.1.2-alpha`             |
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

## Testing

All tests are written in Lua and are loaded only after explicit `gc_runTests 1` opt-in:

```text
resources/[greencore]/gc_core/tests/
```

## Security

- Server is the source of truth
- Client is never trusted
- All payloads are validated
- Identifiers are masked
- Rate limit on all events

## License

See [LICENSE.txt](LICENSE.txt).
