-- RU: Клиентский сервис готовности GreenCore.
-- EN: GreenCore client readiness service.

-- RU: Таблица клиентского сервиса готовности.
-- EN: Client readiness service table.
GCClientReadiness = {}

-- RU: Флаг, что готовность уже была отправлена.
-- EN: Flag that readiness has already been sent.
local readinessSent = false

--- RU:
--- Проверяет, активна ли сетевая сессия.
---
--- EN:
--- Checks whether the network session is active.
---
--- @return boolean active Whether the session is active
local function isNetworkSessionActive()
    return NetworkIsSessionStarted()
end

--- RU:
--- Проверяет, существует ли игрок.
---
--- EN:
--- Checks whether the player exists.
---
--- @return boolean exists Whether the player exists
local function doesPlayerExist()
    return DoesPlayerExist(PlayerId())
end

--- RU:
--- Проверяет, существует ли ped игрока.
---
--- EN:
--- Checks whether the player ped exists.
---
--- @return boolean exists Whether the ped exists
local function doesPlayerPedExist()
    local ped = PlayerPedId()

    return ped ~= 0 and DoesEntityExist(ped)
end

--- RU:
--- Проверяет, готов ли клиент к отправке готовности.
---
--- EN:
--- Checks whether the client is ready to send readiness.
---
--- @return boolean ready Whether the client is ready
function GCClientReadiness.IsClientReady()
    -- RU: Проверяем активность сетевой сессии.
    -- EN: Check the network session activity.
    if not isNetworkSessionActive() then
        return false
    end

    -- RU: Проверяем существование игрока.
    -- EN: Check the player existence.
    if not doesPlayerExist() then
        return false
    end

    -- RU: Проверяем существование ped игрока.
    -- EN: Check the player ped existence.
    if not doesPlayerPedExist() then
        return false
    end

    return true
end

--- RU:
--- Отправляет серверу сообщение о готовности клиента.
---
--- EN:
--- Sends the client readiness message to the server.
function GCClientReadiness.ReportReady()
    -- RU: Проверяем, что готовность ещё не была отправлена.
    -- EN: Verify that readiness has not already been sent.
    if readinessSent then
        return
    end

    -- RU: Проверяем, что клиент действительно готов.
    -- EN: Verify that the client is actually ready.
    if not GCClientReadiness.IsClientReady() then
        return
    end

    -- RU: Отправляем payload готовности.
    -- EN: Send the readiness payload.
    TriggerServerEvent(GCEvents.Server.clientReady, {
        clientVersion = GCVersion.GetString(),
        protocolVersion = GCVersion.GetProtocolVersion(),
        locale = GCConfig.General.locale
    })

    -- RU: Помечаем, что готовность отправлена.
    -- EN: Mark that readiness has been sent.
    readinessSent = true

    -- RU: Устанавливаем флаг готовности клиента.
    -- EN: Set the client readiness flag.
    GCClientState.SetReady(true)
end

--- RU:
--- Запускает ограниченный цикл ожидания готовности клиента.
---
--- EN:
--- Starts a bounded loop waiting for client readiness.
function GCClientReadiness.WaitForReadiness()
    -- RU: Запускаем поток ожидания.
    -- EN: Start the waiting thread.
    CreateThread(function()
        local startedAt = GetGameTimer()
        local timeoutMs = GCConfig.Connection.clientReadyTimeoutMs

        -- RU: Ограниченный цикл с тайм-аутом.
        -- EN: Bounded loop with a timeout.
        while not GCClientReadiness.IsClientReady() do
            -- RU: Проверяем тайм-аут.
            -- EN: Check the timeout.
            if GetGameTimer() - startedAt >= timeoutMs then
                GCClientDiagnostics.Report('GC-CLIENT-READY-001')
                return
            end

            Wait(250)
        end

        -- RU: Сообщаем о готовности.
        -- EN: Report readiness.
        GCClientReadiness.ReportReady()
    end)
end

--- RU:
--- Сбрасывает флаг отправки готовности.
---
--- EN:
--- Resets the readiness sent flag.
function GCClientReadiness.Reset()
    readinessSent = false
end
