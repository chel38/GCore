# Server API v1

Exports are thin adapters over the testable `GCAPI`. They validate source values
and never return internal tables.

| Export | Returns | Contract |
| --- | --- | --- |
| `GetVersion` | table | a fresh, detached version DTO |
| `GetVersionString` | string | `0.1.2-alpha` |
| `GetApiVersion` | number | public API version |
| `GetProtocolVersion` | number | network protocol version |
| `IsPlayerConnected` | boolean | active session exists |
| `IsPlayerReady` | boolean | lifecycle reached ready/resync/spawn |
| `IsPlayerSpawned` | boolean | authoritative state is `spawned` |
| `GetPlayerState` | string or nil | current state |
| `GetPlayerSession` | table or nil | safe session DTO |
| `GetPlayerIdentifier` | string or nil | server-only identifier by allowed type |
| `CanUseGameplayFeatures` | boolean | true only for `spawned` |
| `RequestPlayerSpawn` | table/nil, error/nil | server-side spawn request |
| `NotifyPlayer` | boolean, error/nil | notify one player |
| `NotifyAll` | boolean, error/nil | notify all players |

```lua
local version = exports.gc_core:GetVersion()
-- version.version == '0.1.2-alpha'
-- version.apiVersion == 1
-- version.protocolVersion == 1
```

Mutating the returned DTO cannot mutate the internal version. Likewise,
`GetPlayerSession` never exposes `sessionId`, identifiers, spawn decisions,
rate-limit data, or security state. `GetPlayerIdentifier` is for trusted server
resources only and should not be forwarded to clients without a concrete need.

Continue with the [client API](10-client-api.md).
