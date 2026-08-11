# Optional SDK v0

`gc_sdk 0.1.0-alpha` / SDK API 1 — небольшой optional server-only convenience layer.
Он появился потому, что проверка доступности/версии Core API повторилась в реальных
модулях. В нём нет domain logic и dependency на `gc_ecosystem`.

Direct API полностью поддерживается:

```lua
local apiVersion = exports['gc_core']:GetApiVersion()
```

SDK подключается явно:

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
- `GetCoreApiVersion()` → integer или `nil, code`.
- `RequireCoreApi(minimum)` → `boolean, code?, details?`.
- `RequireResource(name)` → `boolean, code?, details?`.

Stable errors: `GC-SDK-CORE-UNAVAILABLE`, `GC-SDK-CORE-API-INCOMPATIBLE`,
`GC-SDK-MODULE-UNAVAILABLE`, `GC-SDK-ARGUMENT-INVALID`.

DTO copy, rate limit, server-origin client guard, payload schemas, identity,
characters и email validation остаются у владельцев boundary. SDK — convenience,
не обязательная магия; `gc_example` намеренно остаётся без SDK.
