local networkHandlers = {}
local eventHandlers = {}
local publicExports = {}
local commands = {}
local clientEvents = {}
local serverEvents = {}
local storageRaw
local storageData
local saveFails = false
local currentTime = 1000
local onlinePlayers = {}

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
    gameplay = {}
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
    if identifierType == 'license' then
        return ('license:test-%d'):format(playerSource)
    end

    return nil
end

exports = setmetatable({ gc_core = core }, {
    __call = function(_, name, handler)
        publicExports[name] = handler
    end
})

json = {
    encode = function(value)
        storageData = deepCopy(value)
        return '__identity_json__'
    end,
    decode = function(raw)
        if raw ~= '__identity_json__' or storageData == nil then
            error('invalid test JSON')
        end

        return deepCopy(storageData)
    end
}

function GetCurrentResourceName()
    return 'gc_identity'
end

function GetResourceState(resourceName)
    if resourceName == 'gc_core' and IdentityTest and IdentityTest.coreState then
        return IdentityTest.coreState
    end

    return 'started'
end

function LoadResourceFile()
    return storageRaw
end

function SaveResourceFile(_, _, contents)
    if saveFails then
        return false
    end

    storageRaw = contents
    return true
end

function GetGameTimer()
    return currentTime
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

function CreateThread(handler)
    handler()
end

function Wait(milliseconds)
    currentTime = currentTime + (milliseconds or 0)
end

IdentityTest = {
    core = core,
    publicExports = publicExports,
    commands = commands,
    clientEvents = clientEvents,
    serverEvents = serverEvents,
    coreState = 'started'
}

function IdentityTest.Reset(clearStorage)
    if clearStorage ~= false then
        storageRaw = nil
        storageData = nil
    end

    saveFails = false
    currentTime = 1000
    onlinePlayers = {}
    clientEvents = {}
    serverEvents = {}
    IdentityTest.clientEvents = clientEvents
    IdentityTest.serverEvents = serverEvents
    IdentityTest.coreState = 'started'
    core.apiVersion = 1
    core.connected = {}
    core.ready = {}
    core.gameplay = {}
    GCIdentityStates.ClearAll()
    GCIdentityRateLimit.ClearAll()
    GCModuleTest.Load('server/repository.lua')
    local loaded, loadError = GCIdentityRepository.Load()
    GCIdentityService.SetAvailable(loaded)

    if not loaded then
        return false, loadError
    end

    return true
end

function IdentityTest.Advance(milliseconds)
    currentTime = currentTime + milliseconds
end

function IdentityTest.SetOnlinePlayers(players)
    onlinePlayers = deepCopy(players)
end

function IdentityTest.SetSaveFailure(value)
    saveFails = value == true
end

function IdentityTest.SetInvalidStorage()
    storageRaw = '__invalid__'
    storageData = nil
end

function IdentityTest.ReloadFromStorage()
    GCIdentityStates.ClearAll()
    GCIdentityRateLimit.ClearAll()
    GCModuleTest.Load('server/repository.lua')
    local loaded, loadError = GCIdentityRepository.Load()
    GCIdentityService.SetAvailable(loaded)
    return loaded, loadError
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

function IdentityTest.EmitLocal(name, eventSource, payload)
    return IdentityTest.EmitNetwork(name, eventSource, payload)
end

function IdentityTest.EmitEvent(name, eventSource, argument)
    local previousSource = source
    source = eventSource

    for _, handler in ipairs(eventHandlers[name] or {}) do
        handler(argument)
    end

    source = previousSource
end

function IdentityTest.LastClientEvent()
    return clientEvents[#clientEvents]
end

for _, fileName in ipairs({
    'shared/version.lua',
    'shared/config.lua',
    'shared/events.lua',
    'shared/client_security.lua',
    'server/logger.lua',
    'server/state.lua',
    'server/validation.lua',
    'server/rate_limit.lua',
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
    'tests/service_test.lua',
    'tests/security_test.lua',
    'tests/api_test.lua',
    'tests/restart_test.lua'
}) do
    GCModuleTest.Load(fileName)
end
