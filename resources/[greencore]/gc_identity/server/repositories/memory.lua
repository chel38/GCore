GCIdentityRepositories = GCIdentityRepositories or {}

local MemoryRepository = {}
local store
local failureCode
local beforeOperation

local function copy(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local result = {}
    seen[value] = result

    for key, child in pairs(value) do
        result[copy(key, seen)] = copy(child, seen)
    end

    return result
end

local function resetStore()
    store = {
        nextAccountId = 1,
        nextIdentifierId = 1,
        nextCharacterId = 1,
        nextChallengeId = 1,
        nextVerificationCode = 483921,
        accounts = {},
        identifiers = {},
        characters = {},
        selections = {},
        challenges = {}
    }
    failureCode = nil
    beforeOperation = nil
end

local function failed()
    if beforeOperation then
        local callback = beforeOperation
        beforeOperation = nil
        callback()
    end

    if failureCode then
        return true, failureCode
    end

    return false
end

local function accountWithSelection(account)
    if not account then
        return nil
    end

    local result = copy(account)
    result.selectedCharacterId = store.selections[account.id]
    return result
end

function MemoryRepository.Initialize()
    if not store then
        resetStore()
    end

    return true
end

function MemoryRepository.IsReady()
    -- EN: A simulated operation failure must reach the repository call so tests
    -- can prove that storage errors never become a misleading NOT_FOUND result.
    -- RU: Имитация ошибки операции должна дойти до вызова репозитория, чтобы
    -- тесты доказали: ошибка хранилища не превращается в ложный NOT_FOUND.
    return store ~= nil
end

function MemoryRepository.Reset()
    resetStore()
end

function MemoryRepository.SetFailure(code)
    failureCode = code
end

function MemoryRepository.SetBeforeOperation(callback)
    beforeOperation = callback
end

function MemoryRepository.SetAccountStatus(accountId, status)
    if store.accounts[accountId] then
        store.accounts[accountId].status = status
        return true
    end

    return false
end

function MemoryRepository.SetNextVerificationCode(code)
    store.nextVerificationCode = tonumber(code)
end

function MemoryRepository.GetLastChallenge()
    return copy(store.challenges[#store.challenges])
end

function MemoryRepository.SetLastChallengeExpires(expiresAt)
    local challenge = store.challenges[#store.challenges]
    if challenge then
        challenge.expiresAt = expiresAt
        return true
    end
    return false
end

function MemoryRepository.GetCounts()
    local accountCount = 0
    local characterCount = 0

    for _ in pairs(store.accounts) do
        accountCount = accountCount + 1
    end

    for _ in pairs(store.characters) do
        characterCount = characterCount + 1
    end

    return {
        accounts = accountCount,
        identifiers = #store.identifiers,
        characters = characterCount,
        challenges = #store.challenges
    }
end

function MemoryRepository.FindAccountByIdentifier(identifierType, identifier)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    for _, link in ipairs(store.identifiers) do
        if link.identifierType == identifierType and link.identifier == identifier then
            return accountWithSelection(store.accounts[link.accountId])
        end
    end

    return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
end

function MemoryRepository.FindAccountByEmail(email)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    for _, account in pairs(store.accounts) do
        if account.email == email then
            return accountWithSelection(account)
        end
    end

    return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
end

function MemoryRepository.GetAccountById(accountId)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    local account = accountWithSelection(store.accounts[accountId])
    return account, account and nil or 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
end

function MemoryRepository.RegisterAccount(email, identifierType, identifier)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    local emailAccount = MemoryRepository.FindAccountByEmail(email)

    if emailAccount then
        return nil, 'GC-IDENTITY-EMAIL-TAKEN'
    end

    local identifierAccount = MemoryRepository.FindAccountByIdentifier(identifierType, identifier)

    if identifierAccount then
        return nil, 'GC-IDENTITY-REGISTRATION-CONFLICT'
    end

    local now = os.time()
    local account = {
        id = store.nextAccountId,
        email = email,
        emailVerifiedAt = now,
        lastIpFingerprint = nil,
        status = 'active',
        createdAt = now,
        updatedAt = now,
        lastLoginAt = now
    }
    store.nextAccountId = store.nextAccountId + 1
    store.accounts[account.id] = account
    table.insert(store.identifiers, {
        id = store.nextIdentifierId,
        accountId = account.id,
        identifierType = identifierType,
        identifier = identifier,
        createdAt = now,
        lastSeenAt = now
    })
    store.nextIdentifierId = store.nextIdentifierId + 1
    return accountWithSelection(account)
end

function MemoryRepository.CompleteRegistration(accountId, email, identifierType, identifier)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    local account = store.accounts[accountId]

    if not account then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    local emailAccount = MemoryRepository.FindAccountByEmail(email)

    if emailAccount and emailAccount.id ~= accountId then
        return nil, 'GC-IDENTITY-EMAIL-TAKEN'
    end

    local identifierAccount = MemoryRepository.FindAccountByIdentifier(identifierType, identifier)

    if not identifierAccount or identifierAccount.id ~= accountId then
        return nil, 'GC-IDENTITY-REGISTRATION-CONFLICT'
    end

    account.email = email
    account.emailVerifiedAt = os.time()
    account.updatedAt = os.time()
    account.lastLoginAt = account.updatedAt
    return accountWithSelection(account)
end

function MemoryRepository.TouchLogin(accountId, identifierType, identifier)
    local isFailed, code = failed()

    if isFailed then
        return false, code
    end

    local account = store.accounts[accountId]

    if account then
        account.lastLoginAt = os.time()
    end

    for _, link in ipairs(store.identifiers) do
        if link.accountId == accountId
            and link.identifierType == identifierType
            and link.identifier == identifier then
            link.lastSeenAt = os.time()
        end
    end

    return account ~= nil, account and nil or 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
end

function MemoryRepository.GetCharacters(accountId)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    local result = {}

    for _, character in pairs(store.characters) do
        if character.accountId == accountId and character.status == 'active' then
            table.insert(result, copy(character))
        end
    end

    table.sort(result, function(left, right)
        return left.id < right.id
    end)
    return result
end

function MemoryRepository.GetCharacterById(characterId)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    local character = store.characters[characterId]

    if not character or character.status ~= 'active' then
        return nil, 'GC-IDENTITY-CHARACTER-NOT-FOUND'
    end

    return copy(character)
end

function MemoryRepository.CreateCharacter(accountId, firstName, lastName, maximum)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    if not store.accounts[accountId] then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    local characters = MemoryRepository.GetCharacters(accountId)

    if #characters >= maximum then
        return nil, 'GC-IDENTITY-CHARACTER-LIMIT'
    end

    local now = os.time()
    local character = {
        id = store.nextCharacterId,
        accountId = accountId,
        firstName = firstName,
        lastName = lastName,
        status = 'active',
        createdAt = now,
        updatedAt = now
    }
    store.nextCharacterId = store.nextCharacterId + 1
    store.characters[character.id] = character
    return copy(character)
end

function MemoryRepository.SelectCharacter(accountId, characterId)
    local isFailed, code = failed()

    if isFailed then
        return nil, code
    end

    local character = store.characters[characterId]

    if not character then
        return nil, 'GC-IDENTITY-CHARACTER-NOT-FOUND'
    end

    if character.accountId ~= accountId or character.status ~= 'active' then
        return nil, 'GC-IDENTITY-CHARACTER-NOT-OWNED'
    end

    store.selections[accountId] = characterId
    return copy(character)
end

function MemoryRepository.ImportLegacyAccount(record)
    local existing = MemoryRepository.FindAccountByIdentifier(
        record.identifierType,
        record.identifier
    )

    if existing then
        return existing, nil, true
    end

    local now = record.createdAt or os.time()
    local account = {
        id = store.nextAccountId,
        email = nil,
        emailVerifiedAt = nil,
        lastIpFingerprint = nil,
        status = 'active',
        createdAt = now,
        updatedAt = record.updatedAt or now,
        lastLoginAt = nil
    }
    store.nextAccountId = store.nextAccountId + 1
    store.accounts[account.id] = account
    table.insert(store.identifiers, {
        id = store.nextIdentifierId,
        accountId = account.id,
        identifierType = record.identifierType,
        identifier = record.identifier,
        createdAt = now,
        lastSeenAt = now
    })
    store.nextIdentifierId = store.nextIdentifierId + 1

    local selectedNewId

    for _, legacyCharacter in ipairs(record.characters or {}) do
        local character = {
            id = store.nextCharacterId,
            accountId = account.id,
            firstName = legacyCharacter.firstName,
            lastName = legacyCharacter.lastName,
            status = 'active',
            createdAt = legacyCharacter.createdAt or now,
            updatedAt = legacyCharacter.updatedAt or now
        }
        store.nextCharacterId = store.nextCharacterId + 1
        store.characters[character.id] = character

        if legacyCharacter.id == record.selectedCharacterId then
            selectedNewId = character.id
        end
    end

    if selectedNewId then
        store.selections[account.id] = selectedNewId
    end

    return accountWithSelection(account), nil, false
end


function MemoryRepository.GenerateVerificationCode()
    local value = store.nextVerificationCode
    store.nextVerificationCode = value >= 999999 and 100000 or value + 1
    return ('%06d'):format(value)
end

function MemoryRepository.CreateVerificationChallenge(challenge)
    local isFailed, code = failed()
    if isFailed then
        return nil, code
    end

    local now = os.time()
    for _, existing in ipairs(store.challenges) do
        if existing.bindingKey == challenge.bindingKey
            and existing.type == challenge.type
            and not existing.consumedAt then
            existing.consumedAt = now
        end
    end

    local created = copy(challenge)
    created.id = store.nextChallengeId
    created.attempts = 0
    created.createdAt = now
    created.lastSentAt = now
    created.consumedAt = nil
    store.nextChallengeId = store.nextChallengeId + 1
    table.insert(store.challenges, created)
    return copy(created)
end

function MemoryRepository.GetVerificationChallenge(bindingKey, verificationType)
    local isFailed, code = failed()
    if isFailed then
        return nil, code
    end

    for index = #store.challenges, 1, -1 do
        local challenge = store.challenges[index]
        if challenge.bindingKey == bindingKey
            and challenge.type == verificationType
            and not challenge.consumedAt then
            return copy(challenge)
        end
    end
    return nil, 'GC-IDENTITY-EMAIL-VERIFICATION-REQUIRED'
end

function MemoryRepository.RecordVerificationFailure(challengeId)
    local isFailed, code = failed()
    if isFailed then
        return false, code
    end

    for _, challenge in ipairs(store.challenges) do
        if challenge.id == challengeId and not challenge.consumedAt then
            challenge.attempts = challenge.attempts + 1
            if challenge.attempts >= challenge.maxAttempts then
                challenge.consumedAt = os.time()
            end
            return true
        end
    end
    return false, 'GC-IDENTITY-EMAIL-VERIFICATION-REQUIRED'
end

function MemoryRepository.InvalidateVerificationChallenge(challengeId)
    for _, challenge in ipairs(store.challenges) do
        if challenge.id == challengeId then
            challenge.consumedAt = challenge.consumedAt or os.time()
            return true
        end
    end
    return false
end

local function activeChallenge(challengeId, verificationType)
    for _, challenge in ipairs(store.challenges) do
        if challenge.id == challengeId and challenge.type == verificationType
            and not challenge.consumedAt and challenge.expiresAt > os.time()
            and challenge.attempts < challenge.maxAttempts then
            return challenge
        end
    end
    return nil
end

function MemoryRepository.CompleteVerifiedRegistration(
    challengeId,
    accountId,
    email,
    identifierType,
    identifier,
    ipFingerprint
)
    local challenge = activeChallenge(challengeId, 'registration')
    if not challenge or challenge.email ~= email or challenge.accountId ~= accountId then
        return nil, 'GC-IDENTITY-EMAIL-CHALLENGE-STALE'
    end

    local emailAccount = MemoryRepository.FindAccountByEmail(email)
    if emailAccount and emailAccount.id ~= accountId then
        return nil, 'GC-IDENTITY-EMAIL-TAKEN'
    end

    local account
    if accountId then
        account = store.accounts[accountId]
        local identifierAccount = MemoryRepository.FindAccountByIdentifier(identifierType, identifier)
        if not account or not identifierAccount or identifierAccount.id ~= accountId then
            return nil, 'GC-IDENTITY-REGISTRATION-CONFLICT'
        end
    else
        local identifierAccount = MemoryRepository.FindAccountByIdentifier(identifierType, identifier)
        if identifierAccount then
            return nil, 'GC-IDENTITY-REGISTRATION-CONFLICT'
        end

        local now = os.time()
        account = {
            id = store.nextAccountId,
            email = email,
            emailVerifiedAt = now,
            lastIpFingerprint = ipFingerprint,
            status = 'active',
            createdAt = now,
            updatedAt = now,
            lastLoginAt = now
        }
        store.nextAccountId = store.nextAccountId + 1
        store.accounts[account.id] = account
        table.insert(store.identifiers, {
            id = store.nextIdentifierId,
            accountId = account.id,
            identifierType = identifierType,
            identifier = identifier,
            createdAt = now,
            lastSeenAt = now
        })
        store.nextIdentifierId = store.nextIdentifierId + 1
    end

    local now = os.time()
    account.email = email
    account.emailVerifiedAt = now
    account.lastIpFingerprint = ipFingerprint
    account.updatedAt = now
    account.lastLoginAt = now
    challenge.consumedAt = now
    return accountWithSelection(account)
end

function MemoryRepository.CompleteVerifiedAuthentication(challengeId, accountId, ipFingerprint)
    local challenge = activeChallenge(challengeId, 'authentication')
    local account = store.accounts[accountId]
    if not challenge or challenge.accountId ~= accountId or not account then
        return nil, 'GC-IDENTITY-EMAIL-CHALLENGE-STALE'
    end

    local now = os.time()
    account.lastIpFingerprint = ipFingerprint
    account.lastLoginAt = now
    account.updatedAt = now
    challenge.consumedAt = now
    return accountWithSelection(account)
end

GCIdentityRepositories.memory = MemoryRepository
