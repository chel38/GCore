# Pre-spawn registration and secure authorization

Current contract: `gc_core 0.1.5-alpha` (API 1, protocol 2) and
`gc_identity 0.4.1-alpha` (Identity API 1, protocol 3).

## Primary guarantee

When `gc_identity` is enabled, configure the server with:

```cfg
set gcore_spawn_mode manual
ensure gc_core
ensure gc_identity
```

In manual mode a client `gc_core:server:requestSpawn` is always rejected with
`GC-SPAWN-MANUAL-ONLY`. Only the trusted server export
`exports.gc_core:RequestPlayerSpawn(source)` may create a decision. The Core is
still independent: it knows a generic spawn policy, not accounts, email, or
`gc_identity` internals.

```text
clientReady
    ↓
core state = client_ready (no player PED yet)
    ↓
gc_identity Resolve
    ├─ new account → registration_required
    ├─ trusted license + same IP → authorized
    ├─ new IP → auth_verification_required
    └─ legacy account without a name → profile_completion_required
    ↓
gc_identity server confirms the security state
    ↓
exports.gc_core:RequestPlayerSpawn(source)
    ↓
core decision → client spawn → server verification
    ↓
gc_core:hook:playerSpawned
    ↓
post-spawn character selection → ready
```

## New-player registration

1. NUI submits `FirstName LastName` (exactly two ASCII-letter words) and email.
2. The server validates the payload, obtains license and endpoint itself,
   creates a bounded challenge, and sends the code through the local Mail Service.
3. A correct code only moves the challenge to `registration_verified`. No account
   exists, the player is not authorized, and no spawn is requested.
4. “Finish registration” sends only protocol/request identifiers. The server
   revalidates session generation, license, IP fingerprint, challenge, TTL, name,
   and email.
5. One DB transaction creates the account, identifier binding, registered name,
   verified email, and trusted IP, then consumes the challenge.
6. Only after commit does `gc_identity` call the Core spawn export once.

Changing email before finalization consumes the old challenge, retains the name,
resets `emailVerified`, and returns to `registration_required`. The old code is
unusable and abuse counters are not reset.

## Returning player and new IP

- Server-observed license and HMAC IP fingerprint both match: skip registration
  NUI/mail and release spawn immediately.
- Known license with a new IP: authentication email is mandatory before spawn.
- No public event accepts client-supplied license or IP.
- Mail Service or MariaDB failure stays fail-closed in a visible pre-spawn state.

## Registered name and characters

`gc_accounts.first_name/last_name` is the account's registered name. It is not a
FiveM nickname and not a character name. Legacy accounts with `NULL` names enter
`profile_completion_required` before spawn. Character create/select remains a
post-spawn domain.

Identity Public API v1 was extended additively:

```lua
local displayName = exports.gc_identity:GetDisplayName(source) -- string | nil
local account = exports.gc_identity:GetAccount(source)          -- copied DTO
```

The Account DTO contains `id`, `email`, `firstName`, `lastName`, `displayName`,
`status`, and `createdAt`; it excludes license, IP fingerprints, challenges,
hashes, and DB metadata.

## Network contract v3

| Event | Direction | Payload | Authority |
|---|---|---|---|
| `gc_identity:server:sendRegistrationCode` | client → server | `protocolVersion, requestId, fullName, email` | validation + rate limit |
| `gc_identity:server:verifyEmail` | client → server | `protocolVersion, requestId, code` | verification only |
| `gc_identity:server:changeRegistrationEmail` | client → server | `protocolVersion, requestId` | invalidates challenge |
| `gc_identity:server:finalizeRegistration` | client → server | `protocolVersion, requestId` | atomic server commit |
| `gc_identity:server:completeProfile` | client → server | `protocolVersion, requestId, fullName` | legacy profile gate |
| `gc_identity:client:snapshot` | server → client | Public snapshot | server-origin guard |

## Restart and diagnostics

MariaDB persists a pending challenge and restores it through a server-derived
binding. A verified challenge is restored but never auto-finalized. After a
`gc_core` restart, manual recovery returns a player without a live PED to
`client_ready`, and identity decides again whether spawn may be released.
Duplicate hello/finalize/spawn hooks are idempotent.

Primary codes: `GC-SPAWN-MANUAL-ONLY`,
`GC-IDENTITY-SPAWN-MODE-MISCONFIGURED`, `GC-IDENTITY-NAME-INVALID`,
`GC-IDENTITY-REGISTRATION-NOT-VERIFIED`, and
`GC-IDENTITY-EMAIL-CHALLENGE-STALE`.
