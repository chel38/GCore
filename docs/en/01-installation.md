# Installation / Установка

## Requirements

- FXServer (current version)
- Windows or Linux
- OneSync
- Lua 5.4 (used by current FXServer builds; the `lua54` manifest directive is no longer required)

## Step-by-step installation

### Step 1. Open the resources folder

Find the `resources` folder of your FiveM server.

### Step 2. Create the `[greencore]` folder

```text
resources/[greencore]/
```

### Step 3. Place `gc_core`

Copy the `gc_core` folder into `resources/[greencore]/`.

```text
resources/[greencore]/gc_core/
```

### Step 4. Open `server.cfg`

Find the `server.cfg` file in the server root.

### Step 5. Add the line

```cfg
ensure gc_core
```

### Step 6. Save `server.cfg`

### Step 7. Start FXServer

### Step 8. Verify the startup

Look for the message:

```text
[GreenCore] [INFO] gc_core 0.1.5-alpha started successfully
```

## Windows instructions

1. Open the `resources` folder.
2. Create the `[greencore]` folder.
3. Copy `gc_core` inside.
4. Edit `server.cfg` in Notepad.
5. Add `ensure gc_core`.
6. Run `FXServer.exe`.

## Linux instructions

1. Open the `resources` folder.
2. Create the `[greencore]` folder.
3. Copy `gc_core` inside.
4. Edit `server.cfg`.
5. Add `ensure gc_core`.
6. Run `./run.sh`.

## Verification

After startup, a player should:

1. Connect to the server.
2. Pass validation.
3. Get a Lua session.
4. Spawn at the configured point.

## Next step

Go to [First Start](02-first-start.md).
