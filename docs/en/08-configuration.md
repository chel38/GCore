# Configuration

Runtime configuration lives in `resources/[greencore]/gc_core/config/` and is
loaded as Lua. Resource, API, and protocol versions are not duplicated here;
`shared/version.lua` is the single source of truth.

| File | Purpose |
| --- | --- |
| `general.lua` | locale, debug, development mode, test opt-in |
| `connection.lua` | deferral, pending, clientReady, and resync timeouts |
| `spawn.lua` | location, ped whitelist, retry, and server verification |
| `security.lua` | action limits and the violation window |
| `logging.lua` | level and sensitive-data masking |
| `diagnostics.lua` | diagnostic messages |

Critical spawn verification settings:

```lua
verification = {
    enabled = true,
    timeoutMs = 3000,
    intervalMs = 100,
    maxAttempts = 31,
    positionTolerance = 8.0,
    minimumHealth = 1
}
```

Do not disable `verification.enabled` on a public server. A client confirmation
contains only `decisionId`; the server reads the OneSync entity, ownership, model,
health, and coordinates itself.

Retry uses `maxTotalAttempts`, `maxSamePedRetries`, and
`maxDifferentPedRetries`. Only MODEL errors add a PED to `attemptedPedModels`.
ENTITY/COLLISION/POSITION/TIMEOUT may reuse the same PED; DECISION/SESSION/SECURITY
and unknown failures reject. Every retry gets a new decision ID.

Recovery prompts use `resyncForceMaxAttempts` and `resyncForceIntervalMs`; the
single overall bound is `resyncReadyTimeoutMs`. The proactive clientReady path
means recovery does not depend on any prompt being delivered.

Initial/recovery hello retries use `clientHelloRetryIntervalMs` and
`clientHelloMaxAttempts`, with `clientReadyTimeoutMs` as the non-extendable total
deadline. A valid lifecycle ACK cancels the one client retry thread.

Rate limits are independent for `clientReady`, `requestSpawn`, `confirmSpawn`,
`reportClientError`, and `resyncReady`. `violationWindowMs` expires old violations;
`maxViolationsPerWindow` is not a lifetime session counter.

For production, keep tests disabled and set `developmentMode` to `false`.

Continue with the [server API](09-server-api.md).
