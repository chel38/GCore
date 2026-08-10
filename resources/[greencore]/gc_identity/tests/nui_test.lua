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
        protocolVersion = 1
    })
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(
        IdentityTest.LastNuiMessage().payload.state,
        'registration_required',
        'registration view receives authoritative snapshot'
    )
    GCModuleTest.ExpectTrue(IdentityTest.FocusState(), 'registration view owns NUI focus')
    GCModuleTest.ExpectTrue(IdentityTest.FrozenState(), 'registration view freezes local ped presentation')

    local registration = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.registerAccount, {
        email = 'nui@example.test'
    })
    local duplicate = IdentityTest.InvokeNui(GCIdentityNuiCallbacks.registerAccount, {
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
        'character_required',
        'registration result advances to character UI'
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
    IdentityTest.EmitNetwork(selectionEvent.name, 61, selectionEvent.payload)
    deliverLastClientEvent()
    GCModuleTest.ExpectEqual(IdentityTest.LastNuiMessage().payload.state, 'ready', 'ready view reached')
    GCModuleTest.ExpectFalse(IdentityTest.FocusState(), 'ready state releases NUI focus')
    GCModuleTest.ExpectFalse(IdentityTest.FrozenState(), 'ready state unfreezes local ped')
end)

GCModuleTest.Register('identity.nui_server_event_local_spoof_has_no_effect', 'security', function()
    IdentityTest.Reset()
    IdentityTest.ReloadClient()
    IdentityTest.InvokeNui(GCIdentityNuiCallbacks.ready, {})
    IdentityTest.EmitNetwork(GCIdentityEvents.client.snapshot, 0, {
        protocolVersion = 1,
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
    GCModuleTest.ExpectNil(IdentityTest.LastNuiMessage(), 'local spoof sends no NUI state')
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
