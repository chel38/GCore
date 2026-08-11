-- RU: Таблица ошибок GreenCore.
-- EN: GreenCore error table.

-- RU: Каждая ошибка имеет код, ключ локализации, уровень серьёзности и флаг публичности.
-- EN: Each error has a code, a localization key, a severity level, and a public flag.

GCErrors = {
    -- RU: Ошибки загрузки.
    -- EN: Boot errors.
    ['GC-BOOT-001'] = {
        localeKey = 'error.internal',
        severity = 'critical',
        public = false
    },

    -- RU: Ошибки подключения.
    -- EN: Connection errors.
    ['GC-CONNECTION-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },
    ['GC-CONNECTION-002'] = {
        localeKey = 'connection.license_missing',
        severity = 'error',
        public = true
    },
    ['GC-CONNECTION-003'] = {
        localeKey = 'connection.duplicate',
        severity = 'error',
        public = true
    },
    ['GC-CONNECTION-004'] = {
        localeKey = 'connection.timeout',
        severity = 'error',
        public = true
    },
    ['GC-CONNECTION-005'] = {
        localeKey = 'connection.server_stopping',
        severity = 'error',
        public = true
    },

    -- RU: Ошибки идентификаторов.
    -- EN: Identifier errors.
    ['GC-IDENTIFIER-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки сессий.
    -- EN: Session errors.
    ['GC-SESSION-001'] = {
        localeKey = 'error.session_not_found',
        severity = 'error',
        public = false
    },
    ['GC-SESSION-002'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки состояний.
    -- EN: State errors.
    ['GC-STATE-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки payload.
    -- EN: Payload errors.
    ['GC-PAYLOAD-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-SCHEMA-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-NUMBER-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },

    -- RU: Ошибки rate limit.
    -- EN: Rate limit errors.
    ['GC-RATE-LIMIT-001'] = {
        localeKey = 'error.rate_limited',
        severity = 'warn',
        public = false
    },

    -- RU: Ошибки спавна.
    -- EN: Spawn errors.
    ['GC-SPAWN-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = true
    },
    ['GC-SPAWN-002'] = {
        localeKey = 'spawn.rejected',
        severity = 'error',
        public = true
    },
    ['GC-SPAWN-003'] = {
        localeKey = 'spawn.expired',
        severity = 'error',
        public = true
    },
    ['GC-SPAWN-OWNER-001'] = {
        localeKey = 'spawn.rejected',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-STATE-001'] = {
        localeKey = 'spawn.rejected',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-VERIFY-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },
    ['GC-SPAWN-VERIFY-MODEL-001'] = {
        localeKey = 'spawn.failed',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-VERIFY-POSITION-001'] = {
        localeKey = 'spawn.failed',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-ENTITY-MISSING'] = {
        localeKey = 'spawn.failed', severity = 'warn', public = false
    },
    ['GC-SPAWN-ENTITY-DEAD'] = {
        localeKey = 'spawn.failed', severity = 'warn', public = false
    },
    ['GC-SPAWN-OWNER-MISMATCH'] = {
        localeKey = 'spawn.rejected', severity = 'warn', public = false
    },
    ['GC-SPAWN-MODEL-MISMATCH'] = {
        localeKey = 'spawn.failed', severity = 'warn', public = false
    },
    ['GC-SPAWN-POSITION-MISMATCH'] = {
        localeKey = 'spawn.failed', severity = 'warn', public = false
    },
    ['GC-SPAWN-VERIFY-TIMEOUT'] = {
        localeKey = 'spawn.failed', severity = 'error', public = false
    },
    ['GC-SPAWN-SESSION-CHANGED'] = {
        localeKey = 'spawn.rejected', severity = 'warn', public = false
    },
    ['GC-SPAWN-PED-EXHAUSTED-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },
    ['GC-SPAWN-MANUAL-ONLY'] = {
        localeKey = 'spawn.rejected',
        severity = 'warn',
        public = true
    },

    -- RU: Ошибки клиента.
    -- EN: Client errors.
    ['GC-CLIENT-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },
    ['GC-CLIENT-READY-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },
    ['GC-CLIENT-SPAWN-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },
    ['GC-CLIENT-SPAWN-002'] = {
        localeKey = 'spawn.rejected',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-TIMEOUT-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки безопасности.
    -- EN: Security errors.
    ['GC-SECURITY-001'] = {
        localeKey = 'error.internal',
        severity = 'critical',
        public = false
    },

    -- RU: Внутренние ошибки.
    -- EN: Internal errors.
    ['GC-INTERNAL-001'] = {
        localeKey = 'error.internal',
        severity = 'critical',
        public = false
    },

    -- RU: Ошибки валидации payload.
    -- EN: Payload validation errors.
    ['GC-PAYLOAD-TYPE-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-VERSION-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-VERSION-002'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-PROTOCOL-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-PROTOCOL-002'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-LOCALE-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-LOCALE-002'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-DECISION-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-DECISION-002'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-ERROR-001'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },
    ['GC-PAYLOAD-ERROR-002'] = {
        localeKey = 'error.invalid_payload',
        severity = 'warn',
        public = false
    },

    -- RU: Ошибки уведомлений.
    -- EN: Notification errors.
    ['GC-NOTIFY-001'] = {
        localeKey = 'error.internal',
        severity = 'warn',
        public = false
    },
    ['GC-NOTIFY-002'] = {
        localeKey = 'error.internal',
        severity = 'warn',
        public = false
    },
    ['GC-NOTIFY-003'] = {
        localeKey = 'error.internal',
        severity = 'warn',
        public = false
    },
    ['GC-NOTIFY-004'] = {
        localeKey = 'error.session_not_found',
        severity = 'warn',
        public = false
    },

    -- RU: Ошибки deferrals (playerConnecting).
    -- EN: Deferral errors (playerConnecting).
    ['GC-CONNECTION-DEFERRAL-001'] = {
        localeKey = 'connection.rejected',
        severity = 'error',
        public = true
    },

    -- RU: Ошибки pending connection.
    -- EN: Pending connection errors.
    ['GC-CONNECTION-PENDING-001'] = {
        localeKey = 'connection.rejected',
        severity = 'error',
        public = true
    },
    ['GC-CONNECTION-PENDING-002'] = {
        localeKey = 'connection.timeout',
        severity = 'warn',
        public = false
    },

    -- RU: Ошибки playerJoining / миграции source.
    -- EN: playerJoining / source migration errors.
    ['GC-JOIN-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },
    ['GC-JOIN-002'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },

    -- RU: Несовместимая версия протокола.
    -- EN: Incompatible protocol version.
    ['GC-PROTOCOL-MISMATCH-001'] = {
        localeKey = 'protocol.mismatch',
        severity = 'error',
        public = true
    },

    -- RU: Ошибки конфигурации random ped.
    -- EN: Random ped configuration errors.
    ['GC-SPAWN-PED-CONFIG-001'] = {
        localeKey = 'spawn.failed',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-PED-INVALID-001'] = {
        localeKey = 'spawn.failed',
        severity = 'warn',
        public = false
    },
    ['GC-SPAWN-PED-LOAD-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },
    ['GC-SPAWN-PED-TIMEOUT-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки коллизии при спавне.
    -- EN: Spawn collision errors.
    ['GC-SPAWN-COLLISION-001'] = {
        localeKey = 'spawn.failed',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки решения о спавне.
    -- EN: Spawn decision errors.
    ['GC-SPAWN-DECISION-001'] = {
        localeKey = 'spawn.rejected',
        severity = 'error',
        public = true
    },
    ['GC-SPAWN-DECISION-EXPIRED-001'] = {
        localeKey = 'spawn.expired',
        severity = 'error',
        public = true
    },
    ['GC-SPAWN-DECISION-CONSUMED-001'] = {
        localeKey = 'spawn.rejected',
        severity = 'error',
        public = false
    },

    -- RU: Ошибки resync после рестарта.
    -- EN: Resync-after-restart errors.
    ['GC-RESYNC-001'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },
    ['GC-RESYNC-002'] = {
        localeKey = 'error.internal',
        severity = 'error',
        public = false
    },
    ['GC-SPAWN-DECISION-UNKNOWN'] = {
        localeKey = 'spawn.rejected', severity = 'warn', public = false
    },
    ['GC-SPAWN-DECISION-SOURCE-MISMATCH'] = {
        localeKey = 'spawn.rejected', severity = 'warn', public = false
    },
    ['GC-SPAWN-DECISION-SESSION-MISMATCH'] = {
        localeKey = 'spawn.rejected', severity = 'warn', public = false
    },
    ['GC-RECOVERY-TIMEOUT'] = {
        localeKey = 'connection.timeout',
        severity = 'error',
        public = false
    },
    ['GC-RECOVERY-STALE-RESPONSE'] = {
        localeKey = 'error.internal',
        severity = 'warn',
        public = false
    },
    ['GC-RECOVERY-ENTITY-MISSING'] = {
        localeKey = 'spawn.failed',
        severity = 'warn',
        public = false
    }
}

--- RU:
--- Возвращает описание ошибки по её коду.
---
--- EN:
--- Returns the error description by its code.
---
--- @param errorCode string Error code like "GC-CONNECTION-001"
--- @return table|nil errorInfo Error info table
function GCErrors.Get(errorCode)
    if type(errorCode) ~= 'string' then
        return nil
    end

    return GCErrors[errorCode]
end

--- RU:
--- Проверяет, является ли ошибка публичной (можно показывать игроку).
---
--- EN:
--- Checks whether the error is public (can be shown to the player).
---
--- @param errorCode string Error code
--- @return boolean isPublic Whether the error is public
function GCErrors.IsPublic(errorCode)
    local errorInfo = GCErrors.Get(errorCode)

    if not errorInfo then
        return false
    end

    return errorInfo.public == true
end
