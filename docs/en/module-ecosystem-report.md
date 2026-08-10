# GCore Module Ecosystem First-Stage Report

> Historical report for the original `gc_identity 0.1.0-alpha` MVP. The current
> persistent `0.2.0-alpha` result is documented in
> [gc_identity implementation report](modules/gc_identity/implementation-report.md).

## 1. Executive Summary

The `gc_example` reference module and the first production MVP, `gc_identity`,
are implemented. Both consume `gc_core` exclusively through Public API v1. Core
internals were not changed; Core API v1 and Network Protocol 1 remain compatible.

## 2. Commit / Version Audited

- Base SHA: `5fda3617952f790aaf899dab50b434b316c3e60d`.
- `gc_core`: `0.1.3-alpha`, API `1`, protocol `1`.
- `gc_example`: `0.1.0-alpha`.
- `gc_identity`: `0.1.0-alpha`, API `1`, protocol `1`.
- Delivery SHA: the commit containing this report.

## 3. Current GCore Architecture

```text
FiveM
  ↓
gc_core lifecycle + Public API v1
  ├── gc_example (reference consumer)
  └── gc_identity (independent identity domain)
```

## 4. gc_example Architecture

The module checks Core API `>= 1`, exposes server-only `/gcexample`, checks
`CanUseGameplayFeatures`, reads a detached Public Session DTO, and calls
`NotifyPlayer`. It imports no core internal file, global, or protocol event.

## 5. Module Contract Validation Result

The Module Contract works. Repository validation now enforces module manifests,
declared dependency, RU/EN documentation, tests, public core exports, and bans
known internal globals/private paths.

## 6. gc_identity Architecture

The flow is validated network ingress → identity service → repository boundary.
A trusted server-only core identifier resolves an account. The module owns its
state machine and persisted character data; its JSON adapter is an MVP boundary,
not a general ORM.

## 7. gc_identity Public API

Server exports: `GetIdentityVersion`, `GetIdentityApiVersion`,
`GetIdentityProtocolVersion`, `IsAuthorized`, `IsIdentityReady`,
`GetIdentityState`, `GetAccount`, `GetCharacters`, and `GetSelectedCharacter`.
DTOs are detached and exclude identifiers/storage metadata.

## 8. gc_identity State Machine

```text
unknown → account_required → authorized → character_required → ready
                                            └───────────────→ error
```

Identity state never mutates the core lifecycle. Downstream gameplay requires
both core gameplay readiness and identity readiness.

## 9. Security Model

Exact schemas, protocol checks, bounded rate limits, replay IDs, server-side
ownership, server-origin client guards, trusted identifiers, detached DTOs, and
non-sensitive logging protect the module boundary.

## 10. Tests

| Suite | Result |
| --- | ---: |
| gc_core harness | 496/496 PASS |
| gc_example | 31/31 PASS |
| gc_identity | 88/88 PASS |
| Repository validator | PASS |
| Lua syntax | PASS |
| `git diff --check` | PASS |

CI discovers and runs each independent `gc_*` module test suite.

## 11. Real FXServer Results

| Scenario | Result |
| --- | --- |
| FXServer + txAdmin, core/example/identity boot | PASS |
| Real FiveM client, core handshake and spawn | PASS |
| Account, character create/select, `ready` | PASS |
| Public core + identity contract probe | PASS |
| `restart gc_identity`, online recovery | PASS (`recovered=1`) |
| `restart gc_core`, core recovery | PASS (`recovered=1`) |
| `ensure gc_identity` after dependency restart | PASS (`recovered=1`) |
| Disconnect and core cleanup | PASS |
| Additional repeat connect attempt | ENV BLOCKED: external Cfx ticket `CURL 92`; required connected flow already passed |
| 2+ real clients | NOT RUN |

FiveM stops declared dependants when `gc_core` restarts, so the operational
contract explicitly requires `ensure gc_identity` afterwards. The runtime probe
ended with `COMPLETE=PASS` and no GCore `SCRIPT ERROR`.

## 12. Core API Additions

None. Both consumers were completed with API v1 as-is.

## 13. Core API Stability

API v1 remains backward-compatible. No core version/protocol bump was required.

## 14. Module Coupling Analysis

Dependencies are one-way through public exports; no core internal access or cycle
exists. The validator rejects known internal globals, paths, and unknown exports.

## 15. Repeated Development Patterns

API compatibility, fail-closed dependency calls, detached DTOs, ingress schemas,
stable error results, bounded rates, server-event guards, startup diagnostics,
and restart recovery all repeated across real consumers.

## 16. SDK Candidate Features

A small optional SDK v0 may cover those repeated patterns. It was intentionally
not implemented in this stage.

## 17. Remaining Technical Debt

- JSON persistence is alpha/MVP storage and needs backups/a future adapter.
- A 2+ real-client recovery test remains.
- External Cfx authentication intermittently returned `CURL 92`.
- No lifecycle hooks were added because current consumers do not need them.

## 18. Recommended Next Module

After a short SDK v0 design review, the recommended production module is
`gc_admin`. Create a shared database service only after a second real persistence
consumer proves that need.

## Four answers

1. `gc_example` uses Public API only: **YES**.
2. `gc_identity` avoids all `gc_core` internals: **YES**.
3. Core API v1 remains backward-compatible: **YES**.
4. There is enough evidence to start a minimal SDK v0 design: **YES**.
