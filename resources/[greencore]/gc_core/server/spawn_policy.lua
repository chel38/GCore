-- RU: Универсальная политика выдачи spawn без знания о domain-модулях.
-- EN: Generic spawn release policy with no knowledge of domain modules.

GCSpawnPolicy = {}

local allowedModes = {
    automatic = true,
    manual = true
}

function GCSpawnPolicy.GetMode()
    local configured = GCConfig.Spawn and GCConfig.Spawn.mode or 'automatic'
    local override = type(GetConvar) == 'function'
        and GetConvar('gcore_spawn_mode', '') or ''
    local mode = override ~= '' and override or configured

    if not allowedModes[mode] then
        return 'automatic'
    end

    return mode
end

function GCSpawnPolicy.IsManual()
    return GCSpawnPolicy.GetMode() == 'manual'
end

function GCSpawnPolicy.ConnectionPayload()
    return {
        apiVersion = GCVersion.GetApiVersion(),
        protocolVersion = GCVersion.GetProtocolVersion(),
        spawnMode = GCSpawnPolicy.GetMode()
    }
end
