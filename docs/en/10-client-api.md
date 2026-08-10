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

The loaded client resource is itself the readiness boundary. Initial FiveM
network/player/PED natives may still report inactive before the first
server-authoritative spawn, so they do not gate hello.

An early network event may precede the final server `joining` state. The client
therefore retries hello at a configured interval until a valid server ACK. Both
the number of attempts and the total deadline are bounded.

```lua
CreateThread(function()
    for attempt = 1, GCConfig.Connection.clientHelloMaxAttempts do
        GCClientReadiness.ReportReady()
        if serverAckReceived then break end
        Wait(GCConfig.Connection.clientHelloRetryIntervalMs)
    end
end)
```

Valid `connectionAccepted`, `spawnApproved`, `spawnRejected`, or
`spawnConfirmed` events stop the retry loop. All are protected by the
server-origin guard.

Only a validated `spawnConfirmed` also closes the FiveM loading screen. Local
events and earlier lifecycle stages cannot dismiss `Awaiting scripts`.

## Readiness payload

```lua
{
    clientVersion = '0.1.4-alpha',
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
