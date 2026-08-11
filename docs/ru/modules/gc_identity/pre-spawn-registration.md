# Pre-spawn регистрация и безопасная авторизация

Актуальный контракт: `gc_core 0.1.5-alpha` (API 1, protocol 2) и
`gc_identity 0.4.1-alpha` (Identity API 1, protocol 3).

## Главная гарантия

При включённом `gc_identity` сервер запускается с:

```cfg
set gcore_spawn_mode manual
ensure gc_core
ensure gc_identity
```

В этом режиме клиентское `gc_core:server:requestSpawn` всегда получает
`GC-SPAWN-MANUAL-ONLY`. Решение может создать только server export
`exports.gc_core:RequestPlayerSpawn(source)`. `gc_core` не знает о регистрации,
email или `gc_identity`: он знает только generic spawn policy.

```text
clientReady
    ↓
core state = client_ready (PED ещё не создан)
    ↓
gc_identity Resolve
    ├─ новый account → registration_required
    ├─ trusted license + тот же IP → authorized
    ├─ новый IP → auth_verification_required
    └─ legacy account без имени → profile_completion_required
    ↓
gc_identity server подтверждает security state
    ↓
exports.gc_core:RequestPlayerSpawn(source)
    ↓
core server decision → client spawn → server verification
    ↓
gc_core:hook:playerSpawned
    ↓
post-spawn character selection → ready
```

## Регистрация нового игрока

1. NUI отправляет `Имя Фамилия` (ровно два слова, только `A-Z/a-z`) и email.
2. Сервер нормализует payload, получает license и endpoint самостоятельно,
   создаёт bounded email challenge и отправляет код через локальный Mail Service.
3. Верный код переводит challenge в `registration_verified`. Аккаунта всё ещё
   нет, player не authorized, spawn request не выполняется.
4. Кнопка «Завершить регистрацию» отправляет payload только с protocol/request ID.
   Сервер заново сверяет session generation, license, IP fingerprint, challenge,
   TTL, имя и email.
5. Одна DB transaction создаёт account, identifier binding, registered name,
   verified email и trusted IP, затем потребляет challenge.
6. Только после commit `gc_identity` один раз вызывает Core spawn export.

Смена email до финализации потребляет старый challenge, сохраняет введённое имя,
сбрасывает `emailVerified` и возвращает state в `registration_required`. Старый
код повторно использовать нельзя; abuse counters при этом не сбрасываются.

## Повторный вход и новый IP

- Совпали server-observed license и HMAC fingerprint IP: NUI регистрации и письмо
  пропускаются, server сразу освобождает spawn.
- License известен, IP новый: до кода `authentication` spawn закрыт.
- Client-supplied license/IP не принимаются ни одним public event.
- Ошибка Mail Service или MariaDB оставляет игрока в диагностируемом pre-spawn
  состоянии; fail-open отсутствует.

## Registered name и characters

`gc_accounts.first_name/last_name` — имя зарегистрированного аккаунта. Это не
FiveM nickname и не имя игрового персонажа. Старые accounts с `NULL` проходят
`profile_completion_required` до spawn. Character create/select остаётся
post-spawn системой и не используется как регистрационное имя.

Identity Public API v1 дополнен без breaking change:

```lua
local displayName = exports.gc_identity:GetDisplayName(source) -- string | nil
local account = exports.gc_identity:GetAccount(source)          -- copied DTO
```

Account DTO: `id`, `email`, `firstName`, `lastName`, `displayName`, `status`,
`createdAt`. В DTO нет license, IP fingerprint, challenge/hash или DB metadata.

## Network contract v3

| Event | Direction | Payload | Authority |
|---|---|---|---|
| `gc_identity:server:sendRegistrationCode` | client → server | `protocolVersion, requestId, fullName, email` | validation + rate limit |
| `gc_identity:server:verifyEmail` | client → server | `protocolVersion, requestId, code` | verification only |
| `gc_identity:server:changeRegistrationEmail` | client → server | `protocolVersion, requestId` | invalidates challenge |
| `gc_identity:server:finalizeRegistration` | client → server | `protocolVersion, requestId` | atomic server commit |
| `gc_identity:server:completeProfile` | client → server | `protocolVersion, requestId, fullName` | legacy profile gate |
| `gc_identity:client:snapshot` | server → client | Public snapshot | server-origin guard |

## Restart и диагностика

Pending registration challenge хранится в MariaDB и восстанавливается по
server-derived binding. Verified challenge также восстанавливается, но не
финализируется автоматически. После restart `gc_core` manual recovery возвращает
player без live PED в `client_ready`; identity снова решает, можно ли освободить
spawn. Повторные hello/finalize/spawn hooks идемпотентны.

Основные коды: `GC-SPAWN-MANUAL-ONLY`,
`GC-IDENTITY-SPAWN-MODE-MISCONFIGURED`, `GC-IDENTITY-NAME-INVALID`,
`GC-IDENTITY-REGISTRATION-NOT-VERIFIED`,
`GC-IDENTITY-EMAIL-CHALLENGE-STALE`.
