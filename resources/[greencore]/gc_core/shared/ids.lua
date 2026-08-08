-- RU: ID используются только для корреляции и никогда не являются секретами.
-- EN: IDs are correlation values only and are never authentication secrets.

GCIds = {}

local sequence = 0

local function nextId(prefix)
    sequence = sequence + 1
    local timePart = type(GetGameTimer) == 'function' and GetGameTimer() or 0
    local randomPart = math.random(0, 0x7fffffff)

    return ('%s:%x:%x:%x'):format(prefix, timePart, sequence, randomPart)
end

function GCIds.NewCorrelationId(prefix)
    return nextId(prefix or 'gc:correlation')
end

function GCIds.NewSessionId()
    return nextId(GCConstants.sessionPrefix)
end

function GCIds.NewSpawnDecisionId()
    return nextId(GCConstants.spawnPrefix)
end
