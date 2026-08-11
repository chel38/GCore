# Module dependencies

There are two matching declarations for every required GCore module:

```lua
dependency 'gc_identity'
gcore_requires 'gc_identity:api>=1'
```

The FiveM declaration controls start order and runtime dependency. The GCore
declaration describes the required public API contract. The conformance checker
rejects a required GCore edge without its FiveM dependency.

Core is special and uses:

```lua
dependency 'gc_core'
gcore_requires_core_api '1'
```

Do not use Core protocol or exact `0.x` resource versions as module dependencies.

Optional integration uses only `gcore_optional`; its absence is not an error and
must not stop the resource. A required module that is missing, stopped, or exposes
an older API makes the consumer incompatible. Self-dependencies and directed
cycles are invalid.

The registry reports these facts but does not stop, restart, download, or proxy
modules. Modules still call the dependency's documented Public API directly.
