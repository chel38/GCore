# Changelog

Все заметные изменения проекта документируются в этом файле.
All notable changes to this project are documented in this file.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.5-alpha] - 2026-08-11

### Добавлено / Added

- Универсальный Core spawn mode: `automatic` сохраняет standalone-поведение,
  `manual` разрешает spawn только доверенному server export `RequestPlayerSpawn`.
- Server-local `gc_core:hook:playerSpawned` для подтверждённого lifecycle без
  раскрытия внутренних session/state таблиц.
- `gc_identity 0.4.0-alpha` с pre-spawn регистрацией: зарегистрированное имя,
  email challenge, отдельная финализация и атомарное создание аккаунта.
- Миграция `003_pre_spawn_registration` и Public API `GetDisplayName(source)`.
- Regression tests для spawn gate, запрета раннего аккаунта/spawn, duplicate
  finalize, смены email и legacy profile completion.

### Изменено / Changed

- Network protocol `gc_core` повышен до `2`; connection ACK теперь явно
  сообщает `spawnMode`. Core API остаётся `1` и backward-compatible.
- `gc_identity` повышен до resource `0.4.0-alpha`, protocol `3`; Identity API
  остаётся `1`.
- Персонажи остаются post-spawn domain, а account registration/security теперь
  полностью завершаются до выдачи spawn decision.

### Безопасность / Security

- Клиентский `requestSpawn` в manual mode всегда отклоняется кодом
  `GC-SPAWN-MANUAL-ONLY` и не создаёт spawn decision.
- Подтверждение email не создаёт аккаунт и не авторизует spawn. Финализация
  повторно проверяет server-owned identifier, endpoint fingerprint, challenge,
  имя и email внутри атомарной repository transaction.

## [0.1.4-alpha] - 2026-08-10

### Исправлено / Fixed

- Клиент теперь закрывает системный экран FiveM `Awaiting scripts` после
  валидного server-origin `spawnConfirmed`, а не оставляет его поверх уже
  загруженного игрового мира.
- Тот же idempotent flow работает при restart/recovery: повторное подтверждение
  не вызывает loading-screen natives второй раз.

### Изменено / Changed

- Resource version повышена до `0.1.4-alpha`; Core API и network protocol
  остаются совместимыми версиями `1`.

## [0.1.3-alpha] - 2026-08-09

### Исправлено / Fixed

- Restart recovery больше не зависит от единственного `forceResync`: обычный
  `clientReady` идемпотентно завершает recovered session.
- Все server-only client events защищены проверкой FiveM server origin.
- Spawn retry больше не blacklist PED при collision, position, ownership,
  session или decision ошибках.
- Spawn transaction повторно проверяет session/decision после native boundary.
- `playerConnecting` больше не удерживает Cfx deferral references в timer и
  вызывает успешный `deferrals.done()` без явного `nil`, устраняя Mono crash.
- Initial client hello больше не зависит от pre-spawn network/player/PED native;
  раннее событие повторяется до server ACK с bounded attempts/deadline.

### Добавлено / Added

- Декларативная spawn retry policy и раздельные bounded limits.
- Полный production-path набор spawn verification integration tests.
- Contract tests всех Public API v1 exports и защита identifier/session DTO.
- Module Contract, API compatibility policy и синхронизированная RU|EN документация.

### Изменено / Changed

- `shared/version.lua` является единственным source of truth; validator извлекает
  resource/API/protocol версии и сверяет manifest, README, CHANGELOG и release tag.
- Network protocol остаётся v1: существующие события сохранены, recovery change
  является additive/backward-compatible.

## [0.1.2-alpha] - 2026-08-08

### Исправлено / Fixed

- Централизовано определение server/client runtime с фактическим вызовом native.
- Унифицированы `clientReady` и `resyncReady`; protocol mismatch теперь блокирует lifecycle.
- Recovery больше не доверяет клиентскому `isPedAlive`.
- `confirmSpawn` проверяет OneSync ped, ownership, model, health и позицию на сервере.
- Retry инвалидирует старое решение и выбирает новую модель с bounded fallback.
- Violation counter получил временное окно и decay.
- Payload schemas отклоняют лишние поля, NaN и Infinity.

### Добавлено / Added

- Единые resource/API/protocol versions и release `0.1.2-alpha`.
- Реестр сетевых событий, отдельный генератор correlation IDs и тестируемый `GCAPI`.
- `GetVersionString` и `GetProtocolVersion`; `GetVersion` теперь возвращает immutable DTO.
- Категории runtime/security/API тестов, standalone Lua harness и GitHub Actions CI.
- RU/EN migration, runtime, txAdmin и security documentation.

### Изменено / Changed

- Тесты больше не исполняются production manifest и загружаются только по opt-in.
- Maintenance loops останавливаются через generation token при stop/restart.

## [0.1.1] - 2026-08-07

### Добавлено / Added

- Подключение Lua-тестов к `fxmanifest.lua` / Lua tests wired into `fxmanifest.lua`.
- Автоматический запуск тестов при включённом `developmentMode` / Automatic test run when `developmentMode` is enabled (`tests/run.lua`).
- Тест rate limit (`tests/rate_limit_test.lua`) / Rate limit test (`tests/rate_limit_test.lua`).
- Тайм-аут deferrals из конфигурации `deferralTimeoutMs` / Deferral timeout from the `deferralTimeoutMs` config.
- Общий тайм-аут клиентского спавна из конфигурации `clientSpawnTimeoutMs` / Overall client spawn timeout from the `clientSpawnTimeoutMs` config.
- Недостающие коды ошибок `GC-PAYLOAD-*` и `GC-NOTIFY-*` / Missing `GC-PAYLOAD-*` and `GC-NOTIFY-*` error codes.

### Изменено / Changed

- Локализация сообщений теперь берётся из конфигурации (`GCConfig.General.locale`) и метаданных сессии вместо жёстко заданного `'ru'` / Messages now use the configured locale (`GCConfig.General.locale`) and session metadata instead of a hardcoded `'ru'`.
- Маскированный идентификатор выводится в диагностике при включённом `printMaskedIdentifiers` / Masked identifiers are printed in diagnostics when `printMaskedIdentifiers` is enabled.

### Исправлено / Fixed

- Защита от повторного вызова `deferrals.done()` / Guard against calling `deferrals.done()` twice.
- Обновлена документация по тестированию RU|EN / RU|EN testing documentation updated.

## [0.1.0] - 2026-08-06

### Добавлено / Added

- Первая рабочая версия модульного движка GreenCore / First working version of the GreenCore modular engine.
- Единственный системный ресурс `gc_core` / Single system resource `gc_core`.
- Весь код написан на Lua 5.4 / All code written in Lua 5.4.
- Проверка подключения через deferrals / Connection validation via deferrals.
- Проверка идентификаторов игрока / Player identifier validation.
- Временные Lua-сессии в памяти / In-memory Lua sessions.
- Управление состояниями игрока / Player state management.
- Rate limit сетевых событий / Network event rate limiting.
- Серверное решение о спавне / Server-side spawn decision.
- Клиентский спавн на Lua natives / Client spawn with Lua natives.
- Подтверждение спавна / Spawn confirmation.
- Очистка данных после отключения / Data cleanup after disconnection.
- Публичный API v1 / Public API v1.
- Система уведомлений игрока / Player notification system (`NotifyPlayer`, `NotifyAll`).
- Локализация RU|EN / RU|EN localization.
- Диагностический режим / Diagnostics mode.
- Lua-тесты / Lua tests.
- Документация RU|EN / RU|EN documentation.
- Mermaid-диаграммы / Mermaid diagrams.

### Изменено / Changed

- Нет (первый релиз) / None (first release).

### Исправлено / Fixed

- Нет (первый релиз) / None (first release).

### Удалено / Removed

- Нет (первый релиз) / None (first release).
