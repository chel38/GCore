# GCore Module Contract v1

This contract is the boundary between `gc_core` and independent resources such as
future `gc_identity`, `gc_admin`, or `gc_characters`. It is not a full SDK.

## The rule

```text
FiveM → gc_core lifecycle → Public API v1 → independent module
```

A module may depend on API v1. It must not depend on internal tables, filenames,
or the current `0.x` resource patch.

## Required startup check

```lua
local REQUIRED_API_VERSION = 1

local function validateCoreApi()
    if GetResourceState('gc_core') ~= 'started' then
        return false, 'gc_core is not started'
    end

    local apiVersion = exports.gc_core:GetApiVersion()

    if apiVersion < REQUIRED_API_VERSION then
        return false, ('GCore API v%d required; found v%d'):format(
            REQUIRED_API_VERSION,
            apiVersion
        )
    end

    return true
end
```

Require API `1`, not exactly resource `0.1.5-alpha`. Resource and API versions are
separate precisely so compatible patch/minor releases do not stop modules.

## Allowed

- Call exports documented in [Public Server API v1](09-server-api.md).
- Read the detached Public Player DTO.
- Check `CanUseGameplayFeatures(playerSource)` at every gameplay entry point.
- Use `GetPlayerState` for read-only diagnostics or controlled gating.
- Use notifications through `NotifyPlayer`/`NotifyAll`.
- Re-run the API check after `onResourceStart` for `gc_core`.
- Treat a missing/stopped core or `nil` DTO as temporary unavailability and fail
  the module operation safely.

## Forbidden

- `dofile`, `loadfile`, or direct imports from `gc_core/server/*`.
- Reading or mutating `GCSessions`, `GCStates`, `GCSpawn`, decisions, security, or
  rate-limit tables.
- Assigning lifecycle state or forging decision/event payloads.
- Treating client identifiers, positions, PED state, or success reports as trusted.
- Retaining a Public DTO as live state; request a new DTO when needed.
- Sending internal server→client protocol events from a module.

## Gameplay availability in API v1

`CanUseGameplayFeatures(source) == true` means exactly that gc_core's authoritative
lifecycle state is `spawned`. API v1 does **not** promise that identity, character,
account, permissions, or database state exists. Future modules must add their own
server-side conditions after the core check.

```lua
if not exports.gc_core:CanUseGameplayFeatures(source) then
    return false, 'PLAYER_NOT_GAMEPLAY_READY'
end

-- The module now validates its own server-owned state.
```

## Restarts

During a `gc_core` restart, exports may be temporarily unavailable and sessions
are reconstructed. A module must not cache an internal/session reference across
the restart. Handle the core as unavailable, re-check API v1 after it starts, and
query fresh state/DTO before accepting gameplay. Do not implement your own recovery
handshake or assume `forceResync` timing.

FiveM stops resources that declare `dependency 'gc_core'` when the dependency is
restarted. The maintenance sequence is therefore explicit and ordered:

```text
restart gc_core
ensure gc_identity   # and every other stopped dependent module
```

On a normal server boot, the corresponding `ensure` lines provide the same order.
Each dependent module must rebuild its own runtime state idempotently when it is
ensured again; it must not assume FiveM automatically restarts dependants.

No public server lifecycle hook is promised in API v1. Modules should check the
public state at the moment an operation is requested.

## Data and identifiers

`GetPlayerSession` deliberately excludes identifiers and sensitive internals.
`GetPlayerIdentifier` is server-only and returns one captured identifier or `nil`.
Never trust a client-supplied identifier and never forward license/IP/Discord data
to clients without a documented privacy and authorization need.

## Security baseline

1. Client input is never authoritative.
2. Validate every network payload on the server with exact schemas and limits.
3. Check gameplay state through the Public API.
4. Keep module state server-owned.
5. Never mutate gc_core session state or forge spawn decisions.
6. Bound and cancel async work on disconnect, module/core stop, or state change.

See the [API compatibility policy](20-api-compatibility.md).

For machine-readable metadata, dependencies, standalone conformance, and packaging,
see [GCore Module Standard v1](ecosystem/module-standard.md). The Module Contract
remains the runtime boundary; Module Standard v1 describes its declaration.
