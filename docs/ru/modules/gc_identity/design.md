# gc_identity 0.1.0-alpha — проектирование

Статус: согласованный MVP design до начала реализации.
API модуля: 1. Protocol модуля: 1. Требуемый Core API: 1.

## Ответственность

`gc_core` знает, что сетевой игрок подключён и заспавнен. `gc_identity` отвечает
на отдельный вопрос: какой server-owned аккаунт и персонаж принадлежат игроку в
текущей сессии.

MVP владеет:

- поиском аккаунта по license и автоматическим созданием первого аккаунта;
- созданием/списком персонажей, проверкой ownership и выбором персонажа;
- явной identity state machine;
- отделёнными Public Account и Character DTO;
- небольшой persistence boundary и JSON file adapter;
- собственной validation, rate limits, error namespace и restart recovery.

## Что модуль не делает

Модуль не владеет core connection/spawn state, паролями, web login, ролями,
permissions, деньгами, inventory, jobs, admin, NUI или общей БД/ORM. Он никогда
не меняет state `gc_core`, а `gc_core` никогда не импортирует `gc_identity`.

## Зависимость и gameplay rule

```text
gc_core Public API v1
          ↑
     gc_identity
```

Каждая операция запрашивает актуальные core exports. Bootstrap требует
подключённого ready-игрока. Изменение персонажей дополнительно требует
`CanUseGameplayFeatures(source)`. Core API v1 по-прежнему означает только
`core state == spawned`; domain module, которому нужна identity, проверяет оба
условия:

```lua
exports.gc_core:CanUseGameplayFeatures(source)
    and exports.gc_identity:IsIdentityReady(source)
```

Так зависимость остаётся односторонней и не требует изменения core.

## State machine

```text
unknown
   ↓
account_required ── create/resolve trusted account ──→ authorized
                                                        ↓
                              ┌─ selected character ──→ ready
                              └─ no selection ────────→ character_required

любое active state ── unrecoverable repository/config failure ──→ error
disconnect/resource stop ───────────────────────────────────────→ removed
```

`authorized` — server-owned факт найденного аккаунта, а не утверждение клиента.
Переходы выполняет только identity state service. Duplicate hello и повторный
request ID идемпотентны и не создают второй аккаунт или персонажа.

## Data model

Internal Account:

```text
id, identifierType, identifier, selectedCharacterId, createdAt, updatedAt
```

Internal Character:

```text
id, accountId, firstName, lastName, createdAt, updatedAt
```

Trusted identifier берётся только из server-side Core API. Он хранится для
поиска, но никогда не логируется, не отправляется клиенту и не попадает в Public
DTO.

Public Account DTO: `id`, `createdAt`.
Public Character DTO: `id`, `firstName`, `lastName`, `createdAt`.

Все DTO являются копиями. Их изменение не меняет repository/runtime state.

## Public server API v1

| Export | Arguments | Return |
| --- | --- | --- |
| `GetIdentityVersion` | нет | resource version string |
| `GetIdentityApiVersion` | нет | integer API version |
| `GetIdentityProtocolVersion` | нет | integer protocol version |
| `IsAuthorized` | player source | boolean |
| `IsIdentityReady` | player source | boolean |
| `GetIdentityState` | player source | state или `nil` |
| `GetAccount` | player source | detached Account DTO или `nil` |
| `GetCharacters` | player source | массив detached Character DTO |
| `GetSelectedCharacter` | player source | detached Character DTO или `nil` |

Public API v1 не содержит методов, изменяющих identity state.

## Network events

Client → server:

- `gc_identity:server:hello` — `{ protocolVersion }`;
- `gc_identity:server:createCharacter` — `{ protocolVersion, requestId,
  firstName, lastName }`;
- `gc_identity:server:selectCharacter` — `{ protocolVersion, requestId,
  characterId }`.

Только server → client:

- `gc_identity:client:snapshot` — текущий public identity snapshot;
- `gc_identity:client:rejected` — `{ requestId?, code }`.

Client handlers требуют FiveM server origin (`source == 65535`). Payload schema
отклоняет неизвестные поля. Requests ограничиваются rate limit на source/action.
Bounded cache результатов делает повторный request ID идемпотентным.

## Persistence model

Только `GCIdentityRepository` читает и пишет storage. Первый adapter использует
`LoadResourceFile`/`SaveResourceFile` и `data/identities.json`; MVP запускается
без обязательной базы данных и не добавляет database dependency в core. Runtime
services не вызывают JSON/storage natives напрямую. В будущем adapter можно
заменить на database implementation без изменения API v1.

При записи заменяется весь небольшой alpha dataset, ошибки возвращаются явно.
JSON является runtime data и исключён из Git. Adapter подходит для MVP, но не
объявляется high-volume production database.

## Restart и recovery

- При старте `gc_identity` persisted data загружается до ready state ресурса.
- Сервер один раз сканирует online players и восстанавливает runtime sessions
  через актуальные core exports.
- Клиент отправляет bounded hello после старта identity или core resource.
- После старта `gc_core` identity повторно проверяет API и идемпотентно
  восстанавливает всех online players.
- FiveM останавливает declared dependants при `restart gc_core`; затем оператор
  выполняет `ensure gc_identity`. Этот start path запускает тот же bounded recovery
  online players и восстанавливает сохранённого выбранного персонажа.
- Disconnect удаляет runtime state, rate limits и replay cache; persisted
  аккаунт/персонажи остаются.
- Async/recovery paths bounded и отменяются при смене resource generation.

## Security model

- Клиент никогда не присылает identifier, account ID, ownership result или
  authorization state.
- Account lookup использует server-side `gc_core:GetPlayerIdentifier`.
- Выбор персонажа проверяет repository ownership на сервере.
- Character strings проверяются по type, byte length, control characters и
  запрещённой пунктуации.
- Strict schemas, protocol checks, rate limits и replay handling защищают все
  ingress events.
- Public API не позволяет account enumeration: доступ только по текущему player
  source.
- Паролей в MVP нет; собственная схема hashing не создаётся.
- Logs содержат source и stable codes, но не identifiers/чувствительные данные.

Тесты покрывают malformed/oversized input, duplicate requests, replay, wrong
state, stopped core, rate limit, чужой character ID, local spoof server-only
events, DTO mutation, restart recovery и disconnect cleanup.

## Failure cases

Stable namespaces:

- `GC-IDENTITY-CORE-*` — dependency/lifecycle;
- `GC-IDENTITY-PAYLOAD-*` — schema/type;
- `GC-IDENTITY-RATE-LIMIT` — bounded ingress;
- `GC-IDENTITY-ACCOUNT-*` и `GC-IDENTITY-CHARACTER-*` — domain;
- `GC-IDENTITY-STORAGE-*` — repository;
- `GC-IDENTITY-PROTOCOL-MISMATCH` и `GC-IDENTITY-SECURITY-*` — trust boundary.

Ошибки fail-closed: state commit выполняется только после validation и успешного
persistence.
