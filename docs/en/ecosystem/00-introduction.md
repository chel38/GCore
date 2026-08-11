# GCore Ecosystem v0.1

GCore Ecosystem is the developer infrastructure around the small `gc_core`
foundation. Core owns the player lifecycle. Independent resources own gameplay
domains and communicate through documented public APIs.

```text
                         gc_core / Public API v1
                                  ▲
                 ┌────────────────┼────────────────┐
                 │                │                │
            gc_identity      gc_example       third-party

             optional convenience        optional diagnostics
                    gc_sdk                  gc_ecosystem
```

`gc_sdk` removes a small amount of repeated compatibility boilerplate.
`gc_ecosystem` observes installed metadata and reports compatibility. Neither is
required by `gc_core`; neither proxies gameplay or owns player state.

The development flow is:

```text
create-module → write domain logic → conformance → tests → package → artifact
```

Start with [Module Standard v1](module-standard.md), then follow
[Creating a module](creating-module.md). The verified implementation results are in
the [Ecosystem v0.1 report](ecosystem-v0.1-report.md).
