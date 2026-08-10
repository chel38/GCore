GCIdentityRepository = {}

local adapter
local adapterName
local ready = false

local function unavailable()
    return nil, 'GC-IDENTITY-DATABASE-UNAVAILABLE'
end

local function call(methodName, ...)
    if not ready or not adapter or type(adapter[methodName]) ~= 'function' then
        return unavailable()
    end

    return adapter[methodName](...)
end

function GCIdentityRepository.Initialize(name)
    adapterName = name or GCIdentityConfig.storage.adapter
    adapter = GCIdentityRepositories[adapterName]
    ready = false

    if not adapter or type(adapter.Initialize) ~= 'function' then
        return false, 'GC-IDENTITY-REPOSITORY-ADAPTER-INVALID'
    end

    local initialized, initializeError = adapter.Initialize()

    if not initialized then
        return false, initializeError or 'GC-IDENTITY-DATABASE-UNAVAILABLE'
    end

    ready = true
    return true
end

function GCIdentityRepository.IsReady()
    return ready and adapter ~= nil
        and type(adapter.IsReady) == 'function'
        and adapter.IsReady() == true
end

function GCIdentityRepository.GetAdapterName()
    return adapterName
end

function GCIdentityRepository.SetUnavailable()
    ready = false
end

function GCIdentityRepository.FindAccountByIdentifier(identifierType, identifier)
    return call('FindAccountByIdentifier', identifierType, identifier)
end

function GCIdentityRepository.FindAccountByEmail(email)
    return call('FindAccountByEmail', email)
end

function GCIdentityRepository.GetAccountById(accountId)
    return call('GetAccountById', accountId)
end

function GCIdentityRepository.RegisterAccount(email, identifierType, identifier)
    return call('RegisterAccount', email, identifierType, identifier)
end

function GCIdentityRepository.CompleteRegistration(
    accountId,
    email,
    identifierType,
    identifier
)
    return call(
        'CompleteRegistration',
        accountId,
        email,
        identifierType,
        identifier
    )
end

function GCIdentityRepository.TouchLogin(accountId, identifierType, identifier)
    return call('TouchLogin', accountId, identifierType, identifier)
end

function GCIdentityRepository.GetCharacters(accountId)
    return call('GetCharacters', accountId)
end

function GCIdentityRepository.GetCharacterById(characterId)
    return call('GetCharacterById', characterId)
end

function GCIdentityRepository.CreateCharacter(accountId, firstName, lastName, maximum)
    return call('CreateCharacter', accountId, firstName, lastName, maximum)
end

function GCIdentityRepository.SelectCharacter(accountId, characterId)
    return call('SelectCharacter', accountId, characterId)
end

function GCIdentityRepository.ImportLegacyJson()
    if not GCIdentityConfig.storage.importLegacyJson then
        return { imported = 0, skipped = 0 }
    end

    local legacy = GCIdentityRepositories.json_legacy

    if not legacy or type(legacy.LoadRecords) ~= 'function' then
        return nil, 'GC-IDENTITY-LEGACY-STORAGE-INVALID'
    end

    local records, loadError = legacy.LoadRecords()

    if not records then
        return nil, loadError
    end

    local stats = { imported = 0, skipped = 0 }

    for _, record in ipairs(records) do
        local imported, importError, skipped = call('ImportLegacyAccount', record)

        if not imported then
            return nil, importError
        end

        if skipped then
            stats.skipped = stats.skipped + 1
        else
            stats.imported = stats.imported + 1
        end
    end

    return stats
end

function GCIdentityRepository.TestAdapter()
    return adapter
end
