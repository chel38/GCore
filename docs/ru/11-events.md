# Сетевые события протокола v1

Имена определены только в `shared/events.lua`. Runtime-код не дублирует event
literals. Payload schemas точные, неизвестные поля отклоняются.

## Клиент → сервер

| Имя | Видимость | Payload / schema | Rate limit | Server validation | Возможные коды |
| --- | --- | --- | --- | --- | --- |
| `gc_core:server:clientReady` | protocol public | `{clientVersion:string, protocolVersion:integer, locale?:string}` | `clientReady` | session state, точный protocol, bounded strings; normal/recovery/duplicate routing | `GC-PAYLOAD-*`, `GC-PROTOCOL-MISMATCH-001`, `GC-SESSION-001` |
| `gc_core:server:resyncReady` | compatibility public | handshake + `isPedAlive?:boolean` | `resyncReady` | тот же handshake; ped hint только diagnostic | `GC-PAYLOAD-*`, `GC-PROTOCOL-MISMATCH-001`, `GC-SESSION-001` |
| `gc_core:server:requestSpawn` | protocol public | точная пустая table | `requestSpawn` | session и state `client_ready`/`spawn_pending` | `GC-SPAWN-DECISION-001`, `GC-RATE-LIMIT-001` |
| `gc_core:server:confirmSpawn` | protocol public | только `{decisionId:string}` | `confirmSpawn` | source, session, state, TTL, replay, server entity/owner/model/position/alive | `GC-SPAWN-DECISION-*`, `GC-SPAWN-ENTITY-*`, `GC-SPAWN-OWNER-MISMATCH`, `GC-SPAWN-MODEL-MISMATCH`, `GC-SPAWN-POSITION-MISMATCH`, `GC-SPAWN-VERIFY-TIMEOUT` |
| `gc_core:server:reportClientError` | protocol public | `{errorCode:known string}` | `reportClientError` | известный code, active transaction, retry policy | `GC-PAYLOAD-ERROR-001`, `GC-RATE-LIMIT-001` |

Числа rate limit находятся в `config/security.lua`. Invalid payload также считается
нарушением. Duplicate handshake не создаёт вторую session/spawn/thread и не
продлевает timeout бесконечно.

## Только сервер → клиент

Local trigger allowed: **NO** для каждого события ниже. Общий FiveM origin guard
`source == 65535` выполняется до payload validation и side effects.

| Имя | Видимость | Payload / schema | Rate limit | Client/server validation | Возможные коды |
| --- | --- | --- | --- | --- | --- |
| `gc_core:client:connectionAccepted` | internal protocol | `{apiVersion:integer, protocolVersion:integer}` | N/A | server origin; точные local versions | `GC-PROTOCOL-MISMATCH-001` |
| `gc_core:client:spawnApproved` | internal protocol | decisionId, finite position, allowlisted ped, expiry, attempt | N/A | server origin; exact schema; duplicate guard | `GC-PAYLOAD-*` |
| `gc_core:client:spawnRejected` | internal protocol | `{errorCode:known string, retryable:boolean}` | N/A | server origin; known code | `GC-PAYLOAD-SCHEMA-001` |
| `gc_core:client:spawnConfirmed` | internal protocol | `{decisionId?:string, state:'spawned'}` | N/A | server origin; exact state | `GC-PAYLOAD-SCHEMA-001` |
| `gc_core:client:forceResync` | internal recovery prompt | без payload | bounded server attempts | server origin; один объединяемый bounded readiness wait | нет |
| `gc_core:client:notify` | public presentation | `{message:string≤256, type:allowlisted}` | server API validation | server origin; exact schema | `GC-PAYLOAD-SCHEMA-001` |

Decision/session/correlation IDs — значения корреляции, а не credentials. Server
authorization всегда использует event `source`, текущую session, lifecycle, TTL и
one-time decision state.

Перейдите к [безопасности](12-security.md).
