# Third-party modules

A third-party FiveM resource participates by declaring `gcore_module 'yes'` and
following Module Standard v1. It does not need the official `gc_*` prefix. Run:

```text
lua tools/module_conformance.lua /path/to/vendor_resource --json
```

Conformance can prove structure, known Core API use, dependency declarations, and
version compatibility. The local registry can report that metadata and runtime
resource state. Neither proves that the code is safe, trusted, reviewed, or free
from malicious behavior.

Installing a third-party FiveM resource executes its server/client code. Review its
source, permissions, network events, NUI callbacks, database migrations, HTTP calls,
and package checksum before enabling it. GCore v0.1 has no `Verified`, `Trusted`, or
`Safe` badge, no remote installer/updater, and no remote Lua execution.

Capabilities are informational. Depend on a specific documented module API rather
than automatically selecting any provider by capability for security-sensitive work.
