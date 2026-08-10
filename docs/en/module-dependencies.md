# GCore module dependencies

This document records runtime dependency direction. Arrows point from a module
to the public contract it requires.

```text
gc_example  ───────→ gc_core Public API v1
gc_identity ───────→ gc_core Public API v1
```

Or as a layer tree:

```text
gc_core 0.1.4-alpha (API 1)
├── gc_example 0.1.0-alpha (reference, no public API)
└── gc_identity 0.2.0-alpha (Identity API 1, requires oxmysql/MariaDB)
```

`gc_core` has no dependency on either module. `gc_example` and `gc_identity` do
not depend on each other. Future domain modules may require Identity API 1 when
they need a selected character, but they must still check Core API independently.

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
