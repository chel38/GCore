# Конфигурация / Configuration

## Уровень 1. Простыми словами

Конфигурация — это настройки GreenCore.
Они хранятся в Lua-файлах в папке `config/`.

## Уровень 2. Техническое объяснение

Вся конфигурация хранится в глобальной таблице `GCConfig`.
Каждый файл отвечает за свою область.

## Файлы конфигурации

| Файл | Назначение |
| ---- | ---------- |
| `general.lua` | Общие настройки |
| `connection.lua` | Настройки подключения |
| `spawn.lua` | Настройки спавна |
| `security.lua` | Настройки безопасности |
| `logging.lua` | Настройки логирования |
| `diagnostics.lua` | Настройки диагностики |

## Пример: `general.lua`

```lua
GCConfig.General = {
    locale = 'ru',
    fallbackLocale = 'en',

    debug = false,
    developmentMode = true,

    apiVersion = 1,
    protocolVersion = 1
}
```

## Пример: `spawn.lua`

```lua
GCConfig.Spawn = {
    default = {
        x = -1037.65,
        y = -2737.72,
        z = 20.17,
        heading = 329.0,
        model = `mp_m_freemode_01`
    },

    decisionLifetimeMs = 30000,
    modelLoadTimeoutMs = 10000,
    collisionLoadTimeoutMs = 10000,
    clientSpawnTimeoutMs = 20000,

    fadeOutDurationMs = 500,
    fadeInDurationMs = 1000
}
```

## Правила

- Конфигурация хранится **только** в Lua-файлах.
- Нельзя использовать JSON, YAML, XML, TOML, INI.
- Каждый параметр имеет двуязычный комментарий.
- Координаты не жёстко прописываются в основной логике.

## Изменение точки спавна

Откройте `config/spawn.lua` и измените координаты:

```lua
default = {
    x = 0.0,
    y = 0.0,
    z = 71.0,
    heading = 0.0,
    model = `mp_m_freemode_01`
}
```

## Следующий шаг

Перейдите к [Серверному API](09-server-api.md).