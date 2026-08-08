-- RU: Тесты состояний GreenCore.
-- EN: GreenCore state tests.

-- RU: Тест разрешённого перехода.
-- EN: Test of an allowed transition.
GCTest.Register('states.can_transition.allowed', function()
    GCTest.ExpectTrue(GCStates.CanTransition('connecting', 'validated'), 'connecting -> validated allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('validated', 'joining'), 'validated -> joining allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('joining', 'client_ready'), 'joining -> client_ready allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('client_ready', 'spawn_pending'), 'client_ready -> spawn_pending allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawn_pending', 'spawning'), 'spawn_pending -> spawning allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawning', 'spawned'), 'spawning -> spawned allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawned', 'disconnecting'), 'spawned -> disconnecting allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('disconnecting', 'disconnected'), 'disconnecting -> disconnected allowed')
end)

-- RU: Тест запрещённого перехода.
-- EN: Test of a forbidden transition.
GCTest.Register('states.can_transition.forbidden', function()
    GCTest.ExpectFalse(GCStates.CanTransition('connecting', 'spawned'), 'connecting -> spawned forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('validated', 'spawned'), 'validated -> spawned forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('client_ready', 'connecting'), 'client_ready -> connecting forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('spawned', 'spawn_pending'), 'spawned -> spawn_pending forbidden')
    GCTest.ExpectFalse(GCStates.CanTransition('disconnected', 'spawned'), 'disconnected -> spawned forbidden')
end)

-- RU: Тест перехода в rejected.
-- EN: Test of a transition to rejected.
GCTest.Register('states.can_transition.rejected', function()
    GCTest.ExpectTrue(GCStates.CanTransition('connecting', 'rejected'), 'connecting -> rejected allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('validated', 'rejected'), 'validated -> rejected allowed')
end)

-- RU: Тест перехода в error.
-- EN: Test of a transition to error.
GCTest.Register('states.can_transition.error', function()
    GCTest.ExpectTrue(GCStates.CanTransition('joining', 'error'), 'joining -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('client_ready', 'error'), 'client_ready -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawn_pending', 'error'), 'spawn_pending -> error allowed')
    GCTest.ExpectTrue(GCStates.CanTransition('spawning', 'error'), 'spawning -> error allowed')
end)

-- RU: Тест невалидных состояний.
-- EN: Test of invalid states.
GCTest.Register('states.can_transition.invalid', function()
    GCTest.ExpectFalse(GCStates.CanTransition('unknown', 'validated'), 'unknown state rejected')
    GCTest.ExpectFalse(GCStates.CanTransition('connecting', 'unknown'), 'unknown next state rejected')
    GCTest.ExpectFalse(GCStates.CanTransition(nil, 'validated'), 'nil state rejected')
end)

-- RU: Тест получения разрешённых переходов.
-- EN: Test of getting allowed transitions.
GCTest.Register('states.get_allowed_transitions', function()
    local transitions = GCStates.GetAllowedTransitions('connecting')

    GCTest.ExpectEqual(#transitions, 2, 'connecting has 2 allowed transitions')
    GCTest.ExpectTrue(GCUtils.Contains(transitions, 'validated'), 'validated is in connecting transitions')
    GCTest.ExpectTrue(GCUtils.Contains(transitions, 'rejected'), 'rejected is in connecting transitions')
end)