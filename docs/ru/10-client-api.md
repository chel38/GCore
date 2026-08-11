# Клиентский API / Client API

## Уровень 1. Простыми словами

Клиентский код сообщает серверу о своей готовности и выполняет разрешённые действия.

## Уровень 2. Техническое объяснение

Клиент не имеет exports.
Он взаимодействует с сервером через сетевые события.

## Клиентские сервисы

| Сервис | Назначение |
| ------ | ---------- |
| `GCClientState` | Клиентское состояние |
| `GCClientReadiness` | Готовность клиента |
| `GCClientSpawn` | Клиентский спавн |
| `GCClientDiagnostics` | Клиентская диагностика |

## Готовность клиента

Границей готовности является сама загрузка client resource. До первого
server-authoritative spawn FiveM network/player/PED native ещё могут возвращать
inactive, поэтому они не блокируют hello.

Раннее network event может прийти до финального server state `joining`. Поэтому
клиент повторяет hello с настраиваемым интервалом до валидного server ACK. И
число попыток, и общий deadline ограничены.

```lua
CreateThread(function()
    for attempt = 1, GCConfig.Connection.clientHelloMaxAttempts do
        GCClientReadiness.ReportReady()
        if serverAckReceived then break end
        Wait(GCConfig.Connection.clientHelloRetryIntervalMs)
    end
end)
```

Валидные `connectionAccepted`, `spawnApproved`, `spawnRejected` или
`spawnConfirmed` останавливают retry loop. Все они защищены server-origin guard.

Только валидный `spawnConfirmed` также закрывает loading screen FiveM. Локальные
события и более ранние lifecycle stages не могут убрать `Awaiting scripts`.

## Payload готовности

```lua
{
    clientVersion = '0.1.5-alpha',
    protocolVersion = 1,
    locale = 'ru'
}
```

Клиент **не** отправляет:

- `source`;
- Session ID;
- состояние;
- координаты;
- модель;
- разрешение на спавн.

## Клиентский спавн

Клиент получает решение сервера и выполняет спавн через natives.

```lua
RequestModel(modelHash)
HasModelLoaded(modelHash)
SetPlayerModel(PlayerId(), modelHash)
SetModelAsNoLongerNeeded(modelHash)
SetEntityCoordsNoOffset(...)
SetEntityHeading(...)
RequestCollisionAtCoord(...)
HasCollisionLoadedAroundEntity(...)
FreezeEntityPosition(...)
```

## Следующий шаг

Перейдите к [Событиям](11-events.md).
