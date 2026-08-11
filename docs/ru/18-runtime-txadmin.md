# Runtime и txAdmin

Рекомендуемая dev-схема:

```text
C:\Gcore\server\       официальный FXServer artifact (игнорируется Git)
C:\Gcore\txData\       txAdmin profiles, logs, license (игнорируется Git)
C:\Gcore\resources\    отслеживаемый исходный код
```

В папке recipe создайте junction/symlink на tracked resource вместо копии:

```text
txData/<recipe>.base/resources/[greencore]/gc_core
  -> resources/[greencore]/gc_core
```

Минимальный `server.cfg`:

```cfg
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"
set onesync on
sv_maxclients 16
set gc_runTests 0

ensure mapmanager
ensure chat
ensure sessionmanager
ensure hardcap
ensure gc_core
```

Добавьте hostname/project metadata и собственный `sv_licenseKey` через txAdmin.
Не коммитьте ключ. `spawnmanager` и `basic-gamemode` намеренно не запускаются вместе
с текущим gc_core spawn lifecycle, чтобы не было конкурирующей телепортации.

Проверка запуска:

- txAdmin слушает `40120`, FXServer — `30120` TCP/UDP;
- лог содержит authentication succeeded и `gc_core 0.1.5-alpha started successfully`;
- после изменения `fxmanifest.lua` выполните `refresh`, затем `restart gc_core`;
- после тестов верните `gc_runTests 0`.

Recovery после restart создаёт session в `resyncing`, требует строгий handshake и
проверяет существующий ped через OneSync. При timeout игрок отключается, поэтому
зависшая recovery session не остаётся в памяти.

Перейдите к [аудиту релиза](19-release-audit.md).
