# Руководство разработчика / Development Guide

## Уровень 1. Простыми словами

Это руководство для тех, кто хочет создавать Lua-модули для GreenCore.

## Уровень 2. Техническое объяснение

GreenCore — модульный движок.
Будущие модули — отдельные FiveM-ресурсы.

## Правила модульности

1. Каждый модуль — отдельный FiveM-ресурс.
2. Каждый модуль пишется только на Lua.
3. Модули не читают внутренние файлы друг друга.
4. Модули не изменяют внутренние таблицы друг друга.
5. Модули не используют общие глобальные переменные.
6. Взаимодействие через exports, события, callbacks.
7. Внутренняя логика `gc_core` не доступна напрямую.
8. Публичный API отделён от внутренней реализации.
9. API имеет версию.
10. Каждый публичный метод документирован.
11. Все данные из других ресурсов проверяются.
12. Перезапуск модуля не разрушает `gc_core`.
13. Названия событий имеют уникальный namespace.
14. Прямые зависимости модулей друг от друга запрещены.
15. `gc_core` не превращается в склад всех игровых систем.

## Стиль Lua-кода

### Обязательные правила

- Понятные названия.
- Небольшие функции.
- Одна функция — одна задача.
- Ранний возврат при ошибке.
- Минимальная вложенность.
- Отсутствие дублирования.
- Отсутствие магических чисел.
- Локальные переменные по умолчанию.
- Никакого `load` и `loadstring`.

### Плохо

```lua
RegisterNetEvent('a', function(d)
    if d then
        if type(d) == 'table' then
            if d.x then
                -- logic
            end
        end
    end
end)
```

### Хорошо

```lua
RegisterNetEvent('gc_core:server:clientReady', function(payload)
    local playerSource = source

    local isValid, errorCode = GCValidation.ClientReady(payload)
    if not isValid then
        GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
        return
    end

    GCConnection.HandleClientReady(playerSource, payload)
end)
```

## Производительность

Не создавать постоянные циклы с `Wait(0)` без необходимости.

### Плохо

```lua
while true do
    Wait(0)
end
```

### Хорошо

```lua
local startedAt = GetGameTimer()

while not HasModelLoaded(modelHash) do
    if GetGameTimer() - startedAt >= timeoutMs then
        return false, 'GC-SPAWN-MODEL-001'
    end

    Wait(100)
end
```

## Комментарии

Комментарии обязательны на русском и английском.

```lua
-- RU: Проверяем наличие активной серверной сессии игрока.
-- EN: Check whether the player has an active server-side session.
```

## Следующий шаг

Перейдите к [Глоссарию](17-glossary.md).