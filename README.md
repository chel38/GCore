# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore uses Lua 5.4 for all server-side and client-side logic.**
> **GreenCore использует Lua 5.4 для всей серверной и клиентской логики.**

**Логика — только Lua. NUI — TypeScript + Tailwind. / Lua for logic. TypeScript + Tailwind for NUI.**

---

## Назначение / Purpose

GreenCore — это минимальный модульный движок для FiveM, написанный исключительно на Lua 5.4.
Он отвечает за безопасный жизненный цикл игрока:

```text
Подключение → Проверку → Сессию → Готовность клиента → Спавн → Подтверждение → Отключение
```

GreenCore is a minimal modular engine for FiveM written entirely in Lua 5.4.
It handles the secure player lifecycle:

```text
Connection → Validation → Session → Client readiness → Spawn → Confirmation → Disconnection
```

## Статус разработки / Development status

**0.1.0** — первая рабочая версия / first working version.

## Возможности версии / Version features

- Проверка подключения через deferrals / Connection validation via deferrals
- Проверка идентификаторов / Identifier validation
- Временные Lua-сессии в памяти / In-memory Lua sessions
- Управление состояниями игрока / Player state management
- Rate limit сетевых событий / Network event rate limiting
- Серверное решение о спавне / Server-side spawn decision
- Клиентский спавн на Lua natives / Client spawn with Lua natives
- Публичный API v1 / Public API v1
- Локализация RU|EN / RU|EN localization
- Диагностический режим / Diagnostics mode

## Ограничения версии / Version limitations

Первая версия **не** включает / The first version does **not** include:

- Регистрацию, аккаунты, персонажей / Registration, accounts, characters
- Базу данных / Database
- Деньги, инвентарь, транспорт / Money, inventory, vehicles
- Чат, HUD, админ-панель / Chat, HUD, admin panel

## Требования / Requirements

- FXServer (актуальная версия / current version)
- Windows или Linux / Windows or Linux
- OneSync
- Lua 5.4 (включён через `lua54 'yes'`)

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
[GreenCore] [INFO] gc_core 0.1.0 started successfully
```

## Конфигурация / Configuration

Вся конфигурация хранится в Lua-файлах в `resources/[greencore]/gc_core/config/`.
All configuration is stored in Lua files under `resources/[greencore]/gc_core/config/`.

## Структура / Structure

```text
resources/[greencore]/gc_core/
├── fxmanifest.lua
├── config/       # Lua-конфигурация / Lua configuration
├── locales/      # Lua-локализация / Lua localization
├── shared/       # Общий код / Shared code
├── server/       # Серверная логика / Server logic
├── client/       # Клиентская логика / Client logic
└── tests/        # Lua-тесты / Lua tests
```

## API

Серверные exports / Server exports:

| Export                   | Возвращает     | Назначение                |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | Версия API                |
| `GetVersion`             | table          | Версия `gc_core`          |
| `IsPlayerConnected`      | boolean        | Проверяет сессию          |
| `IsPlayerReady`          | boolean        | Проверяет готовность      |
| `IsPlayerSpawned`        | boolean        | Проверяет спавн           |
| `GetPlayerState`         | string или nil | Возвращает состояние      |
| `GetPlayerSession`       | table или nil  | Возвращает копию сессии   |
| `GetPlayerIdentifier`    | string или nil | Возвращает идентификатор  |
| `CanUseGameplayFeatures` | boolean        | Разрешает игровые функции |
| `RequestPlayerSpawn`     | table или nil  | Запрашивает спавн         |
| `NotifyPlayer`           | boolean        | Отправляет уведомление    |
| `NotifyAll`              | boolean        | Отправляет уведомление всем |

## Документация / Documentation

- [Документация RU](docs/ru/00-introduction.md)
- [Documentation EN](docs/en/00-introduction.md)
- [Диаграммы / Diagrams](docs/diagrams/architecture.md)

## Тестирование / Testing

Все тесты написаны на Lua / All tests are written in Lua:

```text
resources/[greencore]/gc_core/tests/
```

## Безопасность / Security

- Сервер является источником истины / Server is the source of truth
- Клиент никогда не доверяется / Client is never trusted
- Все payload проверяются / All payloads are validated
- Идентификаторы маскируются / Identifiers are masked
- Rate limit на все события / Rate limit on all events

## Лицензия / License

См. [LICENSE.txt](LICENSE.txt) / See [LICENSE.txt](LICENSE.txt).