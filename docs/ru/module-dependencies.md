# Зависимости модулей GCore

Документ фиксирует направление runtime dependencies. Стрелка направлена от
модуля к требуемому public contract.

```text
gc_example  ───────→ gc_core Public API v1
gc_identity ───────→ gc_core Public API v1
gc_sdk ────────────→ gc_core Public API v1 (optional convenience)
gc_ecosystem ──────→ gc_core Public API v1 (optional diagnostics)
```

Или как дерево слоёв:

```text
gc_core 0.1.5-alpha (API 1, protocol 2)
├── gc_example 0.1.0-alpha (reference, без Public API)
├── gc_identity 0.4.1-alpha (Identity API 1, protocol 3, manual core spawn mode, oxmysql/MariaDB + localhost mail-service)
├── gc_sdk 0.1.0-alpha (optional SDK API 1)
└── gc_ecosystem 0.1.0-alpha (optional Ecosystem API 1)
```

`gc_core` не зависит от модулей. `gc_example` намеренно использует Core API
напрямую. `gc_identity` не требует SDK или registry. Остановка `gc_sdk` либо
`gc_ecosystem` не влияет на core/identity gameplay lifecycle.

`gc_identity` дополнительно зависит от внешнего resource `oxmysql`. Эта связь
принадлежит identity persistence domain и не переносится в `gc_core`.

Запрещённые связи:

```text
gc_core → gc_identity
gc_identity → gc_core internal files/tables
gc_example → gc_identity
```

Repository validator для каждого `gc_*` resource проверяет manifest, dependency
на `gc_core`, неизвестные core exports и private symbols/paths. Документ нужно
обновлять при добавлении или удалении public module dependency.
