# gc_ecosystem

Optional server-only registry и compatibility diagnostics для GCore Module Standard v1.
Ресурс находит `gcore_module 'yes'` через FiveM metadata, хранит in-memory registry,
возвращает detached DTO и обновляется при start/stop ресурсов.

Он не proxy-ит gameplay, не владеет player state, не принимает client events, не
скачивает code и не останавливает/перезапускает ресурсы. `gc_core` и domain modules
продолжают работать без него.

Server exports Ecosystem API v1: `GetVersion`, `GetApiVersion`, `ListModules`,
`GetModule`, `IsModuleCompatible`, `GetDependencyGraph`, `GetCapabilityProviders`,
`Refresh`. Команда server console: `gcore:modules`.

См. [документацию registry](../../../docs/ru/ecosystem/registry.md).
