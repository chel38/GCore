# Серверный API / Server API

## Уровень 1. Простыми словами

API — это набор функций, которые другие Lua-модули могут вызывать.
GreenCore предоставляет API v1.

## Уровень 2. Техническое объяснение

API реализован через серверные exports.
Каждый export проверяет аргументы и возвращает понятные ошибки.

## Таблица API

| Export                   | Сторона | Возвращает     | Назначение                |
| ------------------------ | ------- | -------------- | ------------------------- |
| `GetApiVersion`          | Server  | number         | Версия API                |
| `GetVersion`             | Server  | table          | Версия `gc_core`          |
| `IsPlayerConnected`      | Server  | boolean        | Проверяет сессию          |
| `IsPlayerReady`          | Server  | boolean        | Проверяет готовность      |
| `IsPlayerSpawned`        | Server  | boolean        | Проверяет спавн           |
| `GetPlayerState`         | Server  | string или nil | Возвращает состояние      |
| `GetPlayerSession`       | Server  | table или nil  | Возвращает копию сессии   |
| `GetPlayerIdentifier`    | Server  | string или nil | Возвращает идентификатор  |
| `CanUseGameplayFeatures` | Server  | boolean        | Разрешает игровые функции |
| `RequestPlayerSpawn`     | Server  | table или nil  | Запрашивает спавн         |
| `NotifyPlayer`           | Server  | boolean        | Отправляет уведомление    |
| `NotifyAll`              | Server  | boolean        | Отправляет уведомление всем |

## Уровень 3. Пример Lua-кода

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
local sent = exports.gc_core:NotifyPlayer(playerSource, 'Добро пожаловать!', 'success')

-- RU: Отправляем уведомление всем игрокам.
-- EN: Send a notification to all players.
local sentAll = exports.gc_core:NotifyAll('Сервер перезапускается', 'warning')
```

## Требования к exports

- Стабильные имена.
- Проверка аргументов.
- Не возвращают внутренние таблицы.
- Возвращают понятные ошибки.
- Документированы.
- Работают только на соответствующей стороне.

## Следующий шаг

Перейдите к [Клиентскому API](10-client-api.md).