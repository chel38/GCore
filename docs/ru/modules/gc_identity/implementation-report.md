# Отчёт о persistent identity для gc_identity

Дата: 2026-08-10

Проверенный baseline: `d1abbf0476e0ca3a5e284fe319cedef43839bc87`

Core: `0.1.4-alpha`, API `1`, protocol `1`
Identity: `0.2.0-alpha`, API `1`, protocol `1`

## Executive summary

JSON-backed MVP с автоматическим созданием account заменён явной persistent
регистрацией и character flow. Production storage — MariaDB через oxmysql;
runtime JSON fallback отсутствует. Trusted server-side FiveM identifier остаётся
authorization credential. Password authentication намеренно отключена, а не
имитируется.

`gc_core` не изменялся и остаётся независимым от identity/database domain.
Public Identity API v1 backward-compatible; `GetIdentityHealth` добавлен
additive.

## Результаты фаз

| Phase | Result | Итог |
| --- | --- | --- |
| Current repository audit | PASS | проверены versions, API boundary, tests, старый JSON flow |
| Persistence design | PASS | repository contract, schema, migrations, failure policy |
| MariaDB repository | PASS | oxmysql adapter, transactions, constraints, parameterization |
| Registration/authorization | PASS | явный email; trusted identifier auto-login |
| Character persistence | PASS | transactional limit, ownership, selection |
| NUI | PASS | TypeScript/Tailwind build, callback bridge, focus lifecycle |
| Security/recovery | PASS | exact schemas, rate/replay, generation cancellation, restart tests |
| Automated verification | PASS | Lua suite, NUI tests, syntax, build, repository validation |
| Real one-client runtime | PASS WITH NOTE | MariaDB/oxmysql/FXServer/restart/reconnect проверены |
| Real two-client runtime | NOT RUN | был доступен только один FiveM client |

## Реализованная архитектура

```text
gc_core Public API v1
        ↓
gc_identity network/NUI boundary
        ↓
identity service + explicit state machine
        ↓
GCIdentityRepository facade
        ↓
oxmysql adapter → MariaDB 12.3.2
```

Adapters выбираются явно:

- `oxmysql`: production default;
- `memory`: только automated tests;
- `json_legacy`: read-only import source, никогда fallback.

## Schema и transactions

Migration `001_initial_identity` создаёт:

- `gc_accounts`;
- `gc_account_identifiers`;
- `gc_characters`;
- `gc_account_character_selections`;
- bootstrap history `gc_identity_schema_migrations`.

Unique email/identifier constraints, foreign keys, status checks и indexes
защищают storage invariants. Registration записывает account+identifier одной
transaction. Character creation блокирует account row и проверяет configured
active-character limit. Selection блокирует и проверяет character перед upsert.
Runtime values используют placeholders `?`.

## Authorization и security

- Unknown trusted identifier входит в `registration_required`; lookup больше не
  создаёт account автоматически.
- Returning identifier восстанавливает persisted account и selected character.
- Email trim/lowercase, bounded, syntax-validated и unique.
- Password collection/authentication отключена; snapshot содержит
  `passwordAuthentication = false`.
- Client payload не может содержать trusted identifier/account/authority fields.
- Server → client events используют FiveM server-origin guard.
- Per-action rate limits и bounded replay results защищают ingress.
- Public DTO исключают identifier, ownership keys, SQL metadata и mutable tables.
- Logger фильтрует email/password/token/secret-like keys.

## Результат NUI

Source и committed production build находятся в `gc_identity/web`. Реализованы
loading, registration, character selection/creation, error и exit confirmation.
Pending action блокирует повторный submit. Escape открывает/закрывает подтверждение
выхода. До authoritative `ready` клиент удерживает focus и freeze PED, затем
освобождает оба.

Web tests проверяют отсутствие password field, double-submit blocking, exit
confirmation и HTML escaping DTO values.

## Automated tests

Lua suite покрывает state, validation, memory/oxmysql repository contracts,
migration order/idempotency/failure, persistent registration, returning auth,
ownership/limit, two-player isolation, replay, rate limiting, event spoofing,
disconnect during storage, restart/recovery, DTO/API contracts, NUI callbacks и
startup races.

CI также устанавливает exact NUI dependencies, запускает tests, strict TypeScript
check, production build и проверяет актуальность committed `dist`.

## Real FXServer/MariaDB result

Environment:

- FXServer artifact `b25770`, txAdmin `8.0.1`;
- MariaDB `12.3.2` portable local runtime;
- oxmysql `2.14.1` release build;
- один реальный FiveM client, game build `3751`.

Наблюдения:

1. oxmysql подключился к MariaDB.
2. Migration 001 применилась один раз; следующие starts показали 0 pending.
3. Legacy JSON account импортировался один раз, затем idempotent skip.
4. Real client подключился без зависания `Awaiting scripts` и получил
   `registration_required` через реальный guarded snapshot boundary.
5. Registration/create/select для online source были вызваны временной локальной
   smoke-командой через production service/repository. MariaDB получила ровно
   один account, character и selection; hook удалён до final build.
6. Client получил `ready`; NUI readiness не выдала timeout.
7. `restart gc_identity` восстановил `ready` без duplicate rows. Startup hello
   race больше не показывает ложную database error.
8. `restart gc_core` восстановил core player. FiveM остановил declared dependent
   `gc_identity`; после документированного `ensure gc_identity` identity вернулась
   в `ready` без потери данных.
9. Завершение client вызвало `playerDropped`; MariaDB data сохранились.
10. Fresh reconnect получил новый source и сразу восстановил `ready` с одним
    persistent character.

Registration form не отправлялась вручную через real NUI; её callback/network
path покрыт integration harness, а real client получил pre/post transaction
snapshots. Два simultaneous real clients были недоступны.

## Compatibility и migration

- Core version/API/protocol: без изменений.
- Identity API/protocol: `1`.
- Identity resource: `0.1.0-alpha` → `0.2.0-alpha`.
- Breaking deployment change: теперь обязательны `oxmysql` и MariaDB.
- Старые JSON records импортируются idempotently. У них нет email, поэтому нужен
  registration completion.
- Downstream export names и DTO isolation сохранены; Account DTO additively
  содержит email/status после регистрации.

## Remaining technical debt

- Выполнить real 2+ client isolation/recovery test.
- Автоматизировать operator restart ordering, если появится ecosystem supervisor;
  сейчас FiveM требует `ensure gc_identity` после `restart gc_core`, потому что
  останавливает declared dependants.
- Verified email или реальный password/WebAuthn provider проектировать отдельным
  security milestone; placeholder password code запрещён.
- Проверить production backup/restore на deployment host.

## Final verdict

| Gate | Result |
| --- | --- |
| Core independence | PASS |
| Explicit registration | PASS |
| Trusted authorization | PASS |
| MariaDB persistence | PASS |
| Migration safety | PASS |
| Character ownership/selection | PASS |
| NUI and focus lifecycle | PASS |
| Security boundary | PASS |
| API v1 compatibility | PASS |
| Automated tests/CI | PASS |
| Real one-client persistence/reconnect | PASS |
| Real two-client validation | NOT RUN |

`gc_identity 0.2.0-alpha` готов к дальнейшей alpha module development; real
two-client test и production backup rehearsal остаются явно открытыми.
