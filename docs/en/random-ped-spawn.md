# Random PED Spawn

## Level 1. In simple words

When a player connects, the **character model is chosen by the server**.

Imagine a box of cards:

```
[Business Man]
[Hipster]
[Beach Ped]
[Business Woman]
```

The server randomly draws one card.

After that, the client receives the **already-chosen** model.

The client **cannot** tell the server: "I want a different model".

## Why this matters

- The server is the source of truth (SERVER = SOURCE OF TRUTH).
- The client is never trusted.
- If the client chose the model, a player could spawn as any ped, including story
  characters or non-existent models.

## How it works

### 1. Model whitelist

An explicit list of allowed models is defined in `config/spawn.lua`:

```lua
GCConfig.Spawn.randomPed = {
    enabled = true,
    avoidImmediateRepeat = true,
    models = {
        'a_m_y_business_01',
        'a_m_y_business_02',
        'a_m_y_hipster_01',
        'a_m_y_beach_01',
        'a_f_y_business_01'
    }
}
```

### 2. The server chooses the model

The server picks a random model **only from this list**:

```lua
local pedDefinition = GCPedProvider.Resolve(playerSource, session)
-- pedDefinition = { name = 'a_m_y_business_01', hash = 0x... }
```

### 3. Spawn decision

The server creates a `spawnDecision` that contains the chosen ped:

```lua
local spawnDecision = {
    id = 'gc:spawn:...',
    sessionId = 'gc:session:...',
    source = playerSource,
    position = { x = ..., y = ..., z = ..., heading = ... },
    ped = {
        name = 'a_m_y_business_01',
        hash = 0x...
    },
    createdAt = os.time(),
    expiresAt = os.time() + 30,
    confirmed = false,
    consumed = false
}
```

### 4. The client receives the finished decision

The client receives the `spawnApproved` event with the already-chosen `ped`.
The client **does not** send its own model to the server.

## Repeat protection

If a player already spawned as `a_m_y_business_01`, the server will try to choose a
different model on the next full spawn (`avoidImmediateRepeat`).

## Fallback

If the random list is empty or a model fails to load, the fallback is used:

```lua
GCConfig.Spawn.fallbackPed = 'mp_m_freemode_01'
```

The server **itself** decides when to use the fallback. The client does not choose it.

## Future

Today the model selection is a random ped from a whitelist.
In the future the `gc_appearance` module can replace it with a character system.

Therefore the model selection is extracted into a separate `GCPedProvider`, and it
can be replaced without rewriting the whole spawn service.

## Related sections

- [Spawn Flow](07-spawn-flow.md)
- [Configuration](08-configuration.md)
- [Player States](06-player-states.md)