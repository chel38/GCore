# Protocol v1 network events

Names are defined only in `shared/events.lua`. Runtime code must not duplicate
event literals. Payload schemas are exact; unknown fields are rejected.

## Client → server

| Name | Visibility | Payload / schema | Rate limit | Server validation | Possible codes |
| --- | --- | --- | --- | --- | --- |
| `gc_core:server:clientReady` | protocol public | `{clientVersion:string, protocolVersion:integer, locale?:string}` | `clientReady` | session state, exact protocol, bounded strings; state-aware normal/recovery/duplicate routing | `GC-PAYLOAD-*`, `GC-PROTOCOL-MISMATCH-001`, `GC-SESSION-001` |
| `gc_core:server:resyncReady` | compatibility public | handshake plus `isPedAlive?:boolean` | `resyncReady` | same handshake path; ped hint is diagnostic only | `GC-PAYLOAD-*`, `GC-PROTOCOL-MISMATCH-001`, `GC-SESSION-001` |
| `gc_core:server:requestSpawn` | protocol public | exact empty table | `requestSpawn` | session and `client_ready`/`spawn_pending` state | `GC-SPAWN-DECISION-001`, `GC-RATE-LIMIT-001` |
| `gc_core:server:confirmSpawn` | protocol public | `{decisionId:string}` only | `confirmSpawn` | source, session, state, TTL, replay, server entity/owner/model/position/alive | `GC-SPAWN-DECISION-*`, `GC-SPAWN-ENTITY-*`, `GC-SPAWN-OWNER-MISMATCH`, `GC-SPAWN-MODEL-MISMATCH`, `GC-SPAWN-POSITION-MISMATCH`, `GC-SPAWN-VERIFY-TIMEOUT` |
| `gc_core:server:reportClientError` | protocol public | `{errorCode:known string}` | `reportClientError` | known code, active spawn transaction, retry policy | `GC-PAYLOAD-ERROR-001`, `GC-RATE-LIMIT-001` |

Rate-limit numbers come from `config/security.lua`. Invalid payloads also record a
violation. A duplicate handshake never creates another session, spawn, thread, or
unbounded timeout extension.

## Server → client only

Local trigger allowed: **NO** for every event below. All handlers use the common
FiveM origin guard `source == 65535` before payload validation or side effects.

| Name | Visibility | Payload / schema | Rate limit | Client/server validation | Possible codes |
| --- | --- | --- | --- | --- | --- |
| `gc_core:client:connectionAccepted` | internal protocol | `{apiVersion:integer, protocolVersion:integer}` | N/A | server origin; exact local versions | `GC-PROTOCOL-MISMATCH-001` |
| `gc_core:client:spawnApproved` | internal protocol | decisionId, finite position, allowlisted ped, expiry, attempt | N/A | server origin; exact schema; duplicate execution guard | `GC-PAYLOAD-*` |
| `gc_core:client:spawnRejected` | internal protocol | `{errorCode:known string, retryable:boolean}` | N/A | server origin; known code | `GC-PAYLOAD-SCHEMA-001` |
| `gc_core:client:spawnConfirmed` | internal protocol | `{decisionId?:string, state:'spawned'}` | N/A | server origin; exact state; commits client state and closes the loading screen once | `GC-PAYLOAD-SCHEMA-001` |
| `gc_core:client:forceResync` | internal recovery prompt | no payload | bounded server attempts | server origin; starts/merges one bounded readiness wait | none |
| `gc_core:client:notify` | public presentation | `{message:string≤256, type:allowlisted}` | server API validation | server origin; exact schema | `GC-PAYLOAD-SCHEMA-001` |

Decision/session/correlation IDs are correlation values, not credentials. Server
authorization always uses event `source`, current session, lifecycle, TTL, and
one-time decision state.

Continue with [security](12-security.md).
