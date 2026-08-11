# Optional SDK v0

`gc_sdk 0.1.0-alpha` / SDK API 1 is a small optional server-only convenience layer.
It exists because Core API availability/version checks repeated across real modules.
It contains no domain logic and does not require `gc_ecosystem`.

Direct use remains fully supported:

```lua
local apiVersion = exports['gc_core']:GetApiVersion()
```

SDK use is opt-in:

```lua
local ok, code, details = exports['gc_sdk']:RequireCoreApi(1)
if not ok then
    error(('Core compatibility failed: %s'):format(code))
end
```

## SDK API v1

- `GetVersion()` → detached `{version, apiVersion}`.
- `GetApiVersion()` → integer `1`.
- `IsCoreAvailable()` → boolean.
- `GetCoreApiVersion()` → integer or `nil, code`.
- `RequireCoreApi(minimum)` → `boolean, code?, details?`.
- `RequireResource(name)` → `boolean, code?, details?`.

Stable errors include `GC-SDK-CORE-UNAVAILABLE`,
`GC-SDK-CORE-API-INCOMPATIBLE`, `GC-SDK-MODULE-UNAVAILABLE`, and
`GC-SDK-ARGUMENT-INVALID`.

DTO copying, rate limiting, server-origin client guards, payload schemas, identity,
characters, and email validation remain with their owning boundaries. SDK is
convenience, never a mandatory magic layer; `gc_example` deliberately stays SDK-free.
