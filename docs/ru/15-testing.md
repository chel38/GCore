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
- единый clientReady/resyncReady handshake и mismatch protocol;
- точные payload schemas, неизвестные поля, NaN/Infinity;
- state machine и lifecycle;
- pending/session/recovery DTO;
- одноразовые spawn decisions, replay/ownership/TTL;
- server snapshot model/owner/position verification;
- новая модель и новый decision на retry;
- action rate limits и decay violation window;
- API DTO immutability и invalid arguments;
- masking, notifications, locale и ped provider.

Workflow также компилирует все Lua-файлы (преобразуя только CfxLua backtick hash во
временной копии), сверяет версии, локальные Markdown-ссылки и запрещённые patterns:
сырой runtime detection, event literals и прямые state mutations.

Перейдите к [руководству разработчика](16-development-guide.md).
