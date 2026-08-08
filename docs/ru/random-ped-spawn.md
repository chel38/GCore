# Случайный выбор PED / Random PED Spawn

## Уровень 1. Простыми словами

Когда игрок подключается, **модель персонажа выбирает сервер**.

Представьте коробку с карточками:

```
[Business Man]
[Hipster]
[Beach Ped]
[Business Woman]
```

Сервер случайно вытаскивает одну карточку.

После этого клиент получает **уже выбранную** модель.

Клиент **не может** сказать серверу: "Я хочу другую модель".

## Почему это важно

- Сервер — источник истины (SERVER = SOURCE OF TRUTH).
- Клиент никогда не доверяется.
- Если бы клиент выбирал модель, игрок мог бы появиться с любым ped, включая
  сюжетных персонажей или несуществующие модели.

## Как это работает

### 1. Белый список моделей

В `config/spawn.lua` задаётся явный список допустимых моделей:

```lua
GCConfig.Spawn.randomPed = {
    enabled = true,
    avoidImmediateRepeat = true,
    models = {
        'a_m_y_business_01',
        'a_m_y_business_02',
        'a_m_y_hipster_01',
        'a_m_y_beach_01',
        'a_f_y_business_01'
    }
}
```

### 2. Сервер выбирает модель

Сервер выбирает случайную модель **только из этого списка**:

```lua
local pedDefinition = GCPedProvider.Resolve(playerSource, session)
-- pedDefinition = { name = 'a_m_y_business_01', hash = 0x... }
```

### 3. Решение о спавне

Сервер создаёт `spawnDecision`, который содержит выбранный ped:

```lua
local spawnDecision = {
    id = 'gc:spawn:...',
    sessionId = 'gc:session:...',
    source = playerSource,
    position = { x = ..., y = ..., z = ..., heading = ... },
    ped = {
        name = 'a_m_y_business_01',
        hash = 0x...
    },
    createdAt = os.time(),
    expiresAt = os.time() + 30,
    confirmed = false,
    consumed = false
}
```

### 4. Клиент получает готовое решение

Клиент получает событие `spawnApproved` с уже выбранным `ped`.
Клиент **не** передаёт серверу свою модель.

## Защита от повтора

Если игрок уже появился с `a_m_y_business_01`, при следующем полном спавне
сервер постарается выбрать другую модель (`avoidImmediateRepeat`).

## Запасной вариант (fallback)

Если случайный список пуст или модель не загружается, используется:

```lua
GCConfig.Spawn.fallbackPed = 'mp_m_freemode_01'
```

Сервер **сам** решает, когда использовать fallback. Клиент не выбирает его.

## Будущее

Сегодня выбор модели — это случайный ped из белого списка.
В будущем модуль `gc_appearance` сможет заменить его системой персонажа.

Поэтому выбор модели вынесен в отдельный провайдер `GCPedProvider`, и его можно
заменить, не переписывая весь spawn service.

## Связанные разделы

- [Поток спавна](07-spawn-flow.md)
- [Конфигурация](08-configuration.md)
- [Состояния игрока](06-player-states.md)