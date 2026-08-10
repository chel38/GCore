-- EN: gc_example intentionally uses only documented gc_core server exports.
-- RU: gc_example намеренно использует только документированные server exports gc_core.

GCExample = {}

local function validSource(playerSource)
    return type(playerSource) == 'number'
        and playerSource > 0
        and playerSource % 1 == 0
end

local function readCoreMetadata()
    if GetResourceState('gc_core') ~= 'started' then
        return nil, 'GC-EXAMPLE-CORE-UNAVAILABLE'
    end

    local ok, metadata, metadataError = pcall(function()
        local core = exports['gc_core']
        local apiVersion = core:GetApiVersion()

        if type(apiVersion) ~= 'number'
            or apiVersion % 1 ~= 0
            or apiVersion < GCExampleConfig.requiredCoreApi then
            return nil, 'GC-EXAMPLE-CORE-API-INCOMPATIBLE'
        end

        return {
            version = core:GetVersion(),
            versionString = core:GetVersionString(),
            apiVersion = apiVersion,
            protocolVersion = core:GetProtocolVersion()
        }
    end)

    if not ok then
        return nil, 'GC-EXAMPLE-CORE-UNAVAILABLE'
    end

    return metadata, metadataError
end

function GCExample.CheckCompatibility()
    return readCoreMetadata()
end

function GCExample.InspectPlayer(playerSource)
    if not validSource(playerSource) then
        return nil, 'GC-EXAMPLE-SOURCE-INVALID'
    end

    local metadata, metadataError = readCoreMetadata()

    if not metadata then
        return nil, metadataError
    end

    local ok, result, resultError = pcall(function()
        local core = exports['gc_core']

        if not core:IsPlayerConnected(playerSource) then
            return nil, 'GC-EXAMPLE-PLAYER-NOT-CONNECTED'
        end

        local snapshot = {
            core = metadata,
            connected = true,
            ready = core:IsPlayerReady(playerSource),
            spawned = core:IsPlayerSpawned(playerSource),
            state = core:GetPlayerState(playerSource),
            session = core:GetPlayerSession(playerSource)
        }

        if not core:CanUseGameplayFeatures(playerSource) then
            return nil, 'GC-EXAMPLE-GAMEPLAY-NOT-READY'
        end

        local notified, notifyError = core:NotifyPlayer(
            playerSource,
            ('gc_example: core=%s, API=%d, state=%s'):format(
                metadata.versionString,
                metadata.apiVersion,
                tostring(snapshot.state)
            ),
            'info'
        )

        if not notified then
            return nil, notifyError or 'GC-EXAMPLE-NOTIFY-FAILED'
        end

        return snapshot
    end)

    if not ok then
        return nil, 'GC-EXAMPLE-CORE-UNAVAILABLE'
    end

    return result, resultError
end

RegisterCommand(GCExampleConfig.command, function(playerSource)
    if playerSource == 0 then
        local metadata, compatibilityError = GCExample.CheckCompatibility()

        if metadata then
            print(('[GC][EXAMPLE] gc_core %s / API %d / protocol %d'):format(
                metadata.versionString,
                metadata.apiVersion,
                metadata.protocolVersion
            ))
        else
            print(('[GC][EXAMPLE] compatibility check failed: %s'):format(
                tostring(compatibilityError)
            ))
        end

        return
    end

    local _, inspectError = GCExample.InspectPlayer(playerSource)

    if inspectError then
        print(('[GC][EXAMPLE] request rejected: source=%d code=%s'):format(
            playerSource,
            inspectError
        ))
    end
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'gc_core' and resourceName ~= GetCurrentResourceName() then
        return
    end

    local metadata, compatibilityError = GCExample.CheckCompatibility()

    if metadata then
        print(('[GC][EXAMPLE] ready: gc_core API %d'):format(metadata.apiVersion))
    else
        print(('[GC][EXAMPLE] unavailable: %s'):format(tostring(compatibilityError)))
    end
end)
