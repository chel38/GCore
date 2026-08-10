# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore runtime is 100% Lua.**
> **GreenCore runtime полностью написан на Lua.**
>
> Сервер, клиент, shared, config, locales и tests `gc_core` — всё на Lua.
> NUI модулей использует **TypeScript + Tailwind CSS** и современные технологии,
> поддерживаемые FiveM. **C# использоваться не будет.**

---

## Назначение / Purpose

GreenCore — это минимальный модульный движок для FiveM, написанный исключительно на Lua.
Он отвечает за безопасный жизненный цикл игрока:

```text
Подключение → Deferrals → Парольная сессия → playerJoining → Готовность клиента →
Сервер выбирает PED → Спавн → Подтверждение → Отключение
```

GreenCore is a minimal modular engine for FiveM written entirely in Lua.
It handles the secure player lifecycle:

```text
Connection → Deferrals → Pending session → playerJoining → Client readiness →
Server picks PED → Spawn → Confirmation → Disconnection
```

## Статус разработки / Development status

**0.1.4-alpha** — исправление client loading lifecycle / client loading lifecycle fix.

Core Resource Version: `0.1.4-alpha`

Core API Version: `1`

Network Protocol Version: `1`

Core API Status: **Stable for module development**

Module ecosystem: `gc_example 0.1.0-alpha`, `gc_identity 0.2.0-alpha`.

## Возможности версии / Version features

- Проверка подключения через deferrals (корректный lifecycle) / Connection validation via deferrals (correct lifecycle)
- Pending connection + playerJoining (миграция temporary → final source) / Pending connection + playerJoining (temporary → final source migration)
- Временные Lua-сессии в памяти / In-memory Lua sessions
- Серверная state machine с подтверждением спавна / Server state machine with spawn confirmation
- **Сервер выбирает случайный PED из белого списка** / **Server picks a random PED from a whitelist**
- Спавн подтверждается только сервером (SERVER = source of truth) / Spawn is confirmed only by the server
- Сервер проверяет OneSync ped, ownership, model и позицию / Server verifies OneSync ped, ownership, model, and position
- Строгий handshake и recovery без доверия `isPedAlive` / Strict handshake and recovery without trusting `isPedAlive`
- Rate limit сетевых событий / Network event rate limiting
- Автоматическая маскировка чувствительных данных в логах / Automatic sensitive-data masking in logs
- Recovery сессий при рестарте gc_core / Session recovery on gc_core restart
- Публичный API v1 (безопасный DTO сессии) / Public API v1 (safe session DTO)
- Локализация RU|EN / RU|EN localization
- Диагностический режим / Diagnostics mode
- Reference module, использующий только Public API v1 / Public-API-only reference module
- Persistent identity/character module с MariaDB и NUI / Persistent MariaDB-backed identity/character module with NUI

## Ограничения версии / Version limitations

Первая версия **не** включает / The first version does **not** include:

- `gc_core` не содержит аккаунты/персонажей; это отдельный `gc_identity` / `gc_core` does not contain identity; `gc_identity` owns it
- Общая ORM в `gc_core` / General ORM inside `gc_core`
- Деньги, инвентарь, транспорт / Money, inventory, vehicles
- Чат, HUD, админ-панель / Chat, HUD, admin panel
- C# (не планируется) / C# (not planned)

> **`gc_identity` NUI написан на TypeScript + Tailwind CSS.**
> **The `gc_identity` NUI is built with TypeScript + Tailwind CSS.**

## Требования / Requirements

- FXServer (актуальная версия / current version)
- Windows или Linux / Windows or Linux
- OneSync
- Lua 5.4 (runtime полностью на Lua / runtime is entirely Lua)
- Для `gc_identity`: MariaDB + `oxmysql` / For `gc_identity`: MariaDB + `oxmysql`

## Установка / Installation

1. Откройте папку ресурсов FiveM-сервера / Open your FiveM server resources folder.
2. Создайте папку `[greencore]` / Create a `[greencore]` folder.
3. Поместите нужные `gc_*` resources в эту папку / Place required `gc_*` resources there.
4. Откройте `server.cfg` / Open `server.cfg`.
5. Добавьте / Add:

```cfg
set mysql_connection_string "mysql://USER:PASSWORD@127.0.0.1:3306/gcore?charset=utf8mb4"
ensure oxmysql
ensure gc_core
ensure gc_example
ensure gc_identity
```

6. Сохраните `server.cfg` / Save `server.cfg`.
7. Запустите FXServer / Start FXServer.
8. Найдите сообщение / Look for the message:

```text
[GreenCore] [INFO] gc_core 0.1.4-alpha started successfully (recovered N players)
```

## Конфигурация / Configuration

Вся конфигурация хранится в Lua-файлах в `resources/[greencore]/gc_core/config/`.
All configuration is stored in Lua files under `resources/[greencore]/gc_core/config/`.

## Структура / Structure

```text
resources/[greencore]/
├── gc_core/      # lifecycle foundation / фундамент lifecycle
├── gc_example/   # Public API reference
└── gc_identity/  # account and character identity domain
```

## API

Серверные exports / Server exports:

| Export                   | Возвращает     | Назначение                |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | Версия API                |
| `GetProtocolVersion`     | number         | Версия протокола          |
| `GetVersion`             | table          | Версия `gc_core`          |
| `GetVersionString`       | string         | `0.1.4-alpha`             |
| `IsPlayerConnected`      | boolean        | Проверяет сессию          |
| `IsPlayerReady`          | boolean        | Проверяет готовность      |
| `IsPlayerSpawned`        | boolean        | Проверяет спавн           |
| `GetPlayerState`         | string или nil | Возвращает состояние      |
| `GetPlayerSession`       | table или nil  | Безопасный DTO сессии     |
| `GetPlayerIdentifier`    | string или nil | Возвращает идентификатор  |
| `CanUseGameplayFeatures` | boolean        | Разрешает игровые функции |
| `RequestPlayerSpawn`     | table или nil  | Запрашивает спавн         |
| `NotifyPlayer`           | boolean        | Отправляет уведомление    |
| `NotifyAll`              | boolean        | Отправляет уведомление всем |

`GetPlayerSession` возвращает **безопасный DTO**: только source, state, playerName,
timestamps, lastPed и locale. Внутренние identifiers, spawn decision и rate-limit
данные не раскрываются.

## Документация / Documentation

- [Документация RU](docs/ru/00-introduction.md)
- [Documentation EN](docs/en/00-introduction.md)
- [Random PED spawn RU](docs/ru/random-ped-spawn.md)
- [Random PED spawn EN](docs/en/random-ped-spawn.md)
- [txAdmin и runtime](docs/ru/18-runtime-txadmin.md) / [txAdmin and runtime](docs/en/18-runtime-txadmin.md)
- [Контракт модулей](docs/ru/module-contract.md) / [Module Contract](docs/en/module-contract.md)
- [Зависимости модулей](docs/ru/module-dependencies.md) / [Module dependencies](docs/en/module-dependencies.md)
- [gc_identity design RU](docs/ru/modules/gc_identity/design.md) / [EN](docs/en/modules/gc_identity/design.md)
- [Persistent identity report RU](docs/ru/modules/gc_identity/implementation-report.md) / [EN](docs/en/modules/gc_identity/implementation-report.md)
- [Отчёт модульного этапа](docs/ru/module-ecosystem-report.md) / [Module stage report](docs/en/module-ecosystem-report.md)
- [Совместимость API](docs/ru/20-api-compatibility.md) / [API compatibility](docs/en/20-api-compatibility.md)
- [Миграция 0.1.1 → 0.1.2](docs/ru/migration/0.1.1-to-0.1.2.md) / [Migration](docs/en/migration/0.1.1-to-0.1.2.md)

## Тестирование / Testing

Все тесты написаны на Lua / All tests are written in Lua.

Тесты **не загружаются и не запускаются** при обычном `ensure gc_core`.
Они запускаются только при явном включении:

```cfg
set gc_runTests 1
```

или через конфигурацию `GCConfig.Tests.enabled = true`.

Standalone module suites / Автономные тесты модулей:

```text
lua tools/module_test_harness.lua . gc_example
lua tools/module_test_harness.lua . gc_identity
```

## Безопасность / Security

- Сервер является источником истины / Server is the source of truth
- Сервер выбирает модель PED и координаты / Server chooses the PED model and coordinates
- Клиент не может выбрать свою модель / The client cannot choose its own model
- Клиент не устанавливает `spawned=true` самостоятельно / The client does not set `spawned=true` itself
- Все payload проверяются / All payloads are validated
- Идентификаторы маскируются автоматически / Identifiers are masked automatically
- Rate limit на все события / Rate limit on all events

## Лицензия / License

См. [LICENSE.txt](LICENSE.txt) / See [LICENSE.txt](LICENSE.txt).
