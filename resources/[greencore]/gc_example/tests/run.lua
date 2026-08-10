local resourceState = 'started'
local registeredCommand
local eventHandlers = {}
local calls = {}

local function record(name)
    calls[name] = (calls[name] or 0) + 1
end

local core = {}

function core:GetVersion()
    record('GetVersion')
    return {
        version = '0.1.3-alpha',
        apiVersion = 1,
        protocolVersion = 1
    }
end

function core:GetVersionString()
    record('GetVersionString')
    return '0.1.3-alpha'
end

function core:GetApiVersion()
    record('GetApiVersion')
    return self.apiVersion or 1
end

function core:GetProtocolVersion()
    record('GetProtocolVersion')
    return 1
end

function core:IsPlayerConnected()
    record('IsPlayerConnected')
    return self.connected ~= false
end

function core:IsPlayerReady()
    record('IsPlayerReady')
    return true
end

function core:IsPlayerSpawned()
    record('IsPlayerSpawned')
    return true
end

function core:GetPlayerState()
    record('GetPlayerState')
    return self.state or 'spawned'
end

function core:GetPlayerSession(playerSource)
    record('GetPlayerSession')
    return { source = playerSource, state = self.state or 'spawned' }
end

function core:CanUseGameplayFeatures()
    record('CanUseGameplayFeatures')
    return self.gameplay ~= false
end

function core:NotifyPlayer(playerSource, message, notificationType)
    record('NotifyPlayer')
    self.lastNotification = {
        source = playerSource,
        message = message,
        notificationType = notificationType
    }
    return true
end

exports = { gc_core = core }

function GetResourceState()
    return resourceState
end

function GetCurrentResourceName()
    return 'gc_example'
end

function RegisterCommand(_, handler)
    registeredCommand = handler
end

function AddEventHandler(name, handler)
    eventHandlers[name] = handler
end

GCModuleTest.Load('shared/config.lua')
GCModuleTest.Load('server/main.lua')

local function reset()
    resourceState = 'started'
    core.apiVersion = 1
    core.connected = true
    core.gameplay = true
    core.state = 'spawned'
    core.lastNotification = nil
    calls = {}
end

GCModuleTest.Register('example.compatibility_uses_api_version', 'contract', function()
    reset()
    local metadata, checkError = GCExample.CheckCompatibility()
    GCModuleTest.ExpectNotNil(metadata, 'compatible core is accepted')
    GCModuleTest.ExpectNil(checkError, 'compatible core has no error')
    GCModuleTest.ExpectEqual(metadata.apiVersion, 1, 'API contract is used')
    GCModuleTest.ExpectEqual(calls.GetApiVersion, 1, 'GetApiVersion is queried')
end)

GCModuleTest.Register('example.incompatible_api_fails_closed', 'contract', function()
    reset()
    core.apiVersion = 0
    local metadata, checkError = GCExample.CheckCompatibility()
    GCModuleTest.ExpectNil(metadata, 'old API is rejected')
    GCModuleTest.ExpectEqual(
        checkError,
        'GC-EXAMPLE-CORE-API-INCOMPATIBLE',
        'incompatible API has stable code'
    )
end)

GCModuleTest.Register('example.core_restart_fails_safely', 'integration', function()
    reset()
    resourceState = 'stopped'
    local result, inspectError = GCExample.InspectPlayer(7)
    GCModuleTest.ExpectNil(result, 'stopped core creates no result')
    GCModuleTest.ExpectEqual(
        inspectError,
        'GC-EXAMPLE-CORE-UNAVAILABLE',
        'stopped core has stable error'
    )
end)

GCModuleTest.Register('example.player_flow_uses_public_contract', 'integration', function()
    reset()
    local result, inspectError = GCExample.InspectPlayer(7)
    GCModuleTest.ExpectNotNil(result, 'spawned player gets a snapshot')
    GCModuleTest.ExpectNil(inspectError, 'valid example request has no error')
    GCModuleTest.ExpectEqual(result.state, 'spawned', 'public player state is returned')
    GCModuleTest.ExpectEqual(result.session.source, 7, 'public DTO is used')
    GCModuleTest.ExpectEqual(core.lastNotification.source, 7, 'public NotifyPlayer is used')

    for _, method in ipairs({
        'GetVersion',
        'GetVersionString',
        'GetApiVersion',
        'GetProtocolVersion',
        'IsPlayerConnected',
        'IsPlayerReady',
        'IsPlayerSpawned',
        'GetPlayerState',
        'GetPlayerSession',
        'CanUseGameplayFeatures',
        'NotifyPlayer'
    }) do
        GCModuleTest.ExpectEqual(calls[method], 1, method .. ' was called exactly once')
    end
end)

GCModuleTest.Register('example.gameplay_gate_rejects', 'security', function()
    reset()
    core.gameplay = false
    local result, inspectError = GCExample.InspectPlayer(8)
    GCModuleTest.ExpectNil(result, 'unready player gets no module result')
    GCModuleTest.ExpectEqual(
        inspectError,
        'GC-EXAMPLE-GAMEPLAY-NOT-READY',
        'gameplay gate has stable code'
    )
    GCModuleTest.ExpectNil(core.lastNotification, 'rejected operation has no side effect')
end)

GCModuleTest.Register('example.invalid_source_rejects', 'security', function()
    reset()
    local result, inspectError = GCExample.InspectPlayer('7')
    GCModuleTest.ExpectNil(result, 'invalid source gets no result')
    GCModuleTest.ExpectEqual(
        inspectError,
        'GC-EXAMPLE-SOURCE-INVALID',
        'invalid source has stable code'
    )
end)

GCModuleTest.Register('example.command_is_registered', 'runtime', function()
    GCModuleTest.ExpectEqual(type(registeredCommand), 'function', 'server command exists')
    GCModuleTest.ExpectEqual(type(eventHandlers.onResourceStart), 'function', 'restart handler exists')
end)
