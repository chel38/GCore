# Поток подключения и recovery / Connection and recovery flow

```mermaid
sequenceDiagram
    participant F as FiveM
    participant S as gc_core Server
    participant C as gc_core Client
    participant O as OneSync

    F->>S: playerConnecting(temp source)
    S->>S: Deferral + identifiers + pending connection
    F->>S: playerJoining(old source; runtime source)
    S->>S: Promote pending → session
    C->>S: clientReady(version, protocol, locale)
    S->>S: Shared strict handshake validator
    S-->>C: connectionAccepted(API, protocol)
    Note over S,C: Normal spawn flow follows

    rect rgb(240, 245, 255)
        Note over S,C: gc_core restart while player remains online
        S->>S: Create recovered session → resyncing
        S-->>C: forceResync
        C->>S: resyncReady(version, protocol, isPedAlive hint)
        S->>S: Same strict handshake validator
        S->>O: Read server ped/entity/owner/health
        alt Server ped is authoritative and alive
            S->>S: resyncing → spawned
            S-->>C: spawnConfirmed
        else No valid server ped
            S->>S: resyncing → spawn_pending
            Note over S,C: Normal spawn flow follows
        end
    end
```

`isPedAlive` is stored only as diagnostics and never drives the transition.
