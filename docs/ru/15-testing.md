# Тестирование

Тесты написаны на Lua и разделены логическими категориями: `unit`, `integration`,
`security`, `runtime`. При обычном `ensure gc_core` файлы только упакованы как
resource files и не исполняются.

## FXServer

Для проверки реальных CfxLua/native boundaries временно включите:

```cfg
set gc_runTests 1
```

После `refresh` и `restart gc_core` найдите `ALL TESTS PASSED`, затем обязательно
верните `gc_runTests 0`. Альтернатива для локальной разработки — временный
`GCConfig.Tests.enabled = true`.

## Standalone Lua 5.4

CI выполняет:

```text
lua tools/test_harness.lua .
pwsh tools/validate-repository.ps1
```

Harness эмулирует только границы FiveM, нужные unit/integration тестам. Реальную
работу OneSync подтверждает локальный FXServer smoke test.

## Что проверяется

- runtime detection с фактическим вызовом native;
- lost-forceResync race, duplicate/stale clientReady/resyncReady и protocol mismatch;
- точные payload schemas, неизвестные поля, NaN/Infinity;
- state machine и lifecycle;
- pending/session/recovery DTO;
- одноразовые spawn decisions, replay/ownership/TTL;
- все шесть client event origin guards;
- полный production `GCSpawn.Confirm` с `verification.enabled=true`: entity
  missing/dead, owner/model/position mismatch, timeout, expired/consumed/foreign
  decision, session replacement и disconnect cancellation;
- retry policy для same/different PED и terminal categories;
- action rate limits и decay violation window;
- contract всех 14 API v1 methods, DTO immutability, state и side effects;
- masking, notifications, locale и ped provider.

Workflow также компилирует все Lua-файлы (преобразуя только CfxLua backtick hash во
временной копии), извлекает version/API/protocol из `shared/version.lua`, сверяет
manifest/CHANGELOG/README/tag, локальные Markdown-ссылки и запрещённые patterns:
сырой runtime detection, event literals и прямые state mutations.

Standalone harness не заменяет реальный client. Release gate обязан писать
`REAL FXSERVER TEST: NOT RUN`, если connect/spawn/restart/disconnect/reconnect
сценарий фактически не выполнялся.

Перейдите к [руководству разработчика](16-development-guide.md).
