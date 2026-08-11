GCIdentityRepositories = GCIdentityRepositories or {}

local OxMySQLRepository = {}

local ACCOUNT_SELECT = [[
    SELECT
        a.`id`,
        a.`email`,
        a.`first_name` AS `firstName`,
        a.`last_name` AS `lastName`,
        UNIX_TIMESTAMP(a.`email_verified_at`) AS `emailVerifiedAt`,
        a.`last_ip_fingerprint` AS `lastIpFingerprint`,
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
        firstName = row.firstName,
        lastName = row.lastName,
        emailVerifiedAt = row.emailVerifiedAt and tonumber(row.emailVerifiedAt) or nil,
        lastIpFingerprint = row.lastIpFingerprint,
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

local function normalizeChallenge(row)
    if not row then
        return nil
    end

    return {
        id = tonumber(row.id),
        accountId = row.accountId and tonumber(row.accountId) or nil,
        bindingKey = row.bindingKey,
        email = row.email,
        firstName = row.firstName,
        lastName = row.lastName,
        type = row.type,
        codeHash = row.codeHash,
        expiresAt = tonumber(row.expiresAt),
        attempts = tonumber(row.attempts),
        maxAttempts = tonumber(row.maxAttempts),
        createdAt = tonumber(row.createdAt),
        lastSentAt = tonumber(row.lastSentAt),
        verifiedAt = row.verifiedAt and tonumber(row.verifiedAt) or nil,
        consumedAt = row.consumedAt and tonumber(row.consumedAt) or nil
    }
end

function OxMySQLRepository.GenerateVerificationCode()
    local row, queryError = await(
        MySQL.single,
        'SELECT CONV(HEX(RANDOM_BYTES(4)), 16, 10) AS `entropy`'
    )

    if queryError then
        return nil, queryError
    end

    local entropy = row and tonumber(row.entropy)
    if not entropy then
        return nil, 'GC-IDENTITY-RANDOM-UNAVAILABLE'
    end

    return ('%06d'):format((entropy % 900000) + 100000)
end

function OxMySQLRepository.CreateVerificationChallenge(challenge)
    local challengeId
    local committed, transactionError = startTransaction(function(query)
        query([[
            UPDATE `gc_identity_verification_challenges`
            SET `consumed_at` = UTC_TIMESTAMP(3)
            WHERE `binding_key` = ? AND `verification_type` = ?
                AND `consumed_at` IS NULL
        ]], { challenge.bindingKey, challenge.type })

        local inserted = query([[
            INSERT INTO `gc_identity_verification_challenges`
                (`account_id`, `binding_key`, `email`, `pending_first_name`,
                 `pending_last_name`, `verification_type`, `code_hash`,
                 `expires_at`, `attempts`, `max_attempts`, `created_at`, `last_sent_at`)
            VALUES (NULLIF(?, 0), ?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?), 0, ?, UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
        ]], {
            challenge.accountId or 0,
            challenge.bindingKey,
            challenge.email,
            challenge.firstName,
            challenge.lastName,
            challenge.type,
            challenge.codeHash,
            challenge.expiresAt,
            challenge.maxAttempts
        })

        if not inserted or not inserted.insertId then
            return false
        end
        challengeId = tonumber(inserted.insertId)
        return true
    end)

    if not committed then
        return nil, transactionError or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end

    challenge.id = challengeId
    challenge.attempts = 0
    challenge.createdAt = os.time()
    challenge.lastSentAt = challenge.createdAt
    return challenge
end

function OxMySQLRepository.GetVerificationChallenge(bindingKey, verificationType)
    local row, queryError = await(MySQL.single, [[
        SELECT
            `id`, `account_id` AS `accountId`, `binding_key` AS `bindingKey`,
            `email`, `pending_first_name` AS `firstName`,
            `pending_last_name` AS `lastName`,
            `verification_type` AS `type`, `code_hash` AS `codeHash`,
            UNIX_TIMESTAMP(`expires_at`) AS `expiresAt`,
            `attempts`, `max_attempts` AS `maxAttempts`,
            UNIX_TIMESTAMP(`created_at`) AS `createdAt`,
            UNIX_TIMESTAMP(`last_sent_at`) AS `lastSentAt`,
            UNIX_TIMESTAMP(`verified_at`) AS `verifiedAt`,
            UNIX_TIMESTAMP(`consumed_at`) AS `consumedAt`
        FROM `gc_identity_verification_challenges`
        WHERE `binding_key` = ? AND `verification_type` = ?
            AND `consumed_at` IS NULL
        ORDER BY `id` DESC LIMIT 1
    ]], { bindingKey, verificationType })

    if queryError then
        return nil, queryError
    end
    if not row then
        return nil, 'GC-IDENTITY-EMAIL-VERIFICATION-REQUIRED'
    end
    return normalizeChallenge(row)
end

function OxMySQLRepository.RecordVerificationFailure(challengeId)
    local result, queryError = await(MySQL.update, [[
        UPDATE `gc_identity_verification_challenges`
        SET `attempts` = `attempts` + 1,
            `consumed_at` = IF(`attempts` + 1 >= `max_attempts`, UTC_TIMESTAMP(3), NULL)
        WHERE `id` = ? AND `consumed_at` IS NULL
    ]], { challengeId })

    if queryError then
        return false, queryError
    end
    return tonumber(result) == 1, tonumber(result) == 1
        and nil or 'GC-IDENTITY-EMAIL-VERIFICATION-REQUIRED'
end

function OxMySQLRepository.InvalidateVerificationChallenge(challengeId)
    local result, queryError = await(MySQL.update, [[
        UPDATE `gc_identity_verification_challenges`
        SET `consumed_at` = COALESCE(`consumed_at`, UTC_TIMESTAMP(3))
        WHERE `id` = ?
    ]], { challengeId })

    if queryError then
        return false, queryError
    end
    return tonumber(result) == 1
end

function OxMySQLRepository.MarkVerificationChallengeVerified(challengeId)
    local result, queryError = await(MySQL.update, [[
        UPDATE `gc_identity_verification_challenges`
        SET `verified_at` = COALESCE(`verified_at`, UTC_TIMESTAMP(3))
        WHERE `id` = ? AND `consumed_at` IS NULL
            AND `expires_at` > UTC_TIMESTAMP(3)
            AND `attempts` < `max_attempts`
    ]], { challengeId })

    if queryError then
        return false, queryError
    end
    return tonumber(result) == 1, tonumber(result) == 1
        and nil or 'GC-IDENTITY-EMAIL-CHALLENGE-STALE'
end

function OxMySQLRepository.UpdateAccountRegisteredName(accountId, firstName, lastName)
    local result, queryError = await(MySQL.update, [[
        UPDATE `gc_accounts`
        SET `first_name` = ?, `last_name` = ?, `updated_at` = UTC_TIMESTAMP(3)
        WHERE `id` = ? AND `status` = 'active'
    ]], { firstName, lastName, accountId })

    if queryError then
        return nil, queryError
    end
    if tonumber(result) ~= 1 then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end
    return findAccountById(accountId)
end

function OxMySQLRepository.CompleteVerifiedRegistration(
    challengeId,
    accountId,
    email,
    firstName,
    lastName,
    identifierType,
    identifier,
    ipFingerprint
)
    local completedAccountId = accountId
    local domainError
    local committed, transactionError = startTransaction(function(query)
        local challenges = query([[
            SELECT `id`, `email`, `account_id`, `pending_first_name`,
                `pending_last_name`
            FROM `gc_identity_verification_challenges`
            WHERE `id` = ? AND `verification_type` = 'registration'
                AND `consumed_at` IS NULL AND `expires_at` > UTC_TIMESTAMP(3)
                AND `attempts` < `max_attempts` AND `verified_at` IS NOT NULL
            LIMIT 1 FOR UPDATE
        ]], { challengeId })

        local storedAccountId = challenges and challenges[1]
            and challenges[1].account_id and tonumber(challenges[1].account_id) or nil
        if not challenges or not challenges[1]
            or challenges[1].email ~= email
            or challenges[1].pending_first_name ~= firstName
            or challenges[1].pending_last_name ~= lastName
            or storedAccountId ~= accountId then
            domainError = 'GC-IDENTITY-EMAIL-CHALLENGE-STALE'
            return false
        end

        local emailSql = 'SELECT `id` FROM `gc_accounts` WHERE `email` = ?'
        local emailValues = { email }
        if accountId then
            emailSql = emailSql .. ' AND `id` <> ?'
            table.insert(emailValues, accountId)
        end
        local emailRows = query(emailSql .. ' LIMIT 1 FOR UPDATE', emailValues)
        if emailRows and emailRows[1] then
            domainError = 'GC-IDENTITY-EMAIL-TAKEN'
            return false
        end

        if accountId then
            local identifiers = query([[
                SELECT `account_id` FROM `gc_account_identifiers`
                WHERE `identifier_type` = ? AND `identifier` = ?
                LIMIT 1 FOR UPDATE
            ]], { identifierType, identifier })
            if not identifiers or not identifiers[1]
                or tonumber(identifiers[1].account_id) ~= accountId then
                domainError = 'GC-IDENTITY-REGISTRATION-CONFLICT'
                return false
            end

            local updated = query([[
                UPDATE `gc_accounts`
                SET `email` = ?, `first_name` = ?, `last_name` = ?,
                    `email_verified_at` = UTC_TIMESTAMP(3),
                    `last_ip_fingerprint` = ?, `updated_at` = UTC_TIMESTAMP(3),
                    `last_login_at` = UTC_TIMESTAMP(3)
                WHERE `id` = ? AND `status` = 'active'
            ]], { email, firstName, lastName, ipFingerprint, accountId })
            if not updated or updated.affectedRows ~= 1 then
                return false
            end
        else
            local identifierRows = query([[
                SELECT `account_id` FROM `gc_account_identifiers`
                WHERE `identifier_type` = ? AND `identifier` = ?
                LIMIT 1 FOR UPDATE
            ]], { identifierType, identifier })
            if identifierRows and identifierRows[1] then
                domainError = 'GC-IDENTITY-REGISTRATION-CONFLICT'
                return false
            end

            local inserted = query([[
                INSERT INTO `gc_accounts`
                    (`email`, `first_name`, `last_name`, `email_verified_at`,
                     `last_ip_fingerprint`, `status`,
                     `created_at`, `updated_at`, `last_login_at`)
                VALUES (?, ?, ?, UTC_TIMESTAMP(3), ?, 'active', UTC_TIMESTAMP(3),
                        UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
            ]], { email, firstName, lastName, ipFingerprint })
            if not inserted or not inserted.insertId then
                return false
            end
            completedAccountId = tonumber(inserted.insertId)
            local linked = query([[
                INSERT INTO `gc_account_identifiers`
                    (`account_id`, `identifier_type`, `identifier`, `created_at`, `last_seen_at`)
                VALUES (?, ?, ?, UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
            ]], { completedAccountId, identifierType, identifier })
            if not linked or linked.affectedRows ~= 1 then
                return false
            end
        end

        local consumed = query([[
            UPDATE `gc_identity_verification_challenges`
            SET `consumed_at` = UTC_TIMESTAMP(3)
            WHERE `id` = ? AND `consumed_at` IS NULL
        ]], { challengeId })
        return consumed and consumed.affectedRows == 1
    end)

    if not committed then
        return nil, domainError or transactionError
            or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end
    return findAccountById(completedAccountId)
end

function OxMySQLRepository.CompleteVerifiedAuthentication(challengeId, accountId, ipFingerprint)
    local domainError
    local committed, transactionError = startTransaction(function(query)
        local challenges = query([[
            SELECT `id` FROM `gc_identity_verification_challenges`
            WHERE `id` = ? AND `account_id` = ?
                AND `verification_type` = 'authentication'
                AND `consumed_at` IS NULL AND `expires_at` > UTC_TIMESTAMP(3)
                AND `attempts` < `max_attempts`
            LIMIT 1 FOR UPDATE
        ]], { challengeId, accountId })
        if not challenges or not challenges[1] then
            domainError = 'GC-IDENTITY-EMAIL-CHALLENGE-STALE'
            return false
        end

        local updated = query([[
            UPDATE `gc_accounts`
            SET `last_ip_fingerprint` = ?, `last_login_at` = UTC_TIMESTAMP(3),
                `updated_at` = UTC_TIMESTAMP(3)
            WHERE `id` = ? AND `status` = 'active'
        ]], { ipFingerprint, accountId })
        if not updated or updated.affectedRows ~= 1 then
            return false
        end

        local consumed = query([[
            UPDATE `gc_identity_verification_challenges`
            SET `consumed_at` = UTC_TIMESTAMP(3)
            WHERE `id` = ? AND `consumed_at` IS NULL
        ]], { challengeId })
        return consumed and consumed.affectedRows == 1
    end)

    if not committed then
        return nil, domainError or transactionError
            or 'GC-IDENTITY-DATABASE-TRANSACTION-FAILED'
    end
    return findAccountById(accountId)
end

GCIdentityRepositories.oxmysql = OxMySQLRepository
