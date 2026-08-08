-- RU: Пример серверной логики будущего Lua-модуля GreenCore.
-- EN: Example server logic for a future GreenCore Lua module.

-- RU: Проверяем версию API gc_core.
-- EN: Check the gc_core API version.
local apiVersion = exports.gc_core:GetApiVersion()

if apiVersion ~= 1 then
    print('[ExampleModule] Unsupported gc_core API version')
    return
end

-- RU: Проверяем, может ли игрок использовать игровые функции.
-- EN: Check whether a player can use gameplay features.
local function canPlayerUseFeature(playerSource)
    -- RU: Проверяем через API gc_core, завершил ли игрок спавн.
    -- EN: Check through the gc_core API whether the player completed spawning.
    return exports.gc_core:CanUseGameplayFeatures(playerSource)
end

-- RU: Пример события модуля.
-- EN: Example module event.
RegisterNetEvent('gc_example:server:useFeature', function()
    local playerSource = source

    -- RU: Проверяем, готов ли игрок.
    -- EN: Check whether the player is ready.
    if not canPlayerUseFeature(playerSource) then
        print(('Player %s is not ready'):format(playerSource))
        return
    end

    print(('Player %s can use the example feature'):format(playerSource))
end)