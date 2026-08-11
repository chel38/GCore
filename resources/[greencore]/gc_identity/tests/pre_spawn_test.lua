local function registration(source, email, requestId)
    return GCIdentityService.SendRegistrationCode(source, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = requestId,
        firstName = 'Secure',
        lastName = 'Player',
        email = email
    })
end

local function verifyLastCode(source, requestId)
    return GCIdentityService.VerifyEmailCode(source, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = requestId,
        code = IdentityTest.LastMailPayload().code
    })
end

GCModuleTest.Register('identity.pre_spawn_registration_requires_explicit_finalize', 'security', function()
    local memory = IdentityTest.Reset()
    GCIdentityService.Resolve(81)
    local pending, sendError = registration(81, 'prespawn@example.test', 'prespawn_send_81')
    GCModuleTest.ExpectNil(sendError, 'registration challenge is sent')
    GCModuleTest.ExpectTrue(pending.pending, 'registration remains pending')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[81] or 0, 0, 'email submit cannot spawn')

    local verified, verifyError = verifyLastCode(81, 'prespawn_verify_81')
    GCModuleTest.ExpectNil(verifyError, 'valid code is accepted')
    GCModuleTest.ExpectTrue(verified.verified, 'code marks only the challenge verified')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'code verification creates no account')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[81] or 0, 0, 'code verification cannot spawn')

    local payload = {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'prespawn_finalize_81'
    }
    local account, finalizeError, replayed = GCIdentityService.FinalizeRegistration(81, payload)
    GCModuleTest.ExpectNil(finalizeError, 'explicit finalization succeeds')
    GCModuleTest.ExpectFalse(replayed, 'first finalization is not a replay')
    GCModuleTest.ExpectEqual(account.displayName, 'Secure Player', 'registered name is persisted')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 1, 'finalization creates one account')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[81], 1, 'finalization releases exactly one spawn')

    local replayAccount, replayError, wasReplay = GCIdentityService.FinalizeRegistration(81, payload)
    GCModuleTest.ExpectNil(replayError, 'duplicate finalization is idempotent')
    GCModuleTest.ExpectTrue(wasReplay, 'duplicate finalization uses the replay record')
    GCModuleTest.ExpectEqual(replayAccount.id, account.id, 'duplicate returns the same public account')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[81], 1, 'duplicate finalization cannot spawn twice')
end)

GCModuleTest.Register('identity.registration_email_change_invalidates_verified_challenge', 'security', function()
    local memory = IdentityTest.Reset()
    GCIdentityService.Resolve(82)
    registration(82, 'old@example.test', 'email_change_send_82')
    local oldChallenge = memory.GetLastChallenge()
    verifyLastCode(82, 'email_change_verify_82')

    local changed, changeError = GCIdentityService.ChangeRegistrationEmail(82, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'email_change_82'
    })
    GCModuleTest.ExpectNil(changeError, 'email change is allowed before finalization')
    GCModuleTest.ExpectTrue(changed.changed, 'email change is explicit')
    local snapshot = GCIdentityService.GetSnapshot(82)
    GCModuleTest.ExpectEqual(snapshot.state, 'registration_required', 'flow returns to registration')
    GCModuleTest.ExpectEqual(snapshot.registration.fullName, 'Secure Player', 'registered name is retained')
    GCModuleTest.ExpectEqual(snapshot.registration.email, '', 'old email is removed from pending DTO')
    GCModuleTest.ExpectFalse(snapshot.registration.emailVerified, 'verification status is reset')
    GCModuleTest.ExpectEqual(memory.GetCounts().accounts, 0, 'email change creates no account')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[82] or 0, 0, 'email change cannot spawn')
    local challenge = memory.GetVerificationChallenge(oldChallenge.bindingKey, 'registration')
    GCModuleTest.ExpectNil(challenge, 'old challenge is invalidated')
end)

GCModuleTest.Register('identity.legacy_account_completes_registered_name_before_spawn', 'integration', function()
    local memory = IdentityTest.Reset()
    local initial = IdentityTest.ResolveAndRegister(83, 'legacy-profile@example.test', 'legacy_profile_83')
    GCModuleTest.ExpectEqual(initial.state, 'character_required', 'baseline account completed registration')
    local account = GCIdentityService.GetAccount(83)
    memory.UpdateAccountRegisteredName(account.id, nil, nil)
    GCIdentityService.Disconnect(83)
    IdentityTest.core.spawned[83] = false
    IdentityTest.core.gameplay[83] = false

    local legacy = GCIdentityService.Resolve(83)
    GCModuleTest.ExpectEqual(legacy.state, 'profile_completion_required', 'legacy account is gated pre-spawn')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[83], 1, 'legacy lookup cannot release another spawn')
    local result, completeError = GCIdentityService.CompleteProfile(83, {
        protocolVersion = GCIdentityVersion.protocol,
        requestId = 'legacy_profile_complete_83',
        firstName = 'Legacy',
        lastName = 'Member'
    })
    GCModuleTest.ExpectNil(completeError, 'legacy registered name is completed')
    GCModuleTest.ExpectEqual(result.displayName, 'Legacy Member', 'completed display name is public')
    GCModuleTest.ExpectEqual(IdentityTest.core.spawnRequests[83], 2, 'profile completion releases spawn once')
end)
