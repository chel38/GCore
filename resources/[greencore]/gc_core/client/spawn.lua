-- RU: Клиентский сервис спавна GreenCore.
-- EN: GreenCore client spawn service.

-- RU: Таблица клиентского сервиса спавна.
-- EN: Client spawn service table.
GCClientSpawn = {}

--- RU:
--- Проверяет корректность решения о спавне.
---
--- EN:
--- Validates the spawn decision.
---
--- @param payload any Spawn decision payload
--- @return boolean valid Whether the decision is valid
local function validateSpawnPayload(payload)
    -- RU: Payload должен быть таблицей.
    -- EN: Payload must be a table.
    if type(payload) ~= 'table' then
        return false
    end

    -- RU: decisionId должен быть строкой.
    -- EN: decisionId must be a string.
    if type(payload.decisionId) ~= 'string' then
        return false
    end

    -- RU: position должен быть таблицей.
    -- EN: position must be a table.
    if type(payload.position) ~= 'table' then
        return false
    end

    -- RU: Координаты должны быть числами.
    -- EN: Coordinates must be numbers.
    if type(payload.position.x) ~= 'number' then
        return false
    end

    if type(payload.position.y) ~= 'number' then
        return false
    end

    if type(payload.position.z) ~= 'number' then
        return false
    end

    if type(payload.position.heading) ~= 'number' then
        return false
    end

    -- RU: model должен быть числом (hash).
    -- EN: model must be a number (hash).
    if type(payload.model) ~= 'number' then
        return false
    end

    return true
end

--- RU:
--- Загружает модель педа с тайм-аутом.
---
--- EN:
--- Loads the ped model with a timeout.
---
--- @param modelHash number Model hash
--- @return boolean loaded Whether the model was loaded
--- @return string|nil errorCode Error code
local function loadModel(modelHash)
    RequestModel(modelHash)

    local startedAt = GetGameTimer()
    local timeoutMs = GCConfig.Spawn.modelLoadTimeoutMs

    -- RU: Ограниченный цикл ожидания загрузки модели.
    -- EN: Bounded loop waiting for the model to load.
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() - startedAt >= timeoutMs then
            return false, 'GC-SPAWN-MODEL-001'
        end

        Wait(100)
    end

    return true
end

--- RU:
--- Загружает коллизию вокруг точки с тайм-аутом.
---
--- EN:
--- Loads the collision around a point with a timeout.
---
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param z number Z coordinate
--- @return boolean loaded Whether the collision was loaded
--- @return string|nil errorCode Error code
local function loadCollision(x, y, z)
    RequestCollisionAtCoord(x, y, z)

    local startedAt = GetGameTimer()
    local timeoutMs = GCConfig.Spawn.collisionLoadTimeoutMs

    -- RU: Ограниченный цикл ожидания загрузки коллизии.
    -- EN: Bounded loop waiting for the collision to load.
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) do
        if GetGameTimer() - startedAt >= timeoutMs then
            return false, 'GC-SPAWN-COLLISION-001'
        end

        Wait(100)
    end

    return true
end

--- RU:
--- Прерывает спавн при ошибке: размораживает ped, возвращает изображение,
--- сбрасывает флаг спавна и сообщает серверу код ошибки.
---
--- EN:
--- Aborts the spawn on error: unfreezes the ped, restores the image,
--- resets the spawn flag, and reports the error code to the server.
---
--- @param ped number Ped to unfreeze
--- @param errorCode string Error code to report
local function abortSpawn(ped, errorCode)
    -- RU: Размораживаем ped.
    -- EN: Unfreeze the ped.
    FreezeEntityPosition(ped, false)

    -- RU: Возвращаем изображение.
    -- EN: Restore the image.
    DoScreenFadeIn(GCConfig.Spawn.fadeInDurationMs)

    -- RU: Сбрасываем флаг спавна.
    -- EN: Reset the spawn flag.
    GCClientState.SetSpawning(false)

    -- RU: Сообщаем серверу об ошибке.
    -- EN: Report the error to the server.
    GCClientDiagnostics.Report(errorCode)
end

--- RU:
--- Выполняет спавн игрока.
---
--- EN:
--- Performs the player spawn.
---
--- @param payload table Spawn decision payload
function GCClientSpawn.PerformSpawn(payload)
    -- RU: Проверяем корректность решения.
    -- EN: Validate the decision.
    if not validateSpawnPayload(payload) then
        GCClientDiagnostics.Report('GC-CLIENT-SPAWN-001')
        return
    end

    -- RU: Проверяем, что спавн ещё не выполняется.
    -- EN: Verify that a spawn is not already in progress.
    if GCClientState.IsSpawning() then
        return
    end

    -- RU: Устанавливаем флаг выполнения спавна.
    -- EN: Set the spawning flag.
    GCClientState.SetSpawning(true)

    -- RU: Фиксируем время начала спавна для общего тайм-аута.
    -- EN: Record the spawn start time for the overall timeout.
    local spawnStartedAt = GetGameTimer()

    -- RU: Получаем текущий ped.
    -- EN: Get the current ped.
    local currentPed = PlayerPedId()

    -- RU: Затемняем экран.
    -- EN: Fade out the screen.
    DoScreenFadeOut(GCConfig.Spawn.fadeOutDurationMs)

    -- RU: Замораживаем текущий ped.
    -- EN: Freeze the current ped.
    FreezeEntityPosition(currentPed, true)

    -- RU: Загружаем модель.
    -- EN: Load the model.
    local modelLoaded, modelError = loadModel(payload.model)

    if not modelLoaded then
        abortSpawn(currentPed, modelError)
        return
    end

    -- RU: Проверяем общий тайм-аут спавна.
    -- EN: Check the overall spawn timeout.
    if GetGameTimer() - spawnStartedAt >= GCConfig.Spawn.clientSpawnTimeoutMs then
        abortSpawn(currentPed, 'GC-SPAWN-TIMEOUT-001')
        return
    end

    -- RU: Устанавливаем модель игрока.
    -- EN: Set the player model.
    SetPlayerModel(PlayerId(), payload.model)

    -- RU: Получаем новый ped.
    -- EN: Get the new ped.
    local newPed = PlayerPedId()

    -- RU: Устанавливаем координаты.
    -- EN: Set the coordinates.
    SetEntityCoordsNoOffset(newPed, payload.position.x, payload.position.y, payload.position.z, false, false, false)

    -- RU: Устанавливаем heading.
    -- EN: Set the heading.
    SetEntityHeading(newPed, payload.position.heading)

    -- RU: Загружаем коллизию.
    -- EN: Load the collision.
    local collisionLoaded, collisionError = loadCollision(payload.position.x, payload.position.y, payload.position.z)

    if not collisionLoaded then
        abortSpawn(newPed, collisionError)
        return
    end

    -- RU: Проверяем общий тайм-аут спавна после загрузки коллизии.
    -- EN: Check the overall spawn timeout after loading the collision.
    if GetGameTimer() - spawnStartedAt >= GCConfig.Spawn.clientSpawnTimeoutMs then
        abortSpawn(newPed, 'GC-SPAWN-TIMEOUT-001')
        return
    end

    -- RU: Очищаем задачи ped.
    -- EN: Clear the ped tasks.
    ClearPedTasksImmediately(newPed)

    -- RU: Снимаем нежелательные состояния.
    -- EN: Remove unwanted states.
    ClearPedWetness(newPed)
    ResetPedMovementClipset(newPed, 0.0)

    -- RU: Размораживаем ped.
    -- EN: Unfreeze the ped.
    FreezeEntityPosition(newPed, false)

    -- RU: Освобождаем модель.
    -- EN: Release the model.
    SetModelAsNoLongerNeeded(payload.model)

    -- RU: Плавно возвращаем изображение.
    -- EN: Smoothly restore the image.
    DoScreenFadeIn(GCConfig.Spawn.fadeInDurationMs)

    -- RU: Сбрасываем флаг выполнения спавна.
    -- EN: Reset the spawning flag.
    GCClientState.SetSpawning(false)

    -- RU: Устанавливаем флаг завершения спавна.
    -- EN: Set the spawned flag.
    GCClientState.SetSpawned(true)

    -- RU: Отправляем подтверждение серверу.
    -- EN: Send the confirmation to the server.
    TriggerServerEvent('gc_core:server:confirmSpawn', {
        decisionId = payload.decisionId
    })
end