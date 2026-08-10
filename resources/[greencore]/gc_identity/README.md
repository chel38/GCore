# gc_identity

`gc_identity` is the independent, server-authoritative account and character
domain for GCore. `gc_core` owns connection/session/spawn; this resource owns
registration, trusted identifier authorization, characters, and identity
readiness.

- Resource version: `0.2.0-alpha`
- Identity API: `1` (backward-compatible, additive health export)
- Identity protocol: `1`
- Required Core API: `>= 1`
- Persistence: MariaDB through `oxmysql`
- NUI: TypeScript + Tailwind CSS

## What it does

First connection:

```text
trusted server-side FiveM license
            ↓
no account → explicit email registration
            ↓
create/select an owned character
            ↓
identity state = ready
```

Returning connection:

```text
trusted license → persisted account → persisted selection → ready
```

Passwords are deliberately disabled in this milestone. The module does not
collect, transmit, store, or pretend to validate a password. A client-provided
identifier, account ID, authorization claim, or character ownership claim is
never trusted.

## Installation

1. Install the release build of `oxmysql` as resource `oxmysql`.
2. Run MariaDB and create a dedicated database/user.
3. Configure the connection string outside the repository:

```cfg
set mysql_connection_string "mysql://gcore:CHANGE_ME@127.0.0.1:3306/gcore?charset=utf8mb4"
ensure oxmysql
ensure gc_core
ensure gc_identity
```

Do not commit database credentials. `gc_identity` applies ordered, idempotent
migrations on start. It stays explicitly degraded when MariaDB/oxmysql or a
migration is unavailable; it never silently falls back to JSON.

The old `data/identities.json` adapter is read-only migration input. With
`storage.importLegacyJson = true`, legacy records are imported idempotently and
must complete email registration. Back up MariaDB and the legacy file before a
production migration.

## NUI and commands

The NUI provides loading, registration, character creation/selection, errors,
and an exit confirmation. It holds focus and freezes the local presentation ped
until authoritative state is `ready`. NUI callbacks only request actions; the
server validates lifecycle, exact schema, rate, replay ID, and ownership.

Diagnostic commands remain available:

- `/gcidentity` — request a fresh snapshot;
- `/gcregister email@example.com` — request registration;
- `/gccreate FirstName LastName` — request character creation;
- `/gcselect ID` — request selection.

## State machine

```text
uninitialized → loading → registration_required → registering
                         ↘ authorized → character_required
                                         ↓
                                  character_selected → ready

active state → error/disconnecting (validated transitions only)
```

## Public server API v1

| Export | Return |
| --- | --- |
| `GetIdentityVersion()` | resource version string |
| `GetIdentityApiVersion()` | integer API version |
| `GetIdentityProtocolVersion()` | integer protocol version |
| `GetIdentityHealth()` | detached health DTO |
| `IsAuthorized(source)` | boolean |
| `IsIdentityReady(source)` | boolean |
| `GetIdentityState(source)` | state or `nil` |
| `GetAccount(source)` | detached Account DTO or `nil` |
| `GetCharacters(source)` | detached Character DTO array |
| `GetSelectedCharacter(source)` | detached Character DTO or `nil` |

Account DTO: `id`, `email`, `status`, `createdAt`. Character DTO: `id`,
`firstName`, `lastName`, `createdAt`. Trusted identifiers, database metadata,
rate-limit state, replay cache, and internal account/character references never
cross the public boundary. Every DTO is a copy.

```lua
local coreReady = exports.gc_core:CanUseGameplayFeatures(source)
local identityReady = exports.gc_identity:IsIdentityReady(source)

if not coreReady or not identityReady then
    return
end
```

## Network contract

Client → server (internal): `hello`, `registerAccount`, `createCharacter`,
`selectCharacter`, `exit`. Server → client only (internal): `snapshot`,
`rejected`. Exact schemas live in `shared/events.lua` and
`server/validation.lua`. Server-only client handlers require FiveM origin
`source == 65535`.

## Restart policy

`restart gc_identity` performs a bounded online-player recovery and restores
the persisted account/selection. FiveM stops declared dependants when
`gc_core` is restarted; the operator must then run `ensure gc_identity`. This
ordering is a FiveM resource dependency behavior, not a data-loss condition.

## Development

```sh
lua tools/module_test_harness.lua . gc_identity
cd resources/[greencore]/gc_identity/web
pnpm install --frozen-lockfile
pnpm test
pnpm build
```

See the [design](../../../docs/en/modules/gc_identity/design.md),
[persistence design](../../../docs/en/modules/gc_identity/persistence-design.md),
and [implementation report](../../../docs/en/modules/gc_identity/implementation-report.md).

## Troubleshooting

- `GC-IDENTITY-DATABASE-UNAVAILABLE`: verify MariaDB, connection string, and
  `ensure oxmysql` ordering.
- `GC-IDENTITY-MIGRATION-FAILED`: inspect the first failed migration; do not
  bypass it or enable a fallback.
- `GC-IDENTITY-EMAIL-TAKEN`: the normalized email is already owned.
- `GC-IDENTITY-PROTOCOL-MISMATCH`: client/server module builds differ.
- stopped after `restart gc_core`: run `ensure gc_identity`.
