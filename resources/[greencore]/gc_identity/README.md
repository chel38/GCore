# gc_identity

`gc_identity` is the independent, server-authoritative account and character
domain for GCore. `gc_core` owns connection/session/spawn; this resource owns
registration, trusted identifier authorization, characters, and identity
readiness.

- Resource version: `0.3.0-alpha`
- Identity API: `1` (backward-compatible)
- Identity protocol: `2` (mandatory email verification handshake)
- Required Core API: `>= 1`
- Persistence: MariaDB through `oxmysql`
- NUI: TypeScript + Tailwind CSS

## What it does

First connection:

```text
trusted server-side FiveM license
            ↓
no account → email → server-generated one-time code
            ↓
verified challenge → transactional account creation
            ↓
create/select an owned character
            ↓
identity state = ready
```

Returning connection:

```text
trusted license + same server-observed IP → automatic authorization
trusted license + new IP → email code → authorization
```

Passwords are deliberately disabled. The module does not
collect, transmit, store, or pretend to validate a password. A client-provided
identifier, account ID, authorization claim, or character ownership claim is
never trusted.

## Installation

1. Install the release build of `oxmysql` as resource `oxmysql`.
2. Run MariaDB and create a dedicated database/user.
3. Configure the connection string outside the repository:

```cfg
set mysql_connection_string "mysql://gcore:CHANGE_ME@127.0.0.1:3306/gcore?charset=utf8mb4"
set gcore_mail_service_url "http://127.0.0.1:8091"
set gcore_mail_token "replace-with-the-mail-service-token"
set gcore_identity_challenge_secret "independent-random-secret-minimum-32-characters"
set gcore_ip_fingerprint_secret "another-independent-random-secret-minimum-32-characters"
ensure oxmysql
ensure gc_core
ensure gc_identity
```

Do not commit database credentials. `gc_identity` applies ordered, idempotent
migrations on start. It stays explicitly degraded when MariaDB/oxmysql or a
migration is unavailable; it never silently falls back to JSON.

The old `data/identities.json` adapter is read-only migration input. With
`storage.importLegacyJson = true`, legacy records are imported idempotently and
must complete email verification. Back up MariaDB and the legacy file before a
production migration.

Run the separate localhost-only [GCore Mail Service](../../../mail-service/README.md)
before starting verification flows. Same-IP returning players do not depend on
mail availability; new registrations and new-IP logins fail closed when mail is
unavailable.

## NUI and commands

The NUI document has a transparent canvas and an explicitly hidden root when
FiveM eagerly loads its HTML. JavaScript first acknowledges `ready`; Lua then
replays the latest authoritative snapshot. Only a
non-ready snapshot may open the UI, acquire focus, and freeze the local
presentation ped. A `ready` snapshot remains hidden and releases both focus and
the ped. NUI callbacks only request actions; the server validates lifecycle,
exact schema, rate, replay ID, and ownership.

Database degradation and bounded hello exhaustion render a diagnostic retry/exit
view. If the JavaScript bundle never acknowledges readiness, the client releases
focus and the server performs one validated controlled disconnect instead of
leaving an infinite black screen.

Diagnostic commands remain available:

- `/gcidentity` — request a fresh snapshot;
- `/gcregister email@example.com` — request registration;
- `/gcverify 483921` — submit a verification code;
- `/gccreate FirstName LastName` — request character creation;
- `/gcselect ID` — request selection.

## State machine

```text
uninitialized → loading → registration_required → registering
                         → email_verification_pending → registering
loading → auth_verification_required → loading
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

Client → server (internal): `hello`, `registerAccount`, `verifyEmail`,
`resendVerification`, `createCharacter`, `selectCharacter`, allowlisted `clientFailure`, `exit`. Server → client only
(internal): `snapshot`, `rejected`. Exact schemas live in `shared/events.lua` and
`server/validation.lua`. Server-only client handlers require FiveM origin
`source == 65535`.

## Restart policy

`restart gc_identity` performs a bounded online-player recovery. DB-backed
one-time challenges survive until TTL and are rebound to the recovered session;
persisted account/selection remains intact. FiveM stops declared dependants when
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
[implementation report](../../../docs/en/modules/gc_identity/implementation-report.md),
and [NUI lifecycle audit](../../../docs/en/modules/gc_identity/nui-lifecycle-audit.md).
The verification/security flow is documented separately in
[email verification](../../../docs/en/modules/gc_identity/email-verification.md).

## Troubleshooting

- `GC-IDENTITY-DATABASE-UNAVAILABLE`: verify MariaDB, connection string, and
  `ensure oxmysql` ordering.
- `GC-IDENTITY-MIGRATION-FAILED`: inspect the first failed migration; do not
  bypass it or enable a fallback.
- `GC-IDENTITY-EMAIL-TAKEN`: the normalized email is already owned.
- `GC-IDENTITY-EMAIL-CODE-INVALID/EXPIRED/ATTEMPTS`: request a valid/new code.
- `GC-IDENTITY-MAIL-SEND-FAILED/TIMEOUT`: inspect the localhost mail service and SMTP.
- `GC-IDENTITY-PROTOCOL-MISMATCH`: client/server module builds differ.
- `GC-IDENTITY-HELLO-TIMEOUT`: no authoritative identity response arrived within
  the bounded retry window; inspect core and database health.
- `GC-IDENTITY-NUI-NOT-READY`: the built JavaScript did not call the NUI-ready
  callback; rebuild `web/dist` and inspect the FiveM client log.
- stopped after `restart gc_core`: run `ensure gc_identity`.
