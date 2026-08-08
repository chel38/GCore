-- RU: Testable implementation of the public server API.
-- EN: Testable implementation of the public server API.

GCAPI = {}

local function validSource(playerSource)
    return GCUtils.IsInteger(playerSource) and playerSource > 0
end

function GCAPI.GetVersion()
    return GCVersion.GetPublicDto()
end

function GCAPI.GetVersionString()
    return GCVersion.GetString()
end

function GCAPI.GetApiVersion()
    return GCVersion.GetApiVersion()
end

function GCAPI.GetProtocolVersion()
    return GCVersion.GetProtocolVersion()
end

function GCAPI.IsPlayerConnected(playerSource)
    return validSource(playerSource) and GCSessions.Exists(playerSource)
end

function GCAPI.IsPlayerReady(playerSource)
    if not validSource(playerSource) then
        return false
    end

    return GCStates.Is(playerSource, 'client_ready')
        or GCStates.Is(playerSource, 'spawn_pending')
        or GCStates.Is(playerSource, 'spawning')
        or GCStates.Is(playerSource, 'spawn_confirming')
        or GCStates.Is(playerSource, 'spawned')
        or GCStates.Is(playerSource, 'resyncing')
end

function GCAPI.IsPlayerSpawned(playerSource)
    return validSource(playerSource) and GCStates.Is(playerSource, 'spawned')
end

function GCAPI.GetPlayerState(playerSource)
    return validSource(playerSource) and GCStates.Get(playerSource) or nil
end

function GCAPI.GetPlayerSession(playerSource)
    return validSource(playerSource) and GCSessions.GetPublicDTO(playerSource) or nil
end

function GCAPI.GetPlayerIdentifier(playerSource, identifierType)
    if not validSource(playerSource)
        or type(identifierType) ~= 'string'
        or not GCUtils.Contains(GCConstants.identifierTypes, identifierType) then
        return nil
    end

    return GCIdentifiers.GetByType(playerSource, identifierType)
end

function GCAPI.CanUseGameplayFeatures(playerSource)
    return GCAPI.IsPlayerSpawned(playerSource)
end

function GCAPI.RequestPlayerSpawn(playerSource)
    if not validSource(playerSource) then
        return nil, 'GC-PAYLOAD-TYPE-001'
    end

    return GCSpawn.Request(playerSource)
end

function GCAPI.NotifyPlayer(playerSource, message, notificationType)
    if not validSource(playerSource) then
        return false, 'GC-NOTIFY-001'
    end

    return GCNotifications.SendToPlayer(playerSource, message, notificationType)
end

function GCAPI.NotifyAll(message, notificationType)
    return GCNotifications.SendToAll(message, notificationType)
end
