# Сессия игрока / Player Session

## Уровень 1. Простыми словами

Сессия — это временная карточка игрока внутри сервера.

Игрок вошёл — карточка появилась.
Игрок вышел — карточка удалена.

## Уровень 2. Техническое объяснение

Сессия хранится в Lua-таблице в оперативной памяти сервера.
Она связывает текущий FiveM `source` с идентификаторами и состоянием игрока.

## Структура сессии

```lua
local session = {
    sessionId = 'gc:session:generated-id',
    source = 1,
    playerName = 'Player Name',

    identifiers = {
        license = 'license:...',
        license2 = nil,
        fivem = 'fivem:...',
        discord = nil
    },

    primaryIdentifierType = 'license',
    primaryIdentifier = 'license:...',

    state = 'connecting',
    previousState = nil,
    stateReason = 'player_connecting',

    connectedAt = 0,
    validatedAt = nil,
    clientReadyAt = nil,
    spawnedAt = nil,
    disconnectedAt = nil,

    spawnDecision = nil,

    metadata = {
        locale = 'ru',
        clientVersion = nil,
        protocolVersion = nil
    }
}
```

## Session ID

Session ID:

- уникален;
- создаётся сервером;
- не зависит только от `source`;
- не содержит license;
- не содержит IP;
- не содержит Discord ID;
- не передаётся клиентом;
- не повторяется после переподключения.

Пример:

```text
gc:session:550e8400-e29b-41d4-a716-446655440000
```

## Методы сервиса сессий

| Метод | Назначение |
| ----- | ---------- |
| `GCSessions.Create` | Создаёт сессию |
| `GCSessions.Get` | Возвращает сессию по source |
| `GCSessions.GetByIdentifier` | Возвращает сессию по идентификатору |
| `GCSessions.Exists` | Проверяет существование сессии |
| `GCSessions.Clone` | Возвращает безопасную копию |
| `GCSessions.Remove` | Удаляет сессию |
| `GCSessions.Count` | Возвращает количество сессий |
| `GCSessions.Clear` | Очищает все сессии |

## Уровень 3. Пример Lua-кода

```lua
local session = exports.gc_core:GetPlayerSession(source)

if not session then
    print('Player session was not found')
    return
end

print(session.state)
```

## Уровень 4. Безопасность

Сторонний модуль **не** может изменить настоящую сессию:

```lua
local session = exports.gc_core:GetPlayerSession(source)
session.state = 'spawned'  -- Это не изменит настоящую сессию
```

`Clone` возвращает глубокую копию. Изменение копии не влияет на оригинал.

## Следующий шаг

Перейдите к [Состояниям игрока](06-player-states.md).