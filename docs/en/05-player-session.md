# Player Session / Сессия игрока

## Level 1. In simple words

A session is a temporary card for a player inside the server.

Player entered — the card appeared.
Player left — the card was removed.

## Level 2. Technical explanation

A session is stored in a Lua table in the server memory.
It links the current FiveM `source` with the player identifiers and state.

## Session structure

```lua
local session = {
    sessionId = 'gc:session:generated-id',
    source = 1,
    playerName = 'Player Name',

    identifiers = {
        license = 'license:...',
        license2 = nil,
        fivem = 'fivem:...',
        discord = nil
    },

    primaryIdentifierType = 'license',
    primaryIdentifier = 'license:...',

    state = 'connecting',
    previousState = nil,
    stateReason = 'player_connecting',

    connectedAt = 0,
    validatedAt = nil,
    clientReadyAt = nil,
    spawnedAt = nil,
    disconnectedAt = nil,

    spawnDecision = nil,

    metadata = {
        locale = 'ru',
        clientVersion = nil,
        protocolVersion = nil
    }
}
```

## Session ID

The Session ID:

- is unique;
- is created by the server;
- does not depend only on `source`;
- does not contain a license;
- does not contain an IP;
- does not contain a Discord ID;
- is not sent by the client;
- does not repeat after reconnection.

Example:

```text
gc:session:550e8400-e29b-41d4-a716-446655440000
```

## Session service methods

| Method | Purpose |
| ------ | ------- |
| `GCSessions.Create` | Creates a session |
| `GCSessions.Get` | Returns a session by source |
| `GCSessions.GetByIdentifier` | Returns a session by identifier |
| `GCSessions.Exists` | Checks session existence |
| `GCSessions.Clone` | Returns a safe copy |
| `GCSessions.Remove` | Removes a session |
| `GCSessions.Count` | Returns the session count |
| `GCSessions.Clear` | Clears all sessions |

## Level 3. Lua code example

```lua
local session = exports.gc_core:GetPlayerSession(source)

if not session then
    print('Player session was not found')
    return
end

print(session.state)
```

## Level 4. Security

A third-party module **cannot** modify the real session:

```lua
local session = exports.gc_core:GetPlayerSession(source)
session.state = 'spawned'  -- This does not change the real session
```

`Clone` returns a deep copy. Modifying the copy does not affect the original.

## Next step

Go to [Player States](06-player-states.md).