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
        accounts = {},
        identifiers = {},
        characters = {},
        selections = {}
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
        characters = characterCount
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

GCIdentityRepositories.memory = MemoryRepository
