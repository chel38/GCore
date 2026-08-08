-- RU: Пример использования серверных событий gc_core.
-- EN: Example of using gc_core server events.

-- RU: Этот файл показывает, как будущий Lua-модуль может реагировать на события gc_core.
-- EN: This file shows how a future Lua module can react to gc_core events.

-- RU: Пример: обработка подключения игрока.
-- EN: Example: handling a player connection.
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    -- RU: Этот обработчик срабатывает до обработчика gc_core.
    -- EN: This handler fires before the gc_core handler.
    print(('[Example] Player %s is connecting'):format(playerName))
end)

-- RU: Пример: обработка отключения игрока.
-- EN: Example: handling a player disconnection.
AddEventHandler('playerDropped', function(reason)
    local playerSource = source

    print(('[Example] Player %s dropped: %s'):format(playerSource, tostring(reason)))
end)

-- RU: Пример: использование события готовности клиента.
-- EN: Example: using the client readiness event.
RegisterNetEvent('gc_core:server:clientReady', function(payload)
    local playerSource = source

    print(('[Example] Player %s client is ready'):format(playerSource))
end)