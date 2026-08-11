# Creating a module

A FiveM resource is a loadable folder with `fxmanifest.lua`. A GCore module is a
resource that declares Module Standard metadata and uses public GCore contracts.
An API version is a compatibility promise; a capability is only a catalog label.

## Generate a starting point

```text
lua tools/create-module.lua gc_weather_example --type=domain
```

This creates a server-only skeleton. It contains no weather or other dummy
gameplay. Available switches:

- `--client` adds client runtime.
- `--nui` adds client runtime and a TypeScript/Tailwind/Vite NUI skeleton.
- `--api=1` declares a module Public API version.
- `--sdk` opts into `gc_sdk`; direct Core API remains the default.
- `--third-party` permits a non-`gc_*` resource name.
- `--output=path` chooses the parent output directory.
- `--dry-run --json` prints a machine-readable plan without writing.

The generator rejects path traversal, invalid types, reserved official prefixes,
and an existing destination. It never overwrites a module.

## Implement the domain

1. Check Core API `>= 1`, not an exact core resource patch.
2. Keep server-owned state and validate every client/NUI payload.
3. Add only necessary client/NUI/public exports.
4. Return detached DTOs and document nil/error behavior.
5. Re-check session/state after DB or HTTP yields.
6. Handle resource/core/dependency stop and restart safely.

Do not import core internals or export every local function. Use local server
events/exports for server-to-server module communication; use network events only
for a real client boundary.

## Verify and package

```text
lua tools/module_conformance.lua resources/[greencore]/gc_weather_example
lua tools/module_test_harness.lua . resources/[greencore]/gc_weather_example
lua tools/package-module.lua resources/[greencore]/gc_weather_example
```

The generated resource remains ordinary readable FiveM Lua; tooling does not hide
architecture or execute remote code.
