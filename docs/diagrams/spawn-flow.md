# Поток спавна / Spawn flow

```mermaid
sequenceDiagram
    participant C as Client Lua
    participant S as Server lifecycle
    participant O as OneSync entity state

    C->>S: requestSpawn {}
    S->>S: Validate state + action limit
    S->>S: New one-time decision + untried ped
    S-->>C: spawnApproved(decisionId, ped, position, attempt)
    C->>C: Model, coordinates, collision
    C->>S: confirmSpawn(decisionId)
    S->>S: Validate source/session/state/TTL/replay
    loop Bounded verification window
        S->>O: Read ped, owner, health, model, coords
        O-->>S: Authoritative snapshot
    end
    alt Snapshot matches
        S->>S: spawn_confirming → spawned
        S-->>C: spawnConfirmed
    else Snapshot or client spawn failed
        S->>S: Consume old decision + remember failed model
        alt Attempts remain
            S->>S: spawn_confirming → spawn_pending
            S->>S: Create new ID and ped
            S-->>C: spawnApproved(new decision)
        else Exhausted
            S->>S: → error
            S-->>C: spawnRejected(retryable=false)
        end
    end
```

The client confirmation is only a request to verify. The server does not enter
`spawned` until the OneSync snapshot matches the immutable decision. Every retry
invalidates the old ID; decision IDs are correlation values, not credentials.
