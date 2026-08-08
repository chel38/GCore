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

Coverage includes the lost-forceResync race, duplicate/stale handshakes, all six
client event origin guards, exact payload schemas, lifecycle, and the full
production `GCSpawn.Confirm` path with verification enabled. Entity missing/dead,
wrong owner/model/position, timeout, expired/consumed/foreign decisions,
session replacement, and disconnect cancellation are tested. All 14 API v1
methods have contract tests, including DTO mutation and side effects.

The workflow also compiles every Lua file (translating only CfxLua backtick hashes
in temporary copies), derives version/API/protocol from `shared/version.lua`,
checks manifest/CHANGELOG/README/tag consistency and Markdown links, and rejects
raw runtime detection, event literals, or direct state mutation.

The standalone harness is not a substitute for a real client. Release gating must
report `REAL FXSERVER TEST: NOT RUN` unless the documented connect/spawn/restart/
disconnect/reconnect scenario was actually executed.

Continue with the [development guide](16-development-guide.md).
