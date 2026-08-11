# GCore Ecosystem v0.1 baseline

Audited source: `main` at `bcae298a403b24574704b8369323ded56829f1bb`.

## Versions before ecosystem work

| Resource | Resource version | Public API | Protocol |
| --- | --- | ---: | ---: |
| `gc_core` | `0.1.5-alpha` | 1 | 2 |
| `gc_example` | `0.1.0-alpha` | none | none |
| `gc_identity` | `0.4.1-alpha` | 1 | 3 |

## Existing foundation

- `gc_core` owns connection, session, readiness, recovery, loading, and spawn.
- `gc_example` consumes only documented Core API v1 exports.
- `gc_identity` owns registration, authorization, persistence, characters, and NUI.
- The Module Contract and API compatibility policy already prohibit core-internal access.
- The repository validator checks core versions, Lua syntax, module docs/tests, known
  core exports, private core references, identity NUI, mail-service, and Markdown links.
- The module harness runs a named module from `resources/[greencore]`; CI discovery was
  based on the `gc_*` directory prefix rather than machine-readable metadata.

## Baseline verification

| Check | Result |
| --- | --- |
| Repository validator | PASS |
| `gc_core` Lua harness | 511/511 PASS |
| `gc_example` module suite | 31/31 PASS |
| `gc_identity` module suite | 373/373 PASS |
| `gc_identity` NUI install/test/build | PASS |
| Local mail-service install/typecheck/test/build | PASS |

## Gaps proven by the audit

1. There was no formal machine-readable Module Standard metadata.
2. Module discovery used the official name prefix and a fixed repository directory.
3. There was no standalone third-party conformance checker or dependency graph.
4. There was no runtime registry, compatibility diagnostics, local catalog, generator,
   template, or packager.
5. CI knew the identity NUI explicitly instead of discovering NUI modules.
6. Core API availability checks were repeated in `gc_example` and `gc_identity`.

## SDK discovery decision

| Pattern | Core | Example | Identity | Generic | SDK v0 |
| --- | ---: | ---: | ---: | --- | --- |
| Resource/Core API availability check | yes | yes | yes | yes | YES |
| Detached DTO copy | yes | consumer only | yes | boundary-specific | NO |
| Server-origin client guard | yes | no client | yes | similar, different ownership | NO |
| Rate limiting | yes | no | yes | different policies | NO |
| Identity, character, email validation | no | no | yes | domain-specific | NO |

SDK v0 is therefore limited to optional server-side resource/API compatibility helpers.
No existing module is forced to migrate to it.
