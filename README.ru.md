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

**0.1.4-alpha** — исправление жизненного цикла клиентской загрузки.

Core Resource Version: `0.1.4-alpha`

Core API Version: `1`

Network Protocol Version: `1`

Core API Status: **Stable for module development**

Модульная экосистема: `gc_example 0.1.0-alpha`, `gc_identity 0.2.0-alpha`.

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
ensure oxmysql
ensure gc_core
ensure gc_example
ensure gc_identity
```

6. Сохраните `server.cfg`.
7. Запустите FXServer.
8. Найдите сообщение:

```text
[GreenCore] [INFO] gc_core 0.1.4-alpha started successfully
```

## Конфигурация

Вся конфигурация хранится в Lua-файлах в `resources/[greencore]/gc_core/config/`.

## Структура

```text
resources/[greencore]/
├── gc_core/      # фундамент lifecycle
├── gc_example/   # reference Public API
└── gc_identity/  # domain аккаунта и персонажа
```

## API

Серверные exports:

| Export                   | Возвращает     | Назначение                |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | Версия API                |
| `GetProtocolVersion`     | number         | Версия протокола          |
| `GetVersion`             | table          | Версия `gc_core`          |
| `GetVersionString`       | string         | Строка `0.1.4-alpha`      |
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
- [Отчёт persistent identity](docs/ru/modules/gc_identity/implementation-report.md)
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
```

## Безопасность

- Сервер является источником истины
- Клиент никогда не доверяется
- Все payload проверяются
- Идентификаторы маскируются
- Rate limit на все события

## Лицензия

См. [LICENSE.txt](LICENSE.txt).
