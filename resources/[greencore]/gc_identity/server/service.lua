GCIdentityService = {}

local available = false

local function validSource(playerSource)
    return type(playerSource) == 'number'
        and playerSource > 0
        and playerSource % 1 == 0
end

local function publicAccount(account)
    if not account then
        return nil
    end

    return {
        id = account.id,
        createdAt = account.createdAt
    }
end

local function publicCharacter(character)
    if not character then
        return nil
    end

    return {
        id = character.id,
        firstName = character.firstName,
        lastName = character.lastName,
        createdAt = character.createdAt
    }
end

local function coreFor(playerSource, requireGameplay)
    if GetResourceState('gc_core') ~= 'started' then
        return nil, 'GC-IDENTITY-CORE-UNAVAILABLE'
    end

    local ok, coreOrError, contractError = pcall(function()
        local core = exports['gc_core']
        local apiVersion = core:GetApiVersion()

        if type(apiVersion) ~= 'number'
            or apiVersion % 1 ~= 0
            or apiVersion < GCIdentityConfig.requiredCoreApi then
            return nil, 'GC-IDENTITY-CORE-API-INCOMPATIBLE'
        end

        if not core:IsPlayerConnected(playerSource) then
            return nil, 'GC-IDENTITY-CORE-PLAYER-NOT-CONNECTED'
        end

        if not core:IsPlayerReady(playerSource) then
            return nil, 'GC-IDENTITY-CORE-PLAYER-NOT-READY'
        end

        if requireGameplay and not core:CanUseGameplayFeatures(playerSource) then
            return nil, 'GC-IDENTITY-CORE-GAMEPLAY-NOT-READY'
        end

        return core
    end)

    if not ok then
        return nil, 'GC-IDENTITY-CORE-UNAVAILABLE'
    end

    return coreOrError, contractError
end

local function trustedIdentifier(core, playerSource)
    for _, identifierType in ipairs(GCIdentityConfig.identifierTypes) do
        local identifier = core:GetPlayerIdentifier(playerSource, identifierType)

        if type(identifier) == 'string' and identifier ~= '' then
            return identifierType, identifier
        end
    end

    return nil, nil, 'GC-IDENTITY-ACCOUNT-IDENTIFIER-MISSING'
end

local function transitionOrError(playerSource, nextState)
    local transitioned, transitionError = GCIdentityStates.Transition(playerSource, nextState)

    if not transitioned then
        return false, transitionError
    end

    return true
end

function GCIdentityService.SetAvailable(value)
    available = value == true
end

function GCIdentityService.IsAvailable()
    return available and GCIdentityRepository.IsLoaded()
end

function GCIdentityService.GetAccount(playerSource)
    local session = GCIdentityStates.Get(playerSource)
    return session and publicAccount(GCIdentityRepository.GetAccountById(session.accountId)) or nil
end

function GCIdentityService.GetCharacters(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    if not session or not session.accountId then
        return {}
    end

    local result = {}

    for _, character in ipairs(GCIdentityRepository.GetCharacters(session.accountId)) do
        table.insert(result, publicCharacter(character))
    end

    return result
end

function GCIdentityService.GetSelectedCharacter(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    if not session or not session.selectedCharacterId then
        return nil
    end

    return publicCharacter(GCIdentityRepository.GetCharacterById(session.selectedCharacterId))
end

function GCIdentityService.GetSnapshot(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    if not session then
        return nil
    end

    return {
        protocolVersion = GCIdentityVersion.protocol,
        state = session.state,
        account = GCIdentityService.GetAccount(playerSource),
        characters = GCIdentityService.GetCharacters(playerSource),
        selectedCharacter = GCIdentityService.GetSelectedCharacter(playerSource)
    }
end

function GCIdentityService.Resolve(playerSource)
    if not validSource(playerSource) then
        return nil, 'GC-IDENTITY-SOURCE-INVALID'
    end

    if not GCIdentityService.IsAvailable() then
        return nil, 'GC-IDENTITY-STORAGE-NOT-LOADED'
    end

    local core, coreError = coreFor(playerSource, false)

    if not core then
        return nil, coreError
    end

    local existingSession = GCIdentityStates.Get(playerSource)

    if existingSession and GCIdentityStates.IsAuthorized(playerSource) then
        return GCIdentityService.GetSnapshot(playerSource)
    end

    if existingSession and existingSession.state == 'error' then
        GCIdentityStates.Remove(playerSource)
    end

    local session, sessionError = GCIdentityStates.Create(playerSource)

    if not session then
        return nil, sessionError
    end

    local transitioned, transitionError = transitionOrError(playerSource, 'account_required')

    if not transitioned then
        return nil, transitionError
    end

    local identifierType, identifier, identifierError = trustedIdentifier(core, playerSource)

    if not identifier then
        GCIdentityStates.Transition(playerSource, 'error')
        return nil, identifierError
    end

    local account = GCIdentityRepository.FindAccountByIdentifier(identifierType, identifier)

    if not account then
        account, sessionError = GCIdentityRepository.CreateAccount(identifierType, identifier)

        if not account then
            GCIdentityStates.Transition(playerSource, 'error')
            return nil, sessionError
        end
    end

    session.accountId = account.id
    transitioned, transitionError = transitionOrError(playerSource, 'authorized')

    if not transitioned then
        return nil, transitionError
    end

    local selected = account.selectedCharacterId
        and GCIdentityRepository.GetCharacterById(account.selectedCharacterId)

    if selected and selected.accountId == account.id then
        session.selectedCharacterId = selected.id
        transitioned, transitionError = transitionOrError(playerSource, 'ready')
    else
        session.selectedCharacterId = nil
        transitioned, transitionError = transitionOrError(playerSource, 'character_required')
    end

    if not transitioned then
        return nil, transitionError
    end

    return GCIdentityService.GetSnapshot(playerSource)
end

function GCIdentityService.Hello(playerSource)
    local allowed, rateError = GCIdentityRateLimit.Check(playerSource, 'hello')

    if not allowed then
        return nil, rateError
    end

    return GCIdentityService.Resolve(playerSource)
end

function GCIdentityService.CreateCharacter(playerSource, payload)
    local core, coreError = coreFor(playerSource, true)

    if not core then
        return nil, coreError
    end

    local session = GCIdentityStates.Get(playerSource)

    if not session or not GCIdentityStates.IsAuthorized(playerSource) then
        return nil, 'GC-IDENTITY-STATE-NOT-AUTHORIZED'
    end

    local replay = GCIdentityStates.GetProcessed(playerSource, 'createCharacter', payload.requestId)

    if replay then
        return publicCharacter(replay), nil, true
    end

    local allowed, rateError = GCIdentityRateLimit.Check(playerSource, 'createCharacter')

    if not allowed then
        return nil, rateError
    end

    local characters = GCIdentityRepository.GetCharacters(session.accountId)

    if #characters >= GCIdentityConfig.characters.maximum then
        return nil, 'GC-IDENTITY-CHARACTER-LIMIT'
    end

    local character, createError = GCIdentityRepository.CreateCharacter(
        session.accountId,
        payload.firstName,
        payload.lastName
    )

    if not character then
        return nil, createError
    end

    GCIdentityStates.RecordProcessed(
        playerSource,
        'createCharacter',
        payload.requestId,
        character
    )

    return publicCharacter(character), nil, false
end

function GCIdentityService.SelectCharacter(playerSource, payload)
    local core, coreError = coreFor(playerSource, true)

    if not core then
        return nil, coreError
    end

    local session = GCIdentityStates.Get(playerSource)

    if not session or not GCIdentityStates.IsAuthorized(playerSource) then
        return nil, 'GC-IDENTITY-STATE-NOT-AUTHORIZED'
    end

    local replay = GCIdentityStates.GetProcessed(playerSource, 'selectCharacter', payload.requestId)

    if replay then
        return publicCharacter(replay), nil, true
    end

    local allowed, rateError = GCIdentityRateLimit.Check(playerSource, 'selectCharacter')

    if not allowed then
        return nil, rateError
    end

    local selected, selectError = GCIdentityRepository.SelectCharacter(
        session.accountId,
        payload.characterId
    )

    if not selected then
        return nil, selectError
    end

    local character = GCIdentityRepository.GetCharacterById(payload.characterId)
    session.selectedCharacterId = character.id
    local transitioned, transitionError = transitionOrError(playerSource, 'ready')

    if not transitioned then
        return nil, transitionError
    end

    GCIdentityStates.RecordProcessed(
        playerSource,
        'selectCharacter',
        payload.requestId,
        character
    )

    return publicCharacter(character), nil, false
end

function GCIdentityService.SendSnapshot(playerSource)
    local snapshot = GCIdentityService.GetSnapshot(playerSource)

    if snapshot then
        TriggerClientEvent(GCIdentityEvents.client.snapshot, playerSource, snapshot)
    end

    return snapshot
end

function GCIdentityService.RecoverOnlinePlayers()
    if not GCIdentityService.IsAvailable() then
        return 0
    end

    local recovered = 0

    for _, value in ipairs(GetPlayers()) do
        local playerSource = tonumber(value)

        if playerSource then
            local snapshot = GCIdentityService.Resolve(playerSource)

            if snapshot then
                recovered = recovered + 1
                GCIdentityService.SendSnapshot(playerSource)
            end
        end
    end

    return recovered
end

function GCIdentityService.Disconnect(playerSource)
    GCIdentityStates.Remove(playerSource)
    GCIdentityRateLimit.Clear(playerSource)
end
