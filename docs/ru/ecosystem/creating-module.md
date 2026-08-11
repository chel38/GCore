# Создание модуля

FiveM resource — загружаемая папка с `fxmanifest.lua`. GCore module — resource с
metadata Module Standard, который использует публичные контракты GCore. API version
является compatibility promise, а capability — только catalog label.

## Создайте skeleton

```text
lua tools/create-module.lua gc_weather_example --type=domain
```

По умолчанию создаётся server-only skeleton без weather или другого dummy gameplay.
Флаги:

- `--client` добавляет client runtime.
- `--nui` добавляет client runtime и TypeScript/Tailwind/Vite NUI skeleton.
- `--api=1` объявляет Public API модуля.
- `--sdk` явно подключает `gc_sdk`; default остаётся direct Core API.
- `--third-party` разрешает имя без `gc_*`.
- `--output=path` задаёт родительскую папку.
- `--dry-run --json` показывает machine-readable план без записи.

Generator отклоняет path traversal, invalid type, reserved official prefix и уже
существующую destination. Он никогда не перезаписывает модуль.

## Реализуйте domain

1. Проверяйте Core API `>= 1`, а не точную resource patch-версию.
2. Храните state на сервере и валидируйте client/NUI payload.
3. Добавляйте только необходимые client/NUI/Public exports.
4. Возвращайте detached DTO и документируйте nil/error behavior.
5. После DB/HTTP yield повторно проверяйте session/state.
6. Безопасно обрабатывайте stop/restart resource, core и dependency.

Не импортируйте internals ядра и не экспортируйте каждую local function. Между
server modules используйте exports/local events; network event нужен только для
реальной client boundary.

## Проверка и package

```text
lua tools/module_conformance.lua resources/[greencore]/gc_weather_example
lua tools/module_test_harness.lua . resources/[greencore]/gc_weather_example
lua tools/package-module.lua resources/[greencore]/gc_weather_example
```

Generated resource остаётся обычным читаемым FiveM Lua. Tooling не скрывает
архитектуру и не выполняет remote code.
