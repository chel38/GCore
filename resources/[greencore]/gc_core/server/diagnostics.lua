-- RU: Сервис диагностики GreenCore (серверная часть).
-- EN: GreenCore diagnostics service (server side).

-- RU: Таблица сервиса диагностики.
-- EN: Diagnostics service table.
GCDiagnostics = {}

--- RU:
--- Сообщает о невалидном payload от игрока.
---
--- EN:
--- Reports an invalid payload from a player.
---
--- @param playerSource number FiveM server player source
--- @param errorCode string Error code
function GCDiagnostics.ReportInvalidPayload(playerSource, errorCode)
    -- RU: Записываем предупреждение в лог.
    -- EN: Write a warning to the log.
    GCLogger.Warn('GC-PAYLOAD-100', 'Invalid payload received', {
        source = playerSource,
        errorCode = errorCode
    })
end

--- RU:
--- Выводит сводку по активным сессиям.
---
--- EN:
--- Prints a summary of active sessions.
---
--- @return number count Number of active sessions
function GCDiagnostics.PrintSessionSummary()
    local count = GCSessions.Count()

    GCLogger.Info('GC-DIAG-100', 'Active sessions summary', {
        count = count
    })

    return count
end