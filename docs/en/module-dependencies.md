# GCore module dependencies

This document records runtime dependency direction. Arrows point from a module
to the public contract it requires.

```text
gc_example  ───────→ gc_core Public API v1
gc_identity ───────→ gc_core Public API v1
gc_sdk ────────────→ gc_core Public API v1 (optional convenience)
gc_ecosystem ──────→ gc_core Public API v1 (optional diagnostics)
```

Or as a layer tree:

```text
gc_core 0.1.5-alpha (API 1, protocol 2)
├── gc_example 0.1.0-alpha (reference, no public API)
├── gc_identity 0.4.1-alpha (Identity API 1, protocol 3, manual core spawn mode, oxmysql/MariaDB + localhost mail-service)
├── gc_sdk 0.1.0-alpha (optional SDK API 1)
└── gc_ecosystem 0.1.0-alpha (optional Ecosystem API 1)
```

`gc_core` has no module dependency. `gc_example` intentionally uses Core API
directly. `gc_identity` requires neither SDK nor registry. Stopping `gc_sdk` or
`gc_ecosystem` cannot affect the core/identity gameplay lifecycle.

`gc_identity` additionally depends on the external `oxmysql` resource. That edge
belongs to the identity persistence domain and does not propagate into `gc_core`.

Forbidden edges:

```text
gc_core → gc_identity
gc_identity → gc_core internal files/tables
gc_example → gc_identity
```

The repository validator checks manifests, `gc_core` dependency declarations,
unknown core exports, and private core symbols/paths for every `gc_*` resource.
Update this file whenever a public module dependency is introduced or removed.
