GCIdentityRepository = {}

local resourceName = GetCurrentResourceName()
local loaded = false
local data = {
    nextAccountId = 1,
    nextCharacterId = 1,
    accounts = {},
    characters = {}
}

local function emptyData()
    return {
        nextAccountId = 1,
        nextCharacterId = 1,
        accounts = {},
        characters = {}
    }
end

local function validData(candidate)
    return type(candidate) == 'table'
        and type(candidate.nextAccountId) == 'number'
        and candidate.nextAccountId >= 1
        and candidate.nextAccountId % 1 == 0
        and type(candidate.nextCharacterId) == 'number'
        and candidate.nextCharacterId >= 1
        and candidate.nextCharacterId % 1 == 0
        and type(candidate.accounts) == 'table'
        and type(candidate.characters) == 'table'
end

local function save()
    local ok, encoded = pcall(json.encode, data)

    if not ok or type(encoded) ~= 'string' then
        return false, 'GC-IDENTITY-STORAGE-ENCODE'
    end

    local saved = SaveResourceFile(
        resourceName,
        GCIdentityConfig.storage.file,
        encoded,
        -1
    )

    if saved == false then
        return false, 'GC-IDENTITY-STORAGE-WRITE'
    end

    return true
end

function GCIdentityRepository.Load()
    local raw = LoadResourceFile(resourceName, GCIdentityConfig.storage.file)

    if raw == nil or raw == '' then
        data = emptyData()
        loaded = true
        return true
    end

    local ok, decoded = pcall(json.decode, raw)

    if not ok or not validData(decoded) then
        return false, 'GC-IDENTITY-STORAGE-DECODE'
    end

    data = decoded
    loaded = true
    return true
end

function GCIdentityRepository.IsLoaded()
    return loaded
end

function GCIdentityRepository.FindAccountByIdentifier(identifierType, identifier)
    for _, account in ipairs(data.accounts) do
        if account.identifierType == identifierType and account.identifier == identifier then
            return account
        end
    end

    return nil
end

function GCIdentityRepository.GetAccountById(accountId)
    for _, account in ipairs(data.accounts) do
        if account.id == accountId then
            return account
        end
    end

    return nil
end

function GCIdentityRepository.CreateAccount(identifierType, identifier)
    if not loaded then
        return nil, 'GC-IDENTITY-STORAGE-NOT-LOADED'
    end

    local existing = GCIdentityRepository.FindAccountByIdentifier(identifierType, identifier)

    if existing then
        return existing
    end

    local account = {
        id = data.nextAccountId,
        identifierType = identifierType,
        identifier = identifier,
        selectedCharacterId = nil,
        createdAt = os.time(),
        updatedAt = os.time()
    }
    local previousNextId = data.nextAccountId
    data.nextAccountId = data.nextAccountId + 1
    table.insert(data.accounts, account)

    local saved, saveError = save()

    if not saved then
        table.remove(data.accounts)
        data.nextAccountId = previousNextId
        return nil, saveError
    end

    return account
end

function GCIdentityRepository.GetCharacters(accountId)
    local characters = {}

    for _, character in ipairs(data.characters) do
        if character.accountId == accountId then
            table.insert(characters, character)
        end
    end

    table.sort(characters, function(left, right)
        return left.id < right.id
    end)

    return characters
end

function GCIdentityRepository.GetCharacterById(characterId)
    for _, character in ipairs(data.characters) do
        if character.id == characterId then
            return character
        end
    end

    return nil
end

function GCIdentityRepository.CreateCharacter(accountId, firstName, lastName)
    if not loaded then
        return nil, 'GC-IDENTITY-STORAGE-NOT-LOADED'
    end

    if not GCIdentityRepository.GetAccountById(accountId) then
        return nil, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    local character = {
        id = data.nextCharacterId,
        accountId = accountId,
        firstName = firstName,
        lastName = lastName,
        createdAt = os.time(),
        updatedAt = os.time()
    }
    local previousNextId = data.nextCharacterId
    data.nextCharacterId = data.nextCharacterId + 1
    table.insert(data.characters, character)

    local saved, saveError = save()

    if not saved then
        table.remove(data.characters)
        data.nextCharacterId = previousNextId
        return nil, saveError
    end

    return character
end

function GCIdentityRepository.SelectCharacter(accountId, characterId)
    local account = GCIdentityRepository.GetAccountById(accountId)
    local character = GCIdentityRepository.GetCharacterById(characterId)

    if not account then
        return false, 'GC-IDENTITY-ACCOUNT-NOT-FOUND'
    end

    if not character or character.accountId ~= accountId then
        return false, 'GC-IDENTITY-CHARACTER-NOT-OWNED'
    end

    local previousSelection = account.selectedCharacterId
    local previousUpdatedAt = account.updatedAt
    account.selectedCharacterId = characterId
    account.updatedAt = os.time()

    local saved, saveError = save()

    if not saved then
        account.selectedCharacterId = previousSelection
        account.updatedAt = previousUpdatedAt
        return false, saveError
    end

    return true
end
