# GCore Ecosystem v0.1 implementation report

## 1. Audited SHA

The work started from clean `main` at `bcae298a403b24574704b8369323ded56829f1bb`.
Repository code, not the planning prompt, was used as the source of truth.

## 2. Current GCore versions

| Resource | Resource version | Public API | Protocol |
| --- | ---: | ---: | ---: |
| `gc_core` | `0.1.5-alpha` | 1 | 2 |
| `gc_identity` | `0.4.1-alpha` | 1 | 3 |
| `gc_example` | `0.1.0-alpha` | — | — |
| `gc_ecosystem` | `0.1.0-alpha` | 1 | — |
| `gc_sdk` | `0.1.0-alpha` | 1 | — |

Core API v1 and the existing network protocols were not changed.

## 3. Ecosystem architecture

`gc_core` remains the independent foundation. Modules may call its Public API
directly. `gc_sdk` is an optional boilerplate helper, and `gc_ecosystem` is an
optional server-side diagnostic registry. Neither is on a gameplay path.

```text
FiveM -> gc_core Public API -> independent modules
                         \-> optional gc_sdk
installed resources -> optional gc_ecosystem diagnostics
repository -> portable tools -> validation/tests/catalog/package
```

## 4. Module Standard v1

Module Standard v1 defines resource structure, ownership boundaries, required
bilingual documentation, a single module version source, tests, dependency
declarations, DTO isolation, and no access to `gc_core` internals.

## 5. Metadata schema

Machine-readable `fxmanifest.lua` metadata includes `gcore_module`,
`gcore_contract`, `gcore_type`, optional `gcore_api`, required Core API,
capabilities, required/optional module dependencies, repository, and license.
The reserved `gcore_*` namespace is validated declaratively without executing a
third-party manifest.

## 6. Existing modules migration

`gc_example` and `gc_identity` now publish Module Standard metadata.
`gc_example` received `shared/version.lua`; its direct-Core reference pattern is
preserved. No existing gameplay or identity contract was moved into ecosystem code.

## 7. gc_ecosystem architecture

`gc_ecosystem` is server-only and reads only FiveM resource metadata/state plus
public API versions. It has an in-memory registry, immutable public DTO boundary,
dependency graph, compatibility evaluator, capability index, bounded refresh on
resource lifecycle events, and a console-only diagnostic command.

## 8. Ecosystem Public API

API v1 exports `GetVersion`, `GetApiVersion`, `ListModules`, `GetModule`,
`IsModuleCompatible`, `GetDependencyGraph`, `GetCapabilityProviders`, and
`Refresh`. Returned tables are deep copies. No mutation or resource-start API is
exposed.

## 9. Module registry

Discovery uses `gcore_module 'yes'`, not a `gc_` name prefix. Official and
third-party names are treated uniformly. Registry status distinguishes compatible,
incompatible, missing dependency, stopped, malformed, and cyclic resources.

## 10. Dependency resolver

Required dependencies use `resource:api>=N` and must also be declared as FiveM
dependencies. Optional dependencies are recorded but do not fail compatibility when
absent. Missing, stopped, or insufficient-API providers fail closed.

## 11. Cycle detection

The portable graph library and runtime registry detect self-dependencies and cycles.
Catalog generation also rejects cycles before generated documentation is written.

## 12. Compatibility logic

Compatibility checks Module Contract version, Core resource state, minimum Core API,
module resource state, required module existence/state/API, metadata validity, and
cycles. Diagnostics use stable `GC-ECOSYSTEM-*` codes.

## 13. Capability model

Capabilities are lowercase metadata labels used for discovery and diagnostics.
They do not grant permissions, establish trust, or replace an explicit dependency.
The registry returns every compatible provider for a capability.

## 14. SDK discovery

Repeated patterns found in `gc_example` and `gc_identity` were limited to checking
Core availability/API and checking a generic resource dependency. Only those patterns
were selected for SDK v0.

## 15. SDK v0 API

`gc_sdk` exports version/API queries, `IsCoreAvailable`, `GetCoreApiVersion`,
`RequireCoreApi`, and `RequireResource`. It is server-only, fail-closed, contains no
domain logic, and is not required by Core, registry, or existing modules.

## 16. Module generator

`lua tools/create-module.lua <name>` creates server, optional client, or optional NUI
modules. It validates names and types, requires an explicit third-party flag for
non-`gc_` names, supports dry-run/JSON output, and never overwrites a destination.

## 17. Module template

Templates produce a normal readable FiveM resource with manifest metadata,
`shared/version.lua`, direct Core API compatibility check, server tests, RU/EN
README files, and only the client/NUI files explicitly requested. No dummy gameplay
or hidden framework is generated.

## 18. Conformance tool

`module_conformance.lua` checks metadata, SemVer/API consistency, required files,
manifest file references, dependency grammar/declarations, forbidden Core globals and
paths, and calls to unknown Core exports. It supports standalone path/JSON usage.

## 19. Packaging tool

The packager runs conformance and module tests, validates NUI `dist`, copies an
allowlist-safe tree, writes a portable tar, SHA-256, and release manifest, and refuses
overwrite. Secrets, dependencies, build output, databases, and top-level runtime
`data/` are excluded. A regression test prevents private identity data from entering
artifacts.

## 20. Local catalog

The catalog is generated from manifests and contains four current modules. Duplicate
resources, missing required dependencies, and cycles stop generation.

## 21. Generated documentation

One command generates `docs/generated/modules.json`, RU/EN module tables, and the
Mermaid dependency graph. `--check` makes stale generated output a CI failure.

## 22. CI changes

CI dynamically discovers all Module Standard resources. A per-module matrix runs
conformance and tests, while a separate dynamic NUI matrix installs exact dependencies,
tests, builds, and checks committed `dist`. Repository validation and catalog drift
checks remain generic; adding a module requires no workflow edit.

## 23. Security model

The ecosystem executes no remote code and never executes third-party manifests during
static discovery. Runtime data and secrets are excluded from packages. Core internals,
private paths, undeclared dependencies, unknown Core exports, unsafe generator names,
and mutable DTO leakage have automated regression coverage.

## 24. Third-party module support

A module may use any valid resource name when marked by metadata. The same parser,
conformance, test harness, runtime registry, compatibility logic, catalog, and packager
work for non-`gc_` resources. No marketplace account is required.

## 25. Automated tests

Final local results: Core `511/511`; modules `463/463` across four resources; ecosystem
tooling `34/34`; identity NUI `16/16`; mail service `14/14`. Repository validation and
generated-document checks pass. Standard `luac` alone cannot parse FiveM backtick model
literals, so repository validation remains the authoritative syntax boundary.

## 26. Real FXServer tests

PASS on the live txAdmin-managed FXServer with one connected player:

- four production modules discovered and compatible;
- player remained Core `spawned` and identity `ready` after stopping `gc_ecosystem`;
- registry restart restored its complete state;
- stopping/starting `gc_example` changed status deterministically;
- compatible third-party resource was discovered without a prefix;
- Core API 999 fixture was rejected;
- missing module dependency fixture was rejected;
- temporary fixtures were stopped and removed; final registry returned to four clean modules.

## 27. Backward compatibility

Core API remains 1, Core protocol remains 2, identity API remains 1, and identity
protocol remains 3. Existing modules can keep calling Core directly. Resource startup
does not require `gc_sdk` or `gc_ecosystem`.

## 28. Remaining technical debt

The registry is intentionally local and in-memory; it is not a trust or signature
system. Packaging uses checksums, not publisher signatures. Module API negotiation is
minimum-version only. Empty-NUI matrix handling can be generalized if the repository
ever contains zero NUI modules. No issue blocks ecosystem v0.1 usage.

## 29. Marketplace readiness

The local metadata, catalog, conformance, packaging, checksums, and third-party path are
a sound prerequisite. Marketplace, remote installer, auto-update, publisher identity,
signing, moderation, and remote code execution are deliberately **not implemented**.

## 30. Recommended next milestone

Use the standard to build one narrowly scoped real module, collect repeated authoring
friction, and only then extend SDK v0 additively. Design signing/trust and marketplace
governance separately before any remote distribution feature.

## Quality table

| Area | Result |
| --- | --- |
| Core independence | PASS |
| Module Standard | PASS |
| Metadata validation | PASS |
| Registry | PASS |
| Dependency graph | PASS |
| Cycle detection | PASS |
| API compatibility | PASS |
| SDK optional | PASS |
| Third-party modules | PASS |
| Generator | PASS |
| Conformance | PASS |
| Packaging | PASS |
| Catalog | PASS |
| Generic CI | PASS |
| RU docs | PASS |
| EN docs | PASS |
| Real FXServer | PASS |

## Final questions

| Question | Answer |
| --- | --- |
| Can a new module be created without opening `gc_core` internals? | YES |
| Can module compatibility be checked automatically? | YES |
| Can a third-party module be tested outside the main repository? | YES |
| Can a module be built into a distributable artifact? | YES |
| Can GCore be used without the SDK? | YES |
| Can GCore be used without `gc_ecosystem`? | YES |

**GCORE ECOSYSTEM v0.1: READY**
