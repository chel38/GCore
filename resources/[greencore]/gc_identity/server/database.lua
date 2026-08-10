GCIdentityDatabase = {}

local health = {
    status = 'stopped',
    code = nil,
    appliedMigrations = 0
}

local function setHealth(status, code, appliedMigrations)
    health.status = status
    health.code = code

    if appliedMigrations ~= nil then
        health.appliedMigrations = appliedMigrations
    end
end
local function executeAwait(method, ...)
    local arguments = { ... }
    local ok, result = pcall(function()
        return method.await(table.unpack(arguments))
    end)

    if not ok then
        return nil, 'GC-IDENTITY-DATABASE-QUERY-FAILED'
    end

    return result
end

local function applyMigrations()
    local bootstrap, bootstrapError = executeAwait(MySQL.query, [[
        CREATE TABLE IF NOT EXISTS `gc_identity_schema_migrations` (
            `version` VARCHAR(64) NOT NULL,
            `description` VARCHAR(255) NOT NULL,
            `applied_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
            PRIMARY KEY (`version`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    if bootstrap == nil then
        return nil, bootstrapError
    end

    local rows, rowsError = executeAwait(
        MySQL.query,
        'SELECT `version` FROM `gc_identity_schema_migrations` ORDER BY `version`'
    )

    if rows == nil then
        return nil, rowsError
    end

    local applied = {}

    for _, row in ipairs(rows) do
        applied[row.version] = true
    end

    local newlyApplied = 0

    for _, migration in ipairs(GCIdentityMigrations.List()) do
        if not applied[migration.version] then
            -- EN: MariaDB DDL may auto-commit. Every statement in this milestone
            -- is intentionally non-destructive and idempotent for safe recovery.
            -- RU: MariaDB DDL может делать auto-commit. Все statements этого
            -- milestone неразрушительны и идемпотентны для безопасного retry.
            for _, statement in ipairs(migration.statements) do
                local result, statementError = executeAwait(MySQL.query, statement)

                if result == nil then
                    return nil, statementError
                end
            end

            local recorded, recordError = executeAwait(
                MySQL.insert,
                [[
                    INSERT INTO `gc_identity_schema_migrations`
                        (`version`, `description`)
                    VALUES (?, ?)
                ]],
                { migration.version, migration.description }
            )

            if recorded == nil then
                return nil, recordError
            end

            newlyApplied = newlyApplied + 1
        end
    end

    return newlyApplied
end

function GCIdentityDatabase.Initialize()
    if GCIdentityConfig.storage.adapter ~= 'oxmysql' then
        setHealth('ready', nil, 0)
        return true
    end

    setHealth('connecting', nil, 0)

    if GetResourceState('oxmysql') ~= 'started'
        or type(MySQL) ~= 'table'
        or type(MySQL.scalar) ~= 'table'
        or type(MySQL.scalar.await) ~= 'function' then
        setHealth('degraded', 'GC-IDENTITY-DATABASE-UNAVAILABLE')
        return false, health.code
    end

    local probe, probeError = executeAwait(MySQL.scalar, 'SELECT 1')

    if probe == nil then
        setHealth('degraded', probeError or 'GC-IDENTITY-DATABASE-UNAVAILABLE')
        return false, health.code
    end

    local applied, migrationError = applyMigrations()

    if applied == nil then
        setHealth('degraded', 'GC-IDENTITY-MIGRATION-FAILED')
        return false, migrationError or health.code
    end

    setHealth('ready', nil, applied)
    return true
end

function GCIdentityDatabase.MarkRuntimeFailure(code)
    setHealth('degraded', code or 'GC-IDENTITY-DATABASE-QUERY-FAILED')
end

function GCIdentityDatabase.IsReady()
    return health.status == 'ready'
end

function GCIdentityDatabase.GetHealth()
    return {
        status = health.status,
        code = health.code,
        appliedMigrations = health.appliedMigrations
    }
end
