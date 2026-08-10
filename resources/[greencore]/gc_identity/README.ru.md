# gc_identity

`gc_identity` определяет, кем является подключённый игрок GCore. `gc_core`
владеет connection/session/spawn lifecycle, а этот независимый модуль — аккаунтом
по license, списком персонажей, выбранным персонажем и identity state.

Версия: `0.1.0-alpha`
Identity API: `1`
Identity protocol: `1`
Требуемый Core API: `>= 1`

## Scope

MVP автоматически находит или создаёт аккаунт через trusted server-side core
identifier. Игрок может создать до трёх персонажей и выбрать одного. Здесь нет
паролей, NUI, ролей, денег, inventory, jobs или общей database layer.

## Установка

Resource объявляет `dependency 'gc_core'`:

```cfg
ensure gc_core
ensure gc_identity
```

После административного `restart gc_core` FiveM останавливает declared dependants.
Затем выполните `ensure gc_identity`: модуль проведёт bounded recovery online players
и восстановит сохранённый выбор персонажа.

Runtime-данные сохраняются в `data/identities.json` и игнорируются Git. Их нужно
резервировать как другие приватные server data.

## Команды

- `/gcidentity` — запросить свежий identity snapshot.
- `/gccreate Имя Фамилия` — создать персонажа после core spawn.
- `/gcselect ID` — выбрать принадлежащего текущему аккаунту персонажа.

Команды — только минимальная alpha interaction surface. Сервер проверяет payload,
lifecycle, ownership, rate limit и replay ID. NUI для MVP не нужен.

## Public server API v1

| Export | Возвращает |
| --- | --- |
| `GetIdentityVersion()` | resource version string |
| `GetIdentityApiVersion()` | integer API version |
| `GetIdentityProtocolVersion()` | integer protocol version |
| `IsAuthorized(source)` | состояние account resolution |
| `IsIdentityReady(source)` | readiness выбранного персонажа |
| `GetIdentityState(source)` | state или `nil` |
| `GetAccount(source)` | detached Account DTO или `nil` |
| `GetCharacters(source)` | массив detached Character DTO |
| `GetSelectedCharacter(source)` | detached Character DTO или `nil` |

Проверка в downstream module:

```lua
local coreReady = exports.gc_core:CanUseGameplayFeatures(source)
local identityReady = exports.gc_identity:IsIdentityReady(source)

if not coreReady or not identityReady then
    return
end
```

Account DTO содержит только `id` и `createdAt`. Character DTO содержит `id`,
`firstName`, `lastName`, `createdAt`. Identifier и persistence metadata не
являются public.

## Events и security

Client → server: `hello`, `createCharacter`, `selectCharacter` из registry
`shared/events.lua`. Server → client: `snapshot`, `rejected`. Server-only client
handlers проверяют `source == 65535`. Каждый ingress payload проходит exact
schema, protocol 1, bounded rate и server-side ownership validation.

См. полный [design](../../../docs/ru/modules/gc_identity/design.md),
[Module Contract](../../../docs/ru/module-contract.md) и тесты:

```sh
lua tools/module_test_harness.lua . gc_identity
```

## Troubleshooting

- `GC-IDENTITY-CORE-*`: проверьте, что `gc_core` запущен и API не ниже 1.
- `GC-IDENTITY-STORAGE-*`: проверьте writable data directory и private JSON.
- `GC-IDENTITY-PROTOCOL-MISMATCH`: client/server resource builds различаются.
- `GC-IDENTITY-RATE-LIMIT`: дождитесь сброса bounded request window.
- Модуль остановлен после `restart gc_core`: выполните `ensure gc_identity` согласно
  документированному dependency restart sequence.
