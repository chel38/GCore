# gc_identity 0.4.1-alpha — реализованный design

Статус: реализовано и проверено automated tests; актуальный runtime smoke-test
документируется отдельно. Identity API 1 совместим; protocol 3 добавляет
pre-spawn registered-name/email finalization и new-IP handshake.

## Ответственность

`gc_core` знает lifecycle сетевого игрока и в manual mode ждёт доверенный server
spawn release. `gc_identity` до spawn определяет persistent account/security,
а после подтверждённого spawn управляет выбранным character.

Модуль владеет явной регистрацией, авторизацией по trusted server-side FiveM
identifier, registered account name, character identity, Public Identity API/DTO, MariaDB persistence,
NUI и собственным recovery. Он не владеет core lifecycle, gameplay domains,
permissions, деньгами, inventory или общей ORM.

```text
FiveM
  ↓
gc_core Public API v1
  ↓
gc_identity service
  ↓
repository facade → oxmysql → MariaDB
```

`gc_core` не импортирует identity code и остаётся независимым от БД.

## Авторизация и регистрация

Primary credential — server-captured `license`/`license2`, полученный через
`gc_core:GetPlayerIdentifier(source)`. Client payload его не содержит.

Неизвестный identifier не создаёт account автоматически. State становится
`registration_required`; normalized unique email создаёт DB-backed one-time
challenge, а не account. Правильный code лишь помечает challenge verified;
отдельный finalize одной transaction создаёт/связывает account, сохраняет имя,
подтверждает email и первый HMAC IP fingerprint. Returning same-IP identifier авторизуется автоматически,
а новый observed IP требует ещё один email code. Password authentication отключена: данные password-типа не принимаются
и не сохраняются.

## State machine

```text
uninitialized
    ↓
 loading ──────────────→ error
    ├─ unknown identifier → registration_required → registering
    │                       → email_verification_pending → registration_verified
    │                       → registration_finalizing → authorized → spawn_releasing
    ├─ persisted account + new IP → auth_verification_required → authorized
    └─ persisted account + same IP ────────────────────────────→ authorized
                                                     ↓
                                      post_spawn_identity → character_required
                                             ↓
                                      character_selected
                                             ↓
                                           ready

любой active state → disconnecting → runtime session removed
```

Все изменения выполняются через `GCIdentityStates.Transition`; service не пишет
`session.state` напрямую. Session generation отменяет stale DB result после
disconnect или замены session.

## Server-authoritative flow

```text
NUI/client request
  → exact schema + protocol + rate + replay validation
  → проверка текущего gc_core lifecycle
  → repository transaction / ownership decision
  → повторная проверка session generation
  → state transition
  → detached server snapshot
  → guarded client handler
```

Клиент передаёт только registered full name, email, verification code, имена character или character ID. Он не может
передать trusted identifier, account ID, authorization state, ownership или DB
fields.

## Public API v1

| Export | Контракт |
| --- | --- |
| `GetIdentityVersion` | `string` |
| `GetIdentityApiVersion` | integer `1` |
| `GetIdentityProtocolVersion` | integer `3` |
| `GetDisplayName(source)` | string или nil, copy-safe registered account name |
| `GetIdentityHealth` | detached `{ available, storage, database, mail }` DTO |
| `IsAuthorized` | boolean для valid current source |
| `IsIdentityReady` | true только в identity state `ready` |
| `GetIdentityState` | state string или `nil` |
| `GetAccount` | detached Account DTO или `nil` |
| `GetCharacters` | массив detached Character DTO |
| `GetSelectedCharacter` | detached Character DTO или `nil` |

Account DTO содержит `id`, `email`, `firstName`, `lastName`, `displayName`,
`status`, `createdAt`. Character DTO содержит
`id`, `firstName`, `lastName`, `createdAt`. Identifiers, ownership keys, internal
timestamps, SQL metadata, replay/rate state и mutable references остаются private.

## Network и NUI contract

| Event | Direction | Payload |
| --- | --- | --- |
| `gc_identity:server:hello` | client → server | `{ protocolVersion }` |
| `gc_identity:server:sendRegistrationCode` | client → server | `{ protocolVersion, requestId, fullName, email }` |
| `gc_identity:server:changeRegistrationEmail` | client → server | `{ protocolVersion, requestId }` |
| `gc_identity:server:finalizeRegistration` | client → server | `{ protocolVersion, requestId }` |
| `gc_identity:server:completeProfile` | client → server | `{ protocolVersion, requestId, fullName }` |
| `gc_identity:server:verifyEmail` | client → server | `{ protocolVersion, requestId, code }` |
| `gc_identity:server:resendVerification` | client → server | `{ protocolVersion, requestId }` |
| `gc_identity:server:createCharacter` | client → server | `{ protocolVersion, requestId, firstName, lastName }` |
| `gc_identity:server:selectCharacter` | client → server | `{ protocolVersion, requestId, characterId }` |
| `gc_identity:server:clientFailure` | client → server | allowlisted `{ protocolVersion, code }` |
| `gc_identity:server:exit` | client → server | `{ protocolVersion }` |
| `gc_identity:client:snapshot` | только server → client | Public snapshot |
| `gc_identity:client:rejected` | только server → client | `{ requestId?, code }` |

Server-only client events требуют `source == 65535`. NUI callbacks формируют эти
requests; локальный pending state блокирует double submit, а authoritative replay
защищается на сервере.

Eagerly loaded HTML использует прозрачный canvas документа и явно скрытый initial
root. После JavaScript-ready callback Lua повторяет сохранённый snapshot;
focus/freeze применяются только после этого ACK. Terminal storage/hello errors
имеют retry/exit view. Отсутствие JavaScript readiness ограничено timeout и
заканчивается validated controlled disconnect.

## Persistence и recovery

Production adapter — `oxmysql`. Memory adapter существует только для tests;
JSON adapter — read-only legacy migration input. Startup bounded: database probe
→ migrations → repository → optional import → recovery. Любая ошибка создаёт
явный degraded state без fallback.

`restart gc_identity` один раз восстанавливает online sessions и persisted
selection. При административном рестарте `gc_core` FiveM останавливает declared
dependants; после него нужен `ensure gc_identity`. Disconnect удаляет только
runtime state. Reconnect находит тот же account/selection без duplicate writes.

## Security baseline

- parameterized runtime SQL и database constraints;
- transactional registration, character limit и selection;
- exact payload schemas и normalized bounded strings;
- per-source/action rate limits и bounded replay cache;
- ownership проверяется в transaction, а не в NUI;
- server-origin guards и DTO copy isolation;
- stable diagnostic codes без identifiers, email и secrets в logs.

См. [persistence design](persistence-design.md) и
[implementation report](implementation-report.md), а также
[NUI lifecycle audit](nui-lifecycle-audit.md).
