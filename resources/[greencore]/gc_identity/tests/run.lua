local networkHandlers = {}
local eventHandlers = {}
local publicExports = {}
local commands = {}
local clientEvents = {}
local serverEvents = {}
local nuiCallbacks = {}
local nuiMessages = {}
local droppedPlayers = {}
local legacyRaw
local legacyData
local currentTime = 1000
local onlinePlayers = {}
local focusState = false
local frozenState = false
local playerEndpoints = {}
local scheduledTimeouts = {}
local mailResponse
local mailPayload

local function deepCopy(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, child in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(child, seen)
    end

    return copy
end

local core = {
    apiVersion = 1,
    connected = {},
    ready = {},
    gameplay = {},
    identifiers = {}
}

function core:GetApiVersion()
    return self.apiVersion
end

function core:IsPlayerConnected(playerSource)
    return self.connected[playerSource] ~= false
end

function core:IsPlayerReady(playerSource)
    return self.ready[playerSource] ~= false
end

function core:CanUseGameplayFeatures(playerSource)
    return self.gameplay[playerSource] ~= false
end

function core:GetPlayerIdentifier(playerSource, identifierType)
    if identifierType ~= 'license' then
        return nil
    end

    if self.identifiers[playerSource] == false then
        return nil
    end

    return self.identifiers[playerSource] or ('license:test-%d'):format(playerSource)
end

exports = setmetatable({ gc_core = core }, {
    __call = function(_, name, handler)
        publicExports[name] = handler
    end
})

json = {
    encode = function(value)
        if type(value) == 'table' and value.email and value.code and value.type then
            mailPayload = deepCopy(value)
            return '__mail_payload__'
        end
        legacyData = deepCopy(value)
        return '__identity_json__'
    end,
    decode = function(raw)
        if raw == '__mail_success__' or raw == '__health_success__' then
            return { ok = true, status = 'sent' }
        end
        if raw ~= '__identity_json__' or legacyData == nil then
            error('invalid test JSON')
        end

        return deepCopy(legacyData)
    end
}

MySQL = {}

function GetCurrentResourceName()
    return 'gc_identity'
end

function GetResourceState(resourceName)
    if resourceName == 'gc_core' then
        return IdentityTest and IdentityTest.coreState or 'started'
    end

    if resourceName == 'oxmysql' then
        return IdentityTest and IdentityTest.oxmysqlState or 'started'
    end

    return 'started'
end

function LoadResourceFile(_, fileName)
    if fileName == GCIdentityConfig.storage.legacyFile then
        return legacyRaw
    end

    return nil
end

function GetGameTimer()
    return currentTime
end

function GetConvar(name, fallback)
    local values = {
        gcore_mail_service_url = 'http://127.0.0.1:8091',
        gcore_mail_token = string.rep('m', 32),
        gcore_identity_challenge_secret = string.rep('c', 32),
        gcore_ip_fingerprint_secret = string.rep('i', 32)
    }
    return values[name] or fallback
end

function GetPlayerEndpoint(playerSource)
    return playerEndpoints[playerSource] or '127.0.0.1:30120'
end

function GetPlayers()
    return deepCopy(onlinePlayers)
end

function RegisterNetEvent(name, handler)
    networkHandlers[name] = handler
end

function AddEventHandler(name, handler)
    eventHandlers[name] = eventHandlers[name] or {}
    table.insert(eventHandlers[name], handler)
end

function TriggerClientEvent(name, target, payload)
    table.insert(clientEvents, { name = name, target = target, payload = deepCopy(payload) })
end

function TriggerServerEvent(name, payload)
    table.insert(serverEvents, { name = name, payload = deepCopy(payload) })
end

function RegisterCommand(name, handler)
    commands[name] = handler
end

function RegisterNUICallback(name, handler)
    nuiCallbacks[name] = handler
end

function SendNUIMessage(payload)
    table.insert(nuiMessages, deepCopy(payload))
end

function SetNuiFocus(hasFocus)
    focusState = hasFocus == true
end

function PlayerPedId()
    return 1
end

function DoesEntityExist(entity)
    return entity == 1
end

function FreezeEntityPosition(_, frozen)
    frozenState = frozen == true
end

function DisableAllControlActions() end

function DropPlayer(playerSource, reason)
    table.insert(droppedPlayers, { source = playerSource, reason = reason })
end

function CreateThread(handler)
    handler()
end

function Wait(milliseconds)
    currentTime = currentTime + (milliseconds or 0)
end

function SetTimeout(milliseconds, handler)
    table.insert(scheduledTimeouts, {
        dueAt = currentTime + milliseconds,
        handler = handler
    })
end

function PerformHttpRequest(url, callback, method, body)
    if body == '__mail_payload__' then
        -- mailPayload was captured by json.encode.
    end
    local response = mailResponse
    if not response then
        response = method == 'GET'
            and { status = 200, body = '__health_success__' }
            or { status = 202, body = '__mail_success__' }
    end
    if not response.timeout then
        callback(response.status, response.body or '')
    end
end

IdentityTest = {
    core = core,
    publicExports = publicExports,
    commands = commands,
    coreState = 'started',
    oxmysqlState = 'started'
}

local function useMemoryRepository(resetData)
    GCIdentityConfig.storage.adapter = 'memory'
    GCIdentityConfig.storage.importLegacyJson = false
    GCIdentityConfig.client.restrictControls = false
    GCIdentityDatabase.Initialize()
    GCIdentityRepository.Initialize('memory')
    local memory = GCIdentityRepository.TestAdapter()

    if resetData then
        memory.Reset()
        GCIdentityRepository.Initialize('memory')
    end

    GCIdentityService.SetAvailable(true)
    return memory
end

function IdentityTest.Reset(resetData)
    currentTime = 1000
    onlinePlayers = {}
    clientEvents = {}
    serverEvents = {}
    nuiMessages = {}
    droppedPlayers = {}
    focusState = false
    frozenState = false
    playerEndpoints = {}
    scheduledTimeouts = {}
    mailResponse = nil
    mailPayload = nil
    legacyRaw = nil
    legacyData = nil
    IdentityTest.clientEvents = clientEvents
    IdentityTest.serverEvents = serverEvents
    IdentityTest.nuiMessages = nuiMessages
    IdentityTest.droppedPlayers = droppedPlayers
    IdentityTest.coreState = 'started'
    IdentityTest.oxmysqlState = 'started'
    core.apiVersion = 1
    core.connected = {}
    core.ready = {}
    core.gameplay = {}
    core.identifiers = {}
    GCIdentityStates.ClearAll()
    GCIdentityRateLimit.ClearAll()
    return useMemoryRepository(resetData ~= false)
end

function IdentityTest.Advance(milliseconds)
    currentTime = currentTime + milliseconds
    local remaining = {}
    for _, timeout in ipairs(scheduledTimeouts) do
        if timeout.dueAt <= currentTime then
            timeout.handler()
        else
            table.insert(remaining, timeout)
        end
    end
    scheduledTimeouts = remaining
end

function IdentityTest.SetEndpoint(playerSource, endpoint)
    playerEndpoints[playerSource] = endpoint
end

function IdentityTest.SetMailResponse(response)
    mailResponse = response and deepCopy(response) or nil
end

function IdentityTest.LastMailPayload()
    return deepCopy(mailPayload)
end

function IdentityTest.SetOnlinePlayers(players)
    onlinePlayers = deepCopy(players)
end

function IdentityTest.SetLegacyData(data)
    legacyData = deepCopy(data)
    legacyRaw = '__identity_json__'
end

function IdentityTest.EmitNetwork(name, eventSource, payload)
    local previousSource = source
    source = eventSource
    local handler = networkHandlers[name]

    if not handler then
        error('Missing network handler: ' .. name)
    end

    handler(payload)
    source = previousSource
end

function IdentityTest.DeliverClientEvent(event)
    IdentityTest.EmitNetwork(event.name, 65535, event.payload)
end

function IdentityTest.EmitEvent(name, eventSource, argument)
    local previousSource = source
    source = eventSource

    for _, handler in ipairs(eventHandlers[name] or {}) do
        handler(argument)
    end

    source = previousSource
end

function IdentityTest.InvokeNui(name, payload)
    local result
    local handler = nuiCallbacks[name]

    if not handler then
        error('Missing NUI callback: ' .. name)
    end

    handler(payload or {}, function(response)
        result = response
    end)
    return result
end

function IdentityTest.LastClientEvent()
    return clientEvents[#clientEvents]
end

function IdentityTest.LastServerEvent()
    return serverEvents[#serverEvents]
end

function IdentityTest.LastNuiMessage()
    return nuiMessages[#nuiMessages]
end

function IdentityTest.FocusState()
    return focusState
end

function IdentityTest.FrozenState()
    return frozenState
end

function IdentityTest.ReloadClient()
    eventHandlers.onClientResourceStart = {}
    eventHandlers.onClientResourceStop = {}
    GCModuleTest.Load('client/main.lua')
end

function IdentityTest.ResolveAndRegister(playerSource, email, requestId)
    local snapshot, resolveError = GCIdentityService.Resolve(playerSource)

    if not snapshot then
        return nil, resolveError
    end

    if snapshot.state == 'registration_required' then
        local _, registrationError = GCIdentityService.RegisterAccount(playerSource, {
            protocolVersion = GCIdentityVersion.protocol,
            requestId = requestId or ('register_%04d'):format(playerSource),
            email = email or ('player%d@example.test'):format(playerSource)
        })

        if registrationError then
            return nil, registrationError
        end

        snapshot = GCIdentityService.GetSnapshot(playerSource)
        if snapshot.state == 'email_verification_pending' then
            local delivered = IdentityTest.LastMailPayload()
            local _, verificationError = GCIdentityService.VerifyEmailCode(playerSource, {
                protocolVersion = GCIdentityVersion.protocol,
                requestId = (requestId or ('register_%04d'):format(playerSource)) .. '_verify',
                code = delivered and delivered.code or '000000'
            })
            if verificationError then
                return nil, verificationError
            end
            snapshot = GCIdentityService.GetSnapshot(playerSource)
        end
    end

    return snapshot
end

for _, fileName in ipairs({
    'shared/version.lua',
    'shared/config.lua'
}) do
    GCModuleTest.Load(fileName)
end

GCIdentityConfig.storage.adapter = 'memory'
GCIdentityConfig.storage.importLegacyJson = false
GCIdentityConfig.client.restrictControls = false

for _, fileName in ipairs({
    'shared/events.lua',
    'shared/client_security.lua',
    'server/logger.lua',
    'server/crypto.lua',
    'server/endpoint.lua',
    'server/security_config.lua',
    'server/mail_client.lua',
    'server/state.lua',
    'server/validation.lua',
    'server/rate_limit.lua',
    'server/migrations/registry.lua',
    'server/migrations/001_initial_identity.lua',
    'server/migrations/002_email_verification_security.lua',
    'server/database.lua',
    'server/repositories/memory.lua',
    'server/repositories/json_legacy.lua',
    'server/repositories/oxmysql.lua',
    'server/repository.lua',
    'server/service.lua',
    'server/api.lua',
    'server/events.lua',
    'server/exports.lua',
    'server/main.lua',
    'client/main.lua'
}) do
    GCModuleTest.Load(fileName)
end

for _, fileName in ipairs({
    'tests/state_test.lua',
    'tests/validation_test.lua',
    'tests/repository_test.lua',
    'tests/service_test.lua',
    'tests/verification_test.lua',
    'tests/security_test.lua',
    'tests/api_test.lua',
    'tests/migration_test.lua',
    'tests/restart_test.lua',
    'tests/nui_test.lua'
}) do
    GCModuleTest.Load(fileName)
end
