# Testing

Tests are written in Lua and use logical `unit`, `integration`, `security`, and
`runtime` categories. During a normal `ensure gc_core`, test files are packaged as
resource files but are not executed.

## FXServer

To validate real CfxLua/native boundaries, temporarily enable:

```cfg
set gc_runTests 1
```

After `refresh` and `restart gc_core`, expect `ALL TESTS PASSED`, then restore
`gc_runTests 0`. Temporarily setting `GCConfig.Tests.enabled = true` is an
alternative for local development.

## Standalone Lua 5.4

CI runs:

```text
lua tools/test_harness.lua .
pwsh tools/validate-repository.ps1
```

The harness emulates only the FiveM boundaries needed by unit/integration tests.
A local FXServer smoke test validates the real OneSync boundary.

Coverage includes runtime detection, unified handshakes, exact payload schemas,
finite numbers, lifecycle transitions, recovery DTOs, one-time spawn decisions,
replay/ownership/TTL, server entity snapshots, new-decision retry, action rate
limits, violation decay, immutable API DTOs, masking, notifications, locale, and
the ped provider.

The workflow also compiles every Lua file (translating only CfxLua backtick hashes
in temporary copies), checks version consistency and Markdown links, and rejects
raw runtime detection, event literals, or direct state mutation.

Continue with the [development guide](16-development-guide.md).
