# gc_identity 0.1.0-alpha — design

Status: approved MVP design before implementation.
Module API: 1. Module protocol: 1. Required Core API: 1.

## Responsibility

`gc_core` knows that a network player is connected and spawned. `gc_identity`
answers a separate question: which server-owned account and character belong to
that player for this session.

The MVP owns:

- license-backed account resolution and automatic first account creation;
- character creation, listing, ownership validation, and selection;
- an explicit identity state machine;
- detached Public Account and Character DTOs;
- a small persistence boundary and a JSON file adapter;
- its own validation, rate limits, error namespace, and restart recovery.

## Non-responsibility

The module does not own core connection/spawn state, passwords, web login, roles,
permissions, money, inventory, jobs, admin, NUI, or a general database/ORM. It
never mutates `gc_core` state and `gc_core` never imports `gc_identity`.

## Dependency and gameplay rule

```text
gc_core Public API v1
          ↑
     gc_identity
```

Every operation queries current core exports. Bootstrap requires a connected,
ready player. Character mutation additionally requires
`CanUseGameplayFeatures(source)`. Core API v1 continues to mean only
`core state == spawned`; a domain module that needs identity must check both:

```lua
exports.gc_core:CanUseGameplayFeatures(source)
    and exports.gc_identity:IsIdentityReady(source)
```

This keeps the dependency one-way and requires no core change.

## State machine

```text
unknown
   ↓
account_required ── create/resolve trusted account ──→ authorized
                                                        ↓
                              ┌─ selected character ──→ ready
                              └─ no selection ────────→ character_required

any active state ── unrecoverable repository/config failure ──→ error
disconnect/resource stop ──────────────────────────────────────→ removed
```

`authorized` is an explicit account milestone, not a client claim. Transitions
are performed only by the identity state service. Duplicate hello and replayed
request IDs are idempotent and cannot create a second account or character.

## Data model

Internal Account:

```text
id, identifierType, identifier, selectedCharacterId, createdAt, updatedAt
```

Internal Character:

```text
id, accountId, firstName, lastName, createdAt, updatedAt
```

The trusted identifier is captured from the server-only core API. It is persisted
only for lookup, never logged, sent to the client, or included in a Public DTO.

Public Account DTO: `id`, `createdAt`.
Public Character DTO: `id`, `firstName`, `lastName`, `createdAt`.

All DTOs are copies. Mutating a returned DTO cannot mutate repository or runtime
state.

## Public server API v1

| Export | Arguments | Return |
| --- | --- | --- |
| `GetIdentityVersion` | none | resource version string |
| `GetIdentityApiVersion` | none | integer API version |
| `GetIdentityProtocolVersion` | none | integer protocol version |
| `IsAuthorized` | player source | boolean |
| `IsIdentityReady` | player source | boolean |
| `GetIdentityState` | player source | state or `nil` |
| `GetAccount` | player source | detached Account DTO or `nil` |
| `GetCharacters` | player source | detached Character DTO array |
| `GetSelectedCharacter` | player source | detached Character DTO or `nil` |

No public API mutates identity state in v1.

## Network events

Client → server:

- `gc_identity:server:hello` — `{ protocolVersion }`;
- `gc_identity:server:createCharacter` — `{ protocolVersion, requestId,
  firstName, lastName }`;
- `gc_identity:server:selectCharacter` — `{ protocolVersion, requestId,
  characterId }`.

Server → client only:

- `gc_identity:client:snapshot` — current public identity snapshot;
- `gc_identity:client:rejected` — `{ requestId?, code }`.

Client handlers require FiveM server origin (`source == 65535`). Payload schemas
reject unknown fields. Requests are rate-limited per source/action. A bounded
request-result cache makes duplicate request IDs idempotent.

## Persistence model

`GCIdentityRepository` is the only component that reads or writes storage. The
first adapter uses `LoadResourceFile`/`SaveResourceFile` with
`data/identities.json`; this keeps the MVP deployable without adding a database
dependency to either module or core. Runtime services do not call JSON or storage
natives directly. A future database adapter may replace this boundary without
changing API v1.

Writes replace the complete small alpha data set and return explicit errors. The
JSON file is runtime data and is excluded from Git. This adapter is suitable for
the MVP, not a high-volume production database.

## Restart and recovery

- On `gc_identity` start, persisted data loads before the module becomes ready.
- The server scans online players once and rebuilds runtime sessions through
  current core exports.
- The client sends bounded hello attempts on identity or core resource start.
- On `gc_core` start, identity re-checks API compatibility and rebuilds all online
  identity sessions idempotently.
- FiveM stops declared dependants during `restart gc_core`; the operator then runs
  `ensure gc_identity`. That start path performs the same bounded online-player
  recovery and restores the persisted selected character.
- Disconnect removes runtime state, rate limits, and replay cache; persisted
  account/characters remain.
- Every async/recovery path is bounded and cancels when its resource generation
  is no longer current.

## Security model

- The client never submits an identifier, account ID, ownership result, or
  authorization state.
- Account lookup uses `gc_core:GetPlayerIdentifier` on the server.
- Character selection verifies repository ownership server-side.
- Character strings have type, byte-length, control-character, and forbidden
  punctuation checks.
- Strict payload schemas, protocol checks, rate limits, and request replay
  handling protect all ingress events.
- Account enumeration is impossible through Public API because lookups are by
  current player source only.
- Passwords do not exist in this MVP. No password or custom hashing scheme is
  introduced.
- Logs contain source and stable codes, never identifiers or character secrets.

Threats covered by tests: malformed/oversized input, duplicate requests, replay,
wrong state, stopped core, rate-limit abuse, foreign character ID, local spoof of
server-only events, DTO mutation, restart recovery, and disconnect cleanup.

## Failure cases

Stable namespaces include:

- `GC-IDENTITY-CORE-*` for missing/incompatible lifecycle;
- `GC-IDENTITY-PAYLOAD-*` for schema/type failures;
- `GC-IDENTITY-RATE-LIMIT` for bounded ingress;
- `GC-IDENTITY-ACCOUNT-*` and `GC-IDENTITY-CHARACTER-*` for domain failures;
- `GC-IDENTITY-STORAGE-*` for repository failures;
- `GC-IDENTITY-PROTOCOL-MISMATCH` and `GC-IDENTITY-SECURITY-*` for trust-boundary failures.

Failures are fail-closed: no state commit is made until validation and required
persistence succeed.
