# Module testing and conformance

Run the portable checks from the repository root:

```text
lua tools/module_conformance.lua path/to/module
lua tools/module_conformance.lua path/to/module --json
lua tools/module_test_harness.lua . path/to/module
lua tools/run-module-suite.lua .
lua tools/tests/run.lua .
lua tools/generate-ecosystem-docs.lua . --check
```

Conformance exit codes are `0` PASS, `1` contract failure, and `2` invalid tool
invocation. It parses manifests declaratively and never executes third-party
manifest Lua. Checks cover required metadata/files, SemVer/version source,
dependencies, contract/API values, reserved fields, private core access, and
unknown Core API exports.

Every production module owns unit, integration, security/restart, and API contract
tests appropriate to its boundary. A module with `ui_page` and `web/package.json`
is discovered by CI for dependency install, frontend tests/build, and committed
`dist` consistency. Modules without NUI have no frontend job.

Fixtures cover valid and malformed third-party modules, missing manifests/metadata,
private core access, unknown exports, dependency declaration errors, and missing
documentation. Registry tests separately cover runtime missing/stopped dependencies,
API incompatibility, cycles, DTO isolation, and start/stop refresh.
