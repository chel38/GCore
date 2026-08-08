# Development Guide / Руководство разработчика

## Level 1. In simple words

This guide is for those who want to create Lua modules for GreenCore.

## Level 2. Technical explanation

GreenCore is a modular engine.
Future modules are separate FiveM resources.

## Modularity rules

1. Each module is a separate FiveM resource.
2. Each module's game logic is written only in Lua; the NUI part uses TypeScript + Tailwind CSS.
3. Modules do not read each other's internal files.
4. Modules do not modify each other's internal tables.
5. Modules do not use shared global variables.
6. Interaction through exports, events, callbacks.
7. `gc_core` internal logic is not directly accessible.
8. The public API is separated from the internal implementation.
9. The API has a version.
10. Every public method is documented.
11. All data from other resources is validated.
12. Restarting a module does not break `gc_core`.
13. Event names have a unique namespace.
14. Direct dependencies between modules are forbidden.
15. `gc_core` does not become a warehouse for all gameplay systems.

## Lua code style

### Mandatory rules

- Clear names.
- Small functions.
- One function — one task.
- Early return on error.
- Minimal nesting.
- No duplication.
- No magic numbers.
- Local variables by default.
- No `load` and `loadstring`.

### Bad

```lua
RegisterNetEvent('a', function(d)
    if d then
        if type(d) == 'table' then
            if d.x then
                -- logic
            end
        end
    end
end)
```

### Good

```lua
RegisterNetEvent('gc_core:server:clientReady', function(payload)
    local playerSource = source

    local isValid, errorCode = GCValidation.ClientReady(payload)
    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    GCConnection.HandleClientReady(playerSource, payload)
end)
```

## Performance

Do not create endless loops with `Wait(0)` without a real need.

### Bad

```lua
while true do
    Wait(0)
end
```

### Good

```lua
local startedAt = GetGameTimer()

while not HasModelLoaded(modelHash) do
    if GetGameTimer() - startedAt >= timeoutMs then
        return false, 'GC-SPAWN-MODEL-001'
    end

    Wait(100)
end
```

## Comments

Comments are mandatory in Russian and English.

```lua
-- RU: Проверяем наличие активной серверной сессии игрока.
-- EN: Check whether the player has an active server-side session.
```

## Next step

Go to [Glossary](17-glossary.md).