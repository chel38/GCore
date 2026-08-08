# Публичный серверный API v1

API Version: `1`

Статус: **Stable for module development**

Сторона: **только SERVER**

Источник истины — `server/api.lua` и `server/exports.lua`. Все возвращаемые
таблицы отделены от internal state. Breaking change требует новой API version и
migration notes; см. [политику совместимости](20-api-compatibility.md).

## Таблица контрактов

| Имя | Аргументы | Возврат / типы | Разрешённые состояния | Ошибки / nil | Добавлен | Security notes |
| --- | --- | --- | --- | --- | --- | --- |
| `GetVersion` | нет | новый version DTO (`table`) | любое | нет | API 1 | Изменение DTO не меняет `GCVersion`. |
| `GetVersionString` | нет | resource version (`string`) | любое | нет | API 1 | Не использовать как compatibility gate модуля. |
| `GetApiVersion` | нет | версия API (`integer`) | любое | нет | API 1 | Рекомендуемый compatibility gate. |
| `GetProtocolVersion` | нет | network protocol (`integer`) | любое | нет | API 1 | Диагностика; модуль обычно не реализует core protocol. |
| `IsPlayerConnected` | `playerSource: integer > 0` | `boolean` | любое | invalid/отключён → `false` | API 1 | Означает наличие active gc_core session. |
| `IsPlayerReady` | `playerSource` | `boolean` | `client_ready`, spawn states, `spawned`, `resyncing` | invalid/отключён → `false` | API 1 | Не означает доступность gameplay. |
| `IsPlayerSpawned` | `playerSource` | `boolean` | только `spawned` | invalid/отключён → `false` | API 1 | Читает authoritative lifecycle state. |
| `GetPlayerState` | `playerSource` | state (`string`) или `nil` | active session | invalid/отключён → `nil` | API 1 | Только чтение; модуль не меняет state. |
| `GetPlayerSession` | `playerSource` | Public Player DTO (`table`) или `nil` | active session | invalid/отключён → `nil` | API 1 | Нет sessionId, identifiers, decisions, security или rate-limit internals. |
| `GetPlayerIdentifier` | `playerSource`, allowlisted `identifierType: string` | captured identifier (`string`) или `nil` | active session | invalid type/source, нет identifier, отключён → `nil` | API 1 | Чувствительные server data; не пересылать клиенту без явной политики. |
| `CanUseGameplayFeatures` | `playerSource` | `boolean` | только `spawned` | invalid/отключён → `false` | API 1 | В API v1 означает только `state == spawned`; identity/character checks не обещаны. |
| `RequestPlayerSpawn` | `playerSource` | decision (`table`) или `nil`, error code (`string`) или `nil` | `client_ready`/`spawn_pending` | invalid source → `GC-PAYLOAD-TYPE-001`; state/duplicate → `GC-SPAWN-DECISION-001` | API 1 | Использует обычные state machine и server decision rules. |
| `NotifyPlayer` | `playerSource`, `message: string`, optional type | `boolean`, error code или `nil` | active session | `GC-NOTIFY-001..004`; message ≤ 256 bytes | API 1 | Server-only; client event защищён origin guard. |
| `NotifyAll` | `message: string`, optional type | `boolean`, error code или `nil` | любое | `GC-NOTIFY-002/003`; message ≤ 256 bytes | API 1 | Broadcast side effect только из trusted server code. |

Типы уведомлений: `info`, `success`, `warning`, `error`. Типы identifiers:
`license`, `license2`, `fivem`, `discord`, `steam`, `xbl`, `live`, `ip`.

## Public DTO

```lua
local player = exports.gc_core:GetPlayerSession(source)
-- {
--   source, state, playerName,
--   connectedAt, clientReadyAt, spawnedAt,
--   lastPed, locale
-- }
```

Каждый вызов возвращает новую таблицу. Изменение `player.state` или version DTO
не влияет на gc_core.

## Пример модуля

```lua
local REQUIRED_API_VERSION = 1

if exports.gc_core:GetApiVersion() < REQUIRED_API_VERSION then
    error('gc_example requires GCore API v1')
end

if exports.gc_core:CanUseGameplayFeatures(source) then
    local player = exports.gc_core:GetPlayerSession(source)
    exports.gc_core:NotifyPlayer(source, ('Готов: %s'):format(player.playerName), 'success')
end
```

Перейдите к [контракту модулей](module-contract.md).
