-- RU: Клиентский сервис спавна GreenCore.
-- EN: GreenCore client spawn service.

-- RU: Таблица клиентского сервиса спавна.
-- EN: Client spawn service table.
GCClientSpawn = {}

--- RU:
--- Загружает модель педа с тайм-аутом.
--- Сначала проверяет валидность модели, затем запрашивает её загрузку.
---
--- EN:
--- Loads the ped model with a timeout.
--- First validates the model, then requests its loading.
---
--- @param modelHash number Model hash
--- @param modelName string Model name (for diagnostics)
--- @return boolean loaded Whether the model was loaded
--- @return string|nil errorCode Error code
local function loadModel(modelHash, modelName)
    -- RU: Проверяем, что модель существует в игре.
    -- EN: Verify that the model exists in the game.
    if not IsModelInCdimage(modelHash) then
        return false, 'GC-SPAWN-PED-LOAD-001'
    end

    -- RU: Проверяем, что модель валидна.
    -- EN: Verify that the model is valid.
    if not IsModelValid(modelHash) then
        return false, 'GC-SPAWN-PED-LOAD-001'
    end

    -- RU: Проверяем, что модель является ped.
    -- EN: Verify that the model is a ped.
    if not IsModelAPed(modelHash) then
        return false, 'GC-SPAWN-PED-LOAD-001'
    end

    -- RU: Запрашиваем загрузку модели.
    -- EN: Request the model loading.
    RequestModel(modelHash)

    local startedAt = GetGameTimer()
    local timeoutMs = GCConfig.Spawn.modelLoadTimeoutMs or 10000

    -- RU: Ограниченный цикл ожидания загрузки модели.
    -- RU: Никакого бесконечного while not HasModelLoaded(...).
    -- EN: Bounded loop waiting for the model to load.
    -- EN: No infinite while not HasModelLoaded(...).
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() - startedAt >= timeoutMs then
            -- RU: Освобождаем модель при тайм-ауте.
            -- EN: Release the model on timeout.
            SetModelAsNoLongerNeeded(modelHash)
            return false, 'GC-SPAWN-PED-TIMEOUT-001'
        end

        Wait(50)
    end

    return true
end

--- RU:
--- Загружает коллизию вокруг точки с тайм-аутом.
---
--- EN:
--- Loads the collision around a point with a timeout.
---
--- @param ped number Ped entity to check collision around
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param z number Z coordinate
--- @return boolean loaded Whether the collision was loaded
--- @return string|nil errorCode Error code
local function loadCollision(ped, x, y, z)
    RequestCollisionAtCoord(x, y, z)

    local startedAt = GetGameTimer()
    local timeoutMs = GCConfig.Spawn.collisionLoadTimeoutMs or 10000

    -- RU: Ограниченный цикл ожидания загрузки коллизии.
    -- EN: Bounded loop waiting for the collision to load.
    while not HasCollisionLoadedAroundEntity(ped) do
        RequestCollisionAtCoord(x, y, z)

        if GetGameTimer() - startedAt >= timeoutMs then
            return false, 'GC-SPAWN-COLLISION-001'
        end

        Wait(100)
    end

    return true
end

--- RU:
--- Ожидает полного затемнения экрана с тайм-аутом.
---
--- EN:
--- Waits for the screen to be fully faded out with a timeout.
---
--- @return boolean fadedOut Whether the screen is faded out
local function waitForFadeOut()
    local startedAt = GetGameTimer()
    local timeoutMs = GCConfig.Spawn.fadeOutTimeoutMs or 2000

    while not IsScreenFadedOut() do
        if GetGameTimer() - startedAt >= timeoutMs then
            return false
        end

        Wait(50)
    end

    return true
end

--- RU:
--- Прерывает спавн при ошибке: размораживает ped, возвращает управление игроку,
--- возвращает изображение и сообщает серверу код ошибки.
---
--- EN:
--- Aborts the spawn on error: unfreezes the ped, restores player control, restores
--- the image, and reports the error code to the server.
---
--- @param ped number Ped to unfreeze
--- @param errorCode string Error code to report
--- @param hadControl boolean Whether player control was disabled
local function abortSpawn(ped, errorCode, hadControl)
    -- RU: Размораживаем ped.
    -- EN: Unfreeze the ped.
    if type(ped) == 'number' and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
    end

    -- RU: Возвращаем управление игроку, если оно было отключено.
    -- EN: Restore player control if it was disabled.
    if hadControl then
        SetPlayerControl(PlayerId(), true, 0)
    end

    -- RU: Возвращаем изображение.
    -- EN: Restore the image.
    DoScreenFadeIn(GCConfig.Spawn.fadeInDurationMs or 1000)

    -- RU: Сбрасываем флаги спавна.
    -- EN: Reset the spawn flags.
    GCClientState.SetSpawning(false)
    GCClientState.SetSpawnConfirming(false)

    -- RU: Сообщаем серверу об ошибке.
    -- EN: Report the error to the server.
    GCClientDiagnostics.Report(errorCode)
end

--- RU:
--- Выполняет спавн игрока.
--- Клиент выполняет спавн, но НЕ считает его завершённым самостоятельно:
--- устанавливается состояние spawn_confirming, а финальное spawned приходит
--- от сервера (spawnConfirmed).
---
--- EN:
--- Performs the player spawn.
--- The client performs the spawn but does NOT consider it complete by itself:
--- the spawn_confirming state is set, and the final spawned comes from the server
--- (spawnConfirmed).
---
--- @param payload table Spawn decision payload
function GCClientSpawn.PerformSpawn(payload)
    -- RU: Проверяем корректность решения (включая ped.name/hash).
    -- EN: Validate the decision (including ped.name/hash).
    local isValid, validationError = GCValidation.SpawnApproved(payload)

    if not isValid then
        -- RU: Повреждённый payload: не спавним, сообщаем серверу.
        -- EN: Damaged payload: do not spawn, report to the server.
        GCClientDiagnostics.Report(validationError or 'GC-CLIENT-SPAWN-001')
        GCClientState.SetSpawnDecisionReceived(false)
        GCClientState.SetSpawning(false)
        GCClientState.SetSpawnConfirming(false)
        GCClientState.SetSpawnError(true)
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
    local oldPed = PlayerPedId()

    -- RU: Получаем hash модели. Предпочитаем серверный hash, иначе вычисляем из имени.
    -- EN: Get the model hash. Prefer the server hash, otherwise compute from the name.
    local modelHash = payload.ped.hash

    if type(modelHash) ~= 'number' then
        modelHash = joaat(payload.ped.name)
    end

    -- RU: Затемняем экран.
    -- EN: Fade out the screen.
    DoScreenFadeOut(GCConfig.Spawn.fadeOutDurationMs or 500)

    -- RU: Ждём полного затемнения с тайм-аутом.
    -- EN: Wait for full fade-out with a timeout.
    if not waitForFadeOut() then
        abortSpawn(oldPed, 'GC-SPAWN-001', false)
        return
    end

    -- RU: Замораживаем текущий ped.
    -- EN: Freeze the current ped.
    FreezeEntityPosition(oldPed, true)

    -- RU: Отключаем управление игроком (будет возвращено после завершения/ошибки).
    -- EN: Disable player control (will be restored after completion/error).
    SetPlayerControl(PlayerId(), false, 0)
    local hadControl = true

    -- RU: Загружаем модель педа.
    -- EN: Load the ped model.
    local modelLoaded, modelError = loadModel(modelHash, payload.ped.name)

    if not modelLoaded then
        abortSpawn(oldPed, modelError, hadControl)
        return
    end

    -- RU: Проверяем общий тайм-аут спавна.
    -- EN: Check the overall spawn timeout.
    if GetGameTimer() - spawnStartedAt >= GCConfig.Spawn.clientSpawnTimeoutMs then
        abortSpawn(oldPed, 'GC-SPAWN-TIMEOUT-001', hadControl)
        return
    end

    -- RU: Устанавливаем модель игрока.
    -- EN: Set the player model.
    SetPlayerModel(PlayerId(), modelHash)

    -- RU: ВАЖНО: после SetPlayerModel старый handle ped устарел, потому что
    -- RU: модель игрока заменяет сущность ped. Получаем ped заново.
    -- EN: IMPORTANT: after SetPlayerModel the old ped handle is stale because the
    -- EN: player model replaces the ped entity. Re-acquire the ped.
    local playerPed = PlayerPedId()

    -- RU: Устанавливаем серверные координаты.
    -- EN: Set the server-provided coordinates.
    SetEntityCoordsNoOffset(playerPed, payload.position.x, payload.position.y, payload.position.z, false, false, false)

    -- RU: Устанавливаем heading.
    -- EN: Set the heading.
    SetEntityHeading(playerPed, payload.position.heading)

    -- RU: Загружаем коллизию вокруг педа.
    -- EN: Load the collision around the ped.
    local collisionLoaded, collisionError = loadCollision(playerPed, payload.position.x, payload.position.y, payload.position.z)

    if not collisionLoaded then
        abortSpawn(playerPed, collisionError, hadControl)
        return
    end

    -- RU: Проверяем общий тайм-аут спавна после загрузки коллизии.
    -- EN: Check the overall spawn timeout after loading the collision.
    if GetGameTimer() - spawnStartedAt >= GCConfig.Spawn.clientSpawnTimeoutMs then
        abortSpawn(playerPed, 'GC-SPAWN-TIMEOUT-001', hadControl)
        return
    end

    -- RU: Приводим ped в нормальное состояние.
    -- EN: Bring the ped to a normal state.
    ClearPedTasksImmediately(playerPed)
    ClearPlayerWantedLevel(PlayerId())

    -- RU: Размораживаем ped.
    -- EN: Unfreeze the ped.
    FreezeEntityPosition(playerPed, false)

    -- RU: Возвращаем управление игроку.
    -- EN: Restore player control.
    SetPlayerControl(PlayerId(), true, 0)
    hadControl = false

    -- RU: Освобождаем модель.
    -- EN: Release the model.
    SetModelAsNoLongerNeeded(modelHash)

    -- RU: Плавно возвращаем изображение.
    -- EN: Smoothly restore the image.
    DoScreenFadeIn(GCConfig.Spawn.fadeInDurationMs or 1000)

    -- RU: Сбрасываем флаг выполнения спавна.
    -- EN: Reset the spawning flag.
    GCClientState.SetSpawning(false)

    -- RU: ВАЖНО: клиент НЕ устанавливает spawned=true. Вместо этого переходит
    -- RU: в состояние spawn_confirming и ждёт подтверждения сервера.
    -- EN: IMPORTANT: the client does NOT set spawned=true. Instead it moves to
    -- EN: the spawn_confirming state and waits for the server confirmation.
    GCClientState.SetSpawnConfirming(true)

    -- RU: Отправляем подтверждение серверу (только decisionId).
    -- EN: Send the confirmation to the server (decisionId only).
    TriggerServerEvent(GCEvents.Server.confirmSpawn, {
        decisionId = payload.decisionId
    })
end
