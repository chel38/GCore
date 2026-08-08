-- RU: Клиентский сервис готовности GreenCore.
-- EN: GreenCore client readiness service.

-- RU: Таблица клиентского сервиса готовности.
-- EN: Client readiness service table.
GCClientReadiness = {}

local waitActive = false
local requestedHandshake = 'ready'
local handshakeAcknowledged = false

--- RU:
--- Проверяет, готов ли клиент к отправке готовности.
---
--- EN:
--- Checks whether the client is ready to send readiness.
---
--- @return boolean ready Whether the client is ready
function GCClientReadiness.IsClientReady()
    -- EN: Reaching this function means the client resource and its event handlers
    -- are loaded. Network/player/ped natives may still report false before the
    -- first server-authoritative spawn, so none of them may gate the hello.
    -- RU: Вызов этой функции означает, что client resource и его обработчики уже
    -- загружены. До первого server-authoritative spawn network/player/PED native
    -- ещё могут возвращать false, поэтому они не должны блокировать hello.
    return true
end

--- RU:
--- Отправляет серверу сообщение о готовности клиента.
---
--- EN:
--- Sends the client readiness message to the server.
function GCClientReadiness.ReportReady()
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

    -- RU: Устанавливаем флаг готовности клиента.
    -- EN: Set the client readiness flag.
    GCClientState.SetReady(true)
    return true
end

--- RU: Отправляет совместимый recovery handshake. isPedAlive остаётся только hint.
--- EN: Sends the compatible recovery handshake. isPedAlive remains only a hint.
--- @return boolean sent
function GCClientReadiness.ReportResyncReady()
    if not GCClientReadiness.IsClientReady() then
        return false
    end

    local ped = PlayerPedId()
    local isPedAlive = ped ~= 0 and DoesEntityExist(ped) and IsPedAlive(ped)

    TriggerServerEvent(GCEvents.Server.resyncReady, {
        protocolVersion = GCVersion.GetProtocolVersion(),
        clientVersion = GCVersion.GetString(),
        locale = GCConfig.General.locale,
        isPedAlive = isPedAlive
    })

    GCClientState.SetReady(true)
    return true
end

--- RU: Подтверждает получение handshake-ответа от сервера.
--- EN: Acknowledges a server response to the handshake.
function GCClientReadiness.Acknowledge()
    handshakeAcknowledged = true
end

--- RU:
--- Запускает ограниченный цикл ожидания готовности клиента.
---
--- EN:
--- Starts a bounded loop waiting for client readiness.
function GCClientReadiness.WaitForReadiness(handshakeType)
    if handshakeType == 'resync' then
        requestedHandshake = 'resync'
    end

    -- RU: Duplicate forceResync не создаёт параллельные readiness threads.
    -- EN: Duplicate forceResync does not create parallel readiness threads.
    if waitActive then
        return
    end

    waitActive = true

    -- RU: Запускаем поток ожидания.
    -- EN: Start the waiting thread.
    CreateThread(function()
        local startedAt = GetGameTimer()
        local timeoutMs = GCConfig.Connection.clientReadyTimeoutMs
        local retryIntervalMs = GCConfig.Connection.clientHelloRetryIntervalMs or 1000
        local maxAttempts = GCConfig.Connection.clientHelloMaxAttempts or 20
        local attempts = 0

        -- EN: A hello sent immediately after client resource start may precede
        -- the final server joining state. Retry until a valid server ACK, with
        -- both an attempt limit and one non-extendable deadline.
        -- RU: Hello сразу после старта client resource может прийти раньше
        -- финального server joining state. Повторяем до валидного server ACK,
        -- с лимитом попыток и одним непродлеваемым deadline.
        while not handshakeAcknowledged do
            if attempts >= maxAttempts or GetGameTimer() - startedAt >= timeoutMs then
                waitActive = false
                GCClientDiagnostics.Report('GC-CLIENT-READY-001')
                return
            end

            if GCClientReadiness.IsClientReady() then
                attempts = attempts + 1

                if requestedHandshake == 'resync' then
                    GCClientReadiness.ReportResyncReady()
                else
                    GCClientReadiness.ReportReady()
                end
            end

            if not handshakeAcknowledged then
                Wait(retryIntervalMs)
            end
        end

        waitActive = false
    end)
end

--- RU:
--- Сбрасывает флаг отправки готовности.
---
--- EN:
--- Resets the readiness sent flag.
function GCClientReadiness.Reset()
    handshakeAcknowledged = false
    requestedHandshake = 'ready'
end
