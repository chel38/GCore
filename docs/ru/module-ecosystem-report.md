# Отчёт о первом этапе модульной экосистемы GCore

> Исторический отчёт по первоначальному MVP `gc_identity 0.1.0-alpha`.
> Актуальный persistent milestone `0.2.0-alpha` описан в
> [implementation report](modules/gc_identity/implementation-report.md).

## 1. Executive Summary

Созданы reference module `gc_example` и первый production MVP `gc_identity`.
Оба используют `gc_core` только через Public API v1. Внутренний код `gc_core` не
изменялся, Core API v1 и Network Protocol 1 остались backward-compatible.

## 2. Commit / Version Audited

- Base SHA: `5fda3617952f790aaf899dab50b434b316c3e60d`.
- `gc_core`: `0.1.3-alpha`, API `1`, protocol `1`.
- `gc_example`: `0.1.0-alpha`.
- `gc_identity`: `0.1.0-alpha`, API `1`, protocol `1`.
- Delivery SHA: commit, содержащий этот отчёт.

## 3. Current GCore Architecture

```text
FiveM
  ↓
gc_core lifecycle + Public API v1
  ├── gc_example (reference consumer)
  └── gc_identity (independent identity domain)
```

`gc_core` остаётся нижним engine-level слоем и не знает о `gc_identity`.

## 4. gc_example Architecture

`gc_example` проверяет Core API `>= 1`, регистрирует server-only команду
`/gcexample`, проверяет `CanUseGameplayFeatures`, читает detached Public Session
DTO и отправляет уведомление через `NotifyPlayer`. Доступ к internal globals,
files или network events ядра отсутствует.

## 5. Module Contract Validation Result

Module Contract работает: reference module реализован только через exports Public
API v1. Repository validator теперь проверяет manifests, dependency, RU/EN README,
tests и запрещённые ссылки на internals ядра.

## 6. gc_identity Architecture

Поток: validated network ingress → identity service → repository boundary. Модуль
получает trusted identifier через server-only core export, автоматически находит
или создаёт account, хранит собственную state machine и persisted character data.
JSON adapter изолирован в repository и является MVP boundary, а не ORM.

## 7. gc_identity Public API

Public server exports: `GetIdentityVersion`, `GetIdentityApiVersion`,
`GetIdentityProtocolVersion`, `IsAuthorized`, `IsIdentityReady`,
`GetIdentityState`, `GetAccount`, `GetCharacters`, `GetSelectedCharacter`.
Account/Character DTO являются копиями и не раскрывают identifiers или storage
metadata.

## 8. gc_identity State Machine

```text
unknown → account_required → authorized → character_required → ready
                                            └───────────────→ error
```

Состояние модуля не меняет lifecycle state ядра. Downstream gameplay gate требует
одновременно core gameplay readiness и identity readiness.

## 9. Security Model

- exact payload schemas и protocol validation;
- bounded per-source rate limits и replay request IDs;
- server-side account/character ownership;
- server-origin guard для client events;
- отсутствие client-supplied identifiers и authoritative state;
- DTO isolation и логирование без чувствительных identifiers.

## 10. Tests

| Набор | Результат |
| --- | ---: |
| gc_core harness | 496/496 PASS |
| gc_example | 31/31 PASS |
| gc_identity | 88/88 PASS |
| Repository validator | PASS |
| Lua syntax | PASS |
| `git diff --check` | PASS |

Identity tests включают unit, integration, security, API contracts, DTO mutation,
disconnect cleanup и restart recovery. CI динамически запускает tests каждого
независимого `gc_*` module.

## 11. Real FXServer Results

| Сценарий | Результат |
| --- | --- |
| FXServer + txAdmin, core/example/identity boot | PASS |
| Реальный FiveM client, core handshake и spawn | PASS |
| Account resolution, character create/select, state `ready` | PASS |
| Public core + identity contract probe | PASS |
| `restart gc_identity`, online recovery | PASS (`recovered=1`) |
| `restart gc_core`, core recovery | PASS (`recovered=1`) |
| `ensure gc_identity` после dependency restart | PASS (`recovered=1`) |
| Disconnect и core session cleanup | PASS |
| Повторная дополнительная попытка подключения | ENV BLOCKED: внешний Cfx ticket `CURL 92`; обязательный connected flow уже пройден |
| 2+ реальных клиента | NOT RUN |

FiveM останавливает declared dependants при `restart gc_core`; поэтому operational
contract требует затем `ensure gc_identity`. Этот реальный порядок добавлен в
Module Contract и README. Runtime завершился marker `COMPLETE=PASS` без
`SCRIPT ERROR` от ресурсов GCore.

## 12. Core API Additions

Нет. `gc_example` и `gc_identity` доказали достаточность существующего API v1.

## 13. Core API Stability

API v1 backward-compatible. Resource version и protocol не повышались; internal
core files не менялись.

## 14. Module Coupling Analysis

`gc_example → gc_core Public API` и `gc_identity → gc_core Public API`. Обратной
или циклической зависимости нет. Validator блокирует известные internal globals,
private paths и неизвестные core exports.

## 15. Repeated Development Patterns

Повторились: API compatibility check, fail-closed dependency access, detached DTO,
event ingress validation, stable error result, bounded rate limit, server-origin
guard, module startup logging и restart recovery.

## 16. SDK Candidate Features

Для небольшого SDK v0 обоснованы helpers проверки API compatibility, module
startup/failure result, detached DTO copy, event ingress schema, rate limit и
server-event guard. SDK должен остаться optional; в этой задаче он не создавался.

## 17. Remaining Technical Debt

- JSON persistence подходит только для alpha/MVP и требует backup/будущего adapter.
- Реальный 2+ client recovery ещё не выполнен.
- Внешний Cfx authentication периодически возвращает `CURL 92` и не относится к
  GCore runtime.
- Public lifecycle hooks не добавлялись: текущим consumers они пока не нужны.

## 18. Recommended Next Module

После короткого SDK v0 design review рекомендуемый следующий production module —
`gc_admin`. Отдельный `gc_database` следует создавать только когда второй реальный
consumer докажет необходимость общего persistence service.

## Контрольные ответы

1. `gc_example` использует исключительно Public API: **YES**.
2. `gc_identity` реализован без доступа к `gc_core` internals: **YES**.
3. Core API v1 остался backward-compatible: **YES**.
4. Опыта достаточно для начала минимального SDK v0 design: **YES**.
