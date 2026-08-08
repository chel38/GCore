# Client API / Клиентский API

## Level 1. In simple words

The client code reports readiness to the server and performs allowed actions.

## Level 2. Technical explanation

The client has no exports.
It interacts with the server through network events.

## Client services

| Service | Purpose |
| ------- | ------- |
| `GCClientState` | Client state |
| `GCClientReadiness` | Client readiness |
| `GCClientSpawn` | Client spawn |
| `GCClientDiagnostics` | Client diagnostics |

## Client readiness

The client does not send a request immediately after loading the file.
It waits for:

- network session activity;
- player existence;
- `PlayerPedId()` existence;
- correct ped state.

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

## Readiness payload

```lua
{
    clientVersion = '0.1.2-alpha',
    protocolVersion = 1,
    locale = 'ru'
}
```

The client does **not** send:

- `source`;
- Session ID;
- state;
- coordinates;
- model;
- spawn permission.

## Client spawn

The client receives the server decision and performs the spawn through natives.

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

## Next step

Go to [Events](11-events.md).
