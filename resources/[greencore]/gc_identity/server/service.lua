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
        email = account.email,
        status = account.status,
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

local function failSession(playerSource, generation, errorCode, recoverableState)
    if GCIdentityStates.IsCurrent(playerSource, generation) then
        local nextState = recoverableState

        if not nextState
            or not GCIdentityStates.Transition(playerSource, nextState) then
            GCIdentityStates.Transition(playerSource, 'error')
        end
    end

    return nil, errorCode
end

local function selectedFrom(characters, characterId)
    if not characterId then
        return nil
    end

    for _, character in ipairs(characters or {}) do
        if character.id == characterId then
            return character
        end
    end

    return nil
end

local function commitAuthorized(
    playerSource,
    generation,
    account,
    characters,
    identifierType,
    identifier
)
    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end

    if account.status ~= 'active' then
        return failSession(playerSource, generation, 'GC-IDENTITY-ACCOUNT-DISABLED')
    end

    local touched, touchError = GCIdentityRepository.TouchLogin(
        account.id,
        identifierType,
        identifier
    )

    if not touched then
        return failSession(playerSource, generation, touchError)
    end

    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end

    local bound, bindError = GCIdentityStates.BindAccount(playerSource, account)

    if not bound then
        return failSession(playerSource, generation, bindError)
    end

    GCIdentityStates.SetCharacters(playerSource, characters)
    local transitioned, transitionError = transitionOrError(playerSource, 'authorized')

    if not transitioned then
        return failSession(playerSource, generation, transitionError)
    end

    local selected = selectedFrom(characters, account.selectedCharacterId)

    if selected then
        GCIdentityStates.SelectCharacter(playerSource, selected.id)
        transitioned, transitionError = transitionOrError(playerSource, 'character_selected')

        if transitioned then
            transitioned, transitionError = transitionOrError(playerSource, 'ready')
        end
    else
        GCIdentityStates.SelectCharacter(playerSource, nil)
        transitioned, transitionError = transitionOrError(playerSource, 'character_required')
    end

    if not transitioned then
        return failSession(playerSource, generation, transitionError)
    end

    return GCIdentityService.GetSnapshot(playerSource)
end

local function replayResult(playerSource, action, requestId)
    local replay = GCIdentityStates.GetProcessed(playerSource, action, requestId)

    if not replay then
        return nil
    end

    if replay.ok then
        return replay.value, nil, true
    end

    return nil, replay.code, true
end

local function recordResult(playerSource, action, requestId, value, code)
    GCIdentityStates.RecordProcessed(playerSource, action, requestId, {
        ok = code == nil,
        value = value,
        code = code
    })
end

function GCIdentityService.SetAvailable(value)
    available = value == true
end

function GCIdentityService.IsAvailable()
    return available and GCIdentityRepository.IsReady()
end

function GCIdentityService.GetAccount(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    if not session or not GCIdentityStates.IsAuthorized(playerSource) then
        return nil
    end

    return publicAccount(session.account)
end

function GCIdentityService.GetCharacters(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    if not session or not GCIdentityStates.IsAuthorized(playerSource) then
        return {}
    end

    local result = {}

    for _, character in ipairs(session.characters or {}) do
        table.insert(result, publicCharacter(character))
    end

    return result
end

function GCIdentityService.GetSelectedCharacter(playerSource)
    local session = GCIdentityStates.Get(playerSource)

    if not session or not session.selectedCharacterId then
        return nil
    end

    return publicCharacter(selectedFrom(session.characters, session.selectedCharacterId))
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
        selectedCharacter = GCIdentityService.GetSelectedCharacter(playerSource),
        limits = {
            maxCharacters = GCIdentityConfig.characters.maximum
        },
        passwordAuthentication = false
    }
end

function GCIdentityService.Resolve(playerSource)
    if not validSource(playerSource) then
        return nil, 'GC-IDENTITY-SOURCE-INVALID'
    end

    if not GCIdentityService.IsAvailable() then
        return nil, 'GC-IDENTITY-DATABASE-UNAVAILABLE'
    end

    local core, coreError = coreFor(playerSource, false)

    if not core then
        return nil, coreError
    end

    local existing = GCIdentityStates.Get(playerSource)

    if existing and (
        GCIdentityStates.IsAuthorized(playerSource)
        or existing.state == 'registration_required'
    ) then
        return GCIdentityService.GetSnapshot(playerSource)
    end

    if existing and (existing.state == 'loading' or existing.state == 'registering') then
        return nil, 'GC-IDENTITY-OPERATION-IN-PROGRESS'
    end

    if existing then
        GCIdentityStates.Remove(playerSource)
    end

    local session, sessionError = GCIdentityStates.Create(playerSource)

    if not session then
        return nil, sessionError
    end

    local generation = session.generation
    local transitioned, transitionError = transitionOrError(playerSource, 'loading')

    if not transitioned then
        return failSession(playerSource, generation, transitionError)
    end

    local identifierType, identifier, identifierError = trustedIdentifier(core, playerSource)

    if not identifier then
        return failSession(playerSource, generation, identifierError)
    end

    local account, accountError = GCIdentityRepository.FindAccountByIdentifier(
        identifierType,
        identifier
    )

    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end

    if not account then
        if accountError == 'GC-IDENTITY-ACCOUNT-NOT-FOUND' then
            transitionOrError(playerSource, 'registration_required')
            return GCIdentityService.GetSnapshot(playerSource)
        end

        return failSession(playerSource, generation, accountError)
    end

    if account.status ~= 'active' then
        return failSession(playerSource, generation, 'GC-IDENTITY-ACCOUNT-DISABLED')
    end

    if type(account.email) ~= 'string' or account.email == '' then
        GCIdentityStates.BindAccount(playerSource, account)
        transitionOrError(playerSource, 'registration_required')
        return GCIdentityService.GetSnapshot(playerSource)
    end

    local characters, charactersError = GCIdentityRepository.GetCharacters(account.id)

    if not characters then
        return failSession(playerSource, generation, charactersError)
    end

    return commitAuthorized(
        playerSource,
        generation,
        account,
        characters,
        identifierType,
        identifier
    )
end

function GCIdentityService.Hello(playerSource)
    return GCIdentityService.Resolve(playerSource)
end

function GCIdentityService.RegisterAccount(playerSource, payload)
    local replayValue, replayError, replayed = replayResult(
        playerSource,
        'registration',
        payload.requestId
    )

    if replayed then
        return replayValue, replayError, true
    end

    local core, coreError = coreFor(playerSource, true)

    if not core then
        return nil, coreError
    end

    local session = GCIdentityStates.Get(playerSource)

    if not session or session.state ~= 'registration_required' then
        return nil, 'GC-IDENTITY-INVALID-STATE'
    end

    local generation = session.generation
    local transitioned, transitionError = transitionOrError(playerSource, 'registering')

    if not transitioned then
        return nil, transitionError
    end

    local identifierType, identifier, identifierError = trustedIdentifier(core, playerSource)

    if not identifier then
        return failSession(playerSource, generation, identifierError, 'registration_required')
    end

    local account, registrationError

    if session.accountId then
        account, registrationError = GCIdentityRepository.CompleteRegistration(
            session.accountId,
            payload.email,
            identifierType,
            identifier
        )
    else
        account, registrationError = GCIdentityRepository.RegisterAccount(
            payload.email,
            identifierType,
            identifier
        )
    end

    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end

    if not account then
        local recoverable = registrationError == 'GC-IDENTITY-EMAIL-TAKEN'
            or registrationError == 'GC-IDENTITY-REGISTRATION-CONFLICT'
        local result, resultError = failSession(
            playerSource,
            generation,
            registrationError,
            recoverable and 'registration_required' or nil
        )
        recordResult(playerSource, 'registration', payload.requestId, result, resultError)
        return result, resultError
    end

    local characters, charactersError = GCIdentityRepository.GetCharacters(account.id)

    if not characters then
        return failSession(playerSource, generation, charactersError)
    end

    local snapshot, authorizeError = commitAuthorized(
        playerSource,
        generation,
        account,
        characters,
        identifierType,
        identifier
    )

    if not snapshot then
        return nil, authorizeError
    end

    local accountDto = publicAccount(account)
    recordResult(playerSource, 'registration', payload.requestId, accountDto, nil)
    return accountDto, nil, false
end

function GCIdentityService.CreateCharacter(playerSource, payload)
    local replayValue, replayError, replayed = replayResult(
        playerSource,
        'createCharacter',
        payload.requestId
    )

    if replayed then
        return replayValue and publicCharacter(replayValue) or nil, replayError, true
    end

    local core, coreError = coreFor(playerSource, true)

    if not core then
        return nil, coreError
    end

    local session = GCIdentityStates.Get(playerSource)

    if not session or not GCIdentityStates.IsAuthorized(playerSource) then
        return nil, 'GC-IDENTITY-NOT-AUTHORIZED'
    end

    local generation = session.generation
    local character, createError = GCIdentityRepository.CreateCharacter(
        session.accountId,
        payload.firstName,
        payload.lastName,
        GCIdentityConfig.characters.maximum
    )

    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end

    if not character then
        recordResult(playerSource, 'createCharacter', payload.requestId, nil, createError)
        return nil, createError
    end

    GCIdentityStates.AddCharacter(playerSource, character)
    recordResult(playerSource, 'createCharacter', payload.requestId, character, nil)
    return publicCharacter(character), nil, false
end

function GCIdentityService.SelectCharacter(playerSource, payload)
    local replayValue, replayError, replayed = replayResult(
        playerSource,
        'selectCharacter',
        payload.requestId
    )

    if replayed then
        return replayValue and publicCharacter(replayValue) or nil, replayError, true
    end

    local core, coreError = coreFor(playerSource, true)

    if not core then
        return nil, coreError
    end

    local session = GCIdentityStates.Get(playerSource)

    if not session or not GCIdentityStates.IsAuthorized(playerSource) then
        return nil, 'GC-IDENTITY-NOT-AUTHORIZED'
    end

    local generation = session.generation
    local character, selectError = GCIdentityRepository.SelectCharacter(
        session.accountId,
        payload.characterId
    )

    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end

    if not character then
        recordResult(playerSource, 'selectCharacter', payload.requestId, nil, selectError)
        return nil, selectError
    end

    GCIdentityStates.SelectCharacter(playerSource, character.id)
    local transitioned, transitionError = transitionOrError(playerSource, 'character_selected')

    if transitioned then
        transitioned, transitionError = transitionOrError(playerSource, 'ready')
    end

    if not transitioned then
        return failSession(playerSource, generation, transitionError)
    end

    recordResult(playerSource, 'selectCharacter', payload.requestId, character, nil)
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
    if GCIdentityStates.Get(playerSource) then
        GCIdentityStates.Transition(playerSource, 'disconnecting')
    end

    GCIdentityStates.Remove(playerSource)
    GCIdentityRateLimit.Clear(playerSource)
end
