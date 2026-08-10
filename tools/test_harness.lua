-- Standalone Lua 5.4 harness for CI. It emulates only the FiveM boundaries used
-- by gc_core unit/integration tests; gameplay natives remain owned by FXServer.

local root = arg[1] or '.'
local resourceRoot = root .. '/resources/[greencore]/gc_core/'
local fakeTime = 1000
local clientEvents = {}
local registeredClientHandlers = {}
local timers = {}
local droppedPlayers = {}
local loadingScreenShutdowns = { nui = 0, game = 0 }

GCTestHarness = {}

function IsDuplicityVersion() return true end
function GetGameTimer() return fakeTime end
function Wait(milliseconds) fakeTime = fakeTime + (milliseconds or 0) end
function CreateThread(callback) callback() end
function SetTimeout(milliseconds, callback)
    timers[#timers + 1] = {
        dueAt = fakeTime + math.max(0, milliseconds or 0),
        callback = callback
    }
end
function GetCurrentResourceName() return 'gc_core' end
function GetResourceState() return 'started' end
function GetConvarInt(_, defaultValue) return defaultValue end
function GetPlayers() return {} end
function GetPlayerName(source) return 'Player' .. tostring(source) end
function GetNumPlayerIdentifiers() return 0 end
function GetPlayerIdentifier() return nil end
function GetPlayerPed() return 0 end
function PlayerId() return 0 end
function PlayerPedId() return 0 end
function NetworkIsSessionStarted() return false end
function NetworkIsPlayerActive() return false end
function DoesEntityExist() return false end
function NetworkGetEntityOwner() return -1 end
function GetEntityHealth() return 0 end
function GetEntityModel() return 0 end
function GetEntityCoords() return { x = 0.0, y = 0.0, z = 0.0 } end
function DropPlayer(playerSource, reason)
    droppedPlayers[#droppedPlayers + 1] = { playerSource, reason }
end
function TriggerClientEvent(eventName, target, payload)
    clientEvents[#clientEvents + 1] = { eventName, target, payload }
end
function TriggerServerEvent() end
function ShutdownLoadingScreenNui()
    loadingScreenShutdowns.nui = loadingScreenShutdowns.nui + 1
end
function ShutdownLoadingScreen()
    loadingScreenShutdowns.game = loadingScreenShutdowns.game + 1
end

function RegisterNetEvent(eventName, handler)
    registeredClientHandlers[eventName] = handler
end

function TriggerEvent(eventName, payload)
    local handler = registeredClientHandlers[eventName]

    if not handler then
        return nil
    end

    local previousSource = source
    source = 0
    local result = handler(payload)
    source = previousSource
    return result
end

function GCTestHarness.RunTimersUntil(targetTime)
    while true do
        local nextIndex = nil
        local nextDueAt = nil

        for index, timer in ipairs(timers) do
            if timer.dueAt <= targetTime and (not nextDueAt or timer.dueAt < nextDueAt) then
                nextIndex = index
                nextDueAt = timer.dueAt
            end
        end

        if not nextIndex then
            break
        end

        local timer = table.remove(timers, nextIndex)
        fakeTime = timer.dueAt
        timer.callback()
    end

    fakeTime = targetTime
end

function GCTestHarness.NowMs()
    return fakeTime
end

function GCTestHarness.GetDroppedPlayers()
    return droppedPlayers
end

function GCTestHarness.ClearDroppedPlayers()
    droppedPlayers = {}
end

function GCTestHarness.EmitServerClientEvent(eventName, payload)
    local handler = registeredClientHandlers[eventName]

    if not handler then
        return nil
    end

    local previousSource = source
    source = 65535
    local result = handler(payload)
    source = previousSource
    return result
end

function GCTestHarness.GetLoadingScreenShutdowns()
    return {
        nui = loadingScreenShutdowns.nui,
        game = loadingScreenShutdowns.game
    }
end

function joaat(value)
    local hash = 0

    for index = 1, #value do
        hash = (hash * 33 + value:byte(index)) % 2147483647
    end

    return hash
end

local function loadFile(relativePath)
    local path = resourceRoot .. relativePath
    local file, openError = io.open(path, 'rb')

    if not file then
        error(('Unable to open %s: %s'):format(path, openError))
    end

    local sourceCode = file:read('*a')
    file:close()

    -- FiveM backtick hashes are a CfxLua extension. Translate them for stock Lua.
    sourceCode = sourceCode:gsub('`([^`\r\n]+)`', "joaat('%1')")
    local chunk, loadError = load(sourceCode, '@' .. relativePath, 't', _ENV)

    if not chunk then
        error(('Unable to compile %s: %s'):format(relativePath, loadError))
    end

    return chunk()
end

local runtimeFiles = {
    'config/general.lua',
    'config/connection.lua',
    'config/spawn.lua',
    'config/security.lua',
    'config/logging.lua',
    'config/diagnostics.lua',
    'locales/en.lua',
    'locales/ru.lua',
    'shared/bootstrap.lua',
    'shared/runtime.lua',
    'shared/version.lua',
    'shared/constants.lua',
    'shared/errors.lua',
    'shared/utils.lua',
    'shared/ids.lua',
    'shared/events.lua',
    'shared/client_security.lua',
    'shared/locale.lua',
    'shared/logger.lua',
    'shared/validation.lua',
    'server/bootstrap.lua',
    'server/identifiers.lua',
    'server/sessions.lua',
    'server/states.lua',
    'server/rate_limit.lua',
    'server/security.lua',
    'server/ped_provider.lua',
    'server/spawn_location.lua',
    'server/connection.lua',
    'server/spawn_retry.lua',
    'server/spawn.lua',
    'server/players.lua',
    'server/notifications.lua',
    'server/api.lua',
    'server/diagnostics.lua'
}

local testFiles = {
    'tests/test_runner.lua',
    'tests/validation_test.lua',
    'tests/states_test.lua',
    'tests/sessions_test.lua',
    'tests/connection_test.lua',
    'tests/spawn_test.lua',
    'tests/spawn_verification_integration_test.lua',
    'tests/protocol_test.lua',
    'tests/ped_provider_test.lua',
    'tests/logger_test.lua',
    'tests/rate_limit_test.lua',
    'tests/notifications_test.lua',
    'tests/runtime_test.lua',
    'tests/client_event_security_test.lua',
    'tests/loading_screen_test.lua',
    'tests/api_test.lua'
}

for _, fileName in ipairs(runtimeFiles) do loadFile(fileName) end

loadFile('client/state.lua')
loadFile('client/readiness.lua')
loadFile('client/loading.lua')
-- Register the real production client handlers. Local TriggerEvent reaches the
-- actual wrapper but must stop before any client-only side effect or dependency.
loadFile('client/events.lua')

for _, fileName in ipairs(testFiles) do loadFile(fileName) end

if not GCTest.Run() then
    os.exit(1)
end
