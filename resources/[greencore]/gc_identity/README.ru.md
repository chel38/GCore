# gc_identity

`gc_identity` — независимый server-authoritative domain аккаунтов и персонажей
GCore. `gc_core` отвечает за connection/session/spawn, а этот resource — за
регистрацию, авторизацию по trusted identifier, персонажей и identity readiness.

- Resource version: `0.2.1-alpha`
- Identity API: `1` (backward-compatible, добавлен health export)
- Identity protocol: `1`
- Требуемый Core API: `>= 1`
- Persistence: MariaDB через `oxmysql`
- NUI: TypeScript + Tailwind CSS

## Что реализовано

Первое подключение:

```text
trusted server-side FiveM license
            ↓
аккаунта нет → явная регистрация email
            ↓
создание/выбор своего персонажа
            ↓
identity state = ready
```

Повторное подключение:

```text
trusted license → сохранённый аккаунт → сохранённый выбор → ready
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
ensure oxmysql
ensure gc_core
ensure gc_identity
```

Не коммитьте credentials. При старте `gc_identity` применяет упорядоченные
идемпотентные migrations. Если MariaDB/oxmysql или migration недоступны, модуль
остаётся в явном degraded state и никогда молча не переключается на JSON.

Старый adapter `data/identities.json` используется только как read-only источник
миграции. При `storage.importLegacyJson = true` записи импортируются
идемпотентно и должны завершить email registration. Перед production migration
сделайте backup MariaDB и legacy file.

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
- `/gccreate Имя Фамилия` — запросить создание персонажа;
- `/gcselect ID` — запросить выбор.

## State machine

```text
uninitialized → loading → registration_required → registering
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

Client → server (internal): `hello`, `registerAccount`, `createCharacter`,
`selectCharacter`, allowlisted `clientFailure`, `exit`. Только server → client
(internal): `snapshot`, `rejected`. Exact schemas находятся в `shared/events.lua` и
`server/validation.lua`. Server-only client handlers требуют FiveM origin
`source == 65535`.

## Restart policy

`restart gc_identity` выполняет bounded recovery online players и восстанавливает
persisted account/selection. При рестарте `gc_core` FiveM останавливает declared
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

## Troubleshooting

- `GC-IDENTITY-DATABASE-UNAVAILABLE`: проверьте MariaDB, connection string и
  порядок `ensure oxmysql`.
- `GC-IDENTITY-MIGRATION-FAILED`: найдите первую упавшую migration; не обходите
  её fallback-ом.
- `GC-IDENTITY-EMAIL-TAKEN`: normalized email уже занят.
- `GC-IDENTITY-PROTOCOL-MISMATCH`: client/server builds различаются.
- `GC-IDENTITY-HELLO-TIMEOUT`: authoritative identity response не пришёл за
  bounded retry window; проверьте core и database health.
- `GC-IDENTITY-NUI-NOT-READY`: собранный JavaScript не вызвал NUI-ready callback;
  пересоберите `web/dist` и проверьте FiveM client log.
- resource остановился после `restart gc_core`: выполните `ensure gc_identity`.
