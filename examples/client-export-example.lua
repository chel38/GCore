-- RU: Пример использования клиентских возможностей gc_core.
-- EN: Example of using gc_core client capabilities.

-- RU: Этот файл показывает, как клиентский Lua-код взаимодействует с gc_core.
-- EN: This file shows how client Lua code interacts with gc_core.

-- RU: Пример: клиент запрашивает спавн у сервера.
-- EN: Example: the client requests a spawn from the server.
RegisterCommand('gcspawn', function()
    -- RU: Отправляем серверу запрос на спавн.
    -- EN: Send a spawn request to the server.
    TriggerServerEvent('gc_core:server:requestSpawn', {})
end, false)

-- RU: Пример: клиент сообщает об ошибке.
-- EN: Example: the client reports an error.
RegisterCommand('gcerror', function()
    -- RU: Отправляем серверу сообщение об ошибке.
    -- EN: Send an error report to the server.
    TriggerServerEvent('gc_core:server:reportClientError', {
        errorCode = 'GC-EXAMPLE-001'
    })
end, false)

-- RU: Пример: обработка уведомления от сервера.
-- EN: Example: handling a notification from the server.
RegisterNetEvent('gc_core:client:notify', function(payload)
    if type(payload) ~= 'table' then
        return
    end

    if type(payload.message) == 'string' then
        print('[Example] Notification: ' .. payload.message)
    end
end)