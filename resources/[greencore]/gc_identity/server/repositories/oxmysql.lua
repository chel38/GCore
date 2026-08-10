GCIdentityRepositories = GCIdentityRepositories or {}

local OxMySQLRepository = {}

local ACCOUNT_SELECT = [[
    SELECT
        a.`id`,
        a.`email`,
        a.`status`,
        UNIX_TIMESTAMP(a.`created_at`) AS `createdAt`,
        UNIX_TIMESTAMP(a.`updated_at`) AS `updatedAt`,
        UNIX_TIMESTAMP(a.`last_login_at`) AS `lastLoginAt`,
        s.`character_id` AS `selectedCharacterId`
    FROM `gc_accounts` a
    LEFT JOIN `gc_account_character_selections` s
        ON s.`account_id` = a.`id`
]]

local function normalizeAccount(row)
    if not row then
        return nil
    end

    return {
        id = tonumber(row.id),
        email = row.email,
        status = row.status,
        selectedCharacterId = row.selectedCharacterId
            and tonumber(row.selectedCharacterId) or nil,
        createdAt = tonumber(row.createdAt),
        updatedAt = tonumber(row.updatedAt),
        lastLoginAt = row.lastLoginAt and tonumber(row.lastLoginAt) or nil
    }
end

local function normalizeCharacter(row)
    if not row then
        return nil
    end

    return {
        id = tonumber(row.id),
        accountId = tonumber(row.accountId),
        firstName = row.firstName,
        lastName = row.lastName,
        status = row.status,
        createdAt = tonumber(row.createdAt),
        updatedAt = tonumber(row.updatedAt)
    }
end

local function await(method, ...)
    local arguments = { ... }
    local ok, result = pcall(function()
        return method.await(table.unpack(arguments))
    end)

    if not ok then
        GCIdentityDatabase.MarkRuntimeFailure('GC-IDENTITY-DATABASE-QUERY-FAILED')
        return nil, 'GC-IDENTITY-DATABASE-QUERY-FAILED'
    end

    return result
end

local function startTransaction(handler)
    if type(MySQL.startTransaction) ~= 'function' then
        GCIdentityDatabase.MarkRuntimeFailure('GC-IDENTITY-DATABASE-TRANSACTION-UNAVAILABLE')
        return nil, 'GC-IDENTITY-DATABASE-TRANSACTION-UNAVAILABLE'
    end

    local ok, committed = pcall(MySQL.startTransaction, handler)

    if not ok then
        GCIdentityDatabase.MarkRuntimeFailure('GC-IDENTITY-DATABASE-TRANSACTION-FAILED')
        return nil, 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    return committed == true
end

local function findAccountById(accountId)
    local row, queryError = await(
        MySQL.single,
        ACCOUNT_SELECT .. ' WHERE a.`id` = ? LIMIT 1',
        { accountId }
    )

    if queryError then
        return nil, queryError
    end

    if not row then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    return normalizeAccount(row)
end

function OxMySQLRepository.Initialize()
    if not GCIdentityDatabase.IsReady() then
        return false, 'GC-IDENTITY-DATABASE-UNAVAILABLE'
    end

    return true
end

function OxMySQLRepository.IsReady()
    return GCIdentityDatabase.IsReady()
end

function OxMySQLRepository.FindAccountByIdentifier(identifierType, identifier)
    local row, queryError = await(
        MySQL.single,
        ACCOUNT_SELECT .. [[
            INNER JOIN `gc_account_identifiers` i ON i.`account_id` = a.`id`
            WHERE i.`identifier_type` = ? AND i.`identifier` = ?
            LIMIT 1
        ]],
        { identifierType, identifier }
    )

    if queryError then
        return nil, queryError
    end

    if not row then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    return normalizeAccount(row)
end

function OxMySQLRepository.FindAccountByEmail(email)
    local row, queryError = await(
        MySQL.single,
        ACCOUNT_SELECT .. ' WHERE a.`email` = ? LIMIT 1',
        { email }
    )

    if queryError then
        return nil, queryError
    end

    if not row then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    return normalizeAccount(row)
end

function OxMySQLRepository.GetAccountById(accountId)
    return findAccountById(accountId)
end

function OxMySQLRepository.RegisterAccount(email, identifierType, identifier)
    local accountId
    local domainError
    local committed, transactionError = startTransaction(function(query)
        local emailRows = query(
            'SELECT `id` FROM `gc_accounts` WHERE `email` = ? LIMIT 1 FOR UPDATE',
            { email }
        )

        if emailRows and emailRows[1] then
            domainError = 'GC-IDENTITY-EMAIL-TAKEN'
            return false
        end

        local identifierRows = query([[
            SELECT `account_id`
            FROM `gc_account_identifiers`
            WHERE `identifier_type` = ? AND `identifier` = ?
            LIMIT 1 FOR UPDATE
        ]], { identifierType, identifier })

        if identifierRows and identifierRows[1] then
            domainError = 'GC-IDENTITY-REGISTRATION-CONFLICT'
            return false
        end

        local inserted = query([[
            INSERT INTO `gc_accounts`
                (`email`, `status`, `created_at`, `updated_at`, `last_login_at`)
            VALUES (?, 'active', UTC_TIMESTAMP(3), UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
        ]], { email })

        if not inserted or not inserted.insertId then
            return false
        end

        accountId = tonumber(inserted.insertId)
        local linked = query([[
            INSERT INTO `gc_account_identifiers`
                (`account_id`, `identifier_type`, `identifier`, `created_at`, `last_seen_at`)
            VALUES (?, ?, ?, UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
        ]], { accountId, identifierType, identifier })

        return linked and linked.affectedRows == 1
    end)

    if not committed then
        if domainError then
            return nil, domainError
        end

        if transactionError then
            return nil, transactionError
        end

        local existingEmail = OxMySQLRepository.FindAccountByEmail(email)

        if existingEmail then
            return nil, 'GC-IDENTITY-EMAIL-TAKEN'
        end

        local existingIdentifier = OxMySQLRepository.FindAccountByIdentifier(
            identifierType,
            identifier
        )

        if existingIdentifier then
            return nil, 'GC-IDENTITY-REGISTRATION-CONFLICT'
        end

        return nil, 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    return findAccountById(accountId)
end

function OxMySQLRepository.CompleteRegistration(accountId, email, identifierType, identifier)
    local domainError
    local committed, transactionError = startTransaction(function(query)
        local accounts = query(
            'SELECT `id`, `email` FROM `gc_accounts` WHERE `id` = ? LIMIT 1 FOR UPDATE',
            { accountId }
        )

        if not accounts or not accounts[1] then
            domainError = 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
            return false
        end

        local links = query([[
            SELECT `account_id` FROM `gc_account_identifiers`
            WHERE `identifier_type` = ? AND `identifier` = ?
            LIMIT 1 FOR UPDATE
        ]], { identifierType, identifier })

        if not links or not links[1] or tonumber(links[1].account_id) ~= accountId then
            domainError = 'GC-IDENTITY-REGISTRATION-CONFLICT'
            return false
        end

        local emailRows = query(
            'SELECT `id` FROM `gc_accounts` WHERE `email` = ? AND `id` <> ? LIMIT 1 FOR UPDATE',
            { email, accountId }
        )

        if emailRows and emailRows[1] then
            domainError = 'GC-IDENTITY-EMAIL-TAKEN'
            return false
        end

        local updated = query([[
            UPDATE `gc_accounts`
            SET `email` = ?, `updated_at` = UTC_TIMESTAMP(3),
                `last_login_at` = UTC_TIMESTAMP(3)
            WHERE `id` = ?
        ]], { email, accountId })

        return updated and updated.affectedRows == 1
    end)

    if not committed then
        return nil, domainError or transactionError
            or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    return findAccountById(accountId)
end

function OxMySQLRepository.TouchLogin(accountId, identifierType, identifier)
    local success, queryError = await(MySQL.transaction, {
        {
            [[
                UPDATE `gc_accounts`
                SET `last_login_at` = UTC_TIMESTAMP(3)
                WHERE `id` = ?
            ]],
            { accountId }
        },
        {
            [[
                UPDATE `gc_account_identifiers`
                SET `last_seen_at` = UTC_TIMESTAMP(3)
                WHERE `account_id` = ? AND `identifier_type` = ? AND `identifier` = ?
            ]],
            { accountId, identifierType, identifier }
        }
    })

    if queryError then
        return false, queryError
    end

    return success == true, success and nil or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
end

function OxMySQLRepository.GetCharacters(accountId)
    local rows, queryError = await(MySQL.query, [[
        SELECT
            `id`, `account_id` AS `accountId`,
            `first_name` AS `firstName`, `last_name` AS `lastName`, `status`,
            UNIX_TIMESTAMP(`created_at`) AS `createdAt`,
            UNIX_TIMESTAMP(`updated_at`) AS `updatedAt`
        FROM `gc_characters`
        WHERE `account_id` = ? AND `status` = 'active'
        ORDER BY `id`
    ]], { accountId })

    if queryError then
        return nil, queryError
    end

    local result = {}

    for _, row in ipairs(rows or {}) do
        table.insert(result, normalizeCharacter(row))
    end

    return result
end

function OxMySQLRepository.GetCharacterById(characterId)
    local row, queryError = await(MySQL.single, [[
        SELECT
            `id`, `account_id` AS `accountId`,
            `first_name` AS `firstName`, `last_name` AS `lastName`, `status`,
            UNIX_TIMESTAMP(`created_at`) AS `createdAt`,
            UNIX_TIMESTAMP(`updated_at`) AS `updatedAt`
        FROM `gc_characters`
        WHERE `id` = ? AND `status` = 'active'
        LIMIT 1
    ]], { characterId })

    if queryError then
        return nil, queryError
    end

    if not row then
        return nil, 'GC-IDENTITY-CHARACTER-NOT-FOUND'
    end

    return normalizeCharacter(row)
end

function OxMySQLRepository.CreateCharacter(accountId, firstName, lastName, maximum)
    local characterId
    local domainError
    local committed, transactionError = startTransaction(function(query)
        local accounts = query(
            "SELECT `id` FROM `gc_accounts` WHERE `id` = ? AND `status` = 'active' LIMIT 1 FOR UPDATE",
            { accountId }
        )

        if not accounts or not accounts[1] then
            domainError = 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
            return false
        end

        local counts = query([[
            SELECT COUNT(*) AS `count`
            FROM `gc_characters`
            WHERE `account_id` = ? AND `status` = 'active'
        ]], { accountId })

        if not counts or tonumber(counts[1] and counts[1].count) >= maximum then
            domainError = 'GC-IDENTITY-CHARACTER-LIMIT'
            return false
        end

        local inserted = query([[
            INSERT INTO `gc_characters`
                (`account_id`, `first_name`, `last_name`, `status`, `created_at`, `updated_at`)
            VALUES (?, ?, ?, 'active', UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
        ]], { accountId, firstName, lastName })

        if not inserted or not inserted.insertId then
            return false
        end

        characterId = tonumber(inserted.insertId)
        return true
    end)

    if not committed then
        return nil, domainError or transactionError
            or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    return OxMySQLRepository.GetCharacterById(characterId)
end

function OxMySQLRepository.SelectCharacter(accountId, characterId)
    local domainError
    local committed, transactionError = startTransaction(function(query)
        local rows = query([[
            SELECT `id`, `account_id`, `status`
            FROM `gc_characters`
            WHERE `id` = ? LIMIT 1 FOR UPDATE
        ]], { characterId })

        if not rows or not rows[1] then
            domainError = 'GC-IDENTITY-CHARACTER-NOT-FOUND'
            return false
        end

        if tonumber(rows[1].account_id) ~= accountId or rows[1].status ~= 'active' then
            domainError = 'GC-IDENTITY-CHARACTER-NOT-OWNED'
            return false
        end

        local selected = query([[
            INSERT INTO `gc_account_character_selections`
                (`account_id`, `character_id`, `selected_at`)
            VALUES (?, ?, UTC_TIMESTAMP(3))
            ON DUPLICATE KEY UPDATE
                `character_id` = VALUES(`character_id`),
                `selected_at` = VALUES(`selected_at`)
        ]], { accountId, characterId })

        return selected and selected.affectedRows >= 1
    end)

    if not committed then
        return nil, domainError or transactionError
            or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    return OxMySQLRepository.GetCharacterById(characterId)
end

function OxMySQLRepository.ImportLegacyAccount(record)
    local existing, existingError = OxMySQLRepository.FindAccountByIdentifier(
        record.identifierType,
        record.identifier
    )

    if existing then
        return existing, nil, true
    end

    if existingError ~= 'GC-IDENTITY-ACCOUNT-NOT-FOUND' then
        return nil, existingError
    end

    local accountId
    local selectedCharacterId
    local committed, transactionError = startTransaction(function(query)
        local insertedAccount = query([[
            INSERT INTO `gc_accounts`
                (`email`, `status`, `created_at`, `updated_at`)
            VALUES (NULL, 'active', FROM_UNIXTIME(?), FROM_UNIXTIME(?))
        ]], {
            record.createdAt or os.time(),
            record.updatedAt or record.createdAt or os.time()
        })

        if not insertedAccount or not insertedAccount.insertId then
            return false
        end

        accountId = tonumber(insertedAccount.insertId)
        local linked = query([[
            INSERT INTO `gc_account_identifiers`
                (`account_id`, `identifier_type`, `identifier`)
            VALUES (?, ?, ?)
        ]], { accountId, record.identifierType, record.identifier })

        if not linked or linked.affectedRows ~= 1 then
            return false
        end

        for _, character in ipairs(record.characters or {}) do
            local insertedCharacter = query([[
                INSERT INTO `gc_characters`
                    (`account_id`, `first_name`, `last_name`, `status`, `created_at`, `updated_at`)
                VALUES (?, ?, ?, 'active', FROM_UNIXTIME(?), FROM_UNIXTIME(?))
            ]], {
                accountId,
                character.firstName,
                character.lastName,
                character.createdAt or os.time(),
                character.updatedAt or character.createdAt or os.time()
            })

            if not insertedCharacter or not insertedCharacter.insertId then
                return false
            end

            if character.id == record.selectedCharacterId then
                selectedCharacterId = tonumber(insertedCharacter.insertId)
            end
        end

        if selectedCharacterId then
            local selected = query([[
                INSERT INTO `gc_account_character_selections`
                    (`account_id`, `character_id`)
                VALUES (?, ?)
            ]], { accountId, selectedCharacterId })

            if not selected or selected.affectedRows ~= 1 then
                return false
            end
        end

        return true
    end)

    if not committed then
        return nil, transactionError or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    return findAccountById(accountId), nil, false
end

GCIdentityRepositories.oxmysql = OxMySQLRepository
