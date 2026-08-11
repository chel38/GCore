# Baseline GCore Ecosystem v0.1

Проверенный источник: `main`, SHA `bcae298a403b24574704b8369323ded56829f1bb`.

## Версии до ecosystem milestone

| Ресурс | Версия ресурса | Public API | Протокол |
| --- | --- | ---: | ---: |
| `gc_core` | `0.1.5-alpha` | 1 | 2 |
| `gc_example` | `0.1.0-alpha` | нет | нет |
| `gc_identity` | `0.4.1-alpha` | 1 | 3 |

## Уже существующий фундамент

- `gc_core` владеет connection, session, readiness, recovery, loading и spawn.
- `gc_example` использует только документированные exports Core API v1.
- `gc_identity` владеет регистрацией, авторизацией, persistence, персонажами и NUI.
- Module Contract и API compatibility policy уже запрещают доступ к internals ядра.
- Repository validator проверяет версии core, Lua syntax, module docs/tests, известные
  core exports, private core references, identity NUI, mail-service и Markdown links.
- Module harness запускал модуль по имени из `resources/[greencore]`, а CI находил
  модули по префиксу `gc_*`, а не по machine-readable metadata.

## Проверка baseline

| Проверка | Результат |
| --- | --- |
| Repository validator | PASS |
| Lua harness `gc_core` | 511/511 PASS |
| Module suite `gc_example` | 31/31 PASS |
| Module suite `gc_identity` | 373/373 PASS |
| Install/test/build NUI `gc_identity` | PASS |
| Install/typecheck/test/build локального mail-service | PASS |

## Подтверждённые пробелы

1. Не было формальных machine-readable metadata Module Standard.
2. Discovery зависел от официального префикса и фиксированной папки repository.
3. Не было standalone conformance checker для third-party module и dependency graph.
4. Не было runtime registry, compatibility diagnostics, local catalog, generator,
   template и packager.
5. CI явно знал про identity NUI вместо автоматического discovery NUI-модулей.
6. Проверка доступности Core API повторялась в `gc_example` и `gc_identity`.

## Решение по SDK

| Pattern | Core | Example | Identity | Generic | SDK v0 |
| --- | ---: | ---: | ---: | --- | --- |
| Проверка resource/Core API | да | да | да | да | YES |
| Detached DTO copy | да | только consumer | да | зависит от boundary | NO |
| Server-origin client guard | да | нет client | да | похож, но принадлежит boundary | NO |
| Rate limiting | да | нет | да | разные policy | NO |
| Identity/character/email validation | нет | нет | да | domain-specific | NO |

Поэтому SDK v0 содержит только optional server-side helpers совместимости ресурсов/API.
Ни один существующий модуль не обязан переходить на SDK.
