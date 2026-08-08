-- RU: Провайдер точки спавна GreenCore.
-- EN: GreenCore spawn location provider.

-- RU: Провайдер отделяет "КАК выбрать точку спавна" от "КАК заспавнить игрока".
-- RU: Сегодня возвращается точка по умолчанию из конфигурации. В будущем здесь
-- RU: можно реализовать last position, housing, hospital, jail или выбор персонажа,
-- RU: не переписывая lifecycle спавна.
-- EN: The provider separates "HOW to choose a spawn point" from "HOW to spawn a player".
-- EN: Today it returns the default point from the configuration. In the future this can
-- EN: implement last position, housing, hospital, jail, or character spawn selection
-- EN: without rewriting the spawn lifecycle.

-- RU: Таблица провайдера точки спавна.
-- EN: Spawn location provider table.
GCSpawnLocationProvider = {}

--- RU:
--- Проверяет корректность конфигурации точки спавна по умолчанию.
---
--- EN:
--- Validates the default spawn point configuration.
---
--- @return boolean valid Whether the configuration is valid
function GCSpawnLocationProvider.ValidateConfig()
    local default = GCConfig.Spawn.default

    if type(default) ~= 'table' then
        return false
    end

    if type(default.x) ~= 'number' then
        return false
    end

    if type(default.y) ~= 'number' then
        return false
    end

    if type(default.z) ~= 'number' then
        return false
    end

    if type(default.heading) ~= 'number' then
        return false
    end

    return true
end

--- RU:
--- Разрешает точку спавна для игрока.
--- Сегодня: точка по умолчанию из конфигурации.
--- В будущем: last position / housing / hospital / jail / character spawn selector.
--- Возвращает безопасную копию координат, чтобы внешний код не мог изменить
--- конфигурацию через возвращённую таблицу.
---
--- EN:
--- Resolves the spawn location for a player.
--- Today: the default point from the configuration.
--- In the future: last position / housing / hospital / jail / character spawn selector.
--- Returns a safe copy of the coordinates so external code cannot mutate the
--- configuration through the returned table.
---
--- @param playerSource number FiveM server player source
--- @param session table Player session
--- @return table|nil position Table with x, y, z, heading
--- @return string|nil errorCode Error code
function GCSpawnLocationProvider.Resolve(playerSource, session)
    -- RU: Проверяем входные данные.
    -- EN: Validate input data.
    if type(playerSource) ~= 'number' then
        return nil, 'GC-SPAWN-001'
    end

    -- RU: Проверяем корректность конфигурации.
    -- EN: Validate the configuration.
    if not GCSpawnLocationProvider.ValidateConfig() then
        return nil, 'GC-SPAWN-001'
    end

    local default = GCConfig.Spawn.default

    -- RU: Возвращаем копию, а не прямую ссылку на конфигурацию.
    -- EN: Return a copy, not a direct reference to the configuration.
    return {
        x = default.x,
        y = default.y,
        z = default.z,
        heading = default.heading
    }
end