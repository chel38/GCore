local function deliverLastClientEvent()
    local event = IdentityTest.LastClientEvent()
    GCModuleTest.ExpectNotNil(event, 'server emitted a client event')
    IdentityTest.DeliverClientEvent(event)
    return event
end

GCModuleTest.Register('identity.nui_registration_character_focus_flow', 'integration', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    local readyResult = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    GCModuleTest.ExpectTrue(readyResult.ok, 'NUI readiness acknowledged')

    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 61, {
        protocolVersion = GCIdentityVersion.protocol
    })
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'registration_required',
        'registration view receives authoritative snapshot'
    )
    GCModuleTest.ExpectTrue(IdentityTest.FocusState(), 'registration view owns NUI focus')
    GCModuleTest.ExpectTrue(IdentityTest.FrozenState(), 'registration view freezes local ped presentation')

    local registration = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.sendRegistrationCode, {
        fullName = 'Nui Player',
        email = 'nui@example.test'
    })
    local duplicate = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.sendRegistrationCode, {
        fullName = 'Nui Player',
        email = 'nui@example.test'
    })
    GCModuleTest.ExpectTrue(registration.ok, 'first registration submit accepted locally')
    GCModuleTest.ExpectFalse(duplicate.ok, 'duplicate submit blocked while request is pending')
    GCModuleTest.ExpectEqual(
        duplicate.code,
        'GC-IDENTITY-CLIENT-REQUEST-PENDING',
        'duplicate submit has diagnostic code'
    )
    local registrationEvent = IdentityTest.LastServerEvent()
    IdentityTest.EmitNetwork(registrationEvent.name, 61, registrationEvent.payload)
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'email_verification_pending',
        'registration advances to the code UI'
    )

    local verification = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.verifyEmail, {
        code = IdentityTest.LastMailPayload().code
    })
    GCModuleTest.ExpectTrue(verification.ok, 'verification submit accepted')
    local verificationEvent = IdentityTest.LastServerEvent()
    IdentityTest.EmitNetwork(verificationEvent.name, 61, verificationEvent.payload)
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'registration_verified',
        'correct code waits for explicit finalization'
    )

    local finalization = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.finalizeRegistration, {})
    GCModuleTest.ExpectTrue(finalization.ok, 'final registration submit accepted')
    local finalizationEvent = IdentityTest.LastServerEvent()
    IdentityTest.EmitNetwork(finalizationEvent.name, 61, finalizationEvent.payload)
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'spawn_releasing',
        'trusted server release is visible while core spawns'
    )

    IdentityTest.CompleteCoreSpawn(61)
    GCIdentityService.SendSnapshot(61)
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'character_required',
        'character UI opens only after authoritative core spawn'
    )

    local creation = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.createCharacter, {
        firstName = 'Nui',
        lastName = 'Player'
    })
    GCModuleTest.ExpectTrue(creation.ok, 'character submit accepted')
    local creationEvent = IdentityTest.LastServerEvent()
    IdentityTest.EmitNetwork(creationEvent.name, 61, creationEvent.payload)
    deliverLastClientEvent()
    local characterId = IdentityTest.LastNuiMessage().payload.characters[1].id

    local selection = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.selectCharacter, {
        characterId = characterId
    })
    GCModuleTest.ExpectTrue(selection.ok, 'character selection accepted')
    local selectionEvent = IdentityTest.LastServerEvent()
    IdentityTest.SetPlayerPed(2, true)
    GCModuleTest.ExpectTrue(
        IdentityTest.FrozenState(),
        'replacement ped may inherit presentation freeze before ready cleanup'
    )
    IdentityTest.EmitNetwork(selectionEvent.name, 61, selectionEvent.payload)
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(IdentityTest.LastNuiMessage().type, 'reset', 'ready state unmounts every NUI view')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'ready state releases NUI focus')
    GCModuleTest.ExpectFalse(IdentityTest.KeepInputState(), 'ready state releases NUI keep-input')
    GCModuleTest.ExpectFalse(
        IdentityTest.FrozenState(),
        'ready state unfreezes the current ped after a model replacement'
    )
end)

GCModuleTest.Register('identity.nui_server_event_local_spoof_has_no_effect', 'security', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    local messageCount = IdentityTest.NuiMessageCount()
    IdentityTest.EmitNetwork(GCIdentityEvents.client.snapshot, 0, {
        protocolVersion = GCIdentityVersion.protocol,
        state = 'ready',
        account = {
            id = 999,
            email = 'forged@example.test',
            status = 'active',
            createdAt = 1
        },
        characters = {},
        selectedCharacter = nil,
        limits = { maxCharacters = 99 },
        passwordAuthentication = false
    })
    GCModuleTest.ExpectEqual(IdentityTest.NuiMessageCount(), messageCount, 'local spoof sends no NUI state')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'local spoof cannot change focus lifecycle')
end)

GCModuleTest.Register('identity.nui_exit_uses_server_disconnect', 'security', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    local exitResult = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.exit, {})
    GCModuleTest.ExpectTrue(exitResult.ok, 'exit callback accepted')
    local exitEvent = IdentityTest.LastServerEvent()
    IdentityTest.EmitNetwork(exitEvent.name, 62, exitEvent.payload)
    GCModuleTest.ExpectEqual(#IdentityTest.droppedPlayers, 1, 'server disconnects requesting player once')
    GCModuleTest.ExpectEqual(IdentityTest.droppedPlayers[1].source, 62, 'exit cannot target another source')
end)

GCModuleTest.Register('identity.nui_snapshot_waits_for_js_ready_before_focus', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 63, {
        protocolVersion = GCIdentityVersion.protocol
    })
    deliverLastClientEvent()

    GCModuleTest.ExpectNil(IdentityTest.LastNuiMessage(), 'snapshot is retained until JS ready')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'HTML load alone never acquires focus')
    GCModuleTest.ExpectFalse(IdentityTest.FrozenState(), 'HTML load alone never freezes the ped')

    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'registration_required',
        'ready callback deterministically replays the authoritative snapshot'
    )
    GCModuleTest.ExpectTrue(IdentityTest.FocusState(), 'focus follows the rendered identity state')
end)

GCModuleTest.Register('identity.nui_loading_handoff_waits_for_presented_ack', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 67, {
        protocolVersion = GCIdentityVersion.protocol
    })
    deliverLastClientEvent()
    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})

    local loadingCount, loadingNuiCount = IdentityTest.LoadingScreenShutdowns()
    GCModuleTest.ExpectEqual(loadingCount, 0, 'JS ready alone cannot reveal the world')
    GCModuleTest.ExpectEqual(loadingNuiCount, 0, 'snapshot replay alone keeps FiveM NUI loading active')

    local presented = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.presented, {
        view = 'registration'
    })
    GCModuleTest.ExpectTrue(presented.ok, 'mounted fullscreen shell acknowledges presentation')
    loadingCount, loadingNuiCount = IdentityTest.LoadingScreenShutdowns()
    GCModuleTest.ExpectEqual(loadingCount, 1, 'presented shell closes the loading screen once')
    GCModuleTest.ExpectEqual(loadingNuiCount, 1, 'presented shell closes the NUI loading screen once')

    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.presented, { view = 'registration' })
    loadingCount, loadingNuiCount = IdentityTest.LoadingScreenShutdowns()
    GCModuleTest.ExpectEqual(loadingCount, 1, 'duplicate presentation ACK is idempotent')
    GCModuleTest.ExpectEqual(loadingNuiCount, 1, 'duplicate presentation ACK cannot close NUI twice')
end)

GCModuleTest.Register('identity.nui_hello_timeout_is_visible_and_retryable', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    IdentityTest.EmitEvent('onClientResourceStart', 0, 'gc_identity')

    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().type,
        'lifecycleError',
        'bounded hello exhaustion becomes a terminal NUI state'
    )
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.code,
        'GC-IDENTITY-HELLO-TIMEOUT',
        'hello timeout has a stable diagnostic code'
    )
    GCModuleTest.ExpectTrue(IdentityTest.FocusState(), 'visible recovery UI owns focus')
end)

GCModuleTest.Register('identity.nui_bundle_failure_disconnects_without_focus_lock', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.EmitEvent('onClientResourceStart', 0, 'gc_identity')

    local failure = IdentityTest.LastServerEvent()
    GCModuleTest.ExpectEqual(
        failure.name,
        GCIdentityEvents.server.clientFailure,
        'missing JS-ready reports one controlled client failure'
    )
    GCModuleTest.ExpectEqual(
        failure.payload.code,
        'GC-IDENTITY-NUI-NOT-READY',
        'bundle failure has a stable diagnostic code'
    )
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'broken NUI never retains focus')
    GCModuleTest.ExpectFalse(IdentityTest.FrozenState(), 'broken NUI never leaves the ped frozen')

    IdentityTest.EmitNetwork(failure.name, 64, failure.payload)
    GCModuleTest.ExpectEqual(#IdentityTest.droppedPlayers, 1, 'server performs controlled disconnect')
end)

GCModuleTest.Register('identity.nui_resource_stop_cleanup_is_idempotent', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 65, {
        protocolVersion = GCIdentityVersion.protocol
    })
    deliverLastClientEvent()

    GCModuleTest.ExpectTrue(IdentityTest.FocusState(), 'registration owns focus before stop')
    GCModuleTest.ExpectTrue(IdentityTest.FrozenState(), 'registration owns presentation freeze before stop')

    IdentityTest.EmitEvent('onClientResourceStop', 0, 'gc_identity')
    GCModuleTest.ExpectEqual(IdentityTest.LastNuiMessage().type, 'reset', 'resource stop resets frontend DOM')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'resource stop releases focus')
    GCModuleTest.ExpectFalse(IdentityTest.KeepInputState(), 'resource stop releases keep-input')
    GCModuleTest.ExpectFalse(IdentityTest.FrozenState(), 'resource stop releases identity-owned freeze')

    IdentityTest.EmitEvent('onClientResourceStop', 0, 'gc_identity')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'duplicate resource stop remains safe')
    GCModuleTest.ExpectFalse(IdentityTest.FrozenState(), 'duplicate cleanup remains safe')
end)

GCModuleTest.Register('identity.nui_explicit_exit_cleans_presentation_before_disconnect', 'runtime', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    IdentityTest.EmitNetwork(GCIdentityEvents.server.hello, 66, {
        protocolVersion = GCIdentityVersion.protocol
    })
    deliverLastClientEvent()

    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.exit, {})
    GCModuleTest.ExpectEqual(IdentityTest.LastNuiMessage().type, 'reset', 'exit resets frontend before server drop')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'exit releases focus immediately')
    GCModuleTest.ExpectFalse(IdentityTest.KeepInputState(), 'exit releases keep-input immediately')
    GCModuleTest.ExpectFalse(IdentityTest.FrozenState(), 'exit releases presentation freeze immediately')
end)
