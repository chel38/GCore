local function registrationPayload(source, email, suffix)
    return {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = ('register_%d_%s'):format(source, suffix or 'request'),
        email = email
    }
end

local function verificationPayload(source, code, suffix)
    return {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = ('verify_%d_%s'):format(source, suffix or 'request'),
        code = code
    }
end

GCModuleTest.Register('identity.crypto_hmac_sha256_vectors', 'security', function()
    GCModuleTest.ExpectEqual(
        GCIdentityCrypto.Sha256('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        'SHA-256 matches the published vector'
    )
    GCModuleTest.ExpectEqual(
        GCIdentityCrypto.HmacSha256('key', 'The quick brown fox jumps over the lazy dog'),
        'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
        'HMAC-SHA256 matches the published vector'
    )
    GCModuleTest.ExpectTrue(
        GCIdentityCrypto.ConstantTimeEquals('same', 'same'),
        'constant-time comparison accepts equal values'
    )
    GCModuleTest.ExpectFalse(
        GCIdentityCrypto.ConstantTimeEquals('same', 'different'),
        'constant-time comparison rejects different values'
    )
end)

GCModuleTest.Register('identity.endpoint_normalization_contract', 'security', function()
    local cases = {
        { '192.168.001.010:30120', '192.168.1.10' },
        { '[2001:db8::1]:30120', '2001:0db8:0000:0000:0000:0000:0000:0001' },
        { '2001:db8:0:0:0:0:0:1', '2001:0db8:0000:0000:0000:0000:0000:0001' },
        { '::ffff:192.0.2.128', '192.0.2.128' }
    }
    for _, case in ipairs(cases) do
        GCModuleTest.ExpectEqual(
            GCIdentityEndpoint.Normalize(case[1]),
            case[2],
            ('endpoint canonicalized: %s'):format(case[1])
        )
    end
    GCModuleTest.ExpectNil(
        GCIdentityEndpoint.Normalize('not-an-endpoint'),
        'malformed endpoint is rejected'
    )
end)

GCModuleTest.Register('identity.registration_requires_correct_one_time_code', 'integration', function()
    local memory = IdentityTest.Reset()
    GCIdentityService.Resolve(71)
    local pending, registrationError = GCIdentityService.RegisterAccount(
        71,
        registrationPayload(71, 'verified@example.test')
    )
    GCModuleTest.ExpectNil(registrationError, 'mail challenge starts')
    GCModuleTest.ExpectTrue(pending.pending, 'registration returns pending result')
    GCModuleTest.ExpectEqual(
        GCIdentityService.GetSnapshot(71).state,
        'email_verification_pending',
        'account remains pending before code verification'
    )
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'pending email creates no account')

    local expectedCode = IdentityTest.LastMailPayload().code
    local rejected, codeError = GCIdentityService.VerifyEmailCode(
        71,
        verificationPayload(71, '000000', 'wrong')
    )
    GCModuleTest.ExpectNil(rejected, 'wrong code authorizes nothing')
    GCModuleTest.ExpectEqual(codeError, 'GC-IDENTITY-EMAIL-CODE-INVALID', 'wrong code is stable')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'wrong code creates no account')

    local account, verifyError = GCIdentityService.VerifyEmailCode(
        71,
        verificationPayload(71, expectedCode, 'correct')
    )
    GCModuleTest.ExpectNil(verifyError, 'correct code verifies registration')
    GCModuleTest.ExpectEqual(account.email, 'verified@example.test', 'verified account is created')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(71), 'correct code authorizes identity')

    local replayed, replayError = GCIdentityService.VerifyEmailCode(
        71,
        verificationPayload(71, expectedCode, 'reuse')
    )
    GCModuleTest.ExpectNil(replayed, 'consumed code cannot be submitted again')
    GCModuleTest.ExpectEqual(replayError, 'GC-IDENTITY-INVALID-STATE', 'code reuse is rejected')
end)

GCModuleTest.Register('identity.verification_expiry_and_attempt_limit_fail_closed', 'security', function()
    local memory = IdentityTest.Reset()
    GCIdentityService.Resolve(72)
    GCIdentityService.RegisterAccount(72, registrationPayload(72, 'expiry@example.test'))
    memory.SetLastChallengeExpires(os.time() - 1)
    local _, expiredError = GCIdentityService.VerifyEmailCode(
        72,
        verificationPayload(72, IdentityTest.LastMailPayload().code, 'expired')
    )
    GCModuleTest.ExpectEqual(expiredError, 'GC-IDENTITY-EMAIL-CODE-EXPIRED', 'expired code rejected')
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(72), 'expired code never authorizes')

    IdentityTest.Reset()
    GCIdentityService.Resolve(73)
    GCIdentityService.RegisterAccount(73, registrationPayload(73, 'attempts@example.test'))
    for attempt = 1, GCIdentityConfig.verification.maximumAttempts do
        local _, attemptError = GCIdentityService.VerifyEmailCode(
            73,
            verificationPayload(73, '000000', tostring(attempt))
        )
        local expected = attempt == GCIdentityConfig.verification.maximumAttempts
            and 'GC-IDENTITY-EMAIL-CODE-ATTEMPTS'
            or 'GC-IDENTITY-EMAIL-CODE-INVALID'
        GCModuleTest.ExpectEqual(attemptError, expected, 'attempt policy is deterministic')
    end
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(73), 'attempt exhaustion fails closed')
end)

GCModuleTest.Register('identity.resend_invalidates_previous_code', 'security', function()
    IdentityTest.Reset()
    GCIdentityService.Resolve(74)
    GCIdentityService.RegisterAccount(74, registrationPayload(74, 'resend@example.test'))
    local oldCode = IdentityTest.LastMailPayload().code
    local previousCooldown = GCIdentityConfig.verification.resendCooldownSeconds
    GCIdentityConfig.verification.resendCooldownSeconds = 0
    local resent, resendError = GCIdentityService.ResendVerification(74, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'resend_7400'
    })
    GCIdentityConfig.verification.resendCooldownSeconds = previousCooldown
    GCModuleTest.ExpectNil(resendError, 'resend succeeds after cooldown')
    GCModuleTest.ExpectTrue(resent.pending, 'resend remains pending')
    local newCode = IdentityTest.LastMailPayload().code
    GCModuleTest.ExpectFalse(oldCode == newCode, 'resend generates a new code')

    local _, oldError = GCIdentityService.VerifyEmailCode(
        74,
        verificationPayload(74, oldCode, 'old')
    )
    GCModuleTest.ExpectEqual(oldError, 'GC-IDENTITY-EMAIL-CODE-INVALID', 'old code is invalid')
    local account, newError = GCIdentityService.VerifyEmailCode(
        74,
        verificationPayload(74, newCode, 'new')
    )
    GCModuleTest.ExpectNil(newError, 'new code succeeds')
    GCModuleTest.ExpectNotNil(account, 'new code creates account')
end)

GCModuleTest.Register('identity.same_ip_auto_auth_new_ip_requires_code', 'integration', function()
    IdentityTest.Reset()
    IdentityTest.SetEndpoint(75, '192.0.2.10:30120')
    IdentityTest.ResolveAndRegister(75, 'network@example.test', 'register_7500')
    GCIdentityService.Disconnect(75)

    local sameIp = GCIdentityService.Resolve(75)
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(75), 'same IP auto-authorizes')
    GCModuleTest.ExpectEqual(sameIp.account.email, 'network@example.test', 'same account restored')
    GCIdentityService.Disconnect(75)

    IdentityTest.SetEndpoint(75, '[2001:db8::75]:30120')
    local newIp = GCIdentityService.Resolve(75)
    GCModuleTest.ExpectEqual(
        newIp.state,
        'auth_verification_required',
        'new IP requires authentication code'
    )
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(75), 'new IP is not authorized early')
    GCModuleTest.ExpectEqual(
        IdentityTest.LastMailPayload().type,
        'authentication',
        'authentication email type is distinct'
    )

    local account, authError = GCIdentityService.VerifyEmailCode(
        75,
        verificationPayload(75, IdentityTest.LastMailPayload().code, 'new_ip')
    )
    GCModuleTest.ExpectNil(authError, 'correct new-IP code succeeds')
    GCModuleTest.ExpectNotNil(account, 'new-IP verification returns account DTO')
    GCModuleTest.ExpectTrue(GCIdentityStates.IsAuthorized(75), 'new IP becomes trusted')
end)

GCModuleTest.Register('identity.mail_failure_policy_is_fail_closed', 'security', function()
    local memory = IdentityTest.Reset()
    IdentityTest.SetMailResponse({ status = 502, body = '{}' })
    GCIdentityService.Resolve(76)
    GCIdentityService.RegisterAccount(76, registrationPayload(76, 'maildown@example.test'))
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(76), 'mail failure blocks registration')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'mail failure creates no account')

    IdentityTest.Reset()
    IdentityTest.SetEndpoint(77, '192.0.2.77:30120')
    IdentityTest.ResolveAndRegister(77, 'existing@example.test', 'register_7700')
    GCIdentityService.Disconnect(77)
    IdentityTest.SetMailResponse({ status = 502, body = '{}' })
    local sameIp = GCIdentityService.Resolve(77)
    GCModuleTest.ExpectNotNil(sameIp.account, 'same-IP login does not depend on mail availability')
    GCIdentityService.Disconnect(77)
    IdentityTest.SetEndpoint(77, '192.0.2.78:30120')
    GCIdentityService.Resolve(77)
    GCModuleTest.ExpectFalse(GCIdentityStates.IsAuthorized(77), 'new-IP login never bypasses failed mail')
end)

GCModuleTest.Register('identity.mail_timeout_is_bounded', 'runtime', function()
    local memory = IdentityTest.Reset()
    IdentityTest.SetMailResponse({ timeout = true })
    GCIdentityService.Resolve(78)
    GCIdentityService.RegisterAccount(78, registrationPayload(78, 'timeout@example.test'))
    GCModuleTest.ExpectEqual(
        GCIdentityService.GetSnapshot(78).state,
        'registering',
        'pending HTTP request has explicit processing state'
    )
    IdentityTest.Advance(GCIdentityConfig.mail.requestTimeoutMs)
    GCModuleTest.ExpectEqual(
        GCIdentityService.GetSnapshot(78).state,
        'registration_required',
        'timeout returns to controlled registration state'
    )
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'timeout creates no account')
end)

GCModuleTest.Register('identity.verification_snapshot_and_api_hide_secrets', 'contract', function()
    local memory = IdentityTest.Reset()
    GCIdentityService.Resolve(79)
    GCIdentityService.RegisterAccount(79, registrationPayload(79, 'privacy@example.test'))
    local snapshot = GCIdentityService.GetSnapshot(79)
    local challenge = memory.GetLastChallenge()
    GCModuleTest.ExpectEqual(snapshot.verification.maskedEmail, 'p***@example.test', 'NUI sees masked email')
    GCModuleTest.ExpectNil(snapshot.verification.code, 'NUI sees no raw code')
    GCModuleTest.ExpectNil(snapshot.verification.codeHash, 'NUI sees no code hash')
    GCModuleTest.ExpectNil(snapshot.verification.ipFingerprint, 'NUI sees no IP fingerprint')
    GCModuleTest.ExpectNil(GCIdentityAPI.GetAccount(79), 'public API exposes no pending account')
    GCModuleTest.ExpectNotNil(challenge.codeHash, 'repository stores only the verification digest')
    GCModuleTest.ExpectFalse(
        challenge.codeHash == IdentityTest.LastMailPayload().code,
        'stored digest is not the raw code'
    )
end)

GCModuleTest.Register('identity.verification_challenge_is_account_bound', 'security', function()
    local memory = IdentityTest.Reset()
    local challenge = memory.CreateVerificationChallenge({
        accountId = nil,
        bindingKey = ('a'):rep(64),
        email = 'bound@example.test',
        type = 'registration',
        codeHash = ('b'):rep(64),
        expiresAt = os.time() + 60,
        maxAttempts = 5
    })
    local account, completionError = memory.CompleteVerifiedRegistration(
        challenge.id,
        999,
        challenge.email,
        'license',
        'license:bound',
        ('c'):rep(64)
    )
    GCModuleTest.ExpectNil(account, 'challenge cannot move to another account')
    GCModuleTest.ExpectEqual(
        completionError,
        'GC-IDENTITY-EMAIL-CHALLENGE-STALE',
        'account binding mismatch fails closed'
    )
end)
