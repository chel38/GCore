# gc_identity 0.2.0-alpha — implemented design

Status: implemented and validated with automated tests and a one-client real
FXServer/MariaDB smoke test. Identity API 1 and protocol 1 remain compatible.

## Responsibility

`gc_core` knows that a network player is connected and spawned. `gc_identity`
answers which persisted account and selected character belong to that player.

The module owns explicit registration, authorization by a trusted server-side
FiveM identifier, character identity, Public Identity API/DTOs, MariaDB
persistence, NUI interaction, and its own restart recovery. It does not own core
lifecycle, gameplay domains, permissions, money, inventory, or a general ORM.

```text
FiveM
  ↓
gc_core Public API v1
  ↓
gc_identity service
  ↓
repository facade → oxmysql → MariaDB
```

`gc_core` imports no identity code and remains database-independent.

## Authentication and registration

The primary credential is a server-captured `license`/`license2` selected through
`gc_core:GetPlayerIdentifier(source)`. It never comes from a client payload.

An unknown identifier does not create an account. It enters
`registration_required`; a normalized unique email plus the trusted identifier
are committed atomically. A returning identifier automatically resolves its
account. Password authentication is disabled and no password-shaped data is
accepted or persisted.

## State machine

```text
uninitialized
    ↓
 loading ──────────────→ error
    ├─ unknown identifier → registration_required → registering
    │                                          └──→ authorized
    └─ persisted account ─────────────────────────→ authorized
                                                     ↓
                                      character_required
                                             ↓
                                      character_selected
                                             ↓
                                           ready

any active state → disconnecting → runtime session removed
```

All changes use `GCIdentityStates.Transition`; services never assign
`session.state` directly. Session generation cancels stale database results after
disconnect or replacement.

## Server-authoritative flow

```text
NUI/client request
  → exact schema + protocol + rate + replay validation
  → current gc_core lifecycle check
  → repository transaction / ownership decision
  → current session generation check
  → state transition
  → detached server snapshot
  → guarded client handler
```

The client may submit only email, character names, or a character ID. It cannot
submit trusted identifiers, account ID, authorization state, ownership, or
database fields.

## Public API v1

| Export | Contract |
| --- | --- |
| `GetIdentityVersion` | `string` |
| `GetIdentityApiVersion` | integer `1` |
| `GetIdentityProtocolVersion` | integer `1` |
| `GetIdentityHealth` | detached `{ available, repository, database }` DTO |
| `IsAuthorized` | boolean for a valid current source |
| `IsIdentityReady` | true only in identity state `ready` |
| `GetIdentityState` | state string or `nil` |
| `GetAccount` | detached Account DTO or `nil` |
| `GetCharacters` | detached Character DTO array |
| `GetSelectedCharacter` | detached Character DTO or `nil` |

Account DTO contains `id`, `email`, `status`, `createdAt`. Character DTO contains
`id`, `firstName`, `lastName`, `createdAt`. Identifiers, account ownership keys,
internal timestamps, SQL metadata, replay/rate state, and mutable references are
private.

## Network and NUI contract

| Event | Direction | Payload |
| --- | --- | --- |
| `gc_identity:server:hello` | client → server | `{ protocolVersion }` |
| `gc_identity:server:registerAccount` | client → server | `{ protocolVersion, requestId, email }` |
| `gc_identity:server:createCharacter` | client → server | `{ protocolVersion, requestId, firstName, lastName }` |
| `gc_identity:server:selectCharacter` | client → server | `{ protocolVersion, requestId, characterId }` |
| `gc_identity:server:exit` | client → server | `{ protocolVersion }` |
| `gc_identity:client:snapshot` | server → client only | Public snapshot |
| `gc_identity:client:rejected` | server → client only | `{ requestId?, code }` |

Server-only client events require `source == 65535`. NUI callbacks map to these
requests; local pending state prevents double submit, while authoritative replay
protection remains server-side.

## Persistence and recovery

The production adapter is `oxmysql`. The memory adapter exists only for tests;
the JSON adapter is read-only legacy migration input. Startup is bounded:
database probe → migrations → repository → optional import → recovery. Any
failure is explicit degraded state with no fallback.

`restart gc_identity` rebuilds online sessions once and restores persisted
selection. When `gc_core` is administratively restarted, FiveM stops declared
dependants; `ensure gc_identity` must follow. Disconnect removes only runtime
state. Reconnect resolves the same account/selection without duplicate writes.

## Security baseline

- parameterized runtime SQL and database constraints;
- transactional registration, character limit, and selection;
- exact payload schemas and normalized bounded strings;
- per-source/action rate limits and bounded replay cache;
- ownership checked in the transaction, never in NUI;
- server-origin guards and DTO copy isolation;
- stable diagnostic codes without identifiers, email, or secrets in logs.

See [persistence design](persistence-design.md) and
[implementation report](implementation-report.md).
