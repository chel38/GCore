# Локальный module registry

`gc_ecosystem 0.1.0-alpha` — optional server-only diagnostics resource. Он
перечисляет FiveM resources, читает official runtime metadata API, выбирает
`gcore_module 'yes'` и строит in-memory registry. Он не сканирует filesystem в
runtime, не polling-ит каждый tick, не принимает client events, не скачивает code
и не меняет resource/player state.

Registry обновляется при собственном startup, `onResourceStart`, `onResourceStop`
и явном `Refresh`. Compatibility проверяет Module Contract v1, Core API, state/API
required resources, malformed descriptor, self-dependency и cycle. Отсутствие
optional module разрешено.

## Ecosystem API v1 (server)

| Export | Arguments | Returns |
| --- | --- | --- |
| `GetVersion` | нет | detached version DTO |
| `GetApiVersion` | нет | integer `1` |
| `ListModules` | нет | sorted detached descriptor array |
| `GetModule` | resource string | detached descriptor или `nil` |
| `IsModuleCompatible` | resource string | boolean, optional error code |
| `GetDependencyGraph` | нет | detached `{nodes, edges}` DTO |
| `GetCapabilityProviders` | capability string | sorted resource names |
| `Refresh` | нет | обновлённый detached module array |

Descriptor содержит resource/name/version/type, contract/API requirements,
capabilities, required/optional modules, реальный FiveM state, compatibility status
и стабильные issue codes. Изменение DTO не меняет internal registry.

Console diagnostics: `gcore:modules`. Player invocation ничего не делает.

Registry metadata не является trust/security authority. Сторонний resource всё
равно запускает FiveM code и требует настоящего code/security review.
