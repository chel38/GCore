# Структура проекта / Project Structure

## Дерево файлов

```text
resources/[greencore]/gc_core/
├── fxmanifest.lua
├── README.md
│
├── config/
│   ├── general.lua
│   ├── connection.lua
│   ├── spawn.lua
│   ├── security.lua
│   ├── logging.lua
│   └── diagnostics.lua
│
├── locales/
│   ├── ru.lua
│   ├── en.lua
│   └── custom.example.lua
│
├── shared/
│   ├── bootstrap.lua
│   ├── version.lua
│   ├── constants.lua
│   ├── errors.lua
│   ├── validation.lua
│   ├── locale.lua
│   ├── logger.lua
│   └── utils.lua
│
├── server/
│   ├── bootstrap.lua
│   ├── main.lua
│   ├── connection.lua
│   ├── identifiers.lua
│   ├── sessions.lua
│   ├── players.lua
│   ├── states.lua
│   ├── spawn.lua
│   ├── rate_limit.lua
│   ├── security.lua
│   ├── notifications.lua
│   ├── events.lua
│   ├── exports.lua
│   └── diagnostics.lua
│
├── client/
│   ├── bootstrap.lua
│   ├── main.lua
│   ├── readiness.lua
│   ├── state.lua
│   ├── spawn.lua
│   ├── events.lua
│   └── diagnostics.lua
│
└── tests/
    ├── test_runner.lua
    ├── validation_test.lua
    ├── states_test.lua
    ├── sessions_test.lua
    ├── connection_test.lua
    ├── spawn_test.lua
    ├── rate_limit_test.lua
    ├── notifications_test.lua
    └── run.lua
```

## Назначение каталогов

| Каталог | Назначение |
| ------- | ---------- |
| `config/` | Lua-конфигурация |
| `locales/` | Lua-локализация |
| `shared/` | Общий код для сервера и клиента |
| `server/` | Серверная логика |
| `client/` | Клиентская логика |
| `tests/` | Lua-тесты |

## Порядок загрузки

### Shared (общий)

```text
config/* → locales/* → shared/bootstrap → shared/version → shared/constants
→ shared/errors → shared/utils → shared/locale → shared/logger → shared/validation
```

### Server (сервер)

```text
server/bootstrap → server/identifiers → server/sessions → server/states
→ server/rate_limit → server/security → server/connection → server/spawn
→ server/players → server/notifications → server/events → server/exports
→ server/diagnostics → server/main
```

### Client (клиент)

```text
client/bootstrap → client/state → client/readiness → client/spawn
→ client/events → client/diagnostics → client/main
```

## Следующий шаг

Перейдите к [Потоку подключения](04-connection-flow.md).