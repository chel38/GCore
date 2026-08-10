GCIdentityClientSecurity = {}

function GCIdentityClientSecurity.IsServerEventSource(eventSource)
    return eventSource == 65535
end

function GCIdentityClientSecurity.RegisterServerEvent(eventName, handler)
    RegisterNetEvent(eventName, function(payload)
        if not GCIdentityClientSecurity.IsServerEventSource(source) then
            return
        end

        handler(payload)
    end)
end
