# Поток подключения и recovery / Connection and recovery flow

```mermaid
sequenceDiagram
    participant F as FiveM
    participant S as gc_core Server
    participant C as gc_core Client
    participant O as OneSync

    F->>S: playerConnecting(temp source)
    S->>S: Deferral + identifiers + pending
    F->>S: playerJoining(old source; runtime source)
    S->>S: Promote pending → session(joining)
    C->>S: clientReady(version, protocol, locale; bounded retry)
    S->>S: State-aware strict handshake
    S-->>C: connectionAccepted

    rect rgb(240, 245, 255)
        Note over S,C: gc_core restarts while player remains online
        S->>S: Create recovered session → resyncing
        par Bounded optional server prompt
            S-->>C: forceResync (max attempts)
            C->>S: resyncReady(..., isPedAlive hint)
        and Proactive client start handshake
            C->>S: clientReady(...; bounded retry until ACK)
        end
        S->>S: First valid handshake wins; duplicates are idempotent
        S->>O: Read ped/entity/owner/health
        alt Authoritative live ped
            S->>S: resyncing → spawned
            S-->>C: spawnConfirmed
        else No valid server ped
            S->>S: resyncing → spawn_pending
            Note over S,C: Normal verified spawn flow
        end
    end
```

`clientPedAliveHint` is diagnostics only. Losing `forceResync` cannot block recovery.
An early client hello is retried with configured attempt/deadline limits; the
first valid lifecycle ACK cancels the single retry thread.
