# Configuration / Конфигурация

## Level 1. In simple words

Configuration is the GreenCore settings.
They are stored in Lua files in the `config/` folder.

## Level 2. Technical explanation

All configuration is stored in the global `GCConfig` table.
Each file is responsible for its own area.

## Configuration files

| File | Purpose |
| ---- | ------- |
| `general.lua` | General settings |
| `connection.lua` | Connection settings |
| `spawn.lua` | Spawn settings |
| `security.lua` | Security settings |
| `logging.lua` | Logging settings |
| `diagnostics.lua` | Diagnostics settings |

## Example: `general.lua`

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

## Example: `spawn.lua`

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

## Rules

- Configuration is stored **only** in Lua files.
- JSON, YAML, XML, TOML, INI are not allowed.
- Each parameter has a bilingual comment.
- Coordinates are not hardcoded in the main logic.

## Changing the spawn point

Open `config/spawn.lua` and change the coordinates:

```lua
default = {
    x = 0.0,
    y = 0.0,
    z = 71.0,
    heading = 0.0,
    model = `mp_m_freemode_01`
}
```

## Next step

Go to [Server API](09-server-api.md).