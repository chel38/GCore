# Сетевые события протокола v1

Имена определены только в `shared/events.lua`. Не создавайте строковые копии в
runtime-коде. Неизвестные поля payload отклоняются.

## Клиент → сервер

| Событие | Payload | Состояние | Лимит |
| --- | --- | --- | --- |
| `gc_core:server:clientReady` | `clientVersion`, `protocolVersion`, optional `locale` | `joining` | `clientReady` |
| `gc_core:server:requestSpawn` | пустая table | `client_ready`/`spawn_pending` | `requestSpawn` |
| `gc_core:server:confirmSpawn` | только `decisionId` | `spawn_confirming` | `confirmSpawn` |
| `gc_core:server:reportClientError` | известный `errorCode` | spawn flow | `reportClientError` |
| `gc_core:server:resyncReady` | handshake + optional `isPedAlive` hint | `resyncing` | `resyncReady` |

`clientReady` и `resyncReady` используют один валидатор handshake. Protocol должен
быть конечным целым числом и точно совпадать с `GetProtocolVersion()`. Подсказка
`isPedAlive` сохраняется только для диагностики: решение recovery принимает сервер
по OneSync entity.

## Сервер → клиент

| Событие | Payload |
| --- | --- |
| `gc_core:client:connectionAccepted` | точные `apiVersion`, `protocolVersion` |
| `gc_core:client:spawnApproved` | `decisionId`, position, ped, expiry, attempt |
| `gc_core:client:spawnRejected` | известный `errorCode`, boolean `retryable` |
| `gc_core:client:spawnConfirmed` | `decisionId` или nil при recovery, state=`spawned` |
| `gc_core:client:forceResync` | без payload |
| `gc_core:client:notify` | message ≤ 256, тип из allowlist |

Spawn decision ID и session/correlation IDs не являются секретами и не дают
авторизацию. Сервер всегда дополнительно проверяет source, session ownership,
TTL, one-time consumption и текущее состояние.

Перейдите к [безопасности](12-security.md).
