# First Start / Первый запуск

## What happens on startup

When `gc_core` starts, the following steps run:

1. Shared files load (configuration, localization, utilities).
2. The server side loads.
3. The client side loads.
4. Event handlers register.
5. Exports register.
6. The startup message prints.

## Expected messages

```text
[GreenCore] [INFO] gc_core server bootstrap loaded | version=0.1.3-alpha
[GreenCore] [INFO] gc_core 0.1.3-alpha started successfully
```

## What happens when a player connects

```text
Player connects
    ↓
gc_core starts deferrals
    ↓
Server validates the name
    ↓
Server collects identifiers
    ↓
Server validates the license
    ↓
Server creates a session
    ↓
Server accepts the connection
    ↓
Client reports readiness
    ↓
Server creates a spawn decision
    ↓
Client performs the spawn
    ↓
Server confirms
```

## Verification

### 1. Player connected

The server console should show a connection message.

### 2. Player spawned

The player should spawn at the point from `config/spawn.lua`.

### 3. API check

In the server console run:

```lua
print(exports.gc_core:GetVersionString())
```

It should print:

```text
0.1.3-alpha
```

## Possible issues

| Issue | Solution |
| ----- | -------- |
| Resource does not start | Check `fxmanifest.lua` |
| No startup message | Check that `ensure gc_core` is in `server.cfg` |
| Player does not spawn | Check `config/spawn.lua` |

## Next step

Go to [Project Structure](03-project-structure.md).
