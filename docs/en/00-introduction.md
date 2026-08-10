# Introduction / Введение

## What is GreenCore?

GreenCore (GCore) is a minimal modular engine for FiveM written **entirely in Lua 5.4**.

It handles the secure player lifecycle:

```text
Connection → Validation → Session → Client readiness → Spawn → Confirmation → Disconnection
```

## Main principle

```text
Server is the source of truth.
Сервер является источником истины.
```

The client does **not** decide:

- whether it can connect;
- where to spawn;
- which model to use;
- whether the spawn is complete.

The client can only:

- report readiness;
- receive the server decision;
- perform an allowed action;
- confirm the execution.

## Technology stack

| Component | Technology |
| --------- | ---------- |
| Server    | Lua 5.4    |
| Client    | Lua 5.4    |
| Configuration | Lua 5.4 |
| Localization | Lua 5.4 |
| Tests     | Lua 5.4    |
| Documentation | Markdown, Mermaid |
| Module NUI | TypeScript + Tailwind CSS |
| Identity persistence | MariaDB + oxmysql |

> **`gc_identity` already uses TypeScript + Tailwind CSS for NUI. C# is not used.**

## What is NOT included in the first version

- Registration, accounts, and characters inside `gc_core` (owned by `gc_identity`)
- A general database/ORM inside `gc_core`
- Money, inventory, vehicles
- Chat, HUD, admin panel

## Project structure

```text
GreenCore/
├── README.md
├── docs/
│   ├── ru/
│   ├── en/
│   └── diagrams/
├── examples/
└── resources/
    └── [greencore]/
        ├── gc_core/
        ├── gc_example/
        └── gc_identity/
```

## Next step

Go to [Installation](01-installation.md).
