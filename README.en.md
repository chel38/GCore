# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore uses Lua 5.4 for all server-side and client-side logic.**
> **GreenCore использует Lua 5.4 для всей серверной и клиентской логики.**

**Lua for logic. TypeScript + Tailwind for NUI. / Логика — только Lua. NUI — TypeScript + Tailwind.**

---

## Purpose

GreenCore is a minimal modular engine for FiveM written entirely in Lua 5.4.
It handles the secure player lifecycle:

```text
Connection → Validation → Session → Client readiness → Spawn → Confirmation → Disconnection
```

## Development status

**0.1.0** — first working version.

## Version features

- Connection validation via deferrals
- Identifier validation
- In-memory Lua sessions
- Player state management
- Network event rate limiting
- Server-side spawn decision
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

## Requirements

- FXServer (current version)
- Windows or Linux
- OneSync
- Lua 5.4 (enabled via `lua54 'yes'`)

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
[GreenCore] [INFO] gc_core 0.1.0 started successfully
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
| `GetVersion`             | table          | `gc_core` version         |
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

## Testing

All tests are written in Lua:

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