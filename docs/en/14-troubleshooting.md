# Troubleshooting / Устранение неполадок

## Level 1. In simple words

If something does not work, check this list.

## Level 2. Technical explanation

Below are common issues and their solutions.

## Resource does not start

**Symptom**: no startup message.

**Solution**:
1. Check that `ensure gc_core` is in `server.cfg`.
2. Check that `gc_core` is in `resources/[greencore]/`.
3. Check `fxmanifest.lua` for syntax errors.

## Player does not spawn

**Symptom**: the player connects but does not spawn.

**Solution**:
1. Check `config/spawn.lua` — coordinates and model.
2. Check that the model exists in the game.
3. Check the logs for spawn errors.

## Player is rejected

**Symptom**: the player receives a rejection message.

**Solution**:
1. Check that the player has a `license`.
2. Check that there is no duplicate connection.
3. Check `config/connection.lua`.

## Duplicate spawn

**Symptom**: the player spawns multiple times.

**Solution**:
1. Check that `clientReady` is sent once.
2. Check the rate limit.
3. Check that the spawn decision is used once.

## Fake Decision ID

**Symptom**: the server rejects the confirmation.

**Solution**:
1. This is expected behavior.
2. Check that the client uses the server decision.

## Expired decision

**Symptom**: the server does not accept the confirmation.

**Solution**:
1. This is expected behavior.
2. Increase `decisionLifetimeMs` in `config/spawn.lua`.

## Model load error

**Symptom**: the client reports a model error.

**Solution**:
1. Check that the model exists.
2. Increase `modelLoadTimeoutMs` in `config/spawn.lua`.

## Disconnection during spawn

**Symptom**: data is not cleaned up.

**Solution**:
1. Check the `playerDropped` handler.
2. Check that the session is removed.

## Resource restart

**Symptom**: players are not synchronized.

**Solution**:
1. Check the `onResourceStart` handler.
2. Check that the client receives `forceResync`.

## Next step

Go to [Testing](15-testing.md).