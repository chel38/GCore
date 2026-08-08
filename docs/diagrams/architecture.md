# Архитектура / Architecture

```mermaid
flowchart LR
    Client["Client Lua\nuntrusted executor"]
    Ingress["Event ingress\nrate limit + exact schema"]
    Lifecycle["State machine + sessions\nserver authority"]
    Spawn["Spawn decisions\none-time + bounded retry"]
    OneSync["OneSync natives\nentity evidence"]
    API["GCAPI / exports\ndetached DTOs"]
    Modules["Trusted server resources"]

    Client -->|requests and confirmations| Ingress
    Ingress --> Lifecycle
    Lifecycle --> Spawn
    Spawn -->|immutable decision| Client
    Spawn -->|verify| OneSync
    OneSync -->|owner/model/health/coords| Spawn
    Modules --> API
    API --> Lifecycle
```

Shared runtime/version/event/validation modules are loaded on both sides, while
side-specific bootstraps assert context through `GCRuntime`. All production state
changes are routed through `GCStates.Set`.
