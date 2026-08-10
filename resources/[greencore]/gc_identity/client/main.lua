local currentSnapshot
local helloGeneration = 0
local helloAcknowledged = false
local requestSequence = 0

local function validSnapshot(payload)
    return type(payload) == 'table'
        and payload.protocolVersion == GCIdentityVersion.protocol
        and type(payload.state) == 'string'
        and type(payload.characters) == 'table'
end

local function nextRequestId()
    requestSequence = requestSequence + 1
    return ('identity_%d_%d'):format(GetGameTimer(), requestSequence)
end

local function startHello()
    helloGeneration = helloGeneration + 1
    local generation = helloGeneration
    helloAcknowledged = false

    CreateThread(function()
        for _ = 1, GCIdentityConfig.clientHello.maximumAttempts do
            if generation ~= helloGeneration or helloAcknowledged then
                return
            end

            TriggerServerEvent(GCIdentityEvents.server.hello, {
                protocolVersion = GCIdentityVersion.protocol
            })
            Wait(GCIdentityConfig.clientHello.retryIntervalMs)
        end
    end)
end

GCIdentityClientSecurity.RegisterServerEvent(
    GCIdentityEvents.client.snapshot,
    function(payload)
        if not validSnapshot(payload) then
            return
        end

        currentSnapshot = payload
        helloAcknowledged = true
        print(('[GC][IDENTITY] state=%s characters=%d'):format(
            payload.state,
            #payload.characters
        ))
    end
)

GCIdentityClientSecurity.RegisterServerEvent(
    GCIdentityEvents.client.rejected,
    function(payload)
        if type(payload) ~= 'table' or type(payload.code) ~= 'string' then
            return
        end

        print(('[GC][IDENTITY] request rejected: %s'):format(payload.code))
    end
)

RegisterCommand('gcidentity', function()
    startHello()
end, false)

RegisterCommand('gccreate', function(_, arguments)
    TriggerServerEvent(GCIdentityEvents.server.createCharacter, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = nextRequestId(),
        firstName = arguments[1],
        lastName = arguments[2]
    })
end, false)

RegisterCommand('gcselect', function(_, arguments)
    TriggerServerEvent(GCIdentityEvents.server.selectCharacter, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = nextRequestId(),
        characterId = tonumber(arguments[1])
    })
end, false)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == 'gc_core' then
        startHello()
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'gc_core' then
        helloGeneration = helloGeneration + 1
        helloAcknowledged = false
        currentSnapshot = nil
    end
end)
