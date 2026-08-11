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

## Black screen or identity NUI does not appear

**Expected lifecycle**: an eagerly loaded identity page is empty until its
JavaScript-ready callback and an authoritative snapshot. A returning `ready`
player never opens the UI. Registration states open it and acquire focus.

1. Find `[GC][IDENTITY][CLIENT]` in the FiveM client log.
2. `GC-IDENTITY-NUI-NOT-READY`: run `pnpm build`, confirm the manifest paths and
   restart `gc_identity`. The server disconnect is intentional fail-closed
   recovery; focus/freeze are released first.
3. `GC-IDENTITY-HELLO-TIMEOUT`: inspect `gc_core` readiness and server identity
   logs. Do not add an arbitrary sleep.
4. `GC-IDENTITY-DATABASE-UNAVAILABLE`: verify MariaDB, `oxmysql`, the connection
   string outside Git, and resource order.
5. Confirm `web/dist/index.html` references `./assets/...` and every referenced
   file is packaged by `fxmanifest.lua`.
6. Confirm the inactive document does not force `color-scheme: dark` and that
   `#app` remains explicitly hidden until a real view is rendered. An empty NUI
   document must have a transparent canvas in FiveM CEF.

See the [identity NUI lifecycle audit](modules/gc_identity/nui-lifecycle-audit.md).

## Next step

Go to [Testing](15-testing.md).
