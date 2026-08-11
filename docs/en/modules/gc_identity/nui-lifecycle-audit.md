# gc_identity NUI and connection lifecycle audit

Audit date: 2026-08-11

> Historical black-screen audit for `0.2.1-alpha`. The fixes remain relevant,
> while the current email-code and new-IP screens are documented in
> [Email verification](email-verification.md).

Audited baseline: `293c92238368a5a8c08eaecccd7b0b610ce5f08d`

Fixed identity version: `0.2.1-alpha` (API 1, protocol 1). Core remains
`0.1.4-alpha` (API 1, protocol 1).

## Root cause

FiveM eagerly loads every declared `ui_page`. Two presentation bugs combined:

1. the old frontend called `renderLoading()` during its first mount while no
   Lua/server snapshot existed, painting a nearly opaque viewport-sized shell;
2. the production document declared `color-scheme: dark` even while the root was
   empty. In the real FiveM CEF compositor that inactive document canvas remained
   black instead of becoming a transparent overlay.

The second condition was isolated in the live runtime: with an already spawned
player, `ensure gc_identity` alone produced the black layer and `stop gc_identity`
removed it. Core was already `spawned`, the ped existed at the verified position,
and the game screen had faded in. This proved that spawn and fade were not the
remaining cause.

The fix removes the forced document colour scheme and gives the DOM root an
explicit `hidden` lifecycle. It becomes visible only when an authoritative
snapshot or terminal diagnostic actually has a view. Early core/database races
and JavaScript/Lua failures also have bounded terminal recovery instead of an
indefinite empty overlay.

Assets were not the cause: `vite.config.ts` already used `base: './'`, the built
HTML referenced relative hashed assets, every referenced file existed in
`web/dist`, and the real FiveM log contained no bundle exception.

## Actual connection path

```text
FiveM connection / deferrals
  → gc_core client scripts loaded
  → bounded clientReady hello
  → server connectionAccepted
  → server-authoritative spawn decision
  → client fade-out, model/collision/position work, fade-in
  → server entity verification and spawnConfirmed
  → gc_core closes FiveM loading screens once
  → gc_identity resolves the trusted identifier
  → ready identity stays visually hidden
     OR registration/character state opens NUI
```

`gc_core` owns all fades, loading-screen shutdown, spawn decisions and spawn
verification. `gc_identity` owns only its NUI focus/presentation restriction and
identity state. The audit found no identity call to screen-fade or loading-screen
natives and no unbounded core wait.

## NUI lifecycle after the fix

```text
HTML loaded → root hidden / transparent document canvas / no focus
JavaScript initialized → NUI ready callback
Lua stores or already has authoritative snapshot
  ├─ state=ready → replay snapshot, keep NUI empty, release focus/freeze
  └─ state!=ready → replay snapshot, render UI, acquire focus/freeze

transient core/DB/bootstrap race → bounded silent hello retry
terminal DB/hello failure → diagnostic retry/exit view
no JavaScript ready ACK → release focus/freeze → validated server disconnect
resource stop → cancel watchdog → clear view → release focus/freeze
```

No fixed sleep is used as a synchronization mechanism. The only waits are
bounded retry/deadline watchdogs; readiness is established by callbacks and
authoritative snapshots.

## Failure recovery and diagnostics

| Code | Meaning | Result |
| --- | --- | --- |
| `GC-IDENTITY-HELLO-TIMEOUT` | no authoritative reply within the bounded hello window | visible retry/exit view |
| `GC-IDENTITY-DATABASE-UNAVAILABLE` | startup completed in degraded database state | server rejection and visible error |
| `GC-IDENTITY-NUI-NOT-READY` | JS bundle did not call ready in time | focus/freeze released and controlled disconnect |
| `GC-IDENTITY-CLIENT-FAILURE-INVALID` | forged/unapproved client failure code | rejected; no privileged effect |

Transient `CORE-UNAVAILABLE`, `PLAYER-NOT-CONNECTED`, `PLAYER-NOT-READY`,
`OPERATION-IN-PROGRESS`, and non-degraded database bootstrap states do not flash
a terminal error. They are retried by the existing bounded hello loop.

For debugging, enable `GCIdentityConfig.client.debug` temporarily and inspect the
FiveM client log for `[GC][IDENTITY][CLIENT]`. Never log connection strings,
email, identifiers, passwords, or tokens. Password authentication is disabled in
this version; no password field or password storage exists.

## Build and manifest contract

- `ui_page`: `web/dist/index.html`;
- manifest files: built HTML and `web/dist/assets/*`;
- Vite base: `./`;
- standalone browser development: the bridge is inert when
  `GetParentResourceName` is absent;
- CI rebuilds NUI and fails if committed `dist` differs.

## Regression coverage

Automated tests cover hidden initial mount, ready-player no-flash, authoritative
snapshot replay after the JS ACK, balanced focus/freeze, bounded hello timeout,
transient core startup, degraded database response, server rejection, broken NUI
bundle cleanup, controlled disconnect allowlist, restart recovery, reconnect,
two isolated server-side player sessions, spawn failure/retry and core loading
completion.

| Scenario | Boundary | Result |
| --- | --- | --- |
| returning player and clean reconnect | real FXServer + one FiveM client | PASS |
| `restart gc_identity` while spawned | real FXServer + one FiveM client | PASS |
| `restart gc_core` + re-ensure declared dependant | real FXServer + one FiveM client | PASS |
| new identity registration through ready | production Lua path in module harness + NUI unit path | PASS |
| database unavailable / degraded | production service/events with database boundary mock | PASS |
| slow database/bootstrap race | production recovery path with deferred boundary | PASS |
| delayed or missing NUI ready | production Lua client path in runtime harness | PASS |
| server rejection and spawn failure | module/core integration harnesses | PASS |
| two simultaneous identity sessions | production service path in integration harness | PASS |
| two separate real FiveM clients | not run | NOT RUN |

## Remaining architectural observation

In the audited API v1 architecture, core spawn currently completes independently
of identity readiness; `CanUseGameplayFeatures` means core state `spawned` only.
This did not cause the black screen and was deliberately not changed by this
minimal bug fix. A future identity-before-gameplay gate must be a generic,
versioned core/module contract, not a private core dependency on `gc_identity`.

## Runtime gate

The fixed production build was verified in FXServer build b3751 with MariaDB and
oxmysql:

- an existing player completed a clean disconnect/reconnect and reached gameplay;
- `restart gc_identity` while spawned preserved the visible world;
- `restart gc_core`, followed by the required `ensure gc_identity`, recovered the
  spawned player and kept the NUI transparent;
- the live FiveM log reported `state=ready`, with no NUI bundle exception;
- stopping and starting only `gc_identity` reproduced the old failure before the
  document-canvas fix and no longer reproduced it after the fix.

New-account form submission, concurrent real clients, and injected real database
latency were not executed as destructive/multi-client live tests in this run;
their production boundaries are covered by the automated module/runtime suites.
