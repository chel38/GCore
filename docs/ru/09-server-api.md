# Серверный API v1

Exports — тонкие адаптеры над тестируемым `GCAPI`. Они валидируют source и не
возвращают внутренние таблицы.

| Export | Возвращает | Контракт |
| --- | --- | --- |
| `GetVersion` | table | новый независимый version DTO |
| `GetVersionString` | string | `0.1.2-alpha` |
| `GetApiVersion` | number | версия публичного API |
| `GetProtocolVersion` | number | версия сетевого протокола |
| `IsPlayerConnected` | boolean | существует активная сессия |
| `IsPlayerReady` | boolean | lifecycle достиг ready/resync/spawn |
| `IsPlayerSpawned` | boolean | серверное состояние `spawned` |
| `GetPlayerState` | string или nil | текущее состояние |
| `GetPlayerSession` | table или nil | безопасный DTO сессии |
| `GetPlayerIdentifier` | string или nil | server-only identifier указанного типа |
| `CanUseGameplayFeatures` | boolean | true только для `spawned` |
| `RequestPlayerSpawn` | table/nil, error/nil | серверный spawn request |
| `NotifyPlayer` | boolean, error/nil | уведомление одному игроку |
| `NotifyAll` | boolean, error/nil | уведомление всем |

Version DTO:

```lua
local version = exports.gc_core:GetVersion()
-- {
--   version = '0.1.2-alpha',
--   resource = { major = 0, minor = 1, patch = 2, prerelease = 'alpha' },
--   apiVersion = 1,
--   protocolVersion = 1
-- }
```

Изменение `version.resource.patch` не меняет внутреннюю версию. Аналогично,
`GetPlayerSession` не раскрывает `sessionId`, identifiers, spawn decision,
rate-limit или security state. `GetPlayerIdentifier` предназначен только для
доверенных серверных ресурсов и не должен пересылаться клиенту без необходимости.

```lua
if exports.gc_core:GetApiVersion() ~= 1 then
    error('Unsupported gc_core API')
end

if exports.gc_core:CanUseGameplayFeatures(source) then
    exports.gc_core:NotifyPlayer(source, 'Добро пожаловать!', 'success')
end
```

Перейдите к [клиентскому API](10-client-api.md).
