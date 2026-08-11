# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore runtime полностью написан на Lua.**
> **GreenCore runtime is 100% Lua.**
>
> Сервер, клиент, shared, config, locales и tests `gc_core` — всё на Lua.
> NUI модулей использует **TypeScript + Tailwind CSS** и другие современные
> технологии FiveM. **C# использоваться не будет.**

---

## Назначение

GreenCore — это минимальный модульный движок для FiveM, написанный исключительно на Lua 5.4.
Он отвечает за безопасный жизненный цикл игрока:

```text
Подключение → Проверку → Сессию → Готовность клиента → Спавн → Подтверждение → Отключение
```

## Статус разработки

**0.1.5-alpha** — безопасная pre-spawn авторизация и ручной spawn gate.

Core Resource Version: `0.1.5-alpha`

Core API Version: `1`

Network Protocol Version: `2`

Core API Status: **Stable for module development**

Модульная экосистема: Module Standard v1, `gc_example 0.1.0-alpha`,
`gc_identity 0.4.1-alpha`, optional `gc_sdk 0.1.0-alpha`, optional
`gc_ecosystem 0.1.0-alpha` и локальный `mail-service 0.1.0-alpha`.

## Возможности версии

- Проверка подключения через deferrals
- Проверка идентификаторов
- Временные Lua-сессии в памяти
- Управление состояниями игрока
- Rate limit сетевых событий
- Серверное решение о спавне
- Серверная проверка OneSync ped, ownership, model и позиции
- Recovery без доверия клиентскому `isPedAlive`
- Клиентский спавн на Lua natives
- Публичный API v1
- Локализация RU|EN
- Диагностический режим
- Reference module только на Public API
- Persistent identity/character module с MariaDB и NUI

## Ограничения версии

Первая версия **не** включает:

- Identity внутри `gc_core` (за неё отвечает отдельный `gc_identity`)
- Общая database/ORM внутри `gc_core`
- Деньги, инвентарь, транспорт
- Чат, HUD, админ-панель
- C# (не планируется) / C# (not planned)

> **NUI модуля `gc_identity` написан на TypeScript + Tailwind CSS.**
> **The `gc_identity` NUI is built with TypeScript + Tailwind CSS.**

## Требования

- FXServer (актуальная версия)
- Windows или Linux
- OneSync
- Lua 5.4 (runtime полностью на Lua / runtime is entirely Lua)
- MariaDB и `oxmysql`, если включён `gc_identity`

## Установка

1. Откройте папку ресурсов FiveM-сервера.
2. Создайте папку `[greencore]`.
3. Поместите нужные `gc_*` resources в эту папку.
4. Откройте `server.cfg`.
5. Добавьте:

```cfg
set mysql_connection_string "mysql://USER:PASSWORD@127.0.0.1:3306/gcore?charset=utf8mb4"
set gcore_spawn_mode manual
ensure oxmysql
ensure gc_core
ensure gc_sdk
ensure gc_ecosystem
ensure gc_example
ensure gc_identity
```

6. Сохраните `server.cfg`.
7. Запустите FXServer.
8. Найдите сообщение:

```text
[GreenCore] [INFO] gc_core 0.1.5-alpha started successfully
```

## Конфигурация

Вся конфигурация хранится в Lua-файлах в `resources/[greencore]/gc_core/config/`.

## Структура

```text
resources/[greencore]/
├── gc_core/       # фундамент lifecycle
├── gc_sdk/        # optional compatibility helpers
├── gc_ecosystem/  # optional local registry/diagnostics
├── gc_example/    # direct reference Public API
└── gc_identity/   # domain аккаунта и персонажа
```

`gc_core` не зависит от SDK или ecosystem. Module может использовать Core API напрямую.

## GCore Ecosystem

- [Введение](docs/ru/ecosystem/00-introduction.md)
- [Module Standard v1](docs/ru/ecosystem/module-standard.md)
- [Создание модуля](docs/ru/ecosystem/creating-module.md)
- [Metadata](docs/ru/ecosystem/metadata.md) и [dependencies](docs/ru/ecosystem/dependencies.md)
- [Registry](docs/ru/ecosystem/registry.md) и [optional SDK](docs/ru/ecosystem/sdk.md)
- [Testing](docs/ru/ecosystem/testing.md), [packaging](docs/ru/ecosystem/packaging.md), [third-party modules](docs/ru/ecosystem/third-party-modules.md)
- [Отчёт о реализации Ecosystem v0.1](docs/ru/ecosystem/ecosystem-v0.1-report.md)

## API

Серверные exports:

| Export                   | Возвращает     | Назначение                |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | Версия API                |
| `GetProtocolVersion`     | number         | Версия протокола          |
| `GetSpawnMode`           | string         | `automatic` или `manual`  |
| `GetVersion`             | table          | Версия `gc_core`          |
| `GetVersionString`       | string         | Строка `0.1.5-alpha`      |
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

## Документация

- [Документация RU](docs/ru/00-introduction.md)
- [Documentation EN](docs/en/00-introduction.md)
- [Диаграммы](docs/diagrams/architecture.md)
- [Runtime и txAdmin](docs/ru/18-runtime-txadmin.md)
- [Миграция 0.1.1 → 0.1.2](docs/ru/migration/0.1.1-to-0.1.2.md)
- [Контракт модулей v1](docs/ru/module-contract.md)
- [Граф зависимостей модулей](docs/ru/module-dependencies.md)
- [Проектирование gc_identity](docs/ru/modules/gc_identity/design.md)
- [Pre-spawn регистрация и безопасная авторизация](docs/ru/modules/gc_identity/pre-spawn-registration.md)
- [Аудит NUI lifecycle gc_identity](docs/ru/modules/gc_identity/nui-lifecycle-audit.md)
- [Отчёт persistent identity](docs/ru/modules/gc_identity/implementation-report.md)
- [Email verification](docs/ru/modules/gc_identity/email-verification.md)
- [Mail Service](mail-service/README.ru.md)
- [Отчёт первого модульного этапа](docs/ru/module-ecosystem-report.md)
- [Политика совместимости API](docs/ru/20-api-compatibility.md)

## Тестирование

Все тесты написаны на Lua и загружаются только при явном `gc_runTests 1`:

```text
resources/[greencore]/gc_core/tests/
```

Автономные тесты модулей:

```text
lua tools/module_test_harness.lua . gc_example
lua tools/module_test_harness.lua . gc_identity
lua tools/run-module-suite.lua .
lua tools/tests/run.lua .
lua tools/module_conformance.lua path/to/module
lua tools/package-module.lua path/to/module
```

## Безопасность

- Сервер является источником истины
- Клиент никогда не доверяется
- Все payload проверяются
- Идентификаторы маскируются
- Rate limit на все события

## Лицензия

См. [LICENSE.txt](LICENSE.txt).
