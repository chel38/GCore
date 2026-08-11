# gc_identity persistent identity implementation report

Date: 2026-08-10

> Historical milestone report. The current `gc_identity 0.3.0-alpha` replaces
> direct trusted-identifier login with verified email plus a server-observed IP
> fingerprint. See [Email verification](email-verification.md) and the module
> README for the active contract.

Audited baseline: `d1abbf0476e0ca3a5e284fe319cedef43839bc87`

Core: `0.1.4-alpha`, API `1`, protocol `1`
Identity: `0.2.0-alpha`, API `1`, protocol `1`

## Executive summary

The JSON-backed automatic-account MVP was replaced by an explicit persistent
registration and character flow. Production storage is MariaDB through
oxmysql; there is no runtime JSON fallback. The trusted server-side FiveM
identifier remains the authorization credential. Password authentication is
intentionally disabled rather than simulated.

`gc_core` was not changed and remains independent of the identity/database
domain. Public Identity API v1 remains backward-compatible; `GetIdentityHealth`
is additive.

## Phase results

| Phase | Result | Main outcome |
| --- | --- | --- |
| Current repository audit | PASS | verified versions, API boundary, tests, old JSON behavior |
| Persistence design | PASS | repository contract, schema, migrations, failure policy |
| MariaDB repository | PASS | oxmysql adapter, transactions, constraints, parameterization |
| Registration/authorization | PASS | explicit email registration; trusted identifier auto-login |
| Character persistence | PASS | transactional limit, ownership, selection |
| NUI | PASS | TypeScript/Tailwind build, callback bridge, focus lifecycle |
| Security/recovery | PASS | exact schemas, rate/replay, generation cancellation, restart tests |
| Automated verification | PASS | Lua suite, NUI tests, syntax, build, repository validation |
| Real one-client runtime | PASS WITH NOTE | MariaDB/oxmysql/FXServer/restart/reconnect validated |
| Real two-client runtime | NOT RUN | only one FiveM client was available |

## Architecture delivered

```text
gc_core Public API v1
        ↓
gc_identity network/NUI boundary
        ↓
identity service + explicit state machine
        ↓
GCIdentityRepository facade
        ↓
oxmysql adapter → MariaDB 12.3.2
```

Adapters are explicit:

- `oxmysql`: production default;
- `memory`: automated tests only;
- `json_legacy`: read-only import source, never a fallback.

## Schema and transactions

Migration `001_initial_identity` creates:

- `gc_accounts`;
- `gc_account_identifiers`;
- `gc_characters`;
- `gc_account_character_selections`;
- `gc_identity_schema_migrations` bootstrap history.

Unique email and identifier constraints, foreign keys, status checks, and
account-scoped indexes enforce storage invariants. Registration writes account
and identifier in one transaction. Character creation locks the account row and
enforces the configured active-character limit before insertion. Selection
locks and verifies the character before upsert. Runtime values use `?`
placeholders.

## Authentication and security

- Unknown trusted identifiers enter `registration_required`; lookup no longer
  auto-creates an account.
- Returning identifiers resolve the persisted account and selected character.
- Email is trimmed/lowercased, bounded, syntax-checked, and unique.
- Password collection/authentication is disabled and the snapshot states
  `passwordAuthentication = false`.
- Client payloads cannot contain trusted identifier/account/authority fields.
- Server-to-client events use the FiveM server-origin guard.
- Stable per-action rate limits and bounded replay results protect ingress.
- Public DTOs exclude identifier, account ownership keys, SQL metadata, and
  mutable internal tables.
- Logs filter email/password/token/secret-like keys.

## NUI result

The source and committed production build live under `gc_identity/web`.
Implemented views: loading, registration, character selection/creation, error,
and exit confirmation. Pending actions disable repeated submissions. Escape
opens/cancels exit confirmation. The client holds NUI focus and freezes the ped
until identity reaches `ready`, then releases both.

The web suite verifies: no password field, duplicate-submit blocking, exit
confirmation, and HTML escaping of DTO values.

## Automated test result

The identity Lua suite covers state, validation, memory/oxmysql repository
contracts, migration order/idempotency/failure, persistent registration,
returning authorization, character ownership/limit, two-player isolation,
replay, rate limiting, server-event spoofing, disconnect during storage,
restart/recovery, DTO/API contracts, NUI callbacks, and startup races.

CI also runs NUI dependency installation, tests, strict TypeScript checking,
production build, and verifies that committed `dist` is current.

## Real FXServer/MariaDB result

Environment:

- FXServer artifact `b25770`, txAdmin `8.0.1`;
- MariaDB `12.3.2` portable local runtime;
- oxmysql `2.14.1` release build;
- one real FiveM client, game build `3751`.

Observed:

1. oxmysql established a MariaDB connection.
2. Migration 001 applied once; subsequent starts reported zero pending.
3. A legacy JSON account imported once and was skipped idempotently later.
4. The real client connected without an `Awaiting scripts` hang and received
   `registration_required` through the real guarded snapshot boundary.
5. Registration/create/select were invoked for that online source through a
   temporary local smoke command calling the production service/repository.
   MariaDB recorded exactly one account, character, and selection; the hook was
   removed before the final build.
6. The client received `ready`; NUI readiness produced no timeout.
7. `restart gc_identity` restored `ready` with the player online and no duplicate
   rows. A startup hello race no longer flashes a false database error.
8. `restart gc_core` recovered the core player. FiveM stopped the declared
   dependent `gc_identity`; after the documented `ensure gc_identity`, identity
   recovered `ready` and preserved data.
9. Client termination produced `playerDropped`; MariaDB data remained.
10. Fresh reconnect used a new source and directly restored `ready` with one
    persisted character.

The registration form itself was not manually submitted through the real NUI;
its callback/network path is covered by the integration harness and the real
client observed both pre- and post-transaction snapshots. Two simultaneous real
clients were not available.

## Compatibility and migration

- Core version/API/protocol: unchanged.
- Identity API/protocol: still `1`.
- Identity resource version: `0.1.0-alpha` → `0.2.0-alpha`.
- Breaking deployment change: `oxmysql` and MariaDB are now required.
- Old JSON records can be imported idempotently. Imported records have no email
  and therefore require registration completion.
- Downstream export names and DTO isolation remain; Account DTO additively
  contains email/status after registration.

## Remaining technical debt

- Run a real 2+ client isolation/recovery test.
- Automate operator restart ordering if an ecosystem supervisor is introduced;
  currently FiveM requires `ensure gc_identity` after `restart gc_core` because
  it stops declared dependants.
- Add verified email or a real password/WebAuthn provider only as a separately
  designed security milestone. No placeholder password code should be added.
- Validate production backup/restore procedures on the deployment host.

## Final verdict

| Gate | Result |
| --- | --- |
| Core independence | PASS |
| Explicit registration | PASS |
| Trusted authorization | PASS |
| MariaDB persistence | PASS |
| Migration safety | PASS |
| Character ownership/selection | PASS |
| NUI and focus lifecycle | PASS |
| Security boundary | PASS |
| API v1 compatibility | PASS |
| Automated tests/CI | PASS |
| Real one-client persistence/reconnect | PASS |
| Real two-client validation | NOT RUN |

`gc_identity 0.2.0-alpha` is ready for continued alpha module development with
the two-client runtime check and production backup rehearsal explicitly open.
