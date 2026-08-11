# Зависимости модулей GCore

Документ фиксирует направление runtime dependencies. Стрелка направлена от
модуля к требуемому public contract.

```text
gc_example  ───────→ gc_core Public API v1
gc_identity ───────→ gc_core Public API v1
```

Или как дерево слоёв:

```text
gc_core 0.1.4-alpha (API 1)
├── gc_example 0.1.0-alpha (reference, без Public API)
└── gc_identity 0.2.1-alpha (Identity API 1, требуется oxmysql/MariaDB)
```

`gc_core` не зависит от модулей. `gc_example` и `gc_identity` также не зависят
друг от друга. Будущий domain module может требовать Identity API 1, если ему
нужен выбранный персонаж, но Core API он проверяет отдельно.

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
