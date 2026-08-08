-- RU: Пример использования клиентских событий gc_core.
-- EN: Example of using gc_core client events.

-- RU: Этот файл показывает, как клиентский Lua-код реагирует на события gc_core.
-- EN: This file shows how client Lua code reacts to gc_core events.

-- RU: Пример: обработка подтверждения подключения.
-- EN: Example: handling the connection acceptance.
RegisterNetEvent('gc_core:client:connectionAccepted', function(payload)
    print('[Example] Connection accepted by gc_core')

    if type(payload) == 'table' then
        print(('[Example] API version: %s'):format(tostring(payload.apiVersion)))
    end
end)

-- RU: Пример: обработка одобрения спавна.
-- EN: Example: handling the spawn approval.
RegisterNetEvent('gc_core:client:spawnApproved', function(payload)
    print('[Example] Spawn approved by gc_core')

    if type(payload) == 'table' then
        print(('[Example] Decision ID: %s'):format(tostring(payload.decisionId)))
    end
end)

-- RU: Пример: обработка отклонения спавна.
-- EN: Example: handling the spawn rejection.
RegisterNetEvent('gc_core:client:spawnRejected', function(payload)
    print('[Example] Spawn rejected by gc_core')

    if type(payload) == 'table' then
        print(('[Example] Error code: %s'):format(tostring(payload.errorCode)))
    end
end)

-- RU: Пример: обработка принудительной ресинхронизации.
-- EN: Example: handling the force resync.
RegisterNetEvent('gc_core:client:forceResync', function()
    print('[Example] gc_core requested a resync')
end)