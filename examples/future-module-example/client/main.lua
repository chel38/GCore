-- RU: Пример клиентской логики будущего Lua-модуля GreenCore.
-- EN: Example client logic for a future GreenCore Lua module.

-- RU: Пример команды модуля.
-- EN: Example module command.
RegisterCommand('gcfeature', function()
    -- RU: Отправляем серверу запрос на использование функции.
    -- EN: Send a request to the server to use the feature.
    TriggerServerEvent('gc_example:server:useFeature')
end, false)