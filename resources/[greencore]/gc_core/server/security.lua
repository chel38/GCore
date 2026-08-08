-- RU: Сервис безопасности GreenCore.
-- EN: GreenCore security service.

-- RU: Таблица сервиса безопасности.
-- EN: Security service table.
GCSecurity = {}

-- RU: Флаг блокировки подключений.
-- EN: Connection blocking flag.
local connectionsBlocked = false

--- RU:
--- Блокирует новые подключения.
---
--- EN:
--- Blocks new connections.
---
--- @param reason string|nil Reason for blocking
function GCSecurity.BlockConnections(reason)
    connectionsBlocked = true

    GCLogger.Warn('GC-SECURITY-100', 'Connections blocked', {
        reason = reason
    })
end

--- RU:
--- Разблокирует новые подключения.
---
--- EN:
--- Unblocks new connections.
function GCSecurity.UnblockConnections()
    connectionsBlocked = false

    GCLogger.Info('GC-SECURITY-101', 'Connections unblocked')
end

--- RU:
--- Проверяет, заблокированы ли подключения.
---
--- EN:
--- Checks whether connections are blocked.
---
--- @return boolean blocked Whether connections are blocked
function GCSecurity.AreConnectionsBlocked()
    return connectionsBlocked
end

--- RU:
--- Проверяет, остановлен ли ресурс.
---
--- EN:
--- Checks whether the resource is stopping.
---
--- @return boolean stopping Whether the resource is stopping
function GCSecurity.IsResourceStopping()
    return GetResourceState(GCConstants.resourceName) == 'stopping'
end