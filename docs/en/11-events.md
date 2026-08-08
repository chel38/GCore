# Protocol v1 network events

Names are defined only in `shared/events.lua`. Do not duplicate string literals in
runtime code. Unknown payload fields are rejected.

## Client to server

| Event | Payload | State | Limit |
| --- | --- | --- | --- |
| `gc_core:server:clientReady` | `clientVersion`, `protocolVersion`, optional `locale` | `joining` | `clientReady` |
| `gc_core:server:requestSpawn` | empty table | `client_ready`/`spawn_pending` | `requestSpawn` |
| `gc_core:server:confirmSpawn` | `decisionId` only | `spawn_confirming` | `confirmSpawn` |
| `gc_core:server:reportClientError` | known `errorCode` | spawn flow | `reportClientError` |
| `gc_core:server:resyncReady` | handshake + optional `isPedAlive` hint | `resyncing` | `resyncReady` |

`clientReady` and `resyncReady` share one handshake validator. Protocol must be a
finite integer and exactly match `GetProtocolVersion()`. The `isPedAlive` hint is
diagnostic only; OneSync server entity state decides recovery.

## Server to client

| Event | Payload |
| --- | --- |
| `gc_core:client:connectionAccepted` | exact `apiVersion`, `protocolVersion` |
| `gc_core:client:spawnApproved` | `decisionId`, position, ped, expiry, attempt |
| `gc_core:client:spawnRejected` | known `errorCode`, boolean `retryable` |
| `gc_core:client:spawnConfirmed` | `decisionId`, or nil during recovery; state=`spawned` |
| `gc_core:client:forceResync` | no payload |
| `gc_core:client:notify` | message ≤ 256 and allowlisted type |

Spawn decision IDs and session/correlation IDs are not secrets or authorization
credentials. The server still verifies source, session ownership, TTL, one-time
consumption, and lifecycle state.

Continue with [security](12-security.md).
