# Контракт модулей GCore v1

Этот контракт — граница между `gc_core` и независимыми ресурсами, например будущими
`gc_identity`, `gc_admin` или `gc_characters`. Это ещё не полноценный SDK.

## Правило

```text
FiveM → gc_core lifecycle → Public API v1 → independent module
```

Модуль может зависеть от API v1. Он не зависит от internal tables, filenames или
текущего resource patch `0.x`.

## Обязательная проверка при старте

```lua
local REQUIRED_API_VERSION = 1

local function validateCoreApi()
    if GetResourceState('gc_core') ~= 'started' then
        return false, 'gc_core is not started'
    end

    local apiVersion = exports.gc_core:GetApiVersion()

    if apiVersion < REQUIRED_API_VERSION then
        return false, ('GCore API v%d required; found v%d'):format(
            REQUIRED_API_VERSION,
            apiVersion
        )
    end

    return true
end
```

Требуйте API `1`, а не ровно resource `0.1.3-alpha`. Resource и API versions
разделены, чтобы совместимые patch/minor releases не останавливали модули.

## Разрешено

- Вызывать exports из [Public Server API v1](09-server-api.md).
- Читать отделённый Public Player DTO.
- Проверять `CanUseGameplayFeatures(playerSource)` в каждой gameplay entry point.
- Использовать `GetPlayerState` только для read-only diagnostics/gating.
- Отправлять уведомления через `NotifyPlayer`/`NotifyAll`.
- Повторять API check после `onResourceStart` для `gc_core`.
- Считать stopped core или `nil` DTO временной недоступностью и безопасно
  отклонять операцию модуля.

## Запрещено

- `dofile`, `loadfile` и прямые imports из `gc_core/server/*`.
- Чтение/изменение `GCSessions`, `GCStates`, `GCSpawn`, decisions, security или
  rate-limit tables.
- Прямое присваивание lifecycle state и подделка decision/event payloads.
- Доверие client identifiers, position, PED state или success reports.
- Хранение Public DTO как live state: при необходимости запросите новый DTO.
- Отправка внутренних server→client protocol events из модуля.

## Gameplay availability в API v1

`CanUseGameplayFeatures(source) == true` означает только, что authoritative
lifecycle gc_core равен `spawned`. API v1 **не обещает** наличие identity,
character, account, permissions или database state. Будущие модули добавляют свои
server-side условия после core check.

```lua
if not exports.gc_core:CanUseGameplayFeatures(source) then
    return false, 'PLAYER_NOT_GAMEPLAY_READY'
end

-- Затем модуль проверяет собственное server-owned state.
```

## Рестарты

Во время рестарта `gc_core` exports временно недоступны, а sessions
восстанавливаются. Модуль не кэширует internal/session reference через рестарт.
Считайте core недоступным, после старта повторите API v1 check и запросите свежий
state/DTO до gameplay. Не создавайте собственный recovery handshake и не
полагайтесь на timing `forceResync`.

API v1 пока не обещает public server lifecycle hook. Проверяйте public state в
момент запроса операции.

## Данные и identifiers

`GetPlayerSession` намеренно исключает identifiers и чувствительные internals.
`GetPlayerIdentifier` доступен только серверу и возвращает один captured identifier
или `nil`. Никогда не доверяйте client-supplied identifier и не пересылайте
license/IP/Discord клиенту без документированной privacy/authorization причины.

## Security baseline

1. Client input никогда не authoritative.
2. Каждый network payload валидируется сервером точной schema и limits.
3. Gameplay state проверяется через Public API.
4. Module state принадлежит серверу.
5. Модуль не меняет gc_core session state и не подделывает spawn decisions.
6. Async work ограничивается и отменяется при disconnect, module/core stop или
   смене state.

См. [политику совместимости API](20-api-compatibility.md).
