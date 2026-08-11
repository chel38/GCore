# gc_sdk

Optional, server-only convenience layer for repeated GCore compatibility checks.
SDK API v1 contains only `GetVersion`, `GetApiVersion`, `IsCoreAvailable`,
`GetCoreApiVersion`, `RequireCoreApi`, and `RequireResource`.

It has no domain logic, network events, state ownership, DTO magic, rate limiter,
or dependency on `gc_ecosystem`. Modules may always call `gc_core` directly;
`gc_example` intentionally remains the direct API reference.

See [SDK documentation](../../../docs/en/ecosystem/sdk.md).
