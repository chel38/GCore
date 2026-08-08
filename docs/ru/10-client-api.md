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

Клиент не отправляет запрос сразу после загрузки файла.
Он ждёт:

- активности сетевой сессии;
- существования игрока;
- существования `PlayerPedId()`;
- корректного состояния ped.

```lua
CreateThread(function()
    local startedAt = GetGameTimer()
    local timeoutMs = 30000

    while not NetworkIsSessionStarted() do
        if GetGameTimer() - startedAt >= timeoutMs then
            GCClientDiagnostics.Report('GC-CLIENT-READY-001')
            return
        end

        Wait(250)
    end

    GCClientReadiness.ReportReady()
end)
```

## Payload готовности

```lua
{
    clientVersion = '0.1.0',
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