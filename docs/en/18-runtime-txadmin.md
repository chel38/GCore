# Runtime and txAdmin

Recommended development layout:

```text
C:\Gcore\server\       official FXServer artifact (Git-ignored)
C:\Gcore\txData\       txAdmin profiles, logs, license (Git-ignored)
C:\Gcore\resources\    tracked source code
```

Create a junction/symlink from the recipe resource directory to the tracked
`resources/[greencore]/gc_core` rather than keeping a second copy.

The server configuration must enable OneSync, keep `gc_runTests 0`, and ensure
`mapmanager`, `chat`, `sessionmanager`, `hardcap`, then `gc_core`. Do not run
`spawnmanager` or `basic-gamemode` alongside the current gc_core spawn lifecycle.
Never commit `sv_licenseKey`; txAdmin data remains under ignored `txData`.

After changing `fxmanifest.lua`, run `refresh` before `restart gc_core`. A healthy
log contains successful license authentication and
`gc_core 0.1.5-alpha started successfully`.

Restart recovery creates a `resyncing` session, requires the strict handshake, and
checks the existing ped through OneSync. Timeout disconnects the player so a stuck
recovery session cannot remain in memory.

Continue with the [release audit](19-release-audit.md).
