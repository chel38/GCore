# gc_identity

`gc_identity` — независимый server-authoritative domain аккаунтов и персонажей
GCore. `gc_core` отвечает за connection/session/spawn, а этот resource — за
регистрацию, авторизацию по trusted identifier, персонажей и identity readiness.

- Resource version: `0.3.0-alpha`
- Identity API: `1` (backward-compatible)
- Identity protocol: `2` (обязательный email verification handshake)
- Требуемый Core API: `>= 1`
- Persistence: MariaDB через `oxmysql`
- NUI: TypeScript + Tailwind CSS

## Что реализовано

Первое подключение:

```text
trusted server-side FiveM license
            ↓
аккаунта нет → email → одноразовый code от сервера
            ↓
verified challenge → transaction создаёт account
            ↓
создание/выбор своего персонажа
            ↓
identity state = ready
```

Повторное подключение:

```text
trusted license + тот же server-observed IP → автоматический вход
trusted license + новый IP → email code → авторизация
```

Пароли на этом этапе намеренно отключены. Модуль не собирает, не передаёт, не
хранит и не имитирует проверку пароля. Client-provided identifier, account ID,
authorization state и утверждение ownership никогда не считаются trusted.

## Установка

1. Установите release build `oxmysql` как resource `oxmysql`.
2. Запустите MariaDB и создайте отдельные database/user.
3. Задайте connection string вне репозитория:

```cfg
set mysql_connection_string "mysql://gcore:CHANGE_ME@127.0.0.1:3306/gcore?charset=utf8mb4"
set gcore_mail_service_url "http://127.0.0.1:8091"
set gcore_mail_token "token-совпадающий-с-mail-service"
set gcore_identity_challenge_secret "отдельный-random-secret-минимум-32-символа"
set gcore_ip_fingerprint_secret "другой-random-secret-минимум-32-символа"
ensure oxmysql
ensure gc_core
ensure gc_identity
```

Не коммитьте credentials. При старте `gc_identity` применяет упорядоченные
идемпотентные migrations. Если MariaDB/oxmysql или migration недоступны, модуль
остаётся в явном degraded state и никогда молча не переключается на JSON.

Старый adapter `data/identities.json` используется только как read-only источник
миграции. При `storage.importLegacyJson = true` записи импортируются
идемпотентно и должны завершить email verification. Перед production migration
сделайте backup MariaDB и legacy file.

До verification flows запустите отдельный localhost-only
[GCore Mail Service](../../../mail-service/README.ru.md). Same-IP вход не зависит
от почты; registration и new-IP login при её отказе всегда fail-closed.

## NUI и команды

При eager-загрузке HTML в FiveM NUI использует прозрачный canvas документа и явно
скрытый root. JavaScript сначала подтверждает `ready`, после чего Lua повторно
отправляет последний authoritative snapshot.
Только non-ready snapshot может открыть UI, получить focus и заморозить локальное
представление PED. Snapshot `ready` остаётся скрытым и снимает focus/freeze. NUI
callbacks только формируют запросы; lifecycle, exact schema, rate, replay ID и
ownership проверяет сервер.

Database degradation и исчерпание bounded hello показывают диагностический экран
с retry/exit. Если JavaScript bundle не подтвердил readiness, client снимает focus,
а server выполняет один validated controlled disconnect вместо вечного чёрного
экрана.

Диагностические команды сохранены:

- `/gcidentity` — запросить свежий snapshot;
- `/gcregister email@example.com` — запросить регистрацию;
- `/gcverify 483921` — отправить verification code;
- `/gccreate Имя Фамилия` — запросить создание персонажа;
- `/gcselect ID` — запросить выбор.

## State machine

```text
uninitialized → loading → registration_required → registering
                         → email_verification_pending → registering
loading → auth_verification_required → loading
                         ↘ authorized → character_required
                                         ↓
                                  character_selected → ready

active state → error/disconnecting (только валидные transitions)
```

## Public server API v1

| Export | Возвращает |
| --- | --- |
| `GetIdentityVersion()` | resource version string |
| `GetIdentityApiVersion()` | integer API version |
| `GetIdentityProtocolVersion()` | integer protocol version |
| `GetIdentityHealth()` | detached health DTO |
| `IsAuthorized(source)` | boolean |
| `IsIdentityReady(source)` | boolean |
| `GetIdentityState(source)` | state или `nil` |
| `GetAccount(source)` | detached Account DTO или `nil` |
| `GetCharacters(source)` | массив detached Character DTO |
| `GetSelectedCharacter(source)` | detached Character DTO или `nil` |

Account DTO: `id`, `email`, `status`, `createdAt`. Character DTO: `id`,
`firstName`, `lastName`, `createdAt`. Trusted identifiers, database metadata,
rate-limit state, replay cache и внутренние ссылки не пересекают public boundary.
Все DTO — копии.

```lua
local coreReady = exports.gc_core:CanUseGameplayFeatures(source)
local identityReady = exports.gc_identity:IsIdentityReady(source)

if not coreReady or not identityReady then
    return
end
```

## Network contract

Client → server (internal): `hello`, `registerAccount`, `verifyEmail`,
`resendVerification`, `createCharacter`, `selectCharacter`, allowlisted `clientFailure`, `exit`. Только server → client
(internal): `snapshot`, `rejected`. Exact schemas находятся в `shared/events.lua` и
`server/validation.lua`. Server-only client handlers требуют FiveM origin
`source == 65535`.

## Restart policy

`restart gc_identity` выполняет bounded recovery online players. DB-backed
challenges переживают restart до TTL и привязываются к новой runtime session;
persisted account/selection сохраняются. При рестарте `gc_core` FiveM останавливает declared
dependants; затем оператор должен выполнить `ensure gc_identity`. Это поведение
resource dependency FiveM, а не потеря данных.

## Разработка

```sh
lua tools/module_test_harness.lua . gc_identity
cd resources/[greencore]/gc_identity/web
pnpm install --frozen-lockfile
pnpm test
pnpm build
```

См. [design](../../../docs/ru/modules/gc_identity/design.md),
[persistence design](../../../docs/ru/modules/gc_identity/persistence-design.md) и
[implementation report](../../../docs/ru/modules/gc_identity/implementation-report.md),
а также [NUI lifecycle audit](../../../docs/ru/modules/gc_identity/nui-lifecycle-audit.md).
Security flow описан в документе
[email verification](../../../docs/ru/modules/gc_identity/email-verification.md).

## Troubleshooting

- `GC-IDENTITY-DATABASE-UNAVAILABLE`: проверьте MariaDB, connection string и
  порядок `ensure oxmysql`.
- `GC-IDENTITY-MIGRATION-FAILED`: найдите первую упавшую migration; не обходите
  её fallback-ом.
- `GC-IDENTITY-EMAIL-TAKEN`: normalized email уже занят.
- `GC-IDENTITY-EMAIL-CODE-INVALID/EXPIRED/ATTEMPTS`: нужен правильный/новый code.
- `GC-IDENTITY-MAIL-SEND-FAILED/TIMEOUT`: проверьте localhost mail-service и SMTP.
- `GC-IDENTITY-PROTOCOL-MISMATCH`: client/server builds различаются.
- `GC-IDENTITY-HELLO-TIMEOUT`: authoritative identity response не пришёл за
  bounded retry window; проверьте core и database health.
- `GC-IDENTITY-NUI-NOT-READY`: собранный JavaScript не вызвал NUI-ready callback;
  пересоберите `web/dist` и проверьте FiveM client log.
- resource остановился после `restart gc_core`: выполните `ensure gc_identity`.
