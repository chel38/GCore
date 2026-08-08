# Public Server API v1

API Version: `1`

Status: **Stable for module development**

Side: **SERVER only**

The source of truth is `server/api.lua` plus `server/exports.lua`. Every returned
table is detached from internal state. Breaking changes require a new API version
and migration notes; see the [compatibility policy](20-api-compatibility.md).

## Contract table

| Name | Arguments | Returns / types | Allowed states | Errors / nil behavior | Introduced | Security notes |
| --- | --- | --- | --- | --- | --- | --- |
| `GetVersion` | none | fresh version DTO (`table`) | any | none | API 1 | Mutating it cannot change `GCVersion`. |
| `GetVersionString` | none | resource version (`string`) | any | none | API 1 | Do not use it as a module compatibility gate. |
| `GetApiVersion` | none | API version (`integer`) | any | none | API 1 | Preferred module compatibility gate. |
| `GetProtocolVersion` | none | network protocol (`integer`) | any | none | API 1 | Diagnostic; modules normally do not implement the core protocol. |
| `IsPlayerConnected` | `playerSource: integer > 0` | `boolean` | any | invalid/missing source → `false` | API 1 | Means an active gc_core session exists. |
| `IsPlayerReady` | `playerSource` | `boolean` | `client_ready`, spawn states, `spawned`, `resyncing` | invalid/disconnected → `false` | API 1 | Does not mean gameplay is allowed. |
| `IsPlayerSpawned` | `playerSource` | `boolean` | exactly `spawned` | invalid/disconnected → `false` | API 1 | Reads authoritative lifecycle state. |
| `GetPlayerState` | `playerSource` | lifecycle state (`string`) or `nil` | any active session | invalid/disconnected → `nil` | API 1 | Read-only; modules cannot mutate state. |
| `GetPlayerSession` | `playerSource` | Public Player DTO (`table`) or `nil` | any active session | invalid/disconnected → `nil` | API 1 | No sessionId, identifiers, decisions, security, or rate-limit internals. |
| `GetPlayerIdentifier` | `playerSource`, allowlisted `identifierType: string` | captured identifier (`string`) or `nil` | any active session | invalid type/source, absent identifier, or disconnected → `nil` | API 1 | Sensitive server data; do not forward to clients without an explicit policy. |
| `CanUseGameplayFeatures` | `playerSource` | `boolean` | exactly `spawned` | invalid/disconnected → `false` | API 1 | In API v1 this means only `state == spawned`; it promises no identity/character checks. |
| `RequestPlayerSpawn` | `playerSource` | decision (`table`) or `nil`, error code (`string`) or `nil` | `client_ready` or `spawn_pending` | invalid source → `GC-PAYLOAD-TYPE-001`; invalid lifecycle/duplicate → `GC-SPAWN-DECISION-001` | API 1 | Uses the same state machine and decision authority as network ingress. |
| `NotifyPlayer` | `playerSource`, `message: string`, optional type | `boolean`, error code or `nil` | active session | `GC-NOTIFY-001..004`; message is bounded to 256 bytes | API 1 | Server-only; resulting client event is server-origin guarded. |
| `NotifyAll` | `message: string`, optional type | `boolean`, error code or `nil` | any | `GC-NOTIFY-002/003`; message is bounded to 256 bytes | API 1 | Broadcast side effect; call only from trusted server code. |

Allowed notification types are `info`, `success`, `warning`, and `error`.
Allowed identifier types are `license`, `license2`, `fivem`, `discord`, `steam`,
`xbl`, `live`, and `ip`.

## Public DTO

```lua
local player = exports.gc_core:GetPlayerSession(source)
-- {
--   source, state, playerName,
--   connectedAt, clientReadyAt, spawnedAt,
--   lastPed, locale
-- }
```

Every call returns a new table. Modifying `player.state` or version DTO fields has
no effect on gc_core.

## Module example

```lua
local REQUIRED_API_VERSION = 1

if exports.gc_core:GetApiVersion() < REQUIRED_API_VERSION then
    error('gc_example requires GCore API v1')
end

if exports.gc_core:CanUseGameplayFeatures(source) then
    local player = exports.gc_core:GetPlayerSession(source)
    exports.gc_core:NotifyPlayer(source, ('Ready: %s'):format(player.playerName), 'success')
end
```

Continue with the [Module Contract](module-contract.md).
