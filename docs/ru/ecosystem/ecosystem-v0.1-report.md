# Отчёт о реализации GCore Ecosystem v0.1

## 1. Audited SHA

Работа начата с чистого `main` на
`bcae298a403b24574704b8369323ded56829f1bb`. Источником истины был код
репозитория, а не предположения из prompt.

## 2. Текущие версии GCore

| Ресурс | Resource version | Public API | Protocol |
| --- | ---: | ---: | ---: |
| `gc_core` | `0.1.5-alpha` | 1 | 2 |
| `gc_identity` | `0.4.1-alpha` | 1 | 3 |
| `gc_example` | `0.1.0-alpha` | — | — |
| `gc_ecosystem` | `0.1.0-alpha` | 1 | — |
| `gc_sdk` | `0.1.0-alpha` | 1 | — |

Core API v1 и существующие сетевые протоколы не изменены.

## 3. Архитектура экосистемы

`gc_core` остался независимым фундаментом. Модули могут напрямую использовать его
Public API. `gc_sdk` — необязательный helper для boilerplate, а `gc_ecosystem` —
необязательный серверный диагностический registry. Они не участвуют в gameplay path.

```text
FiveM -> gc_core Public API -> независимые модули
                         \-> optional gc_sdk
установленные ресурсы -> optional gc_ecosystem diagnostics
репозиторий -> portable tools -> validation/tests/catalog/package
```

## 4. Module Standard v1

Стандарт фиксирует структуру ресурса, границы ответственности, обязательную RU/EN
документацию, один source of truth версии, tests, dependency declarations, изоляцию
DTO и запрет доступа к internal `gc_core`.

## 5. Metadata schema

Machine-readable metadata в `fxmanifest.lua`: `gcore_module`, `gcore_contract`,
`gcore_type`, optional `gcore_api`, требуемая Core API, capabilities, required/optional
module dependencies, repository и license. Зарезервированный namespace `gcore_*`
проверяется декларативно, без выполнения стороннего manifest.

## 6. Миграция существующих модулей

`gc_example` и `gc_identity` публикуют Module Standard metadata. В `gc_example`
добавлен `shared/version.lua`, при этом reference-паттерн прямого вызова Core сохранён.
Gameplay и identity contracts не переносились в ecosystem.

## 7. Архитектура gc_ecosystem

`gc_ecosystem` работает только на server-side и читает FiveM resource metadata/state
и публичные API versions. Внутри: in-memory registry, защищённая DTO boundary,
dependency graph, compatibility evaluator, capability index, bounded refresh по
resource lifecycle и console-only diagnostic command.

## 8. Ecosystem Public API

API v1 экспортирует `GetVersion`, `GetApiVersion`, `ListModules`, `GetModule`,
`IsModuleCompatible`, `GetDependencyGraph`, `GetCapabilityProviders`, `Refresh`.
Таблицы возвращаются глубокими копиями. API управления ресурсами или gameplay нет.

## 9. Module Registry

Discovery основан на `gcore_module 'yes'`, а не на префиксе `gc_`. Официальные и
third-party имена обрабатываются одинаково. Статусы различают compatible,
incompatible, missing dependency, stopped, malformed и cycle.

## 10. Dependency Resolver

Required dependency задаётся как `resource:api>=N` и дополнительно объявляется FiveM
dependency. Optional dependency не ломает совместимость при отсутствии. Missing,
stopped или insufficient API provider отклоняется fail-closed.

## 11. Cycle Detection

Portable graph library и runtime registry обнаруживают self-dependency и циклы.
Catalog generation также прекращается до записи документов при обнаружении цикла.

## 12. Compatibility Logic

Проверяются Module Contract version, состояние Core, minimum Core API, состояние
модуля, наличие/state/API required dependencies, корректность metadata и cycles.
Диагностика использует стабильные коды `GC-ECOSYSTEM-*`.

## 13. Capability Model

Capability — lowercase metadata label для поиска и диагностики. Он не выдаёт права,
не доказывает trust и не заменяет explicit dependency. Registry возвращает всех
совместимых providers.

## 14. Поиск кандидатов для SDK

В `gc_example` и `gc_identity` реально повторялись только проверки доступности/API
Core и generic resource dependency. Только эти patterns попали в SDK v0.

## 15. SDK v0 API

`gc_sdk` экспортирует запросы версии/API, `IsCoreAvailable`, `GetCoreApiVersion`,
`RequireCoreApi`, `RequireResource`. Он server-only, fail-closed, не содержит domain
logic и не нужен Core, registry или существующим модулям.

## 16. Module Generator

`lua tools/create-module.lua <name>` создаёт server, optional client или optional NUI
module. Он валидирует имя/type, требует явный third-party flag для имени без `gc_`,
поддерживает dry-run/JSON и никогда не перезаписывает destination.

## 17. Module Template

Шаблоны создают обычный читаемый FiveM resource: metadata, `shared/version.lua`,
прямая Core API compatibility check, server tests, README RU/EN и только явно
запрошенные client/NUI файлы. Dummy gameplay и скрытой магии нет.

## 18. Conformance Tool

`module_conformance.lua` проверяет metadata, SemVer/API consistency, обязательные
файлы, ссылки manifest, dependency grammar/declarations, запрещённые Core globals и
paths, неизвестные Core exports. Поддерживается standalone path/JSON usage.

## 19. Packaging Tool

Packager запускает conformance/tests, проверяет NUI `dist`, копирует безопасное дерево,
создаёт portable tar, SHA-256 и release manifest, не перезаписывает результат. Secrets,
dependencies, build output, databases и корневой runtime `data/` исключаются.
Regression test защищает от попадания private identity data в artifact.

## 20. Local Catalog

Catalog генерируется из manifests и содержит четыре актуальных модуля. Duplicate
resource, missing required dependency или cycle останавливают генерацию.

## 21. Generated Documentation

Одна команда создаёт `docs/generated/modules.json`, RU/EN module tables и Mermaid
dependency graph. Режим `--check` превращает устаревший output в CI failure.

## 22. Изменения CI

CI динамически находит все ресурсы Module Standard. Per-module matrix запускает
conformance/tests; отдельная NUI matrix устанавливает точные зависимости, тестирует,
собирает и сверяет committed `dist`. Добавление модуля не требует изменения workflow.

## 23. Security Model

Экосистема не загружает remote code и не выполняет сторонний manifest при static
discovery. Runtime data/secrets исключаются из package. Тесты защищают от Core internal
access, private paths, undeclared dependencies, unknown Core exports, unsafe generator
names и mutable DTO leakage.

## 24. Поддержка third-party modules

Модуль может иметь любое допустимое resource name при наличии metadata marker. Один
parser, conformance, test harness, runtime registry, compatibility logic, catalog и
packager работают для ресурсов без `gc_`. Marketplace account не нужен.

## 25. Automated Tests

Финальные локальные результаты: Core `511/511`; modules `463/463` для четырёх
ресурсов; ecosystem tooling `34/34`; identity NUI `16/16`; mail service `14/14`.
Repository validation и generated-doc checks проходят. Обычный `luac` не понимает
FiveM backtick model literals, поэтому authoritative syntax boundary — validator.

## 26. Real FXServer Tests

PASS в реальном FXServer под txAdmin с одним подключённым игроком:

- обнаружены четыре production module, все compatible;
- после остановки `gc_ecosystem` игрок остался Core `spawned`, identity `ready`;
- restart registry полностью восстановил state;
- stop/start `gc_example` детерминированно менял status;
- third-party resource без префикса обнаружен;
- fixture с Core API 999 отклонён;
- fixture с missing module dependency отклонён;
- временные fixtures остановлены и удалены, финальный registry снова содержит 4 модуля.

## 27. Backward Compatibility

Core API = 1, Core protocol = 2, identity API = 1, identity protocol = 3. Модули
по-прежнему могут обращаться к Core напрямую. Для запуска не требуются `gc_sdk` или
`gc_ecosystem`.

## 28. Remaining Technical Debt

Registry намеренно local/in-memory и не является trust/signature system. Checksum не
заменяет подпись издателя. Module API negotiation поддерживает minimum-version.
Empty-NUI matrix можно обобщить, если в репозитории когда-либо не останется NUI.
Блокирующего долга для v0.1 нет.

## 29. Marketplace Readiness

Local metadata, catalog, conformance, packaging, checksum и third-party path создают
правильный фундамент. Marketplace, remote installer, auto-update, publisher identity,
signing, moderation и remote code execution намеренно **не реализованы**.

## 30. Рекомендуемый следующий этап

Создать по стандарту один узкий production module, собрать реальный authoring friction
и только затем additive-расширять SDK v0. Signing/trust и marketplace governance нужно
проектировать отдельно до любого remote distribution.

## Таблица качества

| Область | Результат |
| --- | --- |
| Core independence | PASS |
| Module Standard | PASS |
| Metadata validation | PASS |
| Registry | PASS |
| Dependency graph | PASS |
| Cycle detection | PASS |
| API compatibility | PASS |
| SDK optional | PASS |
| Third-party modules | PASS |
| Generator | PASS |
| Conformance | PASS |
| Packaging | PASS |
| Catalog | PASS |
| Generic CI | PASS |
| RU docs | PASS |
| EN docs | PASS |
| Real FXServer | PASS |

## Финальные вопросы

| Вопрос | Ответ |
| --- | --- |
| Можно ли создать module без открытия internal `gc_core`? | YES |
| Можно ли автоматически проверить совместимость? | YES |
| Можно ли отдельно протестировать third-party module? | YES |
| Можно ли собрать distributable artifact? | YES |
| Можно ли использовать GCore без SDK? | YES |
| Можно ли использовать GCore без `gc_ecosystem`? | YES |

**GCORE ECOSYSTEM v0.1: READY**
