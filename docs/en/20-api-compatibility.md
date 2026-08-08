# API compatibility policy

Core API Version: `1` — **Stable for module development**.

| Change type | Policy |
| --- | --- |
| Patch release (`0.1.x`) | No breaking Public API v1 changes. Fixes, tests, docs, and compatible internals only. |
| Minor pre-1.0 release (`0.x.0`) | Additive API v1 methods/fields may be introduced; existing contracts remain valid. |
| Breaking Public API change | Increment the Core API version and publish migration notes. Keep a compatibility adapter when practical. |
| Breaking network contract | Increment protocol version; resource version alone is not sufficient. |
| Internal refactor | No API/protocol bump when public behavior and payload contracts remain compatible. |

Modules gate on `GetApiVersion()`, not exact `GetVersionString()`. Deprecations must
be documented before removal. A breaking change cannot be hidden in a patch release.
