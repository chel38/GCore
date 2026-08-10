GCIdentityRepositories = GCIdentityRepositories or {}

local JsonLegacyRepository = {}

function JsonLegacyRepository.LoadRecords()
    local raw = LoadResourceFile(
        GetCurrentResourceName(),
        GCIdentityConfig.storage.legacyFile
    )

    if raw == nil or raw == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, raw)

    if not ok
        or type(decoded) ~= 'table'
        or type(decoded.accounts) ~= 'table'
        or type(decoded.characters) ~= 'table' then
        return nil, 'GC-IDENTITY-LEGACY-STORAGE-INVALID'
    end

    local charactersByAccount = {}

    for _, character in ipairs(decoded.characters) do
        if type(character) == 'table' and type(character.accountId) == 'number' then
            charactersByAccount[character.accountId] = charactersByAccount[character.accountId] or {}
            table.insert(charactersByAccount[character.accountId], character)
        end
    end

    local records = {}

    for _, account in ipairs(decoded.accounts) do
        if type(account) == 'table'
            and type(account.identifierType) == 'string'
            and type(account.identifier) == 'string' then
            table.insert(records, {
                legacyAccountId = account.id,
                identifierType = account.identifierType,
                identifier = account.identifier,
                selectedCharacterId = account.selectedCharacterId,
                createdAt = account.createdAt,
                updatedAt = account.updatedAt,
                characters = charactersByAccount[account.id] or {}
            })
        end
    end

    return records
end

GCIdentityRepositories.json_legacy = JsonLegacyRepository
