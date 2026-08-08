-- RU: Сервис уведомлений GreenCore.
-- EN: GreenCore notification service.

-- RU: Таблица сервиса уведомлений.
-- EN: Notification service table.
GCNotifications = {}

-- RU: Имя клиентского события уведомления.
-- EN: Client notification event name.
local NOTIFY_EVENT = 'gc_core:client:notify'

-- RU: Максимальная длина сообщения уведомления.
-- EN: Maximum notification message length.
local MAX_MESSAGE_LENGTH = 256

-- RU: Максимальная длина типа уведомления.
-- EN: Maximum notification type length.
local MAX_TYPE_LENGTH = 32

-- RU: Список допустимых типов уведомлений.
-- EN: List of allowed notification types.
local ALLOWED_TYPES = {
    'info',
    'success',
    'warning',
    'error'
}

--- RU:
--- Проверяет, является ли тип уведомления допустимым.
---
--- EN:
--- Checks whether a notification type is allowed.
---
--- @param notificationType string Notification type
--- @return boolean allowed Whether the type is allowed
local function IsAllowedType(notificationType)
    if type(notificationType) ~= 'string' then
        return false
    end

    for _, allowedType in ipairs(ALLOWED_TYPES) do
        if allowedType == notificationType then
            return true
        end
    end

    return false
end

--- RU:
--- Отправляет уведомление конкретному игроку.
---
--- EN:
--- Sends a notification to a specific player.
---
--- @param playerSource number FiveM server player source
--- @param message string Notification message
--- @param notificationType string|nil Notification type (info, success, warning, error)
--- @return boolean success Whether the notification was sent
--- @return string|nil errorCode Error code
function GCNotifications.SendToPlayer(playerSource, message, notificationType)
    -- RU: Проверяем source игрока.
    -- EN: Validate the player source.
    if type(playerSource) ~= 'number' then
        return false, 'GC-NOTIFY-001'
    end

    -- RU: Проверяем сообщение.
    -- EN: Validate the message.
    if type(message) ~= 'string' or #message == 0 then
        return false, 'GC-NOTIFY-002'
    end

    -- RU: Ограничиваем длину сообщения.
    -- EN: Limit the message length.
    if #message > MAX_MESSAGE_LENGTH then
        message = GCUtils.Truncate(message, MAX_MESSAGE_LENGTH)
    end

    -- RU: Проверяем тип уведомления.
    -- EN: Validate the notification type.
    if notificationType == nil then
        notificationType = 'info'
    end

    if not IsAllowedType(notificationType) then
        return false, 'GC-NOTIFY-003'
    end

    -- RU: Проверяем, что игрок подключён.
    -- EN: Verify that the player is connected.
    if not GCSessions.Exists(playerSource) then
        return false, 'GC-NOTIFY-004'
    end

    -- RU: Отправляем уведомление клиенту.
    -- EN: Send the notification to the client.
    TriggerClientEvent(NOTIFY_EVENT, playerSource, {
        message = message,
        type = notificationType
    })

    return true
end

--- RU:
--- Отправляет уведомление всем подключённым игрокам.
---
--- EN:
--- Sends a notification to all connected players.
---
--- @param message string Notification message
--- @param notificationType string|nil Notification type (info, success, warning, error)
--- @return boolean success Whether the notification was sent
--- @return string|nil errorCode Error code
function GCNotifications.SendToAll(message, notificationType)
    -- RU: Проверяем сообщение.
    -- EN: Validate the message.
    if type(message) ~= 'string' or #message == 0 then
        return false, 'GC-NOTIFY-002'
    end

    -- RU: Ограничиваем длину сообщения.
    -- EN: Limit the message length.
    if #message > MAX_MESSAGE_LENGTH then
        message = GCUtils.Truncate(message, MAX_MESSAGE_LENGTH)
    end

    -- RU: Проверяем тип уведомления.
    -- EN: Validate the notification type.
    if notificationType == nil then
        notificationType = 'info'
    end

    if not IsAllowedType(notificationType) then
        return false, 'GC-NOTIFY-003'
    end

    -- RU: Отправляем уведомление всем клиентам.
    -- EN: Send the notification to all clients.
    TriggerClientEvent(NOTIFY_EVENT, -1, {
        message = message,
        type = notificationType
    })

    return true
end