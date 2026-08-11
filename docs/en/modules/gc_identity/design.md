# gc_identity 0.4.0-alpha — implemented design

Status: implemented and validated with automated tests; current runtime results
are documented separately. Identity API 1 remains compatible; protocol 3 adds
pre-spawn registered-name/email finalization and the new-IP handshake.

## Responsibility

`gc_core` owns network lifecycle and waits for a trusted server spawn release in
manual mode. `gc_identity` resolves account/security before spawn and owns the
selected character after authoritative spawn confirmation.

The module owns explicit registration, authorization by a trusted server-side
FiveM identifier, registered account name, character identity, Public Identity API/DTOs, MariaDB
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
`registration_required`; submitting a normalized registered name and unique
email creates a DB-backed one-time challenge, not an account. A correct code
only marks that challenge verified; explicit finalization atomically
creates/links the account, stores its name, verifies email, and saves the first
HMAC IP fingerprint. A returning same-IP identifier authorizes automatically;
a new observed IP requires another email code. Password authentication is disabled and no password-shaped data is
accepted or persisted.

## State machine

```text
uninitialized
    ↓
 loading ──────────────→ error
    ├─ unknown identifier → registration_required → registering
    │                       → email_verification_pending → registration_verified
    │                       → registration_finalizing → authorized → spawn_releasing
    ├─ persisted account + new IP → auth_verification_required → authorized
    └─ persisted account + same IP ────────────────────────────→ authorized
                                                     ↓
                                      post_spawn_identity → character_required
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

The client may submit only registered full name, email, a verification code,
character names, or a character ID. It cannot
submit trusted identifiers, account ID, authorization state, ownership, or
database fields.

## Public API v1

| Export | Contract |
| --- | --- |
| `GetIdentityVersion` | `string` |
| `GetIdentityApiVersion` | integer `1` |
| `GetIdentityProtocolVersion` | integer `3` |
| `GetDisplayName(source)` | string or nil, copy-safe registered account name |
| `GetIdentityHealth` | detached `{ available, storage, database, mail }` DTO |
| `IsAuthorized` | boolean for a valid current source |
| `IsIdentityReady` | true only in identity state `ready` |
| `GetIdentityState` | state string or `nil` |
| `GetAccount` | detached Account DTO or `nil` |
| `GetCharacters` | detached Character DTO array |
| `GetSelectedCharacter` | detached Character DTO or `nil` |

Account DTO contains `id`, `email`, `firstName`, `lastName`, `displayName`,
`status`, `createdAt`. Character DTO contains
`id`, `firstName`, `lastName`, `createdAt`. Identifiers, account ownership keys,
internal timestamps, SQL metadata, replay/rate state, and mutable references are
private.

## Network and NUI contract

| Event | Direction | Payload |
| --- | --- | --- |
| `gc_identity:server:hello` | client → server | `{ protocolVersion }` |
| `gc_identity:server:sendRegistrationCode` | client → server | `{ protocolVersion, requestId, fullName, email }` |
| `gc_identity:server:changeRegistrationEmail` | client → server | `{ protocolVersion, requestId }` |
| `gc_identity:server:finalizeRegistration` | client → server | `{ protocolVersion, requestId }` |
| `gc_identity:server:completeProfile` | client → server | `{ protocolVersion, requestId, fullName }` |
| `gc_identity:server:verifyEmail` | client → server | `{ protocolVersion, requestId, code }` |
| `gc_identity:server:resendVerification` | client → server | `{ protocolVersion, requestId }` |
| `gc_identity:server:createCharacter` | client → server | `{ protocolVersion, requestId, firstName, lastName }` |
| `gc_identity:server:selectCharacter` | client → server | `{ protocolVersion, requestId, characterId }` |
| `gc_identity:server:clientFailure` | client → server | allowlisted `{ protocolVersion, code }` |
| `gc_identity:server:exit` | client → server | `{ protocolVersion }` |
| `gc_identity:client:snapshot` | server → client only | Public snapshot |
| `gc_identity:client:rejected` | server → client only | `{ requestId?, code }` |

Server-only client events require `source == 65535`. NUI callbacks map to these
requests; local pending state prevents double submit, while authoritative replay
protection remains server-side.

The eagerly loaded HTML uses a transparent document canvas and an explicitly
hidden initial root. The JavaScript-ready callback causes Lua to replay the stored
snapshot; focus/freeze are applied only after that ACK. Terminal storage/hello
errors have a retry/exit view. Missing JavaScript readiness is bounded and ends
in a validated controlled disconnect.

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
[implementation report](implementation-report.md), plus the
[NUI lifecycle audit](nui-lifecycle-audit.md).
