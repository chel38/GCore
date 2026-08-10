-- EN: FiveM keeps the system loading overlay on "Awaiting scripts" until a
-- client script explicitly closes it. GCore closes it only after the server has
-- confirmed the authoritative spawn.
--
-- RU: FiveM держит системный loading overlay на "Awaiting scripts", пока
-- клиентский script явно его не закроет. GCore закрывает его только после
-- server-authoritative подтверждения спавна.

GCClientLoadingScreen = {}

local completed = false

--- Closes the FiveM loading screen once after authoritative spawn confirmation.
--- @return boolean completedNow
function GCClientLoadingScreen.Complete()
    if completed then
        return false
    end

    completed = true

    if type(ShutdownLoadingScreen) == 'function' then
        ShutdownLoadingScreen()
    end

    if type(ShutdownLoadingScreenNui) == 'function' then
        ShutdownLoadingScreenNui()
    end

    return true
end

--- @return boolean completedState
function GCClientLoadingScreen.IsComplete()
    return completed
end
