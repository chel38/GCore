# gc_core

> **GreenCore runtime is 100% Lua.**
> **GreenCore runtime полностью написан на Lua.**
>
> Сервер, клиент, shared, config, locales и tests `gc_core` — всё на Lua.
> Дальнейшая разработка и добавление **NUI** будут использовать **TypeScript + Tailwind CSS**
> и другие современные технологии, поддерживаемые FiveM. **C# использоваться не будет.**

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
| `GetProtocolVersion`     | number         | Версия протокола          |
| `GetVersion`             | table          | Версия `gc_core`          |
| `GetVersionString`       | string         | Строка версии             |
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

## Документация / Documentation

Полная документация находится в корне проекта / Full documentation is in the project root:

```text
docs/ru/
docs/en/
docs/diagrams/
```
