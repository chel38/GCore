# gc_ecosystem

Optional server-only GCore Module Standard v1 registry and compatibility diagnostics.
It discovers `gcore_module 'yes'` through FiveM resource metadata, keeps an in-memory
registry, exposes detached DTOs, and refreshes on resource start/stop.

It does not proxy gameplay, own player state, accept client events, download code,
or stop/restart resources. `gc_core` and domain modules continue working without it.

Server exports (Ecosystem API v1): `GetVersion`, `GetApiVersion`, `ListModules`,
`GetModule`, `IsModuleCompatible`, `GetDependencyGraph`, `GetCapabilityProviders`,
and `Refresh`. Run `gcore:modules` in the server console for a concise report.

See [registry documentation](../../../docs/en/ecosystem/registry.md).
