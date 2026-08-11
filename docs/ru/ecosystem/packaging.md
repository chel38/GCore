# Packaging модуля

```text
lua tools/package-module.lua path/to/module
```

Portable Lua packager выполняет conformance, запускает module tests, проверяет
production `dist` NUI, копирует разрешённые файлы в isolated release folder, создаёт
`.tar`, считает SHA-256 и пишет `release-manifest.json`. `--output=path` задаёт другой
release root. Существующая destination никогда не перезаписывается.

Artifact исключает `.env`, secret environment variants, `node_modules`, `.git`,
coverage, test-results, IDE metadata, logs, temporary files, вложенный build output
и корневой каталог runtime-состояния `data/`. Статические распространяемые данные
нужно размещать в явно подключённом manifest каталоге модуля, а не в `data/`.
NUI artifact содержит `web/dist`, но не dependency directories.

SHA-256 обнаруживает изменение байтов после packaging. Это не digital signature и
не доказательство author identity, code safety или trust. Release manifest относится
к distribution и не является runtime source of truth.
