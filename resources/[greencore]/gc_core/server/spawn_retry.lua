-- RU: Декларативная политика ошибок спавна. Категория определяет действие,
-- RU: поэтому несвязанные ошибки больше не blacklist текущую PED model.
-- EN: Declarative spawn failure policy. The category determines the action, so
-- EN: unrelated failures no longer blacklist the current PED model.

GCSpawnRetryPolicy = {}

GCSpawnRetryPolicy.Actions = {
    NEW_PED = 'NEW_PED',
    SAME_PED = 'SAME_PED',
    REJECT = 'REJECT'
}

local policies = {
    ['GC-SPAWN-PED-INVALID-001'] = { category = 'MODEL', action = 'NEW_PED' },
    ['GC-SPAWN-PED-LOAD-001'] = { category = 'MODEL', action = 'NEW_PED' },
    ['GC-SPAWN-PED-TIMEOUT-001'] = { category = 'MODEL', action = 'NEW_PED' },
    ['GC-SPAWN-VERIFY-MODEL-001'] = { category = 'MODEL', action = 'NEW_PED' },
    ['GC-SPAWN-MODEL-MISMATCH'] = { category = 'MODEL', action = 'NEW_PED' },

    ['GC-SPAWN-ENTITY-MISSING'] = { category = 'ENTITY', action = 'SAME_PED' },
    ['GC-SPAWN-ENTITY-DEAD'] = { category = 'ENTITY', action = 'SAME_PED' },
    ['GC-SPAWN-COLLISION-001'] = { category = 'COLLISION', action = 'SAME_PED' },
    ['GC-SPAWN-VERIFY-POSITION-001'] = { category = 'POSITION', action = 'SAME_PED' },
    ['GC-SPAWN-POSITION-MISMATCH'] = { category = 'POSITION', action = 'SAME_PED' },
    ['GC-SPAWN-VERIFY-001'] = { category = 'VERIFICATION', action = 'SAME_PED' },
    ['GC-SPAWN-VERIFY-TIMEOUT'] = { category = 'TIMEOUT', action = 'SAME_PED' },
    ['GC-SPAWN-TIMEOUT-001'] = { category = 'TIMEOUT', action = 'SAME_PED' },

    ['GC-SPAWN-DECISION-001'] = { category = 'DECISION', action = 'REJECT' },
    ['GC-SPAWN-DECISION-UNKNOWN'] = { category = 'DECISION', action = 'REJECT' },
    ['GC-SPAWN-DECISION-EXPIRED-001'] = { category = 'DECISION', action = 'REJECT' },
    ['GC-SPAWN-DECISION-CONSUMED-001'] = { category = 'DECISION', action = 'REJECT' },
    ['GC-SPAWN-DECISION-SOURCE-MISMATCH'] = { category = 'DECISION', action = 'REJECT' },
    ['GC-SPAWN-DECISION-SESSION-MISMATCH'] = { category = 'SESSION', action = 'REJECT' },
    ['GC-SPAWN-SESSION-CHANGED'] = { category = 'SESSION', action = 'REJECT' },
    ['GC-SESSION-001'] = { category = 'SESSION', action = 'REJECT' },
    ['GC-SPAWN-STATE-001'] = { category = 'SESSION', action = 'REJECT' },
    ['GC-SPAWN-OWNER-001'] = { category = 'SECURITY', action = 'REJECT' },
    ['GC-SPAWN-OWNER-MISMATCH'] = { category = 'SECURITY', action = 'REJECT' }
}

--- @param errorCode string
--- @return table policy Immutable-by-copy policy DTO
function GCSpawnRetryPolicy.Resolve(errorCode)
    local policy = policies[errorCode]

    if not policy then
        return { category = 'UNKNOWN', action = GCSpawnRetryPolicy.Actions.REJECT }
    end

    return { category = policy.category, action = policy.action }
end

--- @param errorCode string
--- @return boolean terminalForVerification
function GCSpawnRetryPolicy.IsTerminalVerificationError(errorCode)
    local action = GCSpawnRetryPolicy.Resolve(errorCode).action
    return action == GCSpawnRetryPolicy.Actions.NEW_PED
        or action == GCSpawnRetryPolicy.Actions.REJECT
end
