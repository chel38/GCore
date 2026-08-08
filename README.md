# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore runtime is 100% Lua.**
> **GreenCore runtime полностью написан на Lua.**
>
> Сервер, клиент, shared, config, locales и tests `gc_core` — всё на Lua.
> Дальнейшая разработка и добавление **NUI** будут использовать **TypeScript + Tailwind CSS**
> и другие современные технологии, поддерживаемые FiveM. **C# использоваться не будет.**

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

**0.1.2-alpha** — стабилизированный early-alpha runtime / stabilized early-alpha runtime.

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

## Ограничения версии / Version limitations

Первая версия **не** включает / The first version does **not** include:

- Регистрацию, аккаунты, персонажей / Registration, accounts, characters
- Базу данных / Database
- Деньги, инвентарь, транспорт / Money, inventory, vehicles
- Чат, HUD, админ-панель / Chat, HUD, admin panel
- NUI в текущей версии (будет добавлен позже) / NUI in the current version (will be added later)
- C# (не планируется) / C# (not planned)

> **NUI, когда будет добавлен, будет написан на TypeScript + Tailwind CSS**
> **и других современных технологиях FiveM. C# не будет использоваться.**
> **When NUI is added, it will be written with TypeScript + Tailwind CSS**
> **and other modern FiveM technologies. C# will not be used.**

## Требования / Requirements

- FXServer (актуальная версия / current version)
- Windows или Linux / Windows or Linux
- OneSync
- Lua 5.4 (runtime полностью на Lua / runtime is entirely Lua)

## Установка / Installation

1. Откройте папку ресурсов FiveM-сервера / Open your FiveM server resources folder.
2. Создайте папку `[greencore]` / Create a `[greencore]` folder.
3. Поместите `gc_core` в эту папку / Place `gc_core` into this folder.
4. Откройте `server.cfg` / Open `server.cfg`.
5. Добавьте / Add:

```cfg
ensure gc_core
```

6. Сохраните `server.cfg` / Save `server.cfg`.
7. Запустите FXServer / Start FXServer.
8. Найдите сообщение / Look for the message:

```text
[GreenCore] [INFO] gc_core 0.1.2-alpha started successfully (recovered N players)
```

## Конфигурация / Configuration

Вся конфигурация хранится в Lua-файлах в `resources/[greencore]/gc_core/config/`.
All configuration is stored in Lua files under `resources/[greencore]/gc_core/config/`.

## Структура / Structure

```text
resources/[greencore]/gc_core/
├── fxmanifest.lua
├── config/          # Lua-конфигурация / Lua configuration
├── locales/         # Lua-локализация / Lua localization
├── shared/          # Общий код / Shared code
├── server/          # Серверная логика / Server logic
│   ├── connection.lua      # Deferrals, pending, playerJoining
│   ├── sessions.lua        # Сессии, миграция source, DTO
│   ├── states.lua          # State machine
│   ├── spawn.lua           # Spawn decision, подтверждение
│   ├── ped_provider.lua    # Выбор модели PED (случайный)
│   ├── spawn_location.lua  # Точка спавна
│   ├── players.lua         # Отключение и recovery
│   └── ...
├── client/          # Клиентская логика / Client logic
└── tests/           # Lua-тесты (запуск по явному включению) / Lua tests
```

## API

Серверные exports / Server exports:

| Export                   | Возвращает     | Назначение                |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | Версия API                |
| `GetProtocolVersion`     | number         | Версия протокола          |
| `GetVersion`             | table          | Версия `gc_core`          |
| `GetVersionString`       | string         | `0.1.2-alpha`             |
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
- [Миграция 0.1.1 → 0.1.2](docs/ru/migration/0.1.1-to-0.1.2.md) / [Migration](docs/en/migration/0.1.1-to-0.1.2.md)

## Тестирование / Testing

Все тесты написаны на Lua / All tests are written in Lua.

Тесты **не загружаются и не запускаются** при обычном `ensure gc_core`.
Они запускаются только при явном включении:

```cfg
set gc_runTests 1
```

или через конфигурацию `GCConfig.Tests.enabled = true`.

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
