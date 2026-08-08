# Финальный отчёт стабилизации GCore 0.1.3-alpha

Дата проверки: 2026-08-09  
Базовый commit аудита: `f62f574`  
Ресурс: `gc_core`  
Core API: `1`  
Protocol: `1`

## 1. Executive Summary

Core stabilization выполнен без переписывания сильных сервисов. Исправлены
restart/recovery race, spoof server-only client events, семантика spawn retry,
server spawn verification, API v1 contracts и version consistency.

Реальный FXServer дополнительно выявил и позволил исправить три runtime-only
ошибки: удержание Cfx deferral callbacks в timer, вызов `deferrals.done(nil)` и
pre-spawn deadlock client hello. Финальный hello теперь bounded и повторяется до
валидного server ACK.

Строгий итог этого отчёта: **MODULE READY: NO**. Кодовые, тестовые и основные
runtime gates зелёные, но полный обязательный real-client gate не закрыт:
restart в `spawn_pending`/`spawn_confirming` не воспроизведён, а последний fresh
client прогон exact final build остановился на внешнем Cfx authentication service.

## 2. Commit / Version Audited

- Audited base: `f62f574` (`main`).
- Stabilization implementation: `cf9fc09`.
- CI exit-status correction: `4f49566`.
- Resulting resource version: `0.1.3-alpha`.
- API version: `1`, без breaking change.
- Protocol version: `1`, network change additive/backward-compatible.
- Source of truth: `shared/version.lua`.
- Remote: `https://github.com/chel38/GCore.git`.
- Git history author/contributor: только `chel38`.

## 3. Recovery Architecture

Client resource start инициирует state-aware hello. Ранний hello повторяется до
первого валидного lifecycle ACK с `clientHelloMaxAttempts`, одним deadline и без
параллельных threads. `forceResync` остаётся bounded дополнительным prompt, а
`resyncReady` — совместимым alias.

Сервер сам выбирает normal/recovery/duplicate/stale flow. Duplicate сообщения не
создают session/spawn/decision и не продлевают timeout. Recovery проверяет ped,
entity, owner и health на сервере; `clientPedAliveHint` остаётся диагностикой.

## 4. Event Security Changes

Все шесть server-only client events регистрируются через общий guard
`source == 65535`: `connectionAccepted`, `spawnApproved`, `spawnRejected`,
`spawnConfirmed`, `forceResync`, `notify`. Локальный `TriggerEvent` не достигает
payload validation и side effects. Event direction синхронизирован в RU/EN docs.

## 5. Spawn Retry Changes

Добавлена декларативная policy с категориями MODEL, ENTITY, COLLISION, POSITION,
VERIFICATION, DECISION, SESSION, SECURITY, TIMEOUT и UNKNOWN. Только MODEL меняет
PED/blacklist. Каждый retry получает новый decision ID. Total, same-PED,
different-PED и verification limits находятся в config и не могут быть
бесконечными.

## 6. Spawn Verification Tests

Production `GCSpawn.Confirm` с `verification.enabled=true` покрыт success и 12
negative paths: missing/dead entity, wrong owner/model/position, timeout,
expired/consumed/foreign decision, session replacement и disconnect во время
verification. После native boundary повторно проверяются session и decision.

## 7. API v1 Contract Results

Проверены все 14 фактических exports из `server/api.lua`: типы, invalid/nil
поведение, allowed states, side effects и отсутствие mutable leakage.
`GetVersion` и Public Session DTO изолированы. `GetPlayerIdentifier` возвращает
только captured session identifier разрешённого типа. В API v1
`CanUseGameplayFeatures == true` означает ровно lifecycle state `spawned`.

Core API Version: **1**  
Status: **Stable for module development**

## 8. Versioning Changes

Validator извлекает resource/API/protocol из `shared/version.lua` и сравнивает
fxmanifest, README markers, последний CHANGELOG и exact release tag при наличии.
Hardcoded expected current version удалён. Release policy записана отдельно.

## 9. CI Results

- Standalone Lua harness: **496/496 PASS**.
- Настоящий CfxLua в FXServer: **485/485 PASS**.
- Repository validation: **PASS** (`63 Lua`, `61 Markdown`).
- Lua syntax: **PASS**.
- `git diff --check`: **PASS**.
- GitHub Actions: **PASS**
  ([run 31284224981](https://github.com/chel38/GCore/actions/runs/31284224981)).

Pipeline не игнорирует failures и не отключает важную spawn verification.

## 10. Real FXServer Test Results

Среда: FXServer b25770/Win, txAdmin 8.0.1, OneSync, FiveM b3751, один реальный
client.

| Сценарий | Результат | Доказательство |
| --- | --- | --- |
| FXServer/gc_core start | PASS | production start 0.1.3-alpha |
| Real player connect/deferral | PASS | player появился в `players.json`; Mono crash устранён |
| Handshake и spawn | PASS | Public API: `state=spawned`, `spawned=true`, `gameplay=true` |
| Server-side verification | PASS | `spawned` достигнут только через production Confirm/verification path |
| Restart while spawned | PASS | recovered=1; игрок остался online; state снова `spawned` |
| Lost/duplicate recovery ordering | PASS | resource restart + normal/recovery hello; bounded regression tests |
| Disconnect cleanup | PASS | Public API после drop: connected=false, state=nil, dto=false |
| Reconnect | PARTIAL | network reconnect выполнен; exact final retry build не дошёл до сервера из-за Cfx auth |
| Restart while spawn_pending | NOT RUN | реальное timing window не зафиксировано |
| Restart while spawn_confirming | NOT RUN | реальное timing window не зафиксировано |
| Two or more players | NOT RUN | второй client отсутствовал |

**REAL FXSERVER TEST: PARTIAL / FAIL FOR STRICT GATE.** Последняя внешняя ошибка:
`Failed to connect to authentication services in a reasonable timespan`; до
`playerConnecting` она не дошла и не является GCore reject/crash.

## 11. Documentation Changes

RU/EN обновлены для recovery, ACK-driven hello retry, trust boundary, client
event origin guard, server verification, retry policy, API v1, compatibility и
testing. Диаграммы connection/lifecycle/spawn соответствуют production flow.

## 12. Module Contract

Созданы `docs/ru/module-contract.md` и `docs/en/module-contract.md`. Модулям
разрешён только Public API/events/DTO. Internal sessions, states, decisions и
пути файлов не являются контрактом. Рекомендуемая dependency — API version, а не
точная resource version. `gc_example` не создавался, потому что strict gate ещё
не разрешает объявить MODULE READY.

## 13. Remaining Technical Debt

1. Повторить fresh client connect на exact final build после восстановления Cfx auth.
2. Реально воспроизвести restart в `spawn_pending` и `spawn_confirming`.
3. По возможности выполнить 2+ client restart test.
4. После закрытия этих runtime checks можно создать минимальный `gc_example`.

## 14. Breaking Changes

Breaking Public API changes отсутствуют. API остаётся v1, protocol остаётся v1.
Добавлены config keys для client hello retry и новые internal diagnostic codes.
Resource version повышена до `0.1.3-alpha`.

## 15. Migration Notes

- Модули должны проверять `GetApiVersion() >= 1`, а не точную 0.1.3-alpha.
- Нельзя обращаться к `GCSessions`, `GCStates`, spawn decisions или internal files.
- Client hello/resync может повторяться; server handlers модулей должны быть
  идемпотентными и не считать client payload authoritative.
- Локальные client events не могут подменять server-only GCore events.

## 16. Module Ready Gate

| Gate | Result |
| --- | --- |
| Runtime | PASS |
| Connection | PASS |
| Session lifecycle | PASS |
| State machine | PASS |
| Protocol | PASS |
| Recovery | PASS |
| Client event security | PASS |
| Spawn authority | PASS |
| Spawn retry policy | PASS |
| Public API v1 | PASS |
| DTO isolation | PASS |
| Rate limiting | PASS |
| Versioning | PASS |
| CI | PASS (local/Cfx/GitHub Actions) |
| Documentation | PASS |
| Real FXServer smoke test | FAIL (strict matrix incomplete) |

### Audit findings

| ID | Audit Finding | Before | After | Test | Status |
| --- | --- | --- | --- | --- | --- |
| P1-001 | Restart/resync race | one-shot flow | idempotent ACK-driven recovery | recovery lost/duplicate/stale/timeout + real restart | PASS |
| P1-002 | Client event spoofing | no common source guard | centralized server-origin guard | six local TriggerEvent spoof tests | PASS |
| P2-001 | Spawn retry semantics | unrelated errors affected PED | error-specific policy | retry policy/category/limit tests | PASS |
| P2-002 | Spawn verification integration | partial snapshot tests | full production Confirm path | 13 integration scenarios | PASS |
| P2-003 | API contracts | partial tests | full API v1 contracts | 14 exports, DTO/side effects/errors | PASS |
| P2-004 | Version source | duplicated expectations | dynamic single source | repository validator | PASS |
| P3-001 | Documentation sync | partially stale | synchronized RU/EN | repository/docs validation | PASS |

## 17. Final Verdict

```text
========================================
GCORE FOUNDATION STATUS
========================================
Core Runtime:          STABLE
Lifecycle:             STABLE
Protocol:              STABLE
Recovery:              STABLE
Server Authority:      STABLE
Spawn:                 STABLE
Security Boundary:     STABLE
Public API v1:         FROZEN
Tests:                 PASS
CI:                    PASS (local/Cfx/GitHub Actions)
Documentation:         SYNCHRONIZED
FOUNDATION:
MODULE READY: NO
========================================
```

Причина `NO` ограничена реальным runtime gate, а не обнаруженным архитектурным
дефектом. После трёх оставшихся smoke scenarios следующий порядок:

1. Freeze Core API v1 окончательно.
2. Publish Module Contract v1.
3. Create `gc_example`.
4. Create first production module.
5. Проектировать SDK по опыту reference + production module.
6. Добавлять CLI только после понимания реального module workflow.

## Appendix A. Phase Reports

### PHASE 1 — Current State Verification

Status: PASS  
Changed: фактические risks сверены с main.  
Files: весь `gc_core`, tests, docs, CI.  
Fixed Audit Findings: подтверждены P1/P2/P3 scopes.  
Tests Added: N/A.  
Tests Passed: baseline.  
Remaining Risks: recovery, client events, spawn/API/version/docs.

### PHASE 2 — Recovery Stabilization

Status: PASS  
Changed: state-aware hello, ACK retry, bounded prompts/timeouts.  
Files: client/server connection/readiness/players/config.  
Fixed Audit Findings: P1-001.  
Tests Added: lost push, duplicate, stale, mismatch, timeout, ACK cadence.  
Tests Passed: PASS.  
Remaining Risks: strict real timing variants.

### PHASE 3 — Client Event Security

Status: PASS  
Changed: centralized FiveM server-origin guard.  
Files: shared/client_security.lua, client/events.lua.  
Fixed Audit Findings: P1-002.  
Tests Added: six spoof scenarios.  
Tests Passed: PASS.  
Remaining Risks: none known.

### PHASE 4 — Spawn Retry Policy

Status: PASS  
Changed: declarative categories/actions/limits.  
Files: server/spawn_retry.lua, spawn.lua, config/spawn.lua.  
Fixed Audit Findings: P2-001.  
Tests Added: category, same/new PED, terminal limits.  
Tests Passed: PASS.  
Remaining Risks: none known.

### PHASE 5 — Spawn Integration Tests

Status: PASS  
Changed: full authoritative verification/cancel checks.  
Files: server/spawn.lua, spawn_verification_integration_test.lua.  
Fixed Audit Findings: P2-002.  
Tests Added: 13 required scenarios.  
Tests Passed: PASS.  
Remaining Risks: real restart timing variants.

### PHASE 6 — API v1 Contract Tests

Status: PASS  
Changed: DTO/identifier contracts and all exports covered.  
Files: server/api.lua, sessions.lua, tests/api_test.lua.  
Fixed Audit Findings: P2-003.  
Tests Added: 14 export contracts.  
Tests Passed: PASS.  
Remaining Risks: none known.

### PHASE 7 — Version Source Cleanup

Status: PASS  
Changed: dynamic validator; release 0.1.3-alpha.  
Files: version, manifest, README, CHANGELOG, validator.  
Fixed Audit Findings: P2-004.  
Tests Added: version consistency validation.  
Tests Passed: PASS.  
Remaining Risks: release tag optional until publication.

### PHASE 8 — Documentation Sync

Status: PASS  
Changed: RU/EN flows, security, API, Module Contract, policy.  
Files: docs/ru, docs/en, diagrams, README.  
Fixed Audit Findings: P3-001.  
Tests Added: repository/doc markers.  
Tests Passed: PASS.  
Remaining Risks: none known.

### PHASE 9 — Real Runtime Validation

Status: PARTIAL  
Changed: исправлены три runtime-only connection defects; txAdmin настроен.  
Files: connection/readiness/events/config; local ignored txData.  
Fixed Audit Findings: deferral Mono crash, pre-spawn hello deadlock.  
Tests Added: deferral arity/lifetime/deadline, hello retry/ACK/cadence.  
Tests Passed: spawn, spawned restart, recovery, cleanup; strict matrix incomplete.  
Remaining Risks: exact final fresh connect после Cfx auth, pending/confirming restart.

### PHASE 10 — Module Ready Gate

Status: FAIL (strict)  
Changed: gate evaluated without false PASS.  
Files: этот отчёт.  
Fixed Audit Findings: все listed audit findings PASS.  
Tests Added: N/A.  
Tests Passed: automated/core gates PASS.  
Remaining Risks: обязательные real-client scenarios выше.
