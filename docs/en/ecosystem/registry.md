# Local module registry

`gc_ecosystem 0.1.0-alpha` is an optional server-only diagnostics resource. It
enumerates FiveM resources, reads official runtime metadata APIs, selects
`gcore_module 'yes'`, and builds an in-memory registry. It never scans the runtime
filesystem, polls every tick, accepts client events, downloads code, or changes
resource/player state.

The registry refreshes on its own startup, `onResourceStart`, `onResourceStop`,
and explicit `Refresh`. Compatibility checks Module Contract v1, Core API,
required resource state/API, malformed descriptors, self-dependencies, and cycles.
Missing optional modules are allowed.

## Ecosystem API v1 (server)

| Export | Arguments | Returns |
| --- | --- | --- |
| `GetVersion` | none | detached version DTO |
| `GetApiVersion` | none | integer `1` |
| `ListModules` | none | sorted detached descriptor array |
| `GetModule` | resource string | detached descriptor or `nil` |
| `IsModuleCompatible` | resource string | boolean, optional error code |
| `GetDependencyGraph` | none | detached `{nodes, edges}` DTO |
| `GetCapabilityProviders` | capability string | sorted resource names |
| `Refresh` | none | refreshed detached module array |

A descriptor includes resource/name/version/type, contract/API requirements,
capabilities, required/optional modules, actual FiveM state, compatibility status,
and stable issue codes. Callers cannot mutate internal registry tables through DTOs.

Console diagnostics: `gcore:modules`. Player invocation does nothing.

Registry metadata is not trust or security authority. A third-party resource still
runs arbitrary FiveM code and requires a real code/security review.
