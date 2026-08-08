# Server API / Серверный API

## Level 1. In simple words

An API is a set of functions that other Lua modules can call.
GreenCore provides API v1.

## Level 2. Technical explanation

The API is implemented through server exports.
Each export validates arguments and returns clear errors.

## API table

| Export                   | Side   | Returns        | Purpose                   |
| ------------------------ | ------ | -------------- | ------------------------- |
| `GetApiVersion`          | Server | number         | API version               |
| `GetVersion`             | Server | table          | `gc_core` version         |
| `IsPlayerConnected`      | Server | boolean        | Checks session            |
| `IsPlayerReady`          | Server | boolean        | Checks readiness          |
| `IsPlayerSpawned`        | Server | boolean        | Checks spawn              |
| `GetPlayerState`         | Server | string or nil  | Returns state             |
| `GetPlayerSession`       | Server | table or nil   | Returns session copy      |
| `GetPlayerIdentifier`    | Server | string or nil  | Returns identifier        |
| `CanUseGameplayFeatures` | Server | boolean        | Allows gameplay features  |
| `RequestPlayerSpawn`     | Server | table or nil   | Requests spawn            |
| `NotifyPlayer`           | Server | boolean        | Sends a notification      |
| `NotifyAll`              | Server | boolean        | Sends a notification to all |

## Level 3. Lua code example

```lua
-- RU: Проверяем версию API.
-- EN: Check the API version.
local apiVersion = exports.gc_core:GetApiVersion()

if apiVersion ~= 1 then
    print('Unsupported API version')
    return
end

-- RU: Проверяем, готов ли игрок.
-- EN: Check whether the player is ready.
local isReady = exports.gc_core:IsPlayerReady(playerSource)

-- RU: Получаем состояние игрока.
-- EN: Get the player state.
local state = exports.gc_core:GetPlayerState(playerSource)

-- RU: Получаем безопасную копию сессии.
-- EN: Get a safe copy of the session.
local session = exports.gc_core:GetPlayerSession(playerSource)

-- RU: Отправляем уведомление игроку.
-- EN: Send a notification to a player.
local sent = exports.gc_core:NotifyPlayer(playerSource, 'Welcome!', 'success')

-- RU: Отправляем уведомление всем игрокам.
-- EN: Send a notification to all players.
local sentAll = exports.gc_core:NotifyAll('Server is restarting', 'warning')
```

## Export requirements

- Stable names.
- Argument validation.
- Do not return internal tables.
- Return clear errors.
- Documented.
- Work only on the corresponding side.

## Next step

Go to [Client API](10-client-api.md).