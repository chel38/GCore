-- RU: Сервис состояний игрока GreenCore.
-- EN: GreenCore player state service.

-- RU: Таблица сервиса состояний.
-- EN: State service table.
GCStates = {}

-- RU: Таблица разрешённых переходов состояний.
-- RU: ВАЖНО: игрок способен отключиться из ЛЮБОГО активного состояния,
-- RU: поэтому каждое активное состояние разрешает переход в disconnecting.
-- EN: Allowed state transition table.
-- EN: IMPORTANT: a player can disconnect from ANY active state, so every active
-- EN: state allows a transition to disconnecting.
local allowedTransitions = {
    connecting = {
        'validated',
        'rejected',
        'disconnecting'
    },
    validated = {
        'joining',
        'rejected',
        'disconnecting'
    },
    joining = {
        'client_ready',
        'error',
        'disconnecting'
    },
    client_ready = {
        'spawn_pending',
        'error',
        'disconnecting'
    },
    spawn_pending = {
        'spawning',
        'error',
        'disconnecting'
    },
    spawning = {
        'spawn_confirming',
        'error',
        'disconnecting'
    },
    spawn_confirming = {
        'spawned',
        'spawn_pending',
        'error',
        'disconnecting'
    },
    spawned = {
        'disconnecting'
    },
    -- RU: Восстановленная после рестарта сессия может быть переведена
    -- RU: в spawned (игрок уже в мире) или в spawn_pending (нужен повторный спавн).
    -- EN: A session recovered after a restart can move to spawned (player already
    -- EN: in the world) or to spawn_pending (a re-spawn is required).
    resyncing = {
        'spawned',
        'spawn_pending',
        'error',
        'disconnecting'
    },
    disconnecting = {
        'disconnected'
    },
    disconnected = {},
    rejected = {},
    error = {
        'disconnecting'
    }
}

--- RU:
--- Проверяет, разрешён ли переход между состояниями.
---
--- EN:
--- Checks whether a transition between states is allowed.
---
--- @param currentState string Current state
--- @param nextState string Next state
--- @return boolean allowed Whether the transition is allowed
function GCStates.CanTransition(currentState, nextState)
    if type(currentState) ~= 'string' then
        return false
    end

    if type(nextState) ~= 'string' then
        return false
    end

    local transitions = allowedTransitions[currentState]

    if not transitions then
        return false
    end

    return GCUtils.Contains(transitions, nextState)
end

--- RU:
--- Возвращает список разрешённых переходов из состояния.
---
--- EN:
--- Returns the list of allowed transitions from a state.
---
--- @param currentState string Current state
--- @return table transitions List of allowed next states
function GCStates.GetAllowedTransitions(currentState)
    if type(currentState) ~= 'string' then
        return {}
    end

    local transitions = allowedTransitions[currentState]

    if not transitions then
        return {}
    end

    return GCUtils.ShallowCopy(transitions)
end

--- RU:
--- Устанавливает новое состояние игрока.
--- ВАЖНО: вызывающие стороны должны проверять возвращаемые success/errorCode
--- и реагировать на неудачный переход (retry, forced cleanup или error),
--- чтобы удаление игрока никогда не оставляло зависшую Lua-сессию.
---
--- EN:
--- Sets a new state for a player.
--- IMPORTANT: callers must check the returned success/errorCode and react to a
--- failed transition (retry, forced cleanup, or error) so that removing a player
--- never leaves a stuck Lua session.
---
--- @param playerSource number FiveM server player source
--- @param nextState string Next state
--- @param reason string|nil Reason for the transition
--- @return boolean success Whether the transition succeeded
--- @return string|nil errorCode Error code
function GCStates.Set(playerSource, nextState, reason)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return false, 'GC-STATE-001'
    end

    if type(nextState) ~= 'string' then
        return false, 'GC-STATE-001'
    end

    -- RU: Находим сессию игрока.
    -- EN: Find the player session.
    local session = GCSessions.Get(playerSource)

    if not session then
        return false, 'GC-SESSION-001'
    end

    -- RU: Получаем текущее состояние.
    -- EN: Get the current state.
    local currentState = session.state

    -- RU: Проверяем разрешённость перехода.
    -- EN: Check whether the transition is allowed.
    if not GCStates.CanTransition(currentState, nextState) then
        return false, 'GC-STATE-001'
    end

    -- RU: Сохраняем предыдущее состояние.
    -- EN: Save the previous state.
    session.previousState = currentState

    -- RU: Устанавливаем новое состояние.
    -- EN: Set the new state.
    session.state = nextState

    -- RU: Сохраняем причину перехода.
    -- EN: Save the transition reason.
    session.stateReason = reason or 'state_changed'

    -- RU: Записываем время перехода.
    -- EN: Record the transition time.
    if nextState == 'validated' then
        session.validatedAt = GCUtils.NowSec()
    elseif nextState == 'client_ready' then
        session.clientReadyAt = GCUtils.NowSec()
    elseif nextState == 'spawned' then
        session.spawnedAt = GCUtils.NowSec()
    elseif nextState == 'disconnected' then
        session.disconnectedAt = GCUtils.NowSec()
    end

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseStates then
        GCLogger.Debug('GC-STATE-100', 'State transition', {
            source = playerSource,
            from = currentState,
            to = nextState,
            reason = reason
        })
    end

    return true
end

--- RU:
--- Возвращает текущее состояние игрока.
---
--- EN:
--- Returns the current state of a player.
---
--- @param playerSource number FiveM server player source
--- @return string|nil state Current state
function GCStates.Get(playerSource)
    if type(playerSource) ~= 'number' then
        return nil
    end

    local session = GCSessions.Get(playerSource)

    if not session then
        return nil
    end

    return session.state
end

--- RU:
--- Проверяет, находится ли игрок в заданном состоянии.
---
--- EN:
--- Checks whether a player is in a given state.
---
--- @param playerSource number FiveM server player source
--- @param expectedState string Expected state
--- @return boolean isInState Whether the player is in the state
function GCStates.Is(playerSource, expectedState)
    if type(playerSource) ~= 'number' then
        return false
    end

    if type(expectedState) ~= 'string' then
        return false
    end

    local session = GCSessions.Get(playerSource)

    if not session then
        return false
    end

    return session.state == expectedState
end

--- RU:
--- Является ли состояние активным (игрок ещё подключён и может отключиться).
---
--- EN:
--- Checks whether a state is active (the player is still connected and may drop).
---
--- @param state string State to check
--- @return boolean active Whether the state is active
function GCStates.IsActiveState(state)
    if type(state) ~= 'string' then
        return false
    end

    -- RU: Терминальные состояния, из которых нельзя отключиться.
    -- EN: Terminal states from which a player cannot disconnect.
    if state == 'disconnected' or state == 'rejected' then
        return false
    end

    return true
end
