-- RU: Минимальная защита клиентских событий, которые разрешено отправлять
-- RU: исключительно серверу FiveM. Локальный TriggerEvent имеет другой source.
-- EN: Minimal guard for client events that may originate only from the FiveM
-- EN: server. A local TriggerEvent has a different source.

GCClientSecurity = {}

local SERVER_EVENT_SOURCE = 65535

--- @param eventSource any FiveM event source
--- @return boolean isServerOrigin
function GCClientSecurity.IsServerEventSource(eventSource)
    return eventSource == SERVER_EVENT_SOURCE
end

--- RU: Оборачивает server-only клиентский handler проверкой источника.
--- EN: Wraps a server-only client handler with an origin check.
--- @param handler function
--- @return function guardedHandler
function GCClientSecurity.GuardServerEvent(handler)
    assert(type(handler) == 'function', 'server event handler must be a function')

    return function(...)
        if not GCClientSecurity.IsServerEventSource(source) then
            return false
        end

        handler(...)
        return true
    end
end

--- RU: Единая точка регистрации SERVER -> CLIENT событий.
--- EN: Single registration point for SERVER -> CLIENT events.
--- @param eventName string
--- @param handler function
function GCClientSecurity.RegisterServerEvent(eventName, handler)
    RegisterNetEvent(eventName, GCClientSecurity.GuardServerEvent(handler))
end
