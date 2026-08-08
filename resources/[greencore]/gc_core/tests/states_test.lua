-- RU: Тесты состояний GreenCore.
-- EN: GreenCore state tests.

-- RU: Тест разрешённого перехода (нормальный lifecycle).
-- EN: Test of allowed transitions (normal lifecycle).
GCTest.Register('states.can_transition.allowed', function()
    GCTest.ExpectTrue(GCStates.CanTransition('connecting', 'validated'), 'connecting -> validated allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('validated', 'joining'), 'validated -> joining allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('joining', 'client_ready'), 'joining -> client_ready allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('client_ready', 'spawn_pending'), 'client_ready -> spawn_pending allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawn_pending', 'spawning'), 'spawn_pending -> spawning allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawning', 'spawn_confirming'), 'spawning -> spawn_confirming allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawn_confirming', 'spawned'), 'spawn_confirming -> spawned allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('disconnecting', 'disconnected'), 'disconnecting -> disconnected allowed')
end)

-- RU: Тест перехода в disconnecting из любого активного состояния.
-- EN: Test of transition to disconnecting from any active state.
GCTest.Register('states.disconnect_from_any_active', function()
    local activeStates = {
        'connecting',
        'validated',
        'joining',
        'client_ready',
        'spawn_pending',
        'spawning',
        'spawn_confirming',
        'spawned',
        'resyncing',
        'error'
    }

    for _, state in ipairs(activeStates) do
        GCTest.ExpectTrue(GCStates.CanTransition(state, 'disconnecting'), state .. ' -> disconnecting allowed')
    end
end)

-- RU: Тест запрещённого перехода.
-- EN: Test of forbidden transitions.
GCTest.Register('states.can_transition.forbidden', function()
    GCTest.ExpectFalse(GCStates.CanTransition('connecting', 'spawned'), 'connecting -> spawned forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('validated', 'spawned'), 'validated -> spawned forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('client_ready', 'connecting'), 'client_ready -> connecting forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('spawned', 'spawn_pending'), 'spawned -> spawn_pending forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('disconnected', 'spawned'), 'disconnected -> spawned forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('spawned', 'spawn_confirming'), 'spawned -> spawn_confirming forbidden')
end)

-- RU: Тест перехода в rejected.
-- EN: Test of transition to rejected.
GCTest.Register('states.can_transition.rejected', function()
    GCTest.ExpectTrue(GCStates.CanTransition('connecting', 'rejected'), 'connecting -> rejected allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('validated', 'rejected'), 'validated -> rejected allowed')
end)

-- RU: Тест перехода в error.
-- EN: Test of transition to error.
GCTest.Register('states.can_transition.error', function()
    GCTest.ExpectTrue(GCStates.CanTransition('joining', 'error'), 'joining -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('client_ready', 'error'), 'client_ready -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawn_pending', 'error'), 'spawn_pending -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawning', 'error'), 'spawning -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawn_confirming', 'error'), 'spawn_confirming -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('resyncing', 'error'), 'resyncing -> error allowed')
end)

-- RU: Тест перехода из resyncing.
-- EN: Test of transitions from resyncing.
GCTest.Register('states.resyncing_transitions', function()
    GCTest.ExpectTrue(GCStates.CanTransition('resyncing', 'spawned'), 'resyncing -> spawned allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('resyncing', 'spawn_pending'), 'resyncing -> spawn_pending allowed')
end)

-- RU: Тест невалидных состояний.
-- EN: Test of invalid states.
GCTest.Register('states.can_transition.invalid', function()
    GCTest.ExpectFalse(GCStates.CanTransition('unknown', 'validated'), 'unknown state rejected')
    GCTest.ExpectFalse(GCStates.CanTransition('connecting', 'unknown'), 'unknown next state rejected')
    GCTest.ExpectFalse(GCStates.CanTransition(nil, 'validated'), 'nil state rejected')
end)

-- RU: Тест терминальных состояний.
-- EN: Test of terminal states.
GCTest.Register('states.is_active', function()
    GCTest.ExpectFalse(GCStates.IsActiveState('disconnected'), 'disconnected is not active')
    GCTest.ExpectFalse(GCStates.IsActiveState('rejected'), 'rejected is not active')
    GCTest.ExpectTrue(GCStates.IsActiveState('spawned'), 'spawned is active')
    GCTest.ExpectTrue(GCStates.IsActiveState('spawn_confirming'), 'spawn_confirming is active')
end)

-- RU: Тест получения разрешённых переходов.
-- EN: Test of getting allowed transitions.
GCTest.Register('states.get_allowed_transitions', function()
    local transitions = GCStates.GetAllowedTransitions('connecting')

    GCTest.ExpectTrue(GCUtils.Contains(transitions, 'validated'), 'validated is in connecting transitions')
    GCTest.ExpectTrue(GCUtils.Contains(transitions, 'rejected'), 'rejected is in connecting transitions')
    GCTest.ExpectTrue(GCUtils.Contains(transitions, 'disconnecting'), 'disconnecting is in connecting transitions')
end)