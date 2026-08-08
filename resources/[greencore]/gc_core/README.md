# gc_core

> **GreenCore uses Lua 5.4 for all server-side and client-side logic.**
> **GreenCore использует Lua 5.4 для всей серверной и клиентской логики.**

Единственный системный ресурс модульного движка GreenCore.
The single system resource of the GreenCore modular engine.

## Структура / Structure

```text
gc_core/
├── fxmanifest.lua
├── config/       # Lua-конфигурация / Lua configuration
├── locales/      # Lua-локализация / Lua localization
├── shared/       # Общий код / Shared code
├── server/       # Серверная логика / Server logic
├── client/       # Клиентская логика / Client logic
└── tests/        # Lua-тесты / Lua tests
```

## Установка / Installation

```cfg
ensure gc_core
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

Полная документация находится в корне проекта / Full documentation is in the project root:

```text
docs/ru/
docs/en/
docs/diagrams/