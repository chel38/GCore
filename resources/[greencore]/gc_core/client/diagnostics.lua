-- RU: Клиентский сервис диагностики GreenCore.
-- EN: GreenCore client diagnostics service.

-- RU: Таблица клиентского сервиса диагностики.
-- EN: Client diagnostics service table.
GCClientDiagnostics = {}

--- RU:
--- Сообщает серверу об ошибке клиента.
---
--- EN:
--- Reports a client error to the server.
---
--- @param errorCode string Error code
function GCClientDiagnostics.Report(errorCode)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(errorCode) ~= 'string' then
        return
    end

    -- RU: Записываем ошибку в локальный лог.
    -- EN: Log the error locally.
    GCLogger.Warn('GC-CLIENT-100', 'Client error', {
        errorCode = errorCode
    })

    -- RU: Отправляем ошибку серверу.
    -- EN: Send the error to the server.
    TriggerServerEvent(GCEvents.Server.reportClientError, {
        errorCode = errorCode
    })
end
