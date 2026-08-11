# gc_sdk

Optional server-only convenience layer для повторяемых compatibility checks GCore.
SDK API v1 содержит только `GetVersion`, `GetApiVersion`, `IsCoreAvailable`,
`GetCoreApiVersion`, `RequireCoreApi`, `RequireResource`.

В SDK нет domain logic, network events, state ownership, DTO magic, rate limiter и
dependency на `gc_ecosystem`. Модуль всегда может вызывать `gc_core` напрямую;
`gc_example` намеренно остаётся direct API reference.

См. [документацию SDK](../../../docs/ru/ecosystem/sdk.md).
