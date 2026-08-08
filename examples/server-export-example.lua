-- RU: Пример использования серверных exports gc_core.
-- EN: Example of using gc_core server exports.

-- RU: Этот файл показывает, как будущий Lua-модуль может использовать API gc_core.
-- EN: This file shows how a future Lua module can use the gc_core API.

-- RU: Проверяем версию API gc_core.
-- EN: Check the gc_core API version.
local apiVersion = exports.gc_core:GetApiVersion()

if apiVersion ~= 1 then
    print('[Example] Unsupported gc_core API version: ' .. tostring(apiVersion))
    return
end

-- RU: Проверяем, подключён ли игрок.
-- EN: Check whether a player is connected.
local function isPlayerConnected(playerSource)
    return exports.gc_core:IsPlayerConnected(playerSource)
end

-- RU: Проверяем, готов ли игрок.
-- EN: Check whether a player is ready.
local function isPlayerReady(playerSource)
    return exports.gc_core:IsPlayerReady(playerSource)
end

-- RU: Проверяем, появился ли игрок.
-- EN: Check whether a player has spawned.
local function isPlayerSpawned(playerSource)
    return exports.gc_core:IsPlayerSpawned(playerSource)
end

-- RU: Получаем состояние игрока.
-- EN: Get the player state.
local function getPlayerState(playerSource)
    return exports.gc_core:GetPlayerState(playerSource)
end

-- RU: Получаем безопасную копию сессии игрока.
-- EN: Get a safe copy of the player session.
local function getPlayerSession(playerSource)
    return exports.gc_core:GetPlayerSession(playerSource)
end

-- RU: Получаем идентификатор игрока.
-- EN: Get a player identifier.
local function getPlayerIdentifier(playerSource, identifierType)
    return exports.gc_core:GetPlayerIdentifier(playerSource, identifierType)
end

-- RU: Проверяем, может ли игрок использовать игровые функции.
-- EN: Check whether a player can use gameplay features.
local function canUseGameplayFeatures(playerSource)
    return exports.gc_core:CanUseGameplayFeatures(playerSource)
end

-- RU: Пример использования exports.
-- EN: Example of using the exports.
RegisterNetEvent('gc_example:server:checkPlayer', function()
    local playerSource = source

    -- RU: Проверяем, подключён ли игрок.
    -- EN: Check whether the player is connected.
    if not isPlayerConnected(playerSource) then
        print(('[Example] Player %s is not connected'):format(playerSource))
        return
    end

    -- RU: Получаем состояние игрока.
    -- EN: Get the player state.
    local state = getPlayerState(playerSource)

    print(('[Example] Player %s state: %s'):format(playerSource, tostring(state)))

    -- RU: Проверяем, может ли игрок использовать игровые функции.
    -- EN: Check whether the player can use gameplay features.
    if canUseGameplayFeatures(playerSource) then
        print(('[Example] Player %s can use gameplay features'):format(playerSource))
    end
end)