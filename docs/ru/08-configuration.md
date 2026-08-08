# Конфигурация

Runtime-конфигурация находится в `resources/[greencore]/gc_core/config/` и
загружается как Lua. Версии ресурса, API и протокола здесь не дублируются:
единственный источник — `shared/version.lua`.

| Файл | Назначение |
| --- | --- |
| `general.lua` | locale, debug, development mode, opt-in тестов |
| `connection.lua` | deferral, pending, clientReady и resync timeout |
| `spawn.lua` | точка, белый список ped, retry и server verification |
| `security.lua` | лимиты действий и окно нарушений |
| `logging.lua` | уровень и маскирование чувствительных данных |
| `diagnostics.lua` | диагностические сообщения |

Критичные настройки spawn verification:

```lua
verification = {
    enabled = true,
    timeoutMs = 3000,
    intervalMs = 100,
    maxAttempts = 31,
    positionTolerance = 8.0,
    minimumHealth = 1
}
```

Не отключайте `verification.enabled` на публичном сервере. Подтверждение клиента
содержит только `decisionId`; сервер сам читает OneSync entity, ownership, model,
health и координаты.

Retry использует `maxTotalAttempts`, `maxSamePedRetries` и
`maxDifferentPedRetries`. Только MODEL error добавляет PED в
`attemptedPedModels`. ENTITY/COLLISION/POSITION/TIMEOUT могут повторить тот же PED;
DECISION/SESSION/SECURITY и unknown failure отклоняются. Каждый retry получает новый
decision ID.

Recovery prompts ограничены `resyncForceMaxAttempts` и
`resyncForceIntervalMs`, общий предел — `resyncReadyTimeoutMs`. Проактивный
clientReady означает, что recovery не зависит от доставки prompt.

Повторы initial/recovery hello используют `clientHelloRetryIntervalMs` и
`clientHelloMaxAttempts`, а `clientReadyTimeoutMs` остаётся общим непродлеваемым
deadline. Валидный lifecycle ACK отменяет единственный client retry thread.

Rate-limit задаётся отдельно для `clientReady`, `requestSpawn`, `confirmSpawn`,
`reportClientError` и `resyncReady`. `violationWindowMs` удаляет старые нарушения;
`maxViolationsPerWindow` не является пожизненным счётчиком сессии.

Для production оставьте:

```lua
GCConfig.General.developmentMode = false
GCConfig.Tests.enabled = false
```

Перейдите к [серверному API](09-server-api.md).
