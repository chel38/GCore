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

local function maskEmail(email)
    local localPart, domain = email:match('^([^@]+)@(.+)$')
    if not localPart then
        return '***'
    end
    return ('%s***@%s'):format(localPart:sub(1, 1), domain)
end

local function currentIpFingerprint(playerSource)
    local normalized, endpointError = GCIdentityEndpoint.ForPlayer(playerSource)
    if not normalized then
        return nil, endpointError
    end

    local fingerprint = GCIdentityCrypto.HmacSha256(
        GCIdentitySecurityConfig.IpSecret(),
        'gcore-ip-v1\0' .. normalized
    )
    if not fingerprint then
        return nil, 'GC-IDENTITY-IP-SECRET-MISSING'
    end
    return fingerprint
end

local function challengeBinding(verificationType, identifierType, identifier, ipFingerprint)
    local value = table.concat({
        'gcore-verification-binding-v1',
        verificationType,
        identifierType,
        identifier,
        ipFingerprint
    }, '\0')
    return GCIdentityCrypto.HmacSha256(
        GCIdentitySecurityConfig.ChallengeSecret(),
        value
    )
end

local function verificationHash(bindingKey, verificationType, email, code)
    return GCIdentityCrypto.HmacSha256(
        GCIdentitySecurityConfig.ChallengeSecret(),
        table.concat({
            'gcore-verification-code-v1',
            bindingKey,
            verificationType,
            email,
            code
        }, '\0')
    )
end

local function sendRejected(playerSource, code)
    TriggerClientEvent(GCIdentityEvents.client.rejected, playerSource, { code = code })
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

    GCIdentityStates.ClearPendingVerification(playerSource)

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

    local verification
    local pending = session.pendingVerification

    if pending then
        verification = {
            type = pending.type,
            maskedEmail = maskEmail(pending.email),
            expiresIn = math.max(0, (pending.expiresAt or os.time()) - os.time()),
            resendIn = math.max(
                0,
                (pending.lastSentAt or 0)
                    + GCIdentityConfig.verification.resendCooldownSeconds
                    - os.time()
            )
        }
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
        passwordAuthentication = false,
        verification = verification
    }
end

local function beginVerification(playerSource, generation, options, isResend)
    local now = os.time()
    local existing = GCIdentityRepository.GetVerificationChallenge(
        options.bindingKey,
        options.type
    )

    if existing and existing.email == options.email and existing.expiresAt > now then
        local resendIn = existing.lastSentAt
            + GCIdentityConfig.verification.resendCooldownSeconds - now
        GCIdentityStates.SetPendingVerification(playerSource, {
            type = options.type,
            email = options.email,
            accountId = options.accountId,
            identifierType = options.identifierType,
            identifier = options.identifier,
            ipFingerprint = options.ipFingerprint,
            bindingKey = options.bindingKey,
            challengeId = existing.id,
            expiresAt = existing.expiresAt,
            lastSentAt = existing.lastSentAt
        })

        if resendIn > 0 then
            transitionOrError(playerSource, options.pendingState)
            if isResend then
                return nil, 'GC-IDENTITY-EMAIL-RESEND-COOLDOWN'
            end
            return GCIdentityService.GetSnapshot(playerSource)
        end
    end

    local code, randomError = GCIdentityRepository.GenerateVerificationCode()
    if not code then
        transitionOrError(playerSource, options.failureState)
        return nil, randomError
    end

    local codeHash = verificationHash(
        options.bindingKey,
        options.type,
        options.email,
        code
    )
    if not codeHash then
        transitionOrError(playerSource, options.failureState)
        return nil, 'GC-IDENTITY-CHALLENGE-SECRET-MISSING'
    end

    local challenge, challengeError = GCIdentityRepository.CreateVerificationChallenge({
        accountId = options.accountId,
        bindingKey = options.bindingKey,
        email = options.email,
        type = options.type,
        codeHash = codeHash,
        expiresAt = now + GCIdentityConfig.verification.ttlSeconds,
        maxAttempts = GCIdentityConfig.verification.maximumAttempts
    })
    if not challenge then
        transitionOrError(playerSource, options.failureState)
        return nil, challengeError
    end

    GCIdentityStates.SetPendingVerification(playerSource, {
        type = options.type,
        email = options.email,
        accountId = options.accountId,
        identifierType = options.identifierType,
        identifier = options.identifier,
        ipFingerprint = options.ipFingerprint,
        bindingKey = options.bindingKey,
        challengeId = challenge.id,
        expiresAt = challenge.expiresAt,
        lastSentAt = challenge.lastSentAt
    })

    GCIdentityMailClient.SendVerification(
        options.email,
        code,
        options.type,
        function(sent, mailError)
            if not GCIdentityStates.IsCurrent(playerSource, generation) then
                return
            end

            if sent then
                transitionOrError(playerSource, options.pendingState)
                GCIdentityLogger.Info(
                    'GC-IDENTITY-EMAIL-VERIFICATION-SENT',
                    'Verification email accepted by local mail service',
                    { source = playerSource, type = options.type }
                )
            else
                GCIdentityRepository.InvalidateVerificationChallenge(challenge.id)
                transitionOrError(playerSource, options.failureState)
                GCIdentityLogger.Warn(
                    mailError or 'GC-IDENTITY-MAIL-SEND-FAILED',
                    'Verification email delivery failed',
                    { source = playerSource, type = options.type }
                )
                sendRejected(playerSource, mailError or 'GC-IDENTITY-MAIL-SEND-FAILED')
            end
            GCIdentityService.SendSnapshot(playerSource)
        end,
        function()
            local session = GCIdentityStates.Get(playerSource)
            return session ~= nil
                and session.generation == generation
                and session.pendingVerification ~= nil
                and session.pendingVerification.challengeId == challenge.id
        end
    )

    return { pending = true }
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
        or existing.state == 'email_verification_pending'
        or existing.state == 'auth_verification_required'
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

    if type(account.email) ~= 'string' or account.email == ''
        or type(account.emailVerifiedAt) ~= 'number' then
        GCIdentityStates.BindAccount(playerSource, account)
        transitionOrError(playerSource, 'registration_required')
        return GCIdentityService.GetSnapshot(playerSource)
    end

    local ipFingerprint, endpointError = currentIpFingerprint(playerSource)
    if not ipFingerprint then
        return failSession(playerSource, generation, endpointError)
    end

    if account.lastIpFingerprint ~= ipFingerprint then
        GCIdentityStates.BindAccount(playerSource, account)
        local bindingKey = challengeBinding(
            'authentication',
            identifierType,
            identifier,
            ipFingerprint
        )
        if not bindingKey then
            return failSession(
                playerSource,
                generation,
                'GC-IDENTITY-CHALLENGE-SECRET-MISSING'
            )
        end

        GCIdentityLogger.Warn(
            'GC-IDENTITY-AUTH-NEW-IP',
            'New server-observed network address requires email verification',
            { source = playerSource }
        )
        local started, startError = beginVerification(playerSource, generation, {
            type = 'authentication',
            email = account.email,
            accountId = account.id,
            identifierType = identifierType,
            identifier = identifier,
            ipFingerprint = ipFingerprint,
            bindingKey = bindingKey,
            pendingState = 'auth_verification_required',
            failureState = 'auth_verification_required'
        }, false)
        if not started then
            return nil, startError
        end
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

    local existingEmail, emailError = GCIdentityRepository.FindAccountByEmail(payload.email)
    if not GCIdentityStates.IsCurrent(playerSource, generation) then
        return nil, 'GC-IDENTITY-SESSION-STALE'
    end
    if existingEmail and existingEmail.id ~= session.accountId then
        transitionOrError(playerSource, 'registration_required')
        recordResult(
            playerSource,
            'registration',
            payload.requestId,
            nil,
            'GC-IDENTITY-EMAIL-TAKEN'
        )
        return nil, 'GC-IDENTITY-EMAIL-TAKEN'
    end
    if not existingEmail and emailError ~= 'GC-IDENTITY-ACCOUNT-NOT-FOUND' then
        return failSession(playerSource, generation, emailError)
    end

    local ipFingerprint, endpointError = currentIpFingerprint(playerSource)
    if not ipFingerprint then
        return failSession(playerSource, generation, endpointError, 'registration_required')
    end
    local bindingKey = challengeBinding(
        'registration',
        identifierType,
        identifier,
        ipFingerprint
    )
    if not bindingKey then
        return failSession(
            playerSource,
            generation,
            'GC-IDENTITY-CHALLENGE-SECRET-MISSING',
            'registration_required'
        )
    end

    local result, resultError = beginVerification(playerSource, generation, {
        type = 'registration',
        email = payload.email,
        accountId = session.accountId,
        identifierType = identifierType,
        identifier = identifier,
        ipFingerprint = ipFingerprint,
        bindingKey = bindingKey,
        pendingState = 'email_verification_pending',
        failureState = 'registration_required'
    }, false)
    recordResult(playerSource, 'registration', payload.requestId, result, resultError)
    return result, resultError, false
end

function GCIdentityService.ResendVerification(playerSource, payload)
    local replayValue, replayError, replayed = replayResult(
        playerSource,
        'resendVerification',
        payload.requestId
    )
    if replayed then
        return replayValue, replayError, true
    end

    local core, coreError = coreFor(playerSource, true)
    if not core then return nil, coreError end
    local session = GCIdentityStates.Get(playerSource)
    local pending = session and session.pendingVerification
    if not session or not pending or (
        session.state ~= 'email_verification_pending'
        and session.state ~= 'auth_verification_required'
    ) then
        return nil, 'GC-IDENTITY-INVALID-STATE'
    end

    local processingState = pending.type == 'registration' and 'registering' or 'loading'
    local pendingState = pending.type == 'registration'
        and 'email_verification_pending' or 'auth_verification_required'
    local transitioned, transitionError = transitionOrError(playerSource, processingState)
    if not transitioned then return nil, transitionError end

    local result, resultError = beginVerification(playerSource, session.generation, {
        type = pending.type,
        email = pending.email,
        accountId = pending.accountId,
        identifierType = pending.identifierType,
        identifier = pending.identifier,
        ipFingerprint = pending.ipFingerprint,
        bindingKey = pending.bindingKey,
        pendingState = pendingState,
        failureState = pendingState
    }, true)
    recordResult(playerSource, 'resendVerification', payload.requestId, result, resultError)
    return result, resultError, false
end

function GCIdentityService.VerifyEmailCode(playerSource, payload)
    local replayValue, replayError, replayed = replayResult(
        playerSource,
        'verifyEmail',
        payload.requestId
    )
    if replayed then return replayValue, replayError, true end

    local core, coreError = coreFor(playerSource, true)
    if not core then return nil, coreError end
    local session = GCIdentityStates.Get(playerSource)
    local pending = session and session.pendingVerification
    if not session or not pending or (
        session.state ~= 'email_verification_pending'
        and session.state ~= 'auth_verification_required'
    ) then
        return nil, 'GC-IDENTITY-INVALID-STATE'
    end

    local generation = session.generation
    local pendingState = pending.type == 'registration'
        and 'email_verification_pending' or 'auth_verification_required'
    local processingState = pending.type == 'registration' and 'registering' or 'loading'
    local transitioned, transitionError = transitionOrError(playerSource, processingState)
    if not transitioned then return nil, transitionError end

    local identifierType, identifier, identifierError = trustedIdentifier(core, playerSource)
    if not identifier then
        return failSession(playerSource, generation, identifierError, pendingState)
    end
    local ipFingerprint, endpointError = currentIpFingerprint(playerSource)
    if not ipFingerprint then
        return failSession(playerSource, generation, endpointError, pendingState)
    end
    local bindingKey = challengeBinding(
        pending.type,
        identifierType,
        identifier,
        ipFingerprint
    )
    if not GCIdentityCrypto.ConstantTimeEquals(bindingKey or '', pending.bindingKey) then
        transitionOrError(playerSource, pendingState)
        return nil, 'GC-IDENTITY-EMAIL-CHALLENGE-STALE'
    end

    local challenge, challengeError = GCIdentityRepository.GetVerificationChallenge(
        pending.bindingKey,
        pending.type
    )
    if not challenge then
        transitionOrError(playerSource, pendingState)
        return nil, challengeError
    end
    if challenge.expiresAt <= os.time() then
        GCIdentityRepository.InvalidateVerificationChallenge(challenge.id)
        transitionOrError(playerSource, pendingState)
        return nil, 'GC-IDENTITY-EMAIL-CODE-EXPIRED'
    end
    if challenge.attempts >= challenge.maxAttempts then
        transitionOrError(playerSource, pendingState)
        return nil, 'GC-IDENTITY-EMAIL-CODE-ATTEMPTS'
    end

    local submittedHash = verificationHash(
        challenge.bindingKey,
        challenge.type,
        challenge.email,
        payload.code
    )
    if not GCIdentityCrypto.ConstantTimeEquals(submittedHash or '', challenge.codeHash) then
        GCIdentityRepository.RecordVerificationFailure(challenge.id)
        transitionOrError(playerSource, pendingState)
        local code = challenge.attempts + 1 >= challenge.maxAttempts
            and 'GC-IDENTITY-EMAIL-CODE-ATTEMPTS'
            or 'GC-IDENTITY-EMAIL-CODE-INVALID'
        GCIdentityLogger.Warn(
            code,
            'Verification code rejected',
            { source = playerSource, type = pending.type }
        )
        recordResult(playerSource, 'verifyEmail', payload.requestId, nil, code)
        return nil, code
    end

    local account, completionError
    if pending.type == 'registration' then
        account, completionError = GCIdentityRepository.CompleteVerifiedRegistration(
            challenge.id,
            pending.accountId,
            challenge.email,
            identifierType,
            identifier,
            ipFingerprint
        )
    else
        account, completionError = GCIdentityRepository.CompleteVerifiedAuthentication(
            challenge.id,
            pending.accountId,
            ipFingerprint
        )
    end
    if not account then
        return failSession(playerSource, generation, completionError, pendingState)
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
    if not snapshot then return nil, authorizeError end

    GCIdentityLogger.Info(
        pending.type == 'registration'
            and 'GC-IDENTITY-EMAIL-VERIFIED' or 'GC-IDENTITY-AUTH-NEW-IP-VERIFIED',
        'Email verification completed',
        { source = playerSource, type = pending.type }
    )
    local accountDto = publicAccount(account)
    recordResult(playerSource, 'verifyEmail', payload.requestId, accountDto, nil)
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
